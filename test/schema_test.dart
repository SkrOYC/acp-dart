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
        clientInfo: Implementation(
          name: 'acp-dart-client',
          title: 'ACP Dart Client',
          version: '0.3.0',
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
          sessionCapabilities: SessionCapabilities(
            fork: SessionForkCapabilities(),
            list: SessionListCapabilities(),
            resume: SessionResumeCapabilities(),
          ),
        ),
        agentInfo: Implementation(
          name: 'acp-dart-agent',
          title: 'ACP Dart Agent',
          version: '0.3.0',
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
      expect(requestDecoded.clientInfo?.name, equals('acp-dart-client'));
      expect(responseDecoded.agentCapabilities?.loadSession, isTrue);
      expect(responseDecoded.agentInfo?.name, equals('acp-dart-agent'));
      expect(
        responseDecoded.agentCapabilities?.sessionCapabilities?.fork,
        isA<SessionForkCapabilities>(),
      );
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
          SseMcpServer(
            name: 'stream-docs',
            url: 'https://example.com/events',
            headers: [HttpHeader(name: 'X-Client', value: 'acp-dart')],
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
      final forkSession = ForkSessionRequest(
        cwd: '/workspace',
        mcpServers: newSession.mcpServers,
        sessionId: 'session-123',
      );
      final listSessions = ListSessionsRequest(
        cwd: '/workspace',
        cursor: 'cursor-1',
      );
      final resumeSession = ResumeSessionRequest(
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
      final setConfigOption = SetSessionConfigOptionRequest(
        sessionId: 'session-123',
        configId: 'mode',
        value: 'code',
      );

      final newSessionDecoded = NewSessionRequest.fromJson(
        jsonDecode(jsonEncode(newSession.toJson())) as Map<String, dynamic>,
      );
      final loadSessionDecoded = LoadSessionRequest.fromJson(
        jsonDecode(jsonEncode(loadSession.toJson())) as Map<String, dynamic>,
      );
      final forkSessionDecoded = ForkSessionRequest.fromJson(
        jsonDecode(jsonEncode(forkSession.toJson())) as Map<String, dynamic>,
      );
      final listSessionsDecoded = ListSessionsRequest.fromJson(
        jsonDecode(jsonEncode(listSessions.toJson())) as Map<String, dynamic>,
      );
      final resumeSessionDecoded = ResumeSessionRequest.fromJson(
        jsonDecode(jsonEncode(resumeSession.toJson())) as Map<String, dynamic>,
      );
      final setModeDecoded = SetSessionModeRequest.fromJson(
        jsonDecode(jsonEncode(setMode.toJson())) as Map<String, dynamic>,
      );
      final setModelDecoded = SetSessionModelRequest.fromJson(
        jsonDecode(jsonEncode(setModel.toJson())) as Map<String, dynamic>,
      );
      final setConfigOptionDecoded = SetSessionConfigOptionRequest.fromJson(
        jsonDecode(jsonEncode(setConfigOption.toJson()))
            as Map<String, dynamic>,
      );

      expect(newSessionDecoded.cwd, equals('/workspace'));
      expect(newSessionDecoded.mcpServers.length, equals(3));
      expect(loadSessionDecoded.sessionId, equals('session-123'));
      expect(forkSessionDecoded.sessionId, equals('session-123'));
      expect(listSessionsDecoded.cursor, equals('cursor-1'));
      expect(resumeSessionDecoded.sessionId, equals('session-123'));
      expect(setModeDecoded.modeId, equals('code'));
      expect(setModelDecoded.modelId, equals('gpt-4'));
      expect(setConfigOptionDecoded.configId, equals('mode'));
      expect(setConfigOptionDecoded.value, equals('code'));
    });

    test('Unstable session lifecycle responses round-trip', () {
      final listSessionsResponse = ListSessionsResponse(
        sessions: [
          SessionInfo(
            sessionId: 'session-1',
            cwd: '/workspace',
            title: 'My Session',
            updatedAt: '2026-02-27T10:00:00Z',
          ),
        ],
        nextCursor: 'cursor-2',
      );
      final forkSessionResponse = ForkSessionResponse(
        sessionId: 'session-2',
        modes: SessionModeState(
          availableModes: [SessionMode(id: 'code', name: 'Code')],
          currentModeId: 'code',
        ),
      );
      final resumeSessionResponse = ResumeSessionResponse(
        models: SessionModelState(
          availableModels: [ModelInfo(modelId: 'gpt-5', name: 'GPT-5')],
          currentModelId: 'gpt-5',
        ),
      );

      final listSessionsResponseDecoded = ListSessionsResponse.fromJson(
        jsonDecode(jsonEncode(listSessionsResponse.toJson()))
            as Map<String, dynamic>,
      );
      final forkSessionResponseDecoded = ForkSessionResponse.fromJson(
        jsonDecode(jsonEncode(forkSessionResponse.toJson()))
            as Map<String, dynamic>,
      );
      final resumeSessionResponseDecoded = ResumeSessionResponse.fromJson(
        jsonDecode(jsonEncode(resumeSessionResponse.toJson()))
            as Map<String, dynamic>,
      );

      expect(
        listSessionsResponseDecoded.sessions.first.sessionId,
        equals('session-1'),
      );
      expect(listSessionsResponseDecoded.nextCursor, equals('cursor-2'));
      expect(forkSessionResponseDecoded.sessionId, equals('session-2'));
      expect(forkSessionResponseDecoded.modes?.currentModeId, equals('code'));
      expect(
        resumeSessionResponseDecoded.models?.currentModelId,
        equals('gpt-5'),
      );
    });

    test('Session config option payloads round-trip', () {
      final option = SessionConfigOption(
        id: 'mode',
        name: 'Session Mode',
        category: 'mode',
        currentValue: 'code',
        options: UngroupedSessionConfigSelectOptions(
          options: [
            SessionConfigSelectOption(
              value: 'ask',
              name: 'Ask',
              description: 'Request permission before edits',
            ),
            SessionConfigSelectOption(value: 'code', name: 'Code'),
          ],
        ),
      );

      final groupedOption = SessionConfigOption(
        id: 'model',
        name: 'Model',
        category: 'model',
        currentValue: 'model-2',
        options: GroupedSessionConfigSelectOptions(
          groups: [
            SessionConfigSelectGroup(
              group: 'provider_a',
              name: 'Provider A',
              options: [
                SessionConfigSelectOption(value: 'model-1', name: 'A1'),
              ],
            ),
            SessionConfigSelectGroup(
              group: 'provider_b',
              name: 'Provider B',
              options: [
                SessionConfigSelectOption(value: 'model-2', name: 'B1'),
              ],
            ),
          ],
        ),
      );

      final setConfigResponse = SetSessionConfigOptionResponse(
        configOptions: [option, groupedOption],
      );
      final newSessionResponse = NewSessionResponse(
        sessionId: 'session-123',
        configOptions: [option],
      );
      final loadSessionResponse = LoadSessionResponse(
        configOptions: [groupedOption],
      );

      final setConfigResponseDecoded = SetSessionConfigOptionResponse.fromJson(
        jsonDecode(jsonEncode(setConfigResponse.toJson()))
            as Map<String, dynamic>,
      );
      final newSessionResponseDecoded = NewSessionResponse.fromJson(
        jsonDecode(jsonEncode(newSessionResponse.toJson()))
            as Map<String, dynamic>,
      );
      final loadSessionResponseDecoded = LoadSessionResponse.fromJson(
        jsonDecode(jsonEncode(loadSessionResponse.toJson()))
            as Map<String, dynamic>,
      );

      expect(setConfigResponseDecoded.configOptions.length, equals(2));
      expect(
        setConfigResponseDecoded.configOptions.first.options,
        isA<UngroupedSessionConfigSelectOptions>(),
      );
      expect(
        setConfigResponseDecoded.configOptions.last.options,
        isA<GroupedSessionConfigSelectOptions>(),
      );
      expect(newSessionResponseDecoded.configOptions?.first.id, equals('mode'));
      expect(
        loadSessionResponseDecoded.configOptions?.first.id,
        equals('model'),
      );
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

    test('PromptResponse usage round-trips', () {
      final response = PromptResponse(
        stopReason: StopReason.endTurn,
        usage: Usage(
          inputTokens: 120,
          outputTokens: 80,
          totalTokens: 200,
          cachedReadTokens: 10,
          cachedWriteTokens: 5,
          thoughtTokens: 30,
        ),
      );

      final decoded = PromptResponse.fromJson(
        jsonDecode(jsonEncode(response.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.stopReason, equals(StopReason.endTurn));
      expect(decoded.usage?.totalTokens, equals(200));
      expect(decoded.usage?.cachedReadTokens, equals(10));
      expect(decoded.usage?.thoughtTokens, equals(30));
    });

    test('Session update variants round-trip and unknown fallback', () {
      final option = SessionConfigOption(
        id: 'mode',
        name: 'Session Mode',
        currentValue: 'code',
        options: UngroupedSessionConfigSelectOptions(
          options: [
            SessionConfigSelectOption(value: 'ask', name: 'Ask'),
            SessionConfigSelectOption(value: 'code', name: 'Code'),
          ],
        ),
      );

      final configUpdateNotification = SessionNotification(
        sessionId: 'session-123',
        update: ConfigOptionUpdate(configOptions: [option]),
      );
      final sessionInfoUpdateNotification = SessionNotification(
        sessionId: 'session-123',
        update: SessionInfoUpdate(
          title: 'Renamed Session',
          updatedAt: '2026-03-01T12:00:00Z',
        ),
      );
      final usageUpdateNotification = SessionNotification(
        sessionId: 'session-123',
        update: UsageUpdate(
          size: 200000,
          used: 90000,
          cost: Cost(amount: 1.23, currency: 'USD'),
        ),
      );

      final configDecoded = SessionNotification.fromJson(
        jsonDecode(jsonEncode(configUpdateNotification.toJson()))
            as Map<String, dynamic>,
      );
      final sessionInfoDecoded = SessionNotification.fromJson(
        jsonDecode(jsonEncode(sessionInfoUpdateNotification.toJson()))
            as Map<String, dynamic>,
      );
      final usageDecoded = SessionNotification.fromJson(
        jsonDecode(jsonEncode(usageUpdateNotification.toJson()))
            as Map<String, dynamic>,
      );

      expect(configDecoded.update, isA<ConfigOptionUpdate>());
      expect(
        (configDecoded.update as ConfigOptionUpdate).configOptions.first.id,
        equals('mode'),
      );
      expect(sessionInfoDecoded.update, isA<SessionInfoUpdate>());
      expect(
        (sessionInfoDecoded.update as SessionInfoUpdate).title,
        equals('Renamed Session'),
      );
      expect(usageDecoded.update, isA<UsageUpdate>());
      expect(
        (usageDecoded.update as UsageUpdate).cost?.currency,
        equals('USD'),
      );

      final unknownDecoded = SessionNotification.fromJson({
        'sessionId': 'session-123',
        'update': {'sessionUpdate': 'future_update', 'foo': 'bar'},
      });
      expect(unknownDecoded.update, isA<UnknownSessionUpdate>());
      expect(
        (unknownDecoded.update as UnknownSessionUpdate).rawJson['foo'],
        equals('bar'),
      );
    });

    test('All stable session update discriminators deserialize correctly', () {
      final cases = <({SessionUpdate update, Matcher matcher})>[
        (
          update: UserMessageChunkSessionUpdate(
            content: TextContentBlock(text: 'user'),
          ),
          matcher: isA<UserMessageChunkSessionUpdate>(),
        ),
        (
          update: AgentMessageChunkSessionUpdate(
            content: TextContentBlock(text: 'agent'),
          ),
          matcher: isA<AgentMessageChunkSessionUpdate>(),
        ),
        (
          update: AgentThoughtChunkSessionUpdate(
            content: TextContentBlock(text: 'thinking'),
          ),
          matcher: isA<AgentThoughtChunkSessionUpdate>(),
        ),
        (
          update: ToolCallSessionUpdate(toolCallId: 'tool-1', title: 'Read'),
          matcher: isA<ToolCallSessionUpdate>(),
        ),
        (
          update: ToolCallUpdateSessionUpdate(toolCallId: 'tool-1'),
          matcher: isA<ToolCallUpdateSessionUpdate>(),
        ),
        (
          update: PlanSessionUpdate(
            entries: [
              PlanEntry(
                content: 'Do work',
                priority: PlanEntryPriority.medium,
                status: PlanEntryStatus.pending,
              ),
            ],
          ),
          matcher: isA<PlanSessionUpdate>(),
        ),
        (
          update: AvailableCommandsUpdateSessionUpdate(availableCommands: []),
          matcher: isA<AvailableCommandsUpdateSessionUpdate>(),
        ),
        (
          update: CurrentModeUpdateSessionUpdate(currentModeId: 'code'),
          matcher: isA<CurrentModeUpdateSessionUpdate>(),
        ),
      ];

      for (final testCase in cases) {
        final notification = SessionNotification(
          sessionId: 'session-123',
          update: testCase.update,
        );

        final decoded = SessionNotification.fromJson(
          jsonDecode(jsonEncode(notification.toJson())) as Map<String, dynamic>,
        );

        expect(decoded.sessionId, equals('session-123'));
        expect(decoded.update, testCase.matcher);
      }
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

    test('CancelRequestNotification round-trips request IDs and metadata', () {
      final withStringId = CancelRequestNotification(
        requestId: 'req-1',
        meta: {'source': 'ui'},
      );
      final withNumericId = CancelRequestNotification(requestId: 42);
      final withNullId = CancelRequestNotification(requestId: null);

      final decodedString = CancelRequestNotification.fromJson(
        jsonDecode(jsonEncode(withStringId.toJson())) as Map<String, dynamic>,
      );
      final decodedNumber = CancelRequestNotification.fromJson(
        jsonDecode(jsonEncode(withNumericId.toJson())) as Map<String, dynamic>,
      );
      final decodedNull = CancelRequestNotification.fromJson(
        jsonDecode(jsonEncode(withNullId.toJson())) as Map<String, dynamic>,
      );

      expect(decodedString.requestId, equals('req-1'));
      expect(decodedString.meta, equals({'source': 'ui'}));
      expect(decodedNumber.requestId, equals(42));
      expect(decodedNull.requestId, isNull);
    });

    test('protocol method constants include cancel request', () {
      expect(protocolMethods['cancelRequest'], equals(r'$/cancel_request'));
    });
  });
}
