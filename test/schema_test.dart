import 'dart:convert';

import 'package:acp_dart/src/schema.dart';
import 'package:test/test.dart';

void main() {
  group('Schema serialization', () {
    test('Initialize handshake round-trips', () {
      final request = InitializeRequest(
        protocolVersion: 1,
        clientCapabilities: ClientCapabilities(
          fs: FileSystemCapability(readTextFile: true, writeTextFile: true),
          terminal: true,
        ),
      );

      final response = InitializeResponse(
        protocolVersion: 1,
        agentCapabilities: AgentCapabilities(
          loadSession: true,
          mcpCapabilities: McpCapabilities(http: true, sse: true),
          promptCapabilities: PromptCapabilities(
            audio: true,
            embeddedContext: true,
            image: true,
          ),
        ),
        authMethods: [
          AuthMethod(
            id: 'password',
            name: 'Password',
            description: 'Basic auth',
          ),
        ],
      );

      final requestDecoded = InitializeRequest.fromJson(
        jsonDecode(jsonEncode(request.toJson())) as Map<String, dynamic>,
      );
      final responseDecoded = InitializeResponse.fromJson(
        jsonDecode(jsonEncode(response.toJson())) as Map<String, dynamic>,
      );

      expect(requestDecoded.protocolVersion, equals(request.protocolVersion));
      expect(requestDecoded.clientCapabilities?.terminal, isTrue);
      expect(responseDecoded.agentCapabilities?.loadSession, isTrue);
      expect(responseDecoded.authMethods.first.id, equals('password'));
    });

    test('Session lifecycle payloads round-trip', () {
      final newSession = NewSessionRequest(
        cwd: '/workspace',
        mcpServers: [
          HttpMcpServer(
            name: 'docs',
            url: 'https://example.com',
            headers: [HttpHeader(name: 'Authorization', value: 'Bearer token')],
          ),
          StdioMcpServer(
            name: 'local-tools',
            command: 'mcp-server',
            args: ['--port', '8080'],
            env: [EnvVariable(name: 'PORT', value: '8080')],
          ),
        ],
      );

      final loadSession = LoadSessionRequest(
        cwd: '/workspace',
        mcpServers: newSession.mcpServers,
        sessionId: 'session-123',
      );

      final setMode = SetSessionModeRequest(
        sessionId: 'session-123',
        modeId: 'code',
      );

      final setModel = SetSessionModelRequest(
        modelId: 'gpt-4',
        sessionId: 'session-123',
      );

      final newSessionDecoded = NewSessionRequest.fromJson(
        jsonDecode(jsonEncode(newSession.toJson())) as Map<String, dynamic>,
      );
      final loadSessionDecoded = LoadSessionRequest.fromJson(
        jsonDecode(jsonEncode(loadSession.toJson())) as Map<String, dynamic>,
      );
      final setModeDecoded = SetSessionModeRequest.fromJson(
        jsonDecode(jsonEncode(setMode.toJson())) as Map<String, dynamic>,
      );
      final setModelDecoded = SetSessionModelRequest.fromJson(
        jsonDecode(jsonEncode(setModel.toJson())) as Map<String, dynamic>,
      );

      expect(newSessionDecoded.cwd, equals('/workspace'));
      expect(newSessionDecoded.mcpServers.length, equals(2));
      expect(loadSessionDecoded.sessionId, equals('session-123'));
      expect(setModeDecoded.modeId, equals('code'));
      expect(setModelDecoded.modelId, equals('gpt-4'));
    });

    test('PromptRequest serializes content blocks correctly', () {
      final prompt = PromptRequest(
        sessionId: 'session-123',
        prompt: [
          TextContentBlock(text: 'Hello, world!'),
          ResourceLinkContentBlock(
            name: 'README.md',
            uri: 'file:///workspace/README.md',
          ),
          ResourceContentBlock(
            resource: EmbeddedResource(
              resource: TextResourceContents(
                text: '# Notes',
                uri: 'memory://notes',
              ),
            ),
          ),
        ],
      );

      final decoded = PromptRequest.fromJson(
        jsonDecode(jsonEncode(prompt.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.sessionId, equals('session-123'));
      expect(decoded.prompt.length, equals(3));
    });

    test('Permission flow round-trips', () {
      final request = RequestPermissionRequest(
        sessionId: 'session-123',
        toolCall: ToolCallUpdate(
          toolCallId: 'tool-1',
          title: 'Read file',
          kind: ToolKind.read,
          locations: [ToolCallLocation(path: '/workspace/lib/main.dart')],
        ),
        options: [
          PermissionOption(
            optionId: 'allow',
            name: 'Allow once',
            kind: PermissionOptionKind.allowOnce,
          ),
          PermissionOption(
            optionId: 'deny',
            name: 'Deny',
            kind: PermissionOptionKind.rejectOnce,
          ),
        ],
      );

      final response = RequestPermissionResponse(
        outcome: SelectedOutcome(optionId: 'allow'),
      );

      final requestDecoded = RequestPermissionRequest.fromJson(
        jsonDecode(jsonEncode(request.toJson())) as Map<String, dynamic>,
      );
      final responseDecoded = RequestPermissionResponse.fromJson(
        jsonDecode(jsonEncode(response.toJson())) as Map<String, dynamic>,
      );

      expect(requestDecoded.options.first.kind, PermissionOptionKind.allowOnce);
      expect(
        (responseDecoded.outcome as SelectedOutcome).optionId,
        equals('allow'),
      );
    });

    test('Terminal RPC payloads round-trip', () {
      final create = CreateTerminalRequest(
        sessionId: 'session-123',
        command: 'bash',
        args: ['-lc', 'ls'],
        env: [EnvVariable(name: 'PATH', value: '/usr/bin')],
        outputByteLimit: 4096,
      );

      final output = TerminalOutputResponse(
        output: 'file.txt',
        truncated: false,
        exitStatus: TerminalExitStatus(exitCode: 0),
      );

      final wait = WaitForTerminalExitResponse(exitCode: 0, signal: null);
      final kill = KillTerminalCommandResponse();

      final createDecoded = CreateTerminalRequest.fromJson(
        jsonDecode(jsonEncode(create.toJson())) as Map<String, dynamic>,
      );
      final outputDecoded = TerminalOutputResponse.fromJson(
        jsonDecode(jsonEncode(output.toJson())) as Map<String, dynamic>,
      );
      final waitDecoded = WaitForTerminalExitResponse.fromJson(
        jsonDecode(jsonEncode(wait.toJson())) as Map<String, dynamic>,
      );
      final killDecoded = KillTerminalCommandResponse.fromJson(
        jsonDecode(jsonEncode(kill.toJson())) as Map<String, dynamic>,
      );

      expect(createDecoded.command, equals('bash'));
      expect(outputDecoded.output, equals('file.txt'));
      expect(waitDecoded.exitCode, equals(0));
      expect(killDecoded, isA<KillTerminalCommandResponse>());
    });

    test('Tool call content variants serialize with type discriminators', () {
      final diff = DiffToolCallContent(
        path: '/workspace/lib/main.dart',
        newText: 'void main() {}',
      );

      final terminal = TerminalToolCallContent(terminalId: 'term-1');

      final diffDecoded = DiffToolCallContent.fromJson(
        jsonDecode(jsonEncode(diff.toJson())) as Map<String, dynamic>,
      );
      final terminalDecoded = TerminalToolCallContent.fromJson(
        jsonDecode(jsonEncode(terminal.toJson())) as Map<String, dynamic>,
      );

      expect(diffDecoded.type, equals('diff'));
      expect(diffDecoded.newText, equals('void main() {}'));
      expect(terminalDecoded.terminalId, equals('term-1'));
    });
  });
}
