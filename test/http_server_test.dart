import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp_dart/src/acp.dart';
import 'package:acp_dart/src/http_server.dart';
import 'package:acp_dart/src/schema.dart';
import 'package:test/test.dart';

class _Agent extends Agent {
  _Agent([this.client]);

  final AgentSideConnection? client;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<InitializeResponse> initialize(InitializeRequest params) async =>
      InitializeResponse(
        protocolVersion: params.protocolVersion,
        agentCapabilities: AgentCapabilities(),
      );

  @override
  Future<NewSessionResponse> newSession(NewSessionRequest params) async =>
      NewSessionResponse(sessionId: 's-1');

  @override
  Future<PromptResponse> prompt(PromptRequest params) async {
    await client?.requestPermission(
      RequestPermissionRequest(
        sessionId: params.sessionId,
        options: [
          PermissionOption(
            optionId: 'allow',
            name: 'Allow once',
            kind: PermissionOptionKind.allowOnce,
          ),
        ],
        toolCall: ToolCallUpdate(toolCallId: 'call-1'),
      ),
    );
    return PromptResponse(stopReason: StopReason.endTurn);
  }

  @override
  Future<void> cancel(CancelNotification params) async {}
}

void main() {
  test(
    'initializes over HTTP, accepts a session request and streams its response',
    () async {
      final server = await AcpHttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
        agentFactory: (_) => _Agent(),
      );
      addTearDown(server.close);
      final client = HttpClient();
      addTearDown(client.close);
      final base = 'http://${server.address.address}:${server.port}';

      final init = await client.postUrl(Uri.parse(base));
      init.headers.contentType = ContentType.json;
      init.write(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'initialize',
          'params': {'protocolVersion': 1, 'clientCapabilities': {}},
        }),
      );
      final initResponse = await init.close();
      expect(initResponse.statusCode, 200);
      final connectionId = initResponse.headers.value('Acp-Connection-Id');
      expect(connectionId, isNotNull);
      expect(
        jsonDecode(await utf8.decoder.bind(initResponse).join()),
        containsPair('id', 1),
      );

      final get = await client.getUrl(Uri.parse(base));
      get.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      get.headers.set('Acp-Connection-Id', connectionId!);
      final events = await get.close();
      expect(events.statusCode, 200);

      final post = await client.postUrl(Uri.parse(base));
      post.headers.contentType = ContentType.json;
      post.headers.set('Acp-Connection-Id', connectionId);
      post.write(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 2,
          'method': 'session/new',
          'params': {'cwd': '/tmp', 'mcpServers': []},
        }),
      );
      expect((await post.close()).statusCode, 202);
      final event = await utf8.decoder
          .bind(events)
          .transform(const LineSplitter())
          .firstWhere((line) => line.startsWith('data: '))
          .timeout(const Duration(seconds: 2));
      expect(jsonDecode(event.substring(6)), containsPair('id', 2));
      final sessionEventsRequest = await client.getUrl(Uri.parse(base));
      sessionEventsRequest.headers.set(
        HttpHeaders.acceptHeader,
        'text/event-stream',
      );
      sessionEventsRequest.headers.set('Acp-Connection-Id', connectionId);
      sessionEventsRequest.headers.set('Acp-Session-Id', 's-1');
      final sessionEvents = await sessionEventsRequest.close();
      final prompt = await client.postUrl(Uri.parse(base));
      prompt.headers.contentType = ContentType.json;
      prompt.headers.set('Acp-Connection-Id', connectionId);
      prompt.headers.set('Acp-Session-Id', 's-1');
      prompt.write(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 3,
          'method': 'session/prompt',
          'params': {'sessionId': 's-1', 'prompt': []},
        }),
      );
      expect((await prompt.close()).statusCode, 202);
      final sessionEvent = await utf8.decoder
          .bind(sessionEvents)
          .transform(const LineSplitter())
          .firstWhere((line) => line.startsWith('data: '))
          .timeout(const Duration(seconds: 2));
      expect(jsonDecode(sessionEvent.substring(6)), containsPair('id', 3));
      final delete = await client.deleteUrl(Uri.parse(base));
      delete.headers.set('Acp-Connection-Id', connectionId);
      expect((await delete.close()).statusCode, 202);
      final postAfterDelete = await client.postUrl(Uri.parse(base));
      postAfterDelete.headers.contentType = ContentType.json;
      postAfterDelete.headers.set('Acp-Connection-Id', connectionId);
      postAfterDelete.write(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 4,
          'method': 'session/new',
          'params': {},
        }),
      );
      expect((await postAfterDelete.close()).statusCode, 404);
    },
  );

  test('rejects missing connection IDs on connected requests', () async {
    final server = await AcpHttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
      agentFactory: (_) => _Agent(),
    );
    addTearDown(server.close);
    final client = HttpClient();
    addTearDown(client.close);
    final request = await client.postUrl(
      Uri.parse('http://${server.address.address}:${server.port}'),
    );
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'session/new',
        'params': {},
      }),
    );
    expect((await request.close()).statusCode, 400);
  });

  test('reports transport validation statuses for HTTP requests', () async {
    final server = await AcpHttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
      agentFactory: (_) => _Agent(),
    );
    addTearDown(server.close);
    final client = HttpClient();
    addTearDown(client.close);
    final base = 'http://${server.address.address}:${server.port}';
    final unsupported = await client.postUrl(Uri.parse(base));
    unsupported.write('{}');
    expect((await unsupported.close()).statusCode, 415);
    final unacceptable = await client.getUrl(Uri.parse(base));
    expect((await unacceptable.close()).statusCode, 406);
    final unknown = await client.getUrl(Uri.parse(base));
    unknown.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
    unknown.headers.set('Acp-Connection-Id', 'missing');
    expect((await unknown.close()).statusCode, 404);
    final batch = await client.postUrl(Uri.parse(base));
    batch.headers.contentType = ContentType.json;
    batch.write('[{}]');
    expect((await batch.close()).statusCode, 501);
  });

  test(
    'returns an initialize JSON-RPC error when agent construction throws',
    () async {
      final server = await AcpHttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
        agentFactory: (_) => throw StateError('factory failed'),
      );
      addTearDown(server.close);
      final client = HttpClient();
      addTearDown(client.close);
      final request = await client.postUrl(
        Uri.parse('http://${server.address.address}:${server.port}'),
      );
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 7,
          'method': 'initialize',
          'params': {'protocolVersion': 1, 'clientCapabilities': {}},
        }),
      );

      final response = await request.close();
      expect(response.statusCode, 500);
      expect(response.headers.contentType?.mimeType, 'application/json');
      final body = jsonDecode(await utf8.decoder.bind(response).join());
      expect(body['id'], 7);
      expect(body['error']['code'], -32603);
      expect(body['error']['message'], 'Initialize failed');
      expect(body['error']['data'], contains('factory failed'));
    },
  );

  test(
    'releases the SSE receiver lease after a client closes the stream',
    () async {
      final server = await AcpHttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
        agentFactory: (_) => _Agent(),
      );
      addTearDown(server.close);
      final client = HttpClient();
      addTearDown(client.close);
      final base = 'http://${server.address.address}:${server.port}';
      final connectionId = await _initialize(client, base);
      final firstRequest = await client.getUrl(Uri.parse(base));
      firstRequest.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      firstRequest.headers.set('Acp-Connection-Id', connectionId);
      final firstResponse = await firstRequest.close();
      final firstChunk = Completer<void>();
      final subscription = firstResponse.listen((_) {
        if (!firstChunk.isCompleted) firstChunk.complete();
      });
      await firstChunk.future.timeout(const Duration(seconds: 2));
      await subscription.cancel();
      client.close(force: true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final retryClient = HttpClient();
      addTearDown(retryClient.close);
      final secondRequest = await retryClient.getUrl(Uri.parse(base));
      secondRequest.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      secondRequest.headers.set('Acp-Connection-Id', connectionId);
      final secondResponse = await secondRequest.close();
      expect(secondResponse.statusCode, 200);
      final responseLines = utf8.decoder
          .bind(secondResponse)
          .transform(const LineSplitter());
      final post = await retryClient.postUrl(Uri.parse(base));
      post.headers.contentType = ContentType.json;
      post.headers.set('Acp-Connection-Id', connectionId);
      post.write(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 2,
          'method': 'session/new',
          'params': {'cwd': '/tmp', 'mcpServers': []},
        }),
      );
      expect((await post.close()).statusCode, 202);
      final event = await responseLines
          .firstWhere((line) => line.startsWith('data: '))
          .timeout(const Duration(seconds: 2));
      expect(jsonDecode(event.substring(6)), containsPair('id', 2));
    },
  );

  test('initializes and processes ACP over a WebSocket upgrade', () async {
    final server = await AcpHttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
      agentFactory: (_) => _Agent(),
    );
    addTearDown(server.close);
    final socket = await WebSocket.connect(
      'ws://${server.address.address}:${server.port}',
    );
    addTearDown(socket.close);
    final messages = StreamIterator<Object?>(socket);
    addTearDown(messages.cancel);
    socket.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {'protocolVersion': 1, 'clientCapabilities': {}},
      }),
    );
    final response = jsonDecode(await _nextSocketMessage(messages));
    expect(response, containsPair('id', 1));
    expect(response['result'], containsPair('protocolVersion', 1));

    socket.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'session/new',
        'params': {'cwd': '/tmp', 'mcpServers': []},
      }),
    );
    final sessionResponse = jsonDecode(await _nextSocketMessage(messages));
    expect(sessionResponse, containsPair('id', 2));
  });

  test('returns the connection ID in the WebSocket upgrade response', () async {
    final server = await AcpHttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
      agentFactory: (_) => _Agent(),
    );
    addTearDown(server.close);
    final socket = await Socket.connect(server.address, server.port);
    addTearDown(socket.close);
    socket.write(
      'GET / HTTP/1.1\r\n'
      'Host: ${server.address.address}:${server.port}\r\n'
      'Upgrade: websocket\r\n'
      'Connection: Upgrade\r\n'
      'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n'
      'Sec-WebSocket-Version: 13\r\n\r\n',
    );
    await socket.flush();
    final lines = StreamIterator<String>(
      utf8.decoder.bind(socket).transform(const LineSplitter()),
    );
    addTearDown(lines.cancel);
    final responseHeaders = <String>[];
    while (await lines.moveNext().timeout(const Duration(seconds: 2))) {
      if (lines.current.isEmpty) break;
      responseHeaders.add(lines.current);
    }
    expect(responseHeaders.first, startsWith('HTTP/1.1 101'));
    expect(
      responseHeaders.any(
        (line) => line.toLowerCase().startsWith('acp-connection-id: acp-'),
      ),
      isTrue,
    );
  });

  test(
    'routes permission requests to session SSE and returns the callback result',
    () async {
      final server = await AcpHttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
        agentFactory: (client) => _Agent(client),
      );
      addTearDown(server.close);
      final client = HttpClient();
      addTearDown(client.close);
      final base = 'http://${server.address.address}:${server.port}';
      final connectionId = await _initialize(client, base);
      final connectionEventsRequest = await client.getUrl(Uri.parse(base));
      connectionEventsRequest.headers.set(
        HttpHeaders.acceptHeader,
        'text/event-stream',
      );
      connectionEventsRequest.headers.set('Acp-Connection-Id', connectionId);
      final connectionEvents = await connectionEventsRequest.close();
      final connectionLines = StreamIterator<String>(
        utf8.decoder.bind(connectionEvents).transform(const LineSplitter()),
      );
      addTearDown(connectionLines.cancel);
      final createSession = await client.postUrl(Uri.parse(base));
      createSession.headers.contentType = ContentType.json;
      createSession.headers.set('Acp-Connection-Id', connectionId);
      createSession.write(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 2,
          'method': 'session/new',
          'params': {'cwd': '/tmp', 'mcpServers': []},
        }),
      );
      expect((await createSession.close()).statusCode, 202);
      final sessionCreation = jsonDecode(await _nextSseData(connectionLines));
      final sessionId = sessionCreation['result']['sessionId'] as String;
      final sessionEventsRequest = await client.getUrl(Uri.parse(base));
      sessionEventsRequest.headers.set(
        HttpHeaders.acceptHeader,
        'text/event-stream',
      );
      sessionEventsRequest.headers.set('Acp-Connection-Id', connectionId);
      sessionEventsRequest.headers.set('Acp-Session-Id', sessionId);
      final sessionEvents = await sessionEventsRequest.close();
      final sessionLines = StreamIterator<String>(
        utf8.decoder.bind(sessionEvents).transform(const LineSplitter()),
      );
      addTearDown(sessionLines.cancel);
      final prompt = await client.postUrl(Uri.parse(base));
      prompt.headers.contentType = ContentType.json;
      prompt.headers.set('Acp-Connection-Id', connectionId);
      prompt.headers.set('Acp-Session-Id', sessionId);
      prompt.write(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 3,
          'method': 'session/prompt',
          'params': {'sessionId': sessionId, 'prompt': []},
        }),
      );
      expect((await prompt.close()).statusCode, 202);
      final permission = jsonDecode(await _nextSseData(sessionLines));
      expect(permission['method'], 'session/request_permission');
      final permissionResponse = await client.postUrl(Uri.parse(base));
      permissionResponse.headers.contentType = ContentType.json;
      permissionResponse.headers.set('Acp-Connection-Id', connectionId);
      final callback = {
        'jsonrpc': '2.0',
        'id': permission['id'],
        'result': {
          'outcome': {'outcome': 'selected', 'optionId': 'allow'},
        },
      };
      permissionResponse.write(jsonEncode(callback));
      expect((await permissionResponse.close()).statusCode, 400);
      final retry = await client.postUrl(Uri.parse(base));
      retry.headers.contentType = ContentType.json;
      retry.headers.set('Acp-Connection-Id', connectionId);
      retry.headers.set('Acp-Session-Id', 'wrong-session');
      retry.write(jsonEncode(callback));
      expect((await retry.close()).statusCode, 400);
      final accepted = await client.postUrl(Uri.parse(base));
      accepted.headers.contentType = ContentType.json;
      accepted.headers.set('Acp-Connection-Id', connectionId);
      accepted.headers.set('Acp-Session-Id', sessionId);
      accepted.write(jsonEncode(callback));
      expect((await accepted.close()).statusCode, 202);
      final response = jsonDecode(await _nextSseData(sessionLines));
      expect(response, containsPair('id', 3));
    },
  );
}

Future<String> _nextSseData(StreamIterator<String> lines) async {
  while (await lines.moveNext().timeout(const Duration(seconds: 2))) {
    final line = lines.current;
    if (line.startsWith('data: ')) return line.substring(6);
  }
  throw StateError('SSE stream closed before a data event');
}

Future<String> _initialize(HttpClient client, String base) async {
  final init = await client.postUrl(Uri.parse(base));
  init.headers.contentType = ContentType.json;
  init.write(
    jsonEncode({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'initialize',
      'params': {'protocolVersion': 1, 'clientCapabilities': {}},
    }),
  );
  final response = await init.close();
  expect(response.statusCode, 200);
  return response.headers.value('Acp-Connection-Id')!;
}

Future<String> _nextSocketMessage(StreamIterator<Object?> messages) async {
  if (!await messages.moveNext().timeout(const Duration(seconds: 2))) {
    throw StateError('WebSocket closed before a response');
  }
  return messages.current as String;
}
