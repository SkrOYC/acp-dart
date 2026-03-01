import 'package:acp_dart/acp_dart.dart';
import 'package:test/test.dart';

void main() {
  group('AgentRequestUnion', () {
    test('parses write_text_file request', () {
      final request = AgentRequestUnion.fromMethod(
        clientMethods['fsWriteTextFile']!,
        {'sessionId': '123', 'path': '/tmp/file.txt', 'content': 'hello'},
      );

      expect(request, isA<AgentWriteTextFileRequest>());
      final typed = request as AgentWriteTextFileRequest;
      expect(typed.params.content, equals('hello'));
      expect(typed.method, equals('fs/write_text_file'));
    });

    test('unknown request falls back to extension method request', () {
      final request = AgentRequestUnion.fromMethod('custom/method', {'k': 'v'});

      expect(request, isA<AgentExtensionMethodRequest>());
      final typed = request as AgentExtensionMethodRequest;
      expect(typed.method, equals('custom/method'));
      expect(typed.toJson(), equals({'k': 'v'}));
    });
  });

  group('ClientRequestUnion', () {
    test('parses session/prompt request', () {
      final request = ClientRequestUnion.fromMethod(
        agentMethods['sessionPrompt']!,
        {
          'sessionId': 'abc',
          'prompt': [
            {'type': 'text', 'text': 'Hello'},
          ],
        },
      );

      expect(request, isA<ClientPromptRequest>());
      final typed = request as ClientPromptRequest;
      expect(typed.params.sessionId, equals('abc'));
      expect(typed.params.prompt.first, isA<TextContentBlock>());
    });

    test('parses session/set_config_option request', () {
      final request = ClientRequestUnion.fromMethod(
        agentMethods['sessionSetConfigOption']!,
        {'sessionId': 'abc', 'configId': 'mode', 'value': 'code'},
      );

      expect(request, isA<ClientSetSessionConfigOptionRequest>());
      final typed = request as ClientSetSessionConfigOptionRequest;
      expect(typed.params.sessionId, equals('abc'));
      expect(typed.params.configId, equals('mode'));
      expect(typed.method, equals('session/set_config_option'));
    });

    test('parses session/list request', () {
      final request = ClientRequestUnion.fromMethod(
        agentMethods['sessionList']!,
        {'cwd': '/workspace', 'cursor': 'next'},
      );

      expect(request, isA<ClientListSessionsRequest>());
      final typed = request as ClientListSessionsRequest;
      expect(typed.params.cwd, equals('/workspace'));
      expect(typed.params.cursor, equals('next'));
      expect(typed.method, equals('session/list'));
    });

    test('parses session/fork request', () {
      final request = ClientRequestUnion.fromMethod(
        agentMethods['sessionFork']!,
        {'sessionId': 'abc', 'cwd': '/workspace'},
      );

      expect(request, isA<ClientForkSessionRequest>());
      final typed = request as ClientForkSessionRequest;
      expect(typed.params.sessionId, equals('abc'));
      expect(typed.params.cwd, equals('/workspace'));
      expect(typed.method, equals('session/fork'));
    });

    test('parses session/resume request', () {
      final request = ClientRequestUnion.fromMethod(
        agentMethods['sessionResume']!,
        {'sessionId': 'abc', 'cwd': '/workspace'},
      );

      expect(request, isA<ClientResumeSessionRequest>());
      final typed = request as ClientResumeSessionRequest;
      expect(typed.params.sessionId, equals('abc'));
      expect(typed.params.cwd, equals('/workspace'));
      expect(typed.method, equals('session/resume'));
    });

    test('unknown request falls back to extension method request', () {
      final request = ClientRequestUnion.fromMethod('custom/method', {
        'k': 'v',
      });

      expect(request, isA<ClientExtensionMethodRequest>());
      final typed = request as ClientExtensionMethodRequest;
      expect(typed.method, equals('custom/method'));
      expect(typed.toJson(), equals({'k': 'v'}));
    });
  });

  group('AgentResponseUnion', () {
    test('parses initialize response', () {
      final response = AgentResponseUnion.fromJson(
        agentMethods['initialize']!,
        {
          'protocolVersion': 1,
          'agentCapabilities': {'loadSession': false},
          'authMethods': const [],
        },
      );

      expect(response, isA<AgentInitializeResponse>());
      final typed = response as AgentInitializeResponse;
      expect(typed.response.protocolVersion, equals(1));
    });

    test('parses session/set_config_option response', () {
      final response = AgentResponseUnion.fromJson(
        agentMethods['sessionSetConfigOption']!,
        {
          'configOptions': [
            {
              'id': 'mode',
              'name': 'Session Mode',
              'type': 'select',
              'currentValue': 'code',
              'options': [
                {'value': 'ask', 'name': 'Ask'},
                {'value': 'code', 'name': 'Code'},
              ],
            },
          ],
        },
      );

      expect(response, isA<AgentSetSessionConfigOptionResponse>());
      final typed = response as AgentSetSessionConfigOptionResponse;
      expect(typed.response.configOptions.first.id, equals('mode'));
    });

    test('parses session/list response', () {
      final response = AgentResponseUnion.fromJson(
        agentMethods['sessionList']!,
        {
          'sessions': [
            {'sessionId': 's1', 'cwd': '/workspace', 'title': 'Session 1'},
          ],
          'nextCursor': 'next',
        },
      );

      expect(response, isA<AgentListSessionsResponse>());
      final typed = response as AgentListSessionsResponse;
      expect(typed.response.sessions.first.sessionId, equals('s1'));
      expect(typed.response.nextCursor, equals('next'));
    });

    test('parses session/fork response', () {
      final response = AgentResponseUnion.fromJson(
        agentMethods['sessionFork']!,
        {'sessionId': 's2'},
      );

      expect(response, isA<AgentForkSessionResponse>());
      final typed = response as AgentForkSessionResponse;
      expect(typed.response.sessionId, equals('s2'));
    });

    test('parses session/resume response', () {
      final response = AgentResponseUnion.fromJson(
        agentMethods['sessionResume']!,
        {'modes': null, 'models': null},
      );

      expect(response, isA<AgentResumeSessionResponse>());
      final typed = response as AgentResumeSessionResponse;
      expect(typed.response, isA<ResumeSessionResponse>());
    });

    test('unknown response falls back to extension response', () {
      final response = AgentResponseUnion.fromJson('custom/method', {
        'ok': true,
      });

      expect(response, isA<AgentExtensionMethodResponse>());
      final typed = response as AgentExtensionMethodResponse;
      expect(typed.toJson(), equals({'ok': true}));
    });
  });

  group('ClientResponseUnion', () {
    test('parses write_text_file response with null payload', () {
      final response = ClientResponseUnion.fromMethod(
        clientMethods['fsWriteTextFile']!,
        null,
      );

      expect(response, isA<ClientWriteTextFileResponse>());
      final typed = response as ClientWriteTextFileResponse;
      expect(typed.toJson(), equals({}));
    });

    test('parses terminal/release response with null payload', () {
      final response = ClientResponseUnion.fromMethod(
        clientMethods['terminalRelease']!,
        null,
      );

      expect(response, isA<ClientReleaseTerminalResponse>());
      final typed = response as ClientReleaseTerminalResponse;
      expect(typed.toJson(), equals({}));
    });

    test('parses terminal/kill response with null payload', () {
      final response = ClientResponseUnion.fromMethod(
        clientMethods['terminalKill']!,
        null,
      );

      expect(response, isA<ClientKillTerminalResponse>());
      final typed = response as ClientKillTerminalResponse;
      expect(typed.toJson(), equals({}));
    });

    test('parses terminal/output response', () {
      final response = ClientResponseUnion.fromMethod(
        clientMethods['terminalOutput']!,
        {'output': 'lines', 'truncated': false},
      );

      expect(response, isA<ClientTerminalOutputResponse>());
      final typed = response as ClientTerminalOutputResponse;
      expect(typed.response.output, equals('lines'));
    });

    test('unknown response falls back to extension response', () {
      final response = ClientResponseUnion.fromMethod('custom/method', {
        'ok': true,
      });

      expect(response, isA<ClientExtensionMethodResponse>());
      final typed = response as ClientExtensionMethodResponse;
      expect(typed.toJson(), equals({'ok': true}));
    });
  });

  group('ClientNotificationUnion', () {
    test('parses session/cancel notification', () {
      final notification = ClientNotificationUnion.fromMethod(
        agentMethods['sessionCancel']!,
        {'sessionId': 'session-1'},
      );

      expect(notification, isA<ClientCancelNotification>());
      final typed = notification as ClientCancelNotification;
      expect(typed.notification.sessionId, equals('session-1'));
      expect(typed.method, equals('session/cancel'));
    });

    test('parses protocol cancel request notification', () {
      final notification = ClientNotificationUnion.fromMethod(
        protocolMethods['cancelRequest']!,
        {
          'requestId': 7,
          '_meta': {'reason': 'timeout'},
        },
      );

      expect(notification, isA<ClientCancelRequestNotification>());
      final typed = notification as ClientCancelRequestNotification;
      expect(typed.notification.requestId, equals(7));
      expect(typed.notification.meta, equals({'reason': 'timeout'}));
      expect(typed.method, equals(r'$/cancel_request'));
      expect(typed.toJson(), containsPair('requestId', 7));
    });

    test('unknown notification falls back to extension notification', () {
      final notification = ClientNotificationUnion.fromMethod('custom/notify', {
        'k': 'v',
      });

      expect(notification, isA<ClientExtensionNotification>());
      final typed = notification as ClientExtensionNotification;
      expect(typed.method, equals('custom/notify'));
      expect(typed.toJson(), equals({'k': 'v'}));
    });
  });

  group('AgentNotificationUnion', () {
    test('parses session notification payload', () {
      final notification = AgentNotificationUnion.fromJson({
        'sessionId': 'session-1',
        'update': {
          'sessionUpdate': 'agent_message_chunk',
          'content': {'type': 'text', 'text': 'hello'},
        },
      });

      expect(notification, isA<SessionAgentNotification>());
      final typed = notification as SessionAgentNotification;
      expect(typed.notification.sessionId, equals('session-1'));
    });

    test('unknown payload falls back to extension notification', () {
      final notification = AgentNotificationUnion.fromJson('raw');

      expect(notification, isA<AgentExtensionNotification>());
      final typed = notification as AgentExtensionNotification;
      expect(typed.toJson(), equals({'payload': 'raw'}));
    });
  });
}
