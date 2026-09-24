import 'dart:convert';

import 'package:acp_dart/src/schema.dart';
import 'package:acp_dart/src/tool_call_content_converter.dart';
import 'package:test/test.dart';

Map<String, dynamic> roundTrip(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

void main() {
  test('boolean config options round-trip both request and session update', () {
    final option = SessionConfigOption(
      id: 'autoApprove',
      name: 'Auto approve',
      type: 'boolean',
      currentValue: true,
    );
    final decoded = SessionConfigOption.fromJson(roundTrip(option.toJson()));
    expect(decoded.currentValue, isTrue);
    expect(decoded.toJson(), {
      'id': 'autoApprove',
      'name': 'Auto approve',
      'type': 'boolean',
      'currentValue': true,
    });

    final request = SetSessionConfigOptionRequest(
      sessionId: 's1',
      configId: 'autoApprove',
      value: true,
      type: 'boolean',
    );
    expect(roundTrip(request.toJson()), containsPair('value', true));

    final update = SessionNotification(
      sessionId: 's1',
      update: ConfigOptionUpdate(configOptions: [option]),
    );
    final updateDecoded = SessionNotification.fromJson(
      roundTrip(update.toJson()),
    );
    expect(
      (updateDecoded.update as ConfigOptionUpdate)
          .configOptions
          .single
          .currentValue,
      isTrue,
    );
  });

  test('v1.5 lifecycle and capability payloads preserve the wire shape', () {
    final caps = AgentCapabilities(
      sessionCapabilities: SessionCapabilities(
        delete: SessionDeleteCapabilities(),
        close: SessionCloseCapabilities(),
        additionalDirectories: SessionAdditionalDirectoriesCapabilities(),
      ),
      auth: AgentAuthCapabilities(logout: LogoutCapabilities()),
      providers: ProvidersCapabilities(),
      positionEncoding: PositionEncodingKind.utf8,
    );
    final decoded = AgentCapabilities.fromJson(roundTrip(caps.toJson()));
    expect(decoded.sessionCapabilities?.delete, isNotNull);
    expect(decoded.sessionCapabilities?.close, isNotNull);
    expect(decoded.providers, isNotNull);
    expect(decoded.positionEncoding, PositionEncodingKind.utf8);
    expect(
      (roundTrip(decoded.toJson())['sessionCapabilities']
          as Map<String, dynamic>)['delete'],
      isNotNull,
    );
    expect(
      (roundTrip(decoded.toJson())['auth'] as Map<String, dynamic>)['logout'],
      isNotNull,
    );

    expect(
      roundTrip(DeleteSessionRequest(sessionId: 's1').toJson()),
      containsPair('sessionId', 's1'),
    );
    expect(
      roundTrip(CloseSessionRequest(sessionId: 's1').toJson()),
      containsPair('sessionId', 's1'),
    );

    final client = ClientCapabilities(
      positionEncodings: [
        PositionEncodingKind.utf8,
        PositionEncodingKind.utf16,
      ],
      session: ClientSessionCapabilities(
        configOptions: SessionConfigOptionsCapabilities(
          boolean: BooleanConfigOptionCapabilities(),
        ),
      ),
    );
    final clientDecoded = ClientCapabilities.fromJson(
      roundTrip(client.toJson()),
    );
    expect(clientDecoded.positionEncodings, [
      PositionEncodingKind.utf8,
      PositionEncodingKind.utf16,
    ]);
    expect(clientDecoded.session?.configOptions?.boolean, isNotNull);
  });

  test('optional filesystem flags and terminal auth follow v1.5 shapes', () {
    expect(FileSystemCapabilities().toJson(), isEmpty);
    final terminal = AuthMethod.fromJson({
      'id': 'login',
      'name': 'Log in',
      'type': 'terminal',
      'args': ['--login'],
      'env': {'MODE': 'interactive'},
    });
    expect(terminal.toJson(), {
      'id': 'login',
      'name': 'Log in',
      'type': 'terminal',
      'args': ['--login'],
      'env': {'MODE': 'interactive'},
    });
  });

  test('elicitation schemas preserve primitive and multi-select fields', () {
    final request = CreateElicitationRequest(
      mode: 'form',
      sessionId: 's1',
      message: 'Choose settings',
      requestedSchema: ElicitationSchema(
        properties: {
          'enabled': {'type': 'boolean', 'default': true},
          'tags': {
            'type': 'array',
            'items': {
              'type': 'string',
              'enum': ['a', 'b'],
            },
          },
        },
        required: ['enabled'],
      ),
    );
    final decoded = CreateElicitationRequest.fromJson(
      roundTrip(request.toJson()),
    );
    expect(decoded.mode, 'form');
    expect(decoded.requestedSchema?.properties['enabled'], {
      'type': 'boolean',
      'default': true,
    });
    expect(decoded.requestedSchema?.properties['tags'], {
      'type': 'array',
      'items': {
        'type': 'string',
        'enum': ['a', 'b'],
      },
    });
  });

  test(
    'elicitation URL and custom modes preserve scope and extension fields',
    () {
      final urlPayload = {
        'mode': 'url',
        'requestId': null,
        'elicitationId': 'e1',
        'url': 'https://example.test/auth',
        'message': 'Connect an account',
      };
      expect(
        CreateElicitationRequest.fromJson(urlPayload).toJson(),
        urlPayload,
      );

      final customPayload = {
        'mode': '_vendor_mode',
        'sessionId': 's1',
        'message': 'Custom prompt',
        'vendorField': {'enabled': true},
      };
      expect(
        CreateElicitationRequest.fromJson(customPayload).toJson(),
        customPayload,
      );
      expect(
        () => CreateElicitationRequest.fromJson({
          'mode': 'form',
          'sessionId': 's1',
          'message': 'Missing schema',
        }),
        throwsArgumentError,
      );
    },
  );

  test('tool call content includes its required discriminator', () {
    final content = ContentToolCallContent(
      content: TextContentBlock(text: 'created'),
    );
    expect(content.toJson(), containsPair('type', 'content'));
    final decoded = ToolCallContentConverter().fromJson(content.toJson());
    expect(decoded, isA<ContentToolCallContent>());
  });

  test('tool calls retain name and non-object raw JSON input/output', () {
    final payload = {
      'toolCallId': 'call-1',
      'title': 'Run command',
      'name': 'shell',
      'rawInput': ['echo', 'hello'],
      'rawOutput': 'hello',
    };
    final toolCall = ToolCall.fromJson(payload);
    expect(toolCall.toJson(), containsPair('name', 'shell'));
    expect(toolCall.toJson(), containsPair('rawInput', ['echo', 'hello']));
    expect(toolCall.toJson(), containsPair('rawOutput', 'hello'));

    final update = ToolCallUpdate.fromJson({
      'toolCallId': 'call-1',
      'name': 'shell',
      'rawInput': true,
      'rawOutput': [1, 2],
    });
    expect(update.toJson(), containsPair('name', 'shell'));
    expect(update.toJson(), containsPair('rawInput', true));
    expect(update.toJson(), containsPair('rawOutput', [1, 2]));

    for (final variant in ['tool_call', 'tool_call_update']) {
      final notification = SessionNotification.fromJson({
        'sessionId': 's1',
        'update': {
          'sessionUpdate': variant,
          'toolCallId': 'call-1',
          'title': 'Run command',
          'name': 'shell',
          'rawInput': ['echo', 'hello'],
          'rawOutput': {'exitCode': 0},
        },
      });
      final wireUpdate =
          roundTrip(notification.toJson())['update'] as Map<String, dynamic>;
      expect(wireUpdate, containsPair('name', 'shell'));
      expect(wireUpdate, containsPair('rawInput', ['echo', 'hello']));
      expect(wireUpdate, containsPair('rawOutput', {'exitCode': 0}));
    }
  });

  test('content chunks preserve message ids and metadata for each role', () {
    for (final kind in [
      'user_message_chunk',
      'agent_message_chunk',
      'agent_thought_chunk',
    ]) {
      final notification = SessionNotification.fromJson({
        'sessionId': 's1',
        'update': {
          'sessionUpdate': kind,
          'content': {'type': 'text', 'text': 'part'},
          'messageId': 'message-1',
          '_meta': {'trace': 1},
        },
      });
      final encoded =
          roundTrip(notification.toJson())['update'] as Map<String, dynamic>;
      expect(encoded, containsPair('messageId', 'message-1'));
      expect(encoded, containsPair('_meta', {'trace': 1}));
    }
  });

  test(
    'upstream numeric bounds and read-file default-on-error are applied',
    () {
      expect(
        () => InitializeRequest.fromJson({'protocolVersion': 65536}),
        throwsArgumentError,
      );
      expect(
        () => InitializeRequest.fromJson({'protocolVersion': -1}),
        throwsArgumentError,
      );
      final normalized = ReadTextFileRequest.fromJson({
        'sessionId': 's1',
        'path': '/file',
        'line': -1,
        'limit': 4294967296,
      });
      expect(normalized.line, isNull);
      expect(normalized.limit, isNull);
      final valid = ReadTextFileRequest.fromJson({
        'sessionId': 's1',
        'path': '/file',
        'line': 0,
        'limit': 4294967295,
      });
      expect(valid.line, 0);
      expect(valid.limit, 4294967295);
      expect(
        ReadTextFileRequest.fromJson({
          'sessionId': 's1',
          'path': '/file',
          'line': 2.0,
          'limit': 3.25,
        }).line,
        2,
      );
      expect(
        ReadTextFileRequest.fromJson({
          'sessionId': 's1',
          'path': '/file',
          'limit': 3.25,
        }).limit,
        isNull,
      );
    },
  );
}
