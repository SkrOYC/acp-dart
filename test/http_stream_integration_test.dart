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
              if (sessionId != 's-1') {
                throw StateError('Missing routed session header');
              }
              routedResponseSeen.complete();
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
      await routedResponseSeen.future.timeout(const Duration(seconds: 3));
      expect(observedCookies, [
        'sid=caller; caller=c',
        'sid=caller; caller=c',
        'sid=caller; caller=c',
      ]);
      await stream.writable.close();
      await server.close(force: true);
    },
  );
}
