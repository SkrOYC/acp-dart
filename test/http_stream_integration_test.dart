import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp_dart/src/http_stream.dart';
import 'package:test/test.dart';

void main() {
  test(
    'HTTP stream surfaces a missing connection ID from initialize',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        await request.drain<void>();
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"jsonrpc":"2.0","id":1,"result":{}}');
        await request.response.close();
      });
      final stream = createHttpStream(
        'http://${server.address.address}:${server.port}/acp',
      );
      stream.writable.add({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {},
      });
      await expectLater(stream.readable.first, throwsA(isA<HttpException>()));
      await stream.writable.close();
      await server.close(force: true);
    },
  );

  test(
    'HTTP stream routes session traffic and affinity cookies over loopback',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final eventsOpened = <String, Completer<void>>{
        '': Completer<void>(),
        's-1': Completer<void>(),
      };
      final events = <String, HttpResponse>{};
      final observedCookies = <String>[];
      final routedResponseSeen = Completer<void>();
      final routedSessionHeaders = <String?>[];
      server.listen((request) async {
        final sessionId = request.headers.value('Acp-Session-Id') ?? '';
        if (request.method == 'POST') {
          final body =
              jsonDecode(await utf8.decoder.bind(request).join())
                  as Map<String, dynamic>;
          observedCookies.add(
            request.headers.value(HttpHeaders.cookieHeader) ?? '',
          );
          if (body['method'] == 'initialize') {
            request.response.headers.set('Acp-Connection-Id', 'c-1');
            request.response.headers.add(
              HttpHeaders.setCookieHeader,
              'sid=managed',
            );
            request.response.headers.contentType = ContentType.json;
            request.response.write(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': body['id'],
                'result': {'protocolVersion': 1},
              }),
            );
          } else {
            if (body['method'] == 'session/prompt') {
              final eventStream = events['s-1']!;
              eventStream.write(
                'data: ${jsonEncode({
                  'jsonrpc': '2.0',
                  'id': body['id'],
                  'result': {'accepted': true},
                })}\n\n',
              );
              eventStream.write(
                'data: ${jsonEncode({
                  'jsonrpc': '2.0',
                  'id': 'server-1',
                  'method': 'session/request_permission',
                  'params': {'sessionId': 's-1'},
                })}\n\n',
              );
              await eventStream.flush();
              await eventStream.close();
            } else {
              routedSessionHeaders.add(request.headers.value('Acp-Session-Id'));
              if (routedSessionHeaders.length == 2) {
                routedResponseSeen.complete();
              }
            }
            request.response.statusCode = HttpStatus.accepted;
          }
          await request.response.close();
        } else if (request.method == 'GET') {
          request.response.headers.contentType = ContentType(
            'text',
            'event-stream',
          );
          events[sessionId] = request.response;
          request.response.write(': ready\n\n');
          await request.response.flush();
          if (!eventsOpened[sessionId]!.isCompleted) {
            eventsOpened[sessionId]!.complete();
          }
        } else if (request.method == 'DELETE') {
          request.response.statusCode = HttpStatus.noContent;
          await request.response.close();
        }
      });

      final stream = createHttpStream(
        'http://${server.address.address}:${server.port}/acp',
        options: const HttpStreamOptions(
          headers: {HttpHeaders.cookieHeader: 'sid=caller; caller=c'},
        ),
      );
      final incoming = StreamIterator(stream.readable);
      stream.writable.add({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {},
      });
      expect(
        await incoming.moveNext().timeout(const Duration(seconds: 3)),
        isTrue,
      );
      expect(incoming.current, {
        'jsonrpc': '2.0',
        'id': 1,
        'result': {'protocolVersion': 1},
      });
      await eventsOpened['']!.future.timeout(const Duration(seconds: 3));

      stream.writable.add({
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'session/prompt',
        'params': {'sessionId': 's-1'},
      });
      await eventsOpened['s-1']!.future.timeout(const Duration(seconds: 3));
      expect(
        await incoming.moveNext().timeout(const Duration(seconds: 3)),
        isTrue,
      );
      expect(incoming.current, {
        'jsonrpc': '2.0',
        'id': 2,
        'result': {'accepted': true},
      });
      expect(
        await incoming.moveNext().timeout(const Duration(seconds: 3)),
        isTrue,
      );
      expect(incoming.current, {
        'jsonrpc': '2.0',
        'id': 'server-1',
        'method': 'session/request_permission',
        'params': {'sessionId': 's-1'},
      });
      stream.writable.add({
        'jsonrpc': '2.0',
        'id': 'server-1',
        'result': {'outcome': 'selected'},
      });
      stream.writable.add({
        'jsonrpc': '2.0',
        'id': 'server-1',
        'result': {'outcome': 'duplicate'},
      });
      await routedResponseSeen.future.timeout(const Duration(seconds: 3));
      expect(routedSessionHeaders, ['s-1', null]);
      expect(observedCookies, [
        'sid=caller; caller=c',
        'sid=caller; caller=c',
        'sid=caller; caller=c',
        'sid=caller; caller=c',
      ]);
      await incoming.cancel();
      await stream.writable.close();
      await server.close(force: true);
    },
  );

  test('HTTP stream skips malformed SSE data and flushes EOF data', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.method == 'POST') {
        final message =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        request.response.headers.set('Acp-Connection-Id', 'c-1');
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({'jsonrpc': '2.0', 'id': message['id'], 'result': {}}),
        );
      } else if (request.method == 'GET') {
        request.response.headers.contentType = ContentType(
          'text',
          'event-stream',
        );
        request.response.write('data: not-json\n\n');
        request.response.write('data: {"jsonrpc":"2.0","method":"ready"}');
      }
      await request.response.close();
    });
    final stream = createHttpStream(
      'http://${server.address.address}:${server.port}/acp',
    );
    final incoming = StreamIterator(stream.readable);
    stream.writable.add({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'initialize',
      'params': {},
    });
    expect(await incoming.moveNext(), isTrue);
    expect(await incoming.moveNext(), isTrue);
    expect(incoming.current, {'jsonrpc': '2.0', 'method': 'ready'});
    await incoming.cancel();
    await stream.writable.close();
    await server.close(force: true);
  });

  test('HTTP transport preserves reserved SSE and delete headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final observed = <String, Map<String, String?>>{};
    final getSeen = Completer<void>();
    final deleteSeen = Completer<void>();
    HttpResponse? events;
    server.listen((request) async {
      observed[request.method] = {
        'accept': request.headers.value(HttpHeaders.acceptHeader),
        'connection': request.headers.value('Acp-Connection-Id'),
        'session': request.headers.value('Acp-Session-Id'),
      };
      if (request.method == 'POST') {
        final message =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        request.response.headers.set('Acp-Connection-Id', 'actual');
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({'jsonrpc': '2.0', 'id': message['id'], 'result': {}}),
        );
      } else if (request.method == 'GET') {
        request.response.headers.contentType = ContentType(
          'text',
          'event-stream',
        );
        events = request.response;
        request.response.write(': ready\n\n');
        await request.response.flush();
        getSeen.complete();
        return;
      }
      if (request.method == 'DELETE') deleteSeen.complete();
      await request.response.close();
    });
    final stream = createHttpStream(
      'http://${server.address.address}:${server.port}/acp',
      options: const HttpStreamOptions(
        headers: {
          HttpHeaders.acceptHeader: 'text/plain',
          'Acp-Connection-Id': 'caller',
          'Acp-Session-Id': 'caller-session',
        },
      ),
    );
    final incoming = StreamIterator(stream.readable);
    stream.writable.add({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'initialize',
      'params': {},
    });
    await incoming.moveNext();
    await getSeen.future.timeout(const Duration(seconds: 2));
    await stream.writable.close();
    await deleteSeen.future.timeout(const Duration(seconds: 2));
    expect(observed['GET']!['accept'], 'text/event-stream');
    expect(observed['GET']!['connection'], 'actual');
    expect(observed['GET']!['session'], isNull);
    expect(observed['DELETE']!['connection'], 'actual');
    await incoming.cancel();
    await events?.close();
    await server.close(force: true);
  });
}
