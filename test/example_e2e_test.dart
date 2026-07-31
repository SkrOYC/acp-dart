@Timeout(Duration(minutes: 2))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp_dart/acp_dart.dart';
import 'package:test/test.dart';

/// End-to-end tests that run `example/agent.dart` as a real subprocess and
/// speak ACP to it over NDJSON, exactly like `example/client.dart` does.
///
/// The example turn calls the agent's simulated model six times per prompt, so
/// these tests are also the regression guard for cancellation plumbing that can
/// only be consumed once (for example a `Future.asStream()` single-subscription
/// stream, which made the second call fail the turn with an internal error).
void main() {
  setUpAll(() {
    expect(
      File('example/agent.dart').existsSync(),
      isTrue,
      reason: 'these tests must run from the package root',
    );
  });

  group('example agent end-to-end', () {
    test('completes a turn when the permission request is allowed', () async {
      final harness = await _startExampleAgent(permissionOptionId: 'allow');

      final initializeResponse = await harness.connection.initialize(
        InitializeRequest(
          protocolVersion: 1,
          clientCapabilities: ClientCapabilities(
            fs: FileSystemCapability(readTextFile: true, writeTextFile: true),
            terminal: true,
          ),
        ),
      );
      expect(initializeResponse.protocolVersion, equals(1));

      final session = await harness.connection.newSession(
        NewSessionRequest(cwd: Directory.current.path, mcpServers: const []),
      );

      final promptResponse = await harness.connection.prompt(
        PromptRequest(
          sessionId: session.sessionId,
          prompt: [TextContentBlock(text: 'Hello, agent!')],
        ),
      );

      expect(
        promptResponse.stopReason,
        equals(StopReason.endTurn),
        reason: 'agent stderr:\n${harness.stderr}',
      );

      // Both tool calls were reported, before and after the permission request.
      expect(
        harness.client.updates.whereType<ToolCallSessionUpdate>().map(
          (update) => update.toolCallId,
        ),
        equals(['call_1', 'call_2']),
      );

      // Exactly one permission request, offering the example's two options.
      expect(harness.client.permissionRequests, hasLength(1));
      expect(
        harness.client.permissionRequests.single.options.map(
          (option) => option.optionId,
        ),
        equals(['allow', 'reject']),
      );

      // Tool call content survives the round trip through the wire, which only
      // works while `ToolCallContent` is encoded with its `type` discriminator.
      final call1Update = harness.client.updates
          .whereType<ToolCallUpdateSessionUpdate>()
          .firstWhere((update) => update.toolCallId == 'call_1');
      expect(call1Update.status, equals(ToolCallStatus.completed));
      final call1Content = call1Update.content!.single;
      expect(call1Content, isA<ContentToolCallContent>());
      expect(
        ((call1Content as ContentToolCallContent).content as TextContentBlock)
            .text,
        contains('My Project'),
      );

      final call2Update = harness.client.updates
          .whereType<ToolCallUpdateSessionUpdate>()
          .firstWhere((update) => update.toolCallId == 'call_2');
      expect(call2Update.status, equals(ToolCallStatus.completed));

      expect(
        harness.client.agentText,
        contains("I've successfully updated the configuration"),
      );
    });

    test('completes a turn when the permission request is rejected', () async {
      final harness = await _startExampleAgent(permissionOptionId: 'reject');

      await harness.connection.initialize(
        InitializeRequest(
          protocolVersion: 1,
          clientCapabilities: ClientCapabilities(
            fs: FileSystemCapability(readTextFile: true, writeTextFile: true),
            terminal: true,
          ),
        ),
      );

      final session = await harness.connection.newSession(
        NewSessionRequest(cwd: Directory.current.path, mcpServers: const []),
      );

      final promptResponse = await harness.connection.prompt(
        PromptRequest(
          sessionId: session.sessionId,
          prompt: [TextContentBlock(text: 'Hello, agent!')],
        ),
      );

      expect(
        promptResponse.stopReason,
        equals(StopReason.endTurn),
        reason: 'agent stderr:\n${harness.stderr}',
      );
      expect(
        harness.client.agentText,
        contains("I'll skip the configuration update"),
      );
      expect(
        harness.client.updates.whereType<ToolCallUpdateSessionUpdate>().map(
          (update) => update.toolCallId,
        ),
        equals(['call_1']),
        reason: 'the rejected tool call must not report a completion',
      );
    });

    test('reports a cancelled stop reason for session/cancel', () async {
      final harness = await _startExampleAgent(permissionOptionId: 'allow');

      await harness.connection.initialize(
        InitializeRequest(
          protocolVersion: 1,
          clientCapabilities: ClientCapabilities(),
        ),
      );

      final session = await harness.connection.newSession(
        NewSessionRequest(cwd: Directory.current.path, mcpServers: const []),
      );

      final promptFuture = harness.connection.prompt(
        PromptRequest(
          sessionId: session.sessionId,
          prompt: [TextContentBlock(text: 'Hello, agent!')],
        ),
      );

      // Cancel once the turn is underway, while the agent is waiting on its
      // next simulated model call.
      await harness.client.firstToolCall;
      await harness.connection.cancel(
        CancelNotification(sessionId: session.sessionId),
      );

      final promptResponse = await promptFuture;

      expect(
        promptResponse.stopReason,
        equals(StopReason.cancelled),
        reason: 'agent stderr:\n${harness.stderr}',
      );
      expect(
        harness.client.permissionRequests,
        isEmpty,
        reason: 'a cancelled turn must not go on to ask for permission',
      );
      expect(
        harness.client.updates.whereType<ToolCallSessionUpdate>().map(
          (update) => update.toolCallId,
        ),
        equals(['call_1']),
        reason: 'a cancelled turn must not start the second tool call',
      );
    });

    test(
      'reports a cancelled stop reason for a cancelled permission request',
      () async {
        final harness = await _startExampleAgent();

        await harness.connection.initialize(
          InitializeRequest(
            protocolVersion: 1,
            clientCapabilities: ClientCapabilities(),
          ),
        );

        final session = await harness.connection.newSession(
          NewSessionRequest(cwd: Directory.current.path, mcpServers: const []),
        );

        final promptResponse = await harness.connection.prompt(
          PromptRequest(
            sessionId: session.sessionId,
            prompt: [TextContentBlock(text: 'Hello, agent!')],
          ),
        );

        expect(
          promptResponse.stopReason,
          equals(StopReason.cancelled),
          reason: 'agent stderr:\n${harness.stderr}',
        );
        // The pending update is still delivered before the turn unwinds.
        expect(
          harness.client.agentText,
          contains('The permission request was cancelled'),
        );
        expect(
          harness.client.updates.whereType<ToolCallUpdateSessionUpdate>().where(
            (update) => update.toolCallId == 'call_2',
          ),
          isEmpty,
          reason: 'the tool call under review must not run',
        );
      },
    );
  });

  test(
    'example/client.dart drives the example agent to a stop reason',
    () async {
      final process = await Process.start(Platform.resolvedExecutable, [
        'run',
        'example/client.dart',
      ], workingDirectory: Directory.current.path);
      addTearDown(() => process.kill());

      // The example client prompts for a permission choice on stdin; "1" selects
      // "Allow this change".
      process.stdin.writeln('1');
      await process.stdin.flush();

      final stdoutText = await process.stdout.transform(utf8.decoder).join();
      final stderrText = await process.stderr.transform(utf8.decoder).join();
      await process.exitCode;

      expect(
        stdoutText,
        contains('Connected to agent (protocol v1)'),
        reason: 'client stderr:\n$stderrText',
      );
      expect(
        stdoutText,
        contains('stop reason: StopReason.endTurn'),
        reason: 'client stderr:\n$stderrText',
      );
      expect(
        stdoutText,
        isNot(contains('Error handling notification')),
        reason: 'every session/update must decode on the client side',
      );
    },
  );
}

/// A running `example/agent.dart` subprocess plus the client that drives it.
class _ExampleAgentHarness {
  _ExampleAgentHarness({
    required this.connection,
    required this.client,
    required StringBuffer stderrBuffer,
  }) : _stderrBuffer = stderrBuffer;

  final ClientSideConnection connection;
  final _RecordingClient client;
  final StringBuffer _stderrBuffer;

  /// Anything the agent wrote to stderr, used to explain failures.
  String get stderr => _stderrBuffer.toString();
}

/// Starts `example/agent.dart` and connects a client to it.
///
/// Permission requests are answered by selecting [permissionOptionId], or with
/// a cancelled outcome when it is null.
Future<_ExampleAgentHarness> _startExampleAgent({
  String? permissionOptionId,
}) async {
  final process = await Process.start(Platform.resolvedExecutable, [
    'run',
    'example/agent.dart',
  ], workingDirectory: Directory.current.path);
  addTearDown(() => process.kill());

  final stderrBuffer = StringBuffer();
  process.stderr.transform(utf8.decoder).listen(stderrBuffer.write);

  final client = _RecordingClient(permissionOptionId: permissionOptionId);
  final connection = ClientSideConnection(
    (agent) => client,
    ndJsonStream(process.stdout, process.stdin),
  );

  return _ExampleAgentHarness(
    connection: connection,
    client: client,
    stderrBuffer: stderrBuffer,
  );
}

/// Records everything the agent reports and answers permission requests with a
/// fixed outcome, so a turn can run without a human at the keyboard.
class _RecordingClient implements Client {
  _RecordingClient({this.permissionOptionId});

  /// The option to select, or null to answer with a cancelled outcome.
  final String? permissionOptionId;

  final List<SessionUpdate> updates = [];
  final List<RequestPermissionRequest> permissionRequests = [];
  final Completer<void> _firstToolCall = Completer<void>();

  /// Completes when the agent reports its first tool call, so a test can
  /// cancel at a known point in the turn instead of after a fixed delay.
  Future<void> get firstToolCall => _firstToolCall.future;

  /// All agent message chunks concatenated, in the order they arrived.
  String get agentText => updates
      .whereType<AgentMessageChunkSessionUpdate>()
      .map((update) => (update.content as TextContentBlock).text)
      .join();

  @override
  Future<RequestPermissionResponse> requestPermission(
    RequestPermissionRequest params,
  ) async {
    permissionRequests.add(params);
    final optionId = permissionOptionId;
    return RequestPermissionResponse(
      outcome: optionId == null
          ? CancelledOutcome()
          : SelectedOutcome(optionId: optionId),
    );
  }

  @override
  Future<void> sessionUpdate(SessionNotification params) async {
    updates.add(params.update);
    if (params.update is ToolCallSessionUpdate && !_firstToolCall.isCompleted) {
      _firstToolCall.complete();
    }
  }

  // The example agent never calls back into the filesystem or terminal methods;
  // returning null reports them as unimplemented.
  @override
  Future<WriteTextFileResponse>? writeTextFile(WriteTextFileRequest params) =>
      null;

  @override
  Future<ReadTextFileResponse>? readTextFile(ReadTextFileRequest params) =>
      null;

  @override
  Future<CreateTerminalResponse>? createTerminal(
    CreateTerminalRequest params,
  ) => null;

  @override
  Future<TerminalOutputResponse>? terminalOutput(
    TerminalOutputRequest params,
  ) => null;

  @override
  Future<ReleaseTerminalResponse?>? releaseTerminal(
    ReleaseTerminalRequest params,
  ) => null;

  @override
  Future<WaitForTerminalExitResponse>? waitForTerminalExit(
    WaitForTerminalExitRequest params,
  ) => null;

  @override
  Future<KillTerminalCommandResponse?>? killTerminal(
    KillTerminalCommandRequest params,
  ) => null;

  @override
  Future<Map<String, dynamic>>? extMethod(
    String method,
    Map<String, dynamic> params,
  ) => null;

  @override
  Future<void>? extNotification(
    String method,
    Map<String, dynamic> params,
  ) async {}
}
