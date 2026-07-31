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

/// Unwinds a turn that has been cancelled, so the prompt handler can report
/// [StopReason.cancelled] instead of finishing the turn as if nothing happened.
class _TurnCancelled implements Exception {}

/// Example agent implementation demonstrating ACP protocol usage
class ExampleAgent implements Agent {
  final AgentSideConnection _connection;
  final Map<String, AgentSession> _sessions = {};

  ExampleAgent(this._connection);

  @override
  Future<InitializeResponse> initialize(InitializeRequest params) async {
    return InitializeResponse(
      protocolVersion: 1,
      agentCapabilities: AgentCapabilities(loadSession: false),
      authMethods: const [],
    );
  }

  @override
  Future<NewSessionResponse> newSession(NewSessionRequest params) async {
    final sessionId = _generateRandomSessionId();

    _sessions[sessionId] = AgentSession();

    return NewSessionResponse(
      sessionId: sessionId,
      modes: SessionModeState(
        availableModes: [SessionMode(id: 'default', name: 'Default')],
        currentModeId: 'default',
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
  Future<ListSessionsResponse>? unstableListSessions(
    ListSessionsRequest params,
  ) {
    // Not implemented in this example
    return null;
  }

  @override
  Future<ForkSessionResponse>? unstableForkSession(ForkSessionRequest params) {
    // Not implemented in this example
    return null;
  }

  @override
  Future<ResumeSessionResponse>? unstableResumeSession(
    ResumeSessionRequest params,
  ) {
    // Not implemented in this example
    return null;
  }

  @override
  Future<SetSessionModeResponse?>? setSessionMode(
    SetSessionModeRequest params,
  ) async {
    // Not implemented in this example
    return SetSessionModeResponse();
  }

  @override
  Future<SetSessionConfigOptionResponse>? setSessionConfigOption(
    SetSessionConfigOptionRequest params,
  ) {
    // Not implemented in this example
    return null;
  }

  @override
  Future<AuthenticateResponse?>? authenticate(
    AuthenticateRequest params,
  ) async {
    // No authentication needed - return empty response
    return AuthenticateResponse();
  }

  @override
  Future<SetSessionModelResponse?>? setSessionModel(
    SetSessionModelRequest params,
  ) async {
    // Not implemented in this example
    return SetSessionModelResponse();
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
      await _simulateTurn(params.sessionId, completer);
    } on _TurnCancelled {
      return PromptResponse(stopReason: StopReason.cancelled);
    } finally {
      // Only clear the completer this call installed: a later prompt may have
      // already replaced it, and that one still needs to be cancellable.
      if (identical(session.pendingPrompt, completer)) {
        session.pendingPrompt = null;
      }
    }

    return PromptResponse(stopReason: StopReason.endTurn);
  }

  /// Simulates an agent turn with text chunks and tool calls.
  ///
  /// [abort] completes when the turn is cancelled. It is awaited alongside each
  /// simulated model call so the turn stops waiting immediately, and throws
  /// [_TurnCancelled] so the rest of the turn is abandoned.
  Future<void> _simulateTurn(String sessionId, Completer<void> abort) async {
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

    await _simulateModelInteraction(abort);

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

    await _simulateModelInteraction(abort);

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

    await _simulateModelInteraction(abort);

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

    await _simulateModelInteraction(abort);

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
        sessionId: sessionId,
        options: [
          PermissionOption(
            optionId: "allow",
            name: "Allow this change",
            kind: PermissionOptionKind.allowOnce,
          ),
          PermissionOption(
            optionId: "reject",
            name: "Skip this change",
            kind: PermissionOptionKind.rejectOnce,
          ),
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

    final outcome = permissionResponse.outcome;

    // A turn cancelled while the permission request was outstanding must not
    // go on to run the tool call it was asking about.
    _throwIfCancelled(abort);

    switch (outcome) {
      case SelectedOutcome(optionId: final optionId) when optionId == "allow":
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

        await _simulateModelInteraction(abort);

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
      case SelectedOutcome(optionId: final optionId) when optionId == "reject":
        await _simulateModelInteraction(abort);

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
      case CancelledOutcome():
        // The client only reports this outcome when the turn itself was
        // cancelled, so report the pending update and end the turn as
        // cancelled rather than as a completed turn.
        await _connection.sessionUpdate(
          SessionNotification(
            sessionId: sessionId,
            update: AgentMessageChunkSessionUpdate(
              content: TextContentBlock(
                text:
                    "The permission request was cancelled, so I will leave the configuration unchanged.",
              ),
            ),
          ),
        );
        throw _TurnCancelled();
      default:
        throw Exception('Unexpected permission outcome $outcome');
    }
  }

  /// Simulates model interaction with a delay, returning as soon as [abort]
  /// completes.
  ///
  /// [abort] is a `Completer` rather than a `Stream` on purpose: it is awaited
  /// once per simulated model call, and a single-subscription stream (such as
  /// the one returned by `Future.asStream()`) can only be listened to once.
  Future<void> _simulateModelInteraction(Completer<void> abort) async {
    await Future.any([
      abort.future,
      Future<void>.delayed(Duration(seconds: 1)),
    ]);
    _throwIfCancelled(abort);
  }

  /// Abandons the turn if the client cancelled it in the meantime.
  void _throwIfCancelled(Completer<void> abort) {
    if (abort.isCompleted) {
      throw _TurnCancelled();
    }
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
