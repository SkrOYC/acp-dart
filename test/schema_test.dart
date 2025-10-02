import 'dart:convert';

import 'package:acp_dart/src/schema.dart';
import 'package:test/test.dart';

void main() {
  group('Schema', () {
    test('InitializeRequest can be serialized and deserialized', () {
      final original = InitializeRequest(
        capabilities: ClientCapabilities(
          fs: FileSystemCapability(readTextFile: true, writeTextFile: true),
        ),
      );

      final json = jsonEncode(original.toJson());
      final decoded = InitializeRequest.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(
        decoded.capabilities.fs?.readTextFile,
        original.capabilities.fs?.readTextFile,
      );
      expect(
        decoded.capabilities.fs?.writeTextFile,
        original.capabilities.fs?.writeTextFile,
      );
    });

    test('InitializeResponse can be serialized and deserialized', () {
      final original = InitializeResponse(
        protocolVersion: '1.0.0',
        capabilities: AgentCapabilities(
          mcp: McpCapabilities(versions: ['1.0']),
          prompt: PromptCapabilities(sessionModes: ['test-mode']),
          loadSession: true,
          auth: [AuthMethod(method: 'test-auth', description: 'Test Auth')],
        ),
      );

      final json = jsonEncode(original.toJson());
      final decoded = InitializeResponse.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.protocolVersion, original.protocolVersion);
      expect(
        decoded.capabilities.mcp?.versions,
        original.capabilities.mcp?.versions,
      );
      expect(
        decoded.capabilities.prompt?.sessionModes.first,
        original.capabilities.prompt?.sessionModes.first,
      );
      expect(
        decoded.capabilities.loadSession,
        original.capabilities.loadSession,
      );
      expect(
        decoded.capabilities.auth.first.method,
        original.capabilities.auth.first.method,
      );
    });

    test('AuthenticateRequest can be serialized and deserialized', () {
      final original = AuthenticateRequest(
        method: 'test-auth',
        token: 'test-token',
      );

      final json = jsonEncode(original.toJson());
      final decoded = AuthenticateRequest.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.method, original.method);
      expect(decoded.token, original.token);
    });

    test('AuthenticateResponse can be serialized and deserialized', () {
      final original = AuthenticateResponse();

      final json = jsonEncode(original.toJson());
      final decoded = AuthenticateResponse.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded, isA<AuthenticateResponse>());
    });

    test('NewSessionRequest can be serialized and deserialized', () {
      final original = NewSessionRequest(
        mcp: McpServer(
          host: 'localhost',
          port: 8080,
          tls: true,
          headers: [HttpHeader(name: 'Authorization', value: 'Bearer token')],
        ),
        stdio: Stdio(
          command: ['node', 'server.js'],
          env: [EnvVariable(name: 'PORT', value: '8080')],
        ),
      );

      final json = jsonEncode(original.toJson());
      final decoded = NewSessionRequest.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.mcp?.host, original.mcp?.host);
      expect(decoded.mcp?.port, original.mcp?.port);
      expect(decoded.mcp?.tls, original.mcp?.tls);
      expect(
        decoded.mcp?.headers?.first.name,
        original.mcp?.headers?.first.name,
      );
      expect(decoded.stdio?.command, original.stdio?.command);
      expect(decoded.stdio?.env?.first.name, original.stdio?.env?.first.name);
    });

    test('LoadSessionRequest can be serialized and deserialized', () {
      final original = LoadSessionRequest(sessionId: 'test-session-id');

      final json = jsonEncode(original.toJson());
      final decoded = LoadSessionRequest.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.sessionId, original.sessionId);
    });

    test('SetSessionModeRequest can be serialized and deserialized', () {
      final original = SetSessionModeRequest(mode: 'code');

      final json = jsonEncode(original.toJson());
      final decoded = SetSessionModeRequest.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.mode, original.mode);
    });

    test('SetSessionModelRequest can be serialized and deserialized', () {
      final original = SetSessionModelRequest(model: 'gpt-4');

      final json = jsonEncode(original.toJson());
      final decoded = SetSessionModelRequest.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.model, original.model);
    });

    test('WriteTextFileRequest can be serialized and deserialized', () {
      final original = WriteTextFileRequest(
        path: '/test/file.txt',
        content: 'Hello World',
      );

      final json = jsonEncode(original.toJson());
      final decoded = WriteTextFileRequest.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.path, original.path);
      expect(decoded.content, original.content);
    });

    test('ReadTextFileRequest can be serialized and deserialized', () {
      final original = ReadTextFileRequest(path: '/test/file.txt');

      final json = jsonEncode(original.toJson());
      final decoded = ReadTextFileRequest.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.path, original.path);
    });

    test('CreateTerminalRequest can be serialized and deserialized', () {
      final original = CreateTerminalRequest(
        command: 'ls',
        args: ['-la'],
        cwd: '/home/user',
        env: {'PATH': '/usr/bin'},
      );

      final json = jsonEncode(original.toJson());
      final decoded = CreateTerminalRequest.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.command, original.command);
      expect(decoded.args, original.args);
      expect(decoded.cwd, original.cwd);
      expect(decoded.env, original.env);
    });

    test('NewSessionResponse can be serialized and deserialized', () {
      final original = NewSessionResponse(
        sessionId: 'test-session-id',
        modes: SessionModeState(
          available: [SessionMode(id: 'code', name: 'Code Mode')],
          current: 'code',
        ),
        models: SessionModelState(
          available: [ModelInfo(id: 'gpt-4', name: 'GPT-4')],
          current: 'gpt-4',
        ),
      );

      final json = jsonEncode(original.toJson());
      final decoded = NewSessionResponse.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.sessionId, original.sessionId);
      expect(
        decoded.modes.available.first.id,
        original.modes.available.first.id,
      );
      expect(decoded.modes.current, original.modes.current);
      expect(
        decoded.models?.available.first.id,
        original.models?.available.first.id,
      );
      expect(decoded.models?.current, original.models?.current);
    });

    test('ReadTextFileResponse can be serialized and deserialized', () {
      final original = ReadTextFileResponse(content: 'file content');

      final json = jsonEncode(original.toJson());
      final decoded = ReadTextFileResponse.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.content, original.content);
    });

    test('CreateTerminalResponse can be serialized and deserialized', () {
      final original = CreateTerminalResponse(terminalId: 'term-123');

      final json = jsonEncode(original.toJson());
      final decoded = CreateTerminalResponse.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.terminalId, original.terminalId);
    });

    test('PromptRequest can be serialized and deserialized', () {
      final original = PromptRequest(
        sessionId: 'test-session-id',
        text: 'Hello, agent!',
        content: [TextContentBlock(text: 'Hello, agent!')],
      );

      final json = jsonEncode(original.toJson());
      final decoded = PromptRequest.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.sessionId, original.sessionId);
      expect(decoded.text, original.text);
      expect(decoded.content, original.content);
    });

    test('RequestPermissionRequest can be serialized and deserialized', () {
      final original = RequestPermissionRequest(
        question: 'Allow file access?',
        options: [
          PermissionOption(
            id: 'yes',
            title: 'Yes',
            description: 'Grant access',
          ),
          PermissionOption(id: 'no', title: 'No'),
        ],
        toolCall: ToolCallUpdate(
          toolCallId: 'test-call',
        ), // Placeholder with required toolCallId
      );

      final json = jsonEncode(original.toJson());
      final decoded = RequestPermissionRequest.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.question, original.question);
      expect(decoded.options.length, original.options.length);
      expect(decoded.options.first.id, original.options.first.id);
    });

    test('TerminalOutputResponse can be serialized and deserialized', () {
      final original = TerminalOutputResponse(
        stdout: 'output',
        stderr: null,
        exitStatus: TerminalExitStatus(code: 0),
      );

      final json = jsonEncode(original.toJson());
      final decoded = TerminalOutputResponse.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.stdout, original.stdout);
      expect(decoded.stderr, original.stderr);
      expect(decoded.exitStatus?.code, original.exitStatus?.code);
    });

    test('CancelNotification can be serialized and deserialized', () {
      final original = CancelNotification(sessionId: 'session-123');

      final json = jsonEncode(original.toJson());
      final decoded = CancelNotification.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.sessionId, original.sessionId);
    });

    test('DiffToolCallContent can be serialized and deserialized', () {
      final original = DiffToolCallContent(
        newText: 'new content',
        oldText: 'old content',
        path: '/file.txt',
      );

      final json = jsonEncode(original.toJson());
      final decoded = DiffToolCallContent.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.newText, original.newText);
      expect(decoded.oldText, original.oldText);
      expect(decoded.path, original.path);
    });

    test('TerminalToolCallContent can be serialized and deserialized', () {
      final original = TerminalToolCallContent(terminalId: 'term-123');

      final json = jsonEncode(original.toJson());
      final decoded = TerminalToolCallContent.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.terminalId, original.terminalId);
    });

    test('WriteTextFileResponse can be serialized and deserialized', () {
      final original = WriteTextFileResponse();

      final json = jsonEncode(original.toJson());
      final decoded = WriteTextFileResponse.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded, isA<WriteTextFileResponse>());
    });

    test('RequestPermissionResponse can be serialized and deserialized', () {
      final original = RequestPermissionResponse(optionId: 'yes');

      final json = jsonEncode(original.toJson());
      final decoded = RequestPermissionResponse.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.optionId, original.optionId);
    });

    test('ReleaseTerminalResponse can be serialized and deserialized', () {
      final original = ReleaseTerminalResponse();

      final json = jsonEncode(original.toJson());
      final decoded = ReleaseTerminalResponse.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded, isA<ReleaseTerminalResponse>());
    });

    test('WaitForTerminalExitResponse can be serialized and deserialized', () {
      final original = WaitForTerminalExitResponse(exitCode: 0);

      final json = jsonEncode(original.toJson());
      final decoded = WaitForTerminalExitResponse.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded.exitCode, original.exitCode);
    });

    test('KillTerminalResponse can be serialized and deserialized', () {
      final original = KillTerminalResponse();

      final json = jsonEncode(original.toJson());
      final decoded = KillTerminalResponse.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      expect(decoded, isA<KillTerminalResponse>());
    });
  });
}
