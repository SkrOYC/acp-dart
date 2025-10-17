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
