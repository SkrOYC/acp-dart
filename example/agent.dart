import 'dart:io';
import 'dart:async';
import 'dart:math';

import 'package:acp_dart/acp_dart.dart';

/// Tracks the state of an agent session including any pending operations
class AgentSession {
  /// Controller for aborting pending operations
  Completer<void>? pendingPrompt;

  AgentSession({this.pendingPrompt});
}

/// Example agent implementation demonstrating ACP protocol usage
class ExampleAgent implements Agent {
  final AgentSideConnection _connection;
  final Map<String, AgentSession> _sessions = {};

  ExampleAgent(this._connection);

  @override
  Future<InitializeResponse> initialize(InitializeRequest params) async {
    return InitializeResponse(
      protocolVersion: '0.1.0', // Using a sample protocol version
      capabilities: AgentCapabilities(
        loadSession: false,
        auth: [], // No authentication methods required for this example
      ),
    );
  }

  @override
  Future<NewSessionResponse> newSession(NewSessionRequest params) async {
    final sessionId = _generateRandomSessionId();

    _sessions[sessionId] = AgentSession();

    return NewSessionResponse(
      sessionId: sessionId,
      modes: SessionModeState(
        available: [SessionMode(id: 'default', name: 'Default')],
        current: 'default',
      ),
    );
  }

  /// Generates a random session ID
  String _generateRandomSessionId() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final buffer = StringBuffer();

    for (int i = 0; i < 16; i++) {
      buffer.write(chars[random.nextInt(chars.length)]);
    }

    return buffer.toString();
  }

  @override
  Future<LoadSessionResponse>? loadSession(LoadSessionRequest params) async {
    // Not implemented in this example
    throw RequestError.methodNotFound('session/load');
  }

  @override
  Future<SetSessionModeResponse?>? setSessionMode(
    SetSessionModeRequest params,
  ) async {
    // Not implemented in this example
    return SetSessionModeResponse();
  }

  @override
  Future<AuthenticateResponse?>? authenticate(
    AuthenticateRequest params,
  ) async {
    // No authentication needed - return empty response
    return AuthenticateResponse();
  }

  @override
  Future<PromptResponse> prompt(PromptRequest params) async {
    final session = _sessions[params.sessionId];

    if (session == null) {
      throw RequestError.resourceNotFound(params.sessionId);
    }

    // Cancel any existing pending prompt
    if (session.pendingPrompt != null && !session.pendingPrompt!.isCompleted) {
      session.pendingPrompt!.complete();
    }

    // Create a new completer for this prompt
    final completer = Completer<void>();
    session.pendingPrompt = completer;

    try {
      await _simulateTurn(params.sessionId, completer.future.asStream());
    } catch (err) {
      if (session.pendingPrompt != null && session.pendingPrompt!.isCompleted) {
        return PromptResponse(done: true);
      }
      rethrow;
    } finally {
      session.pendingPrompt = null;
    }

    return PromptResponse(done: true);
  }

  /// Simulates an agent turn with text chunks and tool calls
  Future<void> _simulateTurn(String sessionId, Stream<void> abortStream) async {
    // Send initial text chunk
    await _connection.sessionUpdate(
      SessionNotification(
        sessionId: sessionId,
        update: AgentMessageChunkSessionUpdate(
          content: TextContentBlock(
            text:
                "I'll help you with that. Let me start by reading some files to understand the current situation.",
          ),
        ),
      ),
    );

    await _simulateModelInteraction(abortStream);

    // Send a tool call that doesn't need permission
    await _connection.sessionUpdate(
      SessionNotification(
        sessionId: sessionId,
        update: ToolCallSessionUpdate(
          toolCallId: "call_1",
          title: "Reading project files",
          kind: ToolKind.read,
          status: ToolCallStatus.pending,
          locations: [ToolCallLocation(path: "/project/README.md")],
          rawInput: {"path": "/project/README.md"},
        ),
      ),
    );

    await _simulateModelInteraction(abortStream);

    // Update tool call to completed
    await _connection.sessionUpdate(
      SessionNotification(
        sessionId: sessionId,
        update: ToolCallUpdateSessionUpdate(
          toolCallId: "call_1",
          status: ToolCallStatus.completed,
          content: [
            ContentToolCallContent(
              content: TextContentBlock(
                text: "# My Project\nThis is a sample project...",
              ),
            ),
          ],
          rawOutput: {"content": "# My Project\n\nThis is a sample project..."},
        ),
      ),
    );

    await _simulateModelInteraction(abortStream);

    // Send more text
    await _connection.sessionUpdate(
      SessionNotification(
        sessionId: sessionId,
        update: AgentMessageChunkSessionUpdate(
          content: TextContentBlock(
            text:
                " Now I understand the project structure. I need to make some changes to improve it.",
          ),
        ),
      ),
    );

    await _simulateModelInteraction(abortStream);

    // Send a tool call that DOES need permission
    await _connection.sessionUpdate(
      SessionNotification(
        sessionId: sessionId,
        update: ToolCallSessionUpdate(
          toolCallId: "call_2",
          title: "Modifying critical configuration file",
          kind: ToolKind.edit,
          status: ToolCallStatus.pending,
          locations: [ToolCallLocation(path: "/project/config.json")],
          rawInput: {
            "path": "/project/config.json",
            "content": '{"database": {"host": "new-host"}}',
          },
        ),
      ),
    );

    // Request permission for the sensitive operation
    final permissionResponse = await _connection.requestPermission(
      RequestPermissionRequest(
        question: "Allow this change?",
        options: [
          PermissionOption(id: "allow", title: "Allow this change"),
          PermissionOption(id: "reject", title: "Skip this change"),
        ],
        toolCall: ToolCallUpdate(
          toolCallId: "call_2",
          title: "Modifying critical configuration file",
          kind: ToolKind.edit,
          status: ToolCallStatus.pending,
          locations: [ToolCallLocation(path: "/home/user/project/config.json")],
          rawInput: {
            "path": "/home/user/project/config.json",
            "content": '{"database": {"host": "new-host"}}',
          },
        ),
      ),
    );

    switch (permissionResponse.optionId) {
      case "allow":
        await _connection.sessionUpdate(
          SessionNotification(
            sessionId: sessionId,
            update: ToolCallUpdateSessionUpdate(
              toolCallId: "call_2",
              status: ToolCallStatus.completed,
              rawOutput: {"success": true, "message": "Configuration updated"},
            ),
          ),
        );

        await _simulateModelInteraction(abortStream);

        await _connection.sessionUpdate(
          SessionNotification(
            sessionId: sessionId,
            update: AgentMessageChunkSessionUpdate(
              content: TextContentBlock(
                text:
                    " Perfect! I've successfully updated the configuration. The changes have been applied.",
              ),
            ),
          ),
        );
        break;
      case "reject":
        await _simulateModelInteraction(abortStream);

        await _connection.sessionUpdate(
          SessionNotification(
            sessionId: sessionId,
            update: AgentMessageChunkSessionUpdate(
              content: TextContentBlock(
                text:
                    " I understand you prefer not to make that change. I'll skip the configuration update.",
              ),
            ),
          ),
        );
        break;
      default:
        throw Exception(
          'Unexpected permission outcome ${permissionResponse.optionId}',
        );
    }
  }

  /// Simulates model interaction with a delay
  Future<void> _simulateModelInteraction(Stream<void> abortStream) {
    return abortStream
        .any((_) => true)
        .then((_) => Future.value())
        .timeout(Duration(seconds: 1), onTimeout: () => {});
  }

  @override
  Future<void> cancel(CancelNotification params) async {
    final session = _sessions[params.sessionId];
    if (session != null &&
        session.pendingPrompt != null &&
        !session.pendingPrompt!.isCompleted) {
      session.pendingPrompt!.complete();
    }
  }

  @override
  Future<Map<String, dynamic>>? extMethod(
    String method,
    Map<String, dynamic> params,
  ) async {
    // Not implemented in this example
    throw RequestError.methodNotFound(method);
  }

  @override
  Future<void>? extNotification(
    String method,
    Map<String, dynamic> params,
  ) async {
    // Not implemented in this example
  }
}

void main() {
  // Create the ACP stream using stdin/stdout
  final stream = ndJsonStream(stdin, stdout);

  // Create the agent connection
  final connection = AgentSideConnection((conn) => ExampleAgent(conn), stream);

  // Keep the program running
  connection;
}
