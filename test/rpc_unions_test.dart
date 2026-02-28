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
  });

  group('ClientResponseUnion', () {
    test('parses terminal/output response', () {
      final response = ClientResponseUnion.fromMethod(
        clientMethods['terminalOutput']!,
        {'output': 'lines', 'truncated': false},
      );

      expect(response, isA<ClientTerminalOutputResponse>());
      final typed = response as ClientTerminalOutputResponse;
      expect(typed.response.output, equals('lines'));
    });
  });
}
