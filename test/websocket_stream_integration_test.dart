import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp_dart/src/websocket_stream.dart';
import 'package:acp_dart/src/cookie_store.dart';
import 'package:test/test.dart';

void main() {
  test('WebSocket stream reports handshake failures', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await server.close(force: true);
    final stream = createWebSocketStream(
      'ws://${InternetAddress.loopbackIPv4.address}:$port/acp',
    );
    final incoming = StreamIterator(stream.readable);
    stream.writable.add({'jsonrpc': '2.0', 'id': 1, 'method': 'initialize'});
    await expectLater(incoming.moveNext(), throwsA(isA<SocketException>()));
    expect(await incoming.moveNext(), isFalse);
    await stream.writable.close();
  });

  test('WebSocket stream drains queued frames before writable close', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final frames = <Map<String, dynamic>>[];
    final receivedBoth = Completer<void>();
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.listen((frame) {
        frames.add(jsonDecode(frame as String) as Map<String, dynamic>);
        if (frames.length == 2 && !receivedBoth.isCompleted) {
          receivedBoth.complete();
        }
      });
    });
    final stream = createWebSocketStream(
      'ws://${server.address.address}:${server.port}/acp',
    );
    stream.writable
      ..add({'jsonrpc': '2.0', 'id': 1, 'method': 'initialize'})
      ..add({'jsonrpc': '2.0', 'method': 'session/cancel', 'params': {}});
    await stream.writable.close();
    await receivedBoth.future.timeout(const Duration(seconds: 3));
    expect(frames.map((frame) => frame['method']), [
      'initialize',
      'session/cancel',
    ]);
    await server.close(force: true);
  });

  test('WebSocket stream exchanges JSON-RPC frames over loopback', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final accepted = Completer<WebSocket>();
    final cookieReceived = Completer<String?>();
    server.listen((request) async {
      cookieReceived.complete(request.headers.value(HttpHeaders.cookieHeader));
      final socket = await WebSocketTransformer.upgrade(request);
      if (!accepted.isCompleted) accepted.complete(socket);
      socket.listen((frame) {
        final message = jsonDecode(frame as String) as Map<String, dynamic>;
        socket.add(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': message['id'],
            'result': {'ok': true},
          }),
        );
      });
    });
    final cookieStore = MemoryAcpCookieStore()..store(['affinity=stored']);
    final stream = createWebSocketStream(
      'ws://${server.address.address}:${server.port}/acp',
      options: WebSocketStreamOptions(
        headers: const {HttpHeaders.cookieHeader: 'affinity=caller; custom=x'},
        cookieStore: cookieStore,
      ),
    );
    final received = stream.readable.first;
    stream.writable.add({
      'jsonrpc': '2.0',
      'id': 9,
      'method': 'initialize',
      'params': {},
    });
    expect(await received.timeout(const Duration(seconds: 3)), {
      'jsonrpc': '2.0',
      'id': 9,
      'result': {'ok': true},
    });
    expect(await cookieReceived.future, 'affinity=caller; custom=x');
    final peer = await accepted.future;
    await stream.writable.close();
    await peer.close();
    await server.close(force: true);
  });

  test(
    'WebSocket stream responds to invalid frames and remains live',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final accepted = Completer<WebSocket>();
      final peerMessages = StreamController<Map<String, dynamic>>();
      server.listen((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        accepted.complete(socket);
        socket.listen((frame) {
          peerMessages.add(jsonDecode(frame as String) as Map<String, dynamic>);
        });
      });
      final stream = createWebSocketStream(
        'ws://${server.address.address}:${server.port}/acp',
      );
      final incoming = StreamIterator(stream.readable);
      final peer = await accepted.future.timeout(const Duration(seconds: 3));
      final responses = StreamIterator(peerMessages.stream);

      peer.add('{');
      expect(
        await responses.moveNext().timeout(const Duration(seconds: 3)),
        isTrue,
      );
      expect(responses.current['id'], isNull);
      expect(responses.current['error']['code'], -32700);
      expect(responses.current['error']['message'], 'Parse error');
      peer.add('null');
      expect(
        await responses.moveNext().timeout(const Duration(seconds: 3)),
        isTrue,
      );
      expect(responses.current['id'], isNull);
      expect(responses.current['error']['code'], -32600);
      expect(responses.current['error']['message'], 'Invalid request');
      expect(responses.current['error']['data'], isNull);

      peer.add('{"jsonrpc":"2.0","method":"test/notification"}');
      expect(
        await incoming.moveNext().timeout(const Duration(seconds: 3)),
        isTrue,
      );
      expect(incoming.current, {
        'jsonrpc': '2.0',
        'method': 'test/notification',
      });
      await incoming.cancel();
      await responses.cancel();
      await peer.close();
      await stream.writable.close();
      await peerMessages.close();
      await server.close(force: true);
    },
  );
}
