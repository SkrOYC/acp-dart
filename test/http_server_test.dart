import 'dart:convert';
import 'dart:io';

import 'package:acp_dart/src/acp.dart';
import 'package:acp_dart/src/http_server.dart';
import 'package:acp_dart/src/schema.dart';
import 'package:test/test.dart';

class _Agent extends Agent {
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
  Future<PromptResponse> prompt(PromptRequest params) async =>
      PromptResponse(stopReason: StopReason.endTurn);

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
}
