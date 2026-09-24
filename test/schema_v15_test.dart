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
}
