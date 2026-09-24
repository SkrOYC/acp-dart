import 'dart:async';
import 'dart:io';

import 'package:acp_dart/src/acp.dart';
import 'package:acp_dart/src/http_server.dart';
import 'package:acp_dart/src/http_stream.dart';
import 'package:acp_dart/src/schema.dart';
import 'package:test/test.dart';

class _LoopbackAgent extends Agent {
  _LoopbackAgent(this.client);

  final AgentSideConnection client;

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
      NewSessionResponse(sessionId: 'loopback-session');

  @override
  Future<void> cancel(CancelNotification params) async {}

  @override
  Future<PromptResponse> prompt(PromptRequest params) async {
    await client.sessionUpdate(
      SessionNotification(
        sessionId: params.sessionId,
        update: AgentMessageChunkSessionUpdate(
          content: TextContentBlock(type: 'text', text: 'working'),
        ),
      ),
    );
    await client.requestPermission(
      RequestPermissionRequest(
        sessionId: params.sessionId,
        options: [
          PermissionOption(
            optionId: 'allow',
            name: 'Allow once',
            kind: PermissionOptionKind.allowOnce,
          ),
        ],
        toolCall: ToolCallUpdate(toolCallId: 'tool-1'),
      ),
    );
    return PromptResponse(stopReason: StopReason.endTurn);
  }
}

class _LoopbackClient extends Client {
  final update = Completer<SessionNotification>();
  final permission = Completer<RequestPermissionRequest>();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> sessionUpdate(SessionNotification params) async {
    update.complete(params);
  }

  @override
  Future<RequestPermissionResponse> requestPermission(
    RequestPermissionRequest params,
  ) async {
    permission.complete(params);
    return RequestPermissionResponse(
      outcome: SelectedOutcome(optionId: 'allow'),
    );
  }
}

void main() {
  test(
    'HTTP client and server complete initialize, session, update and permission',
    () async {
      final server = await AcpHttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
        agentFactory: (connection) => _LoopbackAgent(connection),
      );
      addTearDown(server.close);
      final stream = createHttpStream(
        'http://${server.address.address}:${server.port}',
      );
      final app = _LoopbackClient();
      final connection = ClientSideConnection((_) => app, stream);

      final initialized = await connection.initialize(
        InitializeRequest(
          protocolVersion: 1,
          clientCapabilities: ClientCapabilities(),
        ),
      );
      expect(initialized.protocolVersion, 1);
      final session = await connection.newSession(
        NewSessionRequest(cwd: '/tmp', mcpServers: []),
      );
      expect(session.sessionId, 'loopback-session');
      final prompt = connection.prompt(
        PromptRequest(
          sessionId: session.sessionId,
          prompt: [TextContentBlock(type: 'text', text: 'hello')],
        ),
      );
      final update = await app.update.future.timeout(
        const Duration(seconds: 3),
      );
      final permission = await app.permission.future.timeout(
        const Duration(seconds: 3),
      );
      final result = await prompt.timeout(const Duration(seconds: 3));

      expect(update.sessionId, session.sessionId);
      expect(permission.sessionId, session.sessionId);
      expect(permission.toolCall.toolCallId, 'tool-1');
      expect(result.stopReason, StopReason.endTurn);
      await stream.writable.close();
    },
  );
}
