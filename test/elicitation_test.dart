import 'dart:convert';

import 'package:acp_dart/acp_dart.dart';
import 'package:acp_dart/src/elicitation_converters.dart';
import 'package:test/test.dart';

Map<String, dynamic> _roundTrip(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  group('Elicitation requests', () {
    const converter = CreateElicitationRequestConverter();

    test('form request round-trips with a full property schema', () {
      final request = ElicitationFormRequest(
        message: 'Where should the report go?',
        sessionId: 'sess-1',
        toolCallId: 'call-1',
        requestedSchema: ElicitationSchema(
          title: 'Report options',
          required: ['path'],
          properties: {
            'path': StringPropertySchema(
              title: 'Output path',
              minLength: 1,
              format: StringFormat.uri,
            ),
            'copies': IntegerPropertySchema(minimum: 1, maximum: 10),
            'ratio': NumberPropertySchema(minimum: 0, maximum: 1),
            'overwrite': BooleanPropertySchema(defaultValue: false),
            'formats': MultiSelectPropertySchema(
              minItems: 1,
              items: StringMultiSelectItems(enumValues: ['pdf', 'html']),
            ),
          },
        ),
      );

      final encoded = _roundTrip(converter.toJson(request));
      expect(encoded['mode'], equals('form'));

      final decoded = converter.fromJson(encoded);
      expect(decoded, isA<ElicitationFormRequest>());

      final typed = decoded as ElicitationFormRequest;
      expect(typed.message, equals('Where should the report go?'));
      expect(typed.sessionId, equals('sess-1'));
      expect(typed.toolCallId, equals('call-1'));
      expect(typed.requestedSchema.type, equals('object'));
      expect(typed.requestedSchema.required, equals(['path']));

      final properties = typed.requestedSchema.properties!;
      expect(properties['path'], isA<StringPropertySchema>());
      expect(
        (properties['path'] as StringPropertySchema).format,
        equals(StringFormat.uri),
      );
      expect(properties['copies'], isA<IntegerPropertySchema>());
      expect(properties['ratio'], isA<NumberPropertySchema>());
      expect(properties['overwrite'], isA<BooleanPropertySchema>());

      final multi = properties['formats'] as MultiSelectPropertySchema;
      expect(multi.items, isA<StringMultiSelectItems>());
      expect(
        (multi.items as StringMultiSelectItems).enumValues,
        equals(['pdf', 'html']),
      );
    });

    test('request-scoped url request round-trips', () {
      final request = ElicitationUrlRequest(
        message: 'Finish signing in',
        requestId: 'req-9',
        elicitationId: 'elic-1',
        url: 'https://example.com/auth',
      );

      final encoded = _roundTrip(converter.toJson(request));
      expect(encoded['mode'], equals('url'));

      final typed = converter.fromJson(encoded) as ElicitationUrlRequest;
      expect(typed.requestId, equals('req-9'));
      expect(typed.elicitationId, equals('elic-1'));
      expect(typed.url, equals('https://example.com/auth'));
      expect(typed.sessionId, isNull);
    });

    test('titled multi-select items round-trip through anyOf', () {
      final schema = MultiSelectPropertySchema(
        items: TitledMultiSelectItems(
          anyOf: [
            EnumOption(constValue: 'pdf', title: 'PDF'),
            EnumOption(
              constValue: 'html',
              title: 'HTML',
              description: 'Single page',
            ),
          ],
        ),
      );

      final encoded = _roundTrip(
        const ElicitationPropertySchemaConverter().toJson(schema),
      );
      final decoded =
          const ElicitationPropertySchemaConverter().fromJson(encoded)
              as MultiSelectPropertySchema;

      final items = decoded.items as TitledMultiSelectItems;
      expect(items.anyOf, hasLength(2));
      expect(items.anyOf.first.constValue, equals('pdf'));
      expect(items.anyOf.last.description, equals('Single page'));
    });

    test('unknown mode is preserved rather than dropped', () {
      final raw = {
        'mode': '_vendorPrompt',
        'message': 'Custom',
        'sessionId': 'sess-1',
        'vendorField': 42,
      };

      final decoded = converter.fromJson(raw);
      expect(decoded, isA<UnknownElicitationRequest>());
      expect(decoded.message, equals('Custom'));
      expect(converter.toJson(decoded), equals(raw));
    });

    test('unknown property schema type is preserved', () {
      final raw = {'type': '_vendorType', 'title': 'Custom'};
      final decoded = const ElicitationPropertySchemaConverter().fromJson(raw);

      expect(decoded, isA<UnknownPropertySchema>());
      expect(
        const ElicitationPropertySchemaConverter().toJson(decoded),
        equals(raw),
      );
    });
  });

  group('Elicitation responses', () {
    const converter = CreateElicitationResponseConverter();

    test('accept round-trips with mixed content value types', () {
      final response = ElicitationAcceptResponse(
        content: {
          'path': '/tmp/report.pdf',
          'copies': 3,
          'ratio': 0.5,
          'overwrite': true,
          'formats': ['pdf', 'html'],
        },
      );

      final encoded = _roundTrip(converter.toJson(response));
      expect(encoded['action'], equals('accept'));

      final typed = converter.fromJson(encoded) as ElicitationAcceptResponse;
      expect(typed.content!['path'], equals('/tmp/report.pdf'));
      expect(typed.content!['copies'], equals(3));
      expect(typed.content!['ratio'], equals(0.5));
      expect(typed.content!['overwrite'], isTrue);
      expect(typed.content!['formats'], equals(['pdf', 'html']));
    });

    test('decline and cancel are distinct variants', () {
      final decline = converter.fromJson(
        _roundTrip(converter.toJson(ElicitationDeclineResponse())),
      );
      final cancel = converter.fromJson(
        _roundTrip(converter.toJson(ElicitationCancelResponse())),
      );

      expect(decline, isA<ElicitationDeclineResponse>());
      expect(cancel, isA<ElicitationCancelResponse>());
    });

    test('unknown action is preserved rather than dropped', () {
      final raw = {'action': '_vendorAction', 'detail': 'x'};
      final decoded = converter.fromJson(raw);

      expect(decoded, isA<UnknownElicitationResponse>());
      expect(converter.toJson(decoded), equals(raw));
    });
  });

  group('Elicitation capabilities and notification', () {
    test('client capabilities carry elicitation modes', () {
      final capabilities = ClientCapabilities(
        fs: FileSystemCapability(readTextFile: true),
        elicitation: ElicitationCapabilities(
          form: ElicitationFormCapabilities(),
          url: ElicitationUrlCapabilities(),
        ),
      );

      final decoded = ClientCapabilities.fromJson(
        _roundTrip(capabilities.toJson()),
      );

      expect(decoded.elicitation, isNotNull);
      expect(decoded.elicitation!.form, isNotNull);
      expect(decoded.elicitation!.url, isNotNull);
    });

    test('omitted elicitation capability stays null', () {
      final decoded = ClientCapabilities.fromJson(
        _roundTrip(ClientCapabilities().toJson()),
      );

      expect(decoded.elicitation, isNull);
    });

    test('complete notification round-trips', () {
      final decoded = CompleteElicitationNotification.fromJson(
        _roundTrip(
          CompleteElicitationNotification(elicitationId: 'elic-1').toJson(),
        ),
      );

      expect(decoded.elicitationId, equals('elic-1'));
    });
  });

  group('Method constants', () {
    test('elicitation methods are registered as client methods', () {
      expect(clientMethods['elicitationCreate'], equals('elicitation/create'));
      expect(
        clientMethods['elicitationComplete'],
        equals('elicitation/complete'),
      );
    });
  });
}
