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
    stream.writable.add({'jsonrpc': '2.0', 'id': 1, 'method': 'initialize'});
    await expectLater(stream.readable.first, throwsA(isA<SocketException>()));
    await stream.writable.close();
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

  test('WebSocket stream reports malformed JSON as a readable error', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    WebSocket? peer;
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      peer = socket;
      socket.add('{');
    });
    final stream = createWebSocketStream(
      'ws://${server.address.address}:${server.port}/acp',
    );
    await expectLater(stream.readable.first, throwsA(isA<FormatException>()));
    await stream.writable.close();
    await peer?.close();
    await server.close(force: true);
  });
}
