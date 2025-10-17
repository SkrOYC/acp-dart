import 'dart:io';
import 'dart:convert';
import 'package:acp_dart/acp_dart.dart';

class ExampleClient implements Client {
  @override
  Future<RequestPermissionResponse> requestPermission(
    RequestPermissionRequest params,
  ) async {
    print('\n🔐 Permission requested: ${params.toolCall.title}');

    print('\nOptions:');
    for (int i = 0; i < params.options.length; i++) {
      final option = params.options[i];
      print('   ${i + 1}. ${option.name}');
    }

    while (true) {
      stdout.write('\nChoose an option: ');
      stdout.flush();
      String? answer = stdin.readLineSync();
      if (answer == null) {
        // Handle case where stdin is closed
        throw RequestError.internalError('Unable to read user input');
      }
      String trimmedAnswer = answer.trim();

      int? optionIndex = int.tryParse(trimmedAnswer);
      if (optionIndex != null &&
          optionIndex > 0 &&
          optionIndex <= params.options.length) {
        return RequestPermissionResponse(
          outcome: SelectedOutcome(
            optionId: params.options[optionIndex - 1].optionId,
          ),
        );
      } else {
        print('Invalid option. Please try again.');
      }
    }
  }

  @override
  Future<void> sessionUpdate(SessionNotification params) async {
    final update = params.update;

    if (update is AgentMessageChunkSessionUpdate) {
      if (update.content is TextContentBlock) {
        print((update.content as TextContentBlock).text);
      } else {
        print('[${update.content.runtimeType}]');
      }
    } else if (update is ToolCallSessionUpdate) {
      print('\n🔧 ${update.title} (${update.status})');
    } else if (update is ToolCallUpdateSessionUpdate) {
      print(
        '\n🔧 Tool call `${update.toolCallId}` updated: ${update.status}\n',
      );
    } else if (update is AgentThoughtChunkSessionUpdate) {
      print('[agent_thought_chunk]');
    } else if (update is PlanSessionUpdate) {
      print('[plan]');
    } else if (update is UserMessageChunkSessionUpdate) {
      print('[user_message_chunk]');
    } else if (update is AvailableCommandsUpdateSessionUpdate) {
      print('[available_commands_update]');
    } else if (update is CurrentModeUpdateSessionUpdate) {
      print('[current_mode_update]');
    }
  }

  @override
  Future<WriteTextFileResponse> writeTextFile(
    WriteTextFileRequest params,
  ) async {
    stderr.writeln(
      '[Client] Write text file called with: ${jsonEncode(params)}',
    );
    return WriteTextFileResponse();
  }

  @override
  Future<ReadTextFileResponse> readTextFile(ReadTextFileRequest params) async {
    stderr.writeln(
      '[Client] Read text file called with: ${jsonEncode(params)}',
    );
    return ReadTextFileResponse(content: 'Mock file content');
  }

  @override
  Future<CreateTerminalResponse> createTerminal(
    CreateTerminalRequest params,
  ) async {
    stderr.writeln(
      '[Client] Create terminal called with: ${jsonEncode(params)}',
    );
    // For this example, we'll just return a mock terminal ID
    return CreateTerminalResponse(terminalId: 'mock-terminal-id');
  }

  @override
  Future<TerminalOutputResponse> terminalOutput(
    TerminalOutputRequest params,
  ) async {
    stderr.writeln(
      '[Client] Terminal output called with: ${jsonEncode(params)}',
    );
    return TerminalOutputResponse(output: '', truncated: false);
  }

  @override
  Future<ReleaseTerminalResponse> releaseTerminal(
    ReleaseTerminalRequest params,
  ) async {
    stderr.writeln(
      '[Client] Release terminal called with: ${jsonEncode(params)}',
    );
    return ReleaseTerminalResponse();
  }

  @override
  Future<WaitForTerminalExitResponse> waitForTerminalExit(
    WaitForTerminalExitRequest params,
  ) async {
    stderr.writeln(
      '[Client] Wait for terminal exit called with: ${jsonEncode(params)}',
    );
    return WaitForTerminalExitResponse(exitCode: 0);
  }

  @override
  Future<KillTerminalCommandResponse> killTerminal(
    KillTerminalCommandRequest params,
  ) async {
    stderr.writeln('[Client] Kill terminal called with: ${jsonEncode(params)}');
    return KillTerminalCommandResponse();
  }

  @override
  Future<Map<String, dynamic>>? extMethod(
    String method,
    Map<String, dynamic> params,
  ) async {
    stderr.writeln(
      '[Client] Extension method called: $method with params: $params',
    );
    // For this example, return an empty map to indicate the method is not implemented
    return {};
  }

  @override
  Future<void>? extNotification(
    String method,
    Map<String, dynamic> params,
  ) async {
    stderr.writeln(
      '[Client] Extension notification: $method with params: $params',
    );
    // For this example, just complete the future to indicate the notification is handled
  }
}

Future<void> main() async {
  // Spawn the agent as a subprocess
  final agentProcess = await Process.start('dart', [
    'run',
    'example/agent.dart',
  ]);

  // Create the client connection
  final client = ExampleClient();
  final stream = ndJsonStream(agentProcess.stdout, agentProcess.stdin);
  final connection = ClientSideConnection((agent) => client, stream);

  try {
    // Initialize the connection
    final initResult = await connection.initialize(
      InitializeRequest(
        protocolVersion: 1,
        clientCapabilities: ClientCapabilities(
          fs: FileSystemCapability(readTextFile: true, writeTextFile: true),
          terminal: true,
        ),
      ),
    );

    print('✅ Connected to agent (protocol v${initResult.protocolVersion})');

    // Create a new session
    final sessionResult = await connection.newSession(
      NewSessionRequest(cwd: Directory.current.path, mcpServers: const []),
    );

    print('📝 Created session: ${sessionResult.sessionId}');
    print('💬 User: Hello, agent!\n');
    stdout.write(' ');

    // Send a test prompt
    final promptResult = await connection.prompt(
      PromptRequest(
        sessionId: sessionResult.sessionId,
        prompt: [TextContentBlock(text: 'Hello, agent!')],
      ),
    );

    print('\n\n✅ Agent completed with stop reason: ${promptResult.stopReason}');
  } catch (error) {
    stderr.writeln('[Client] Error: $error');
  } finally {
    agentProcess.kill();
    exit(0);
  }
}
