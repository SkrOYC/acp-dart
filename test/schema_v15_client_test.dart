import 'dart:convert';

import 'package:acp_dart/src/schema_v15_client.dart';
import 'package:test/test.dart';

void main() {
  group('v1.5 client-side schema payloads', () {
    test('elicitation actions preserve known and custom payloads', () {
      final cases = <Map<String, dynamic>>[
        {
          'action': 'accept',
          'content': {
            'name': 'Ada',
            'age': 37,
            'verified': true,
            'tags': ['math'],
          },
          '_meta': {'trace': 'accept'},
        },
        {'action': 'decline'},
        {
          'action': 'cancel',
          '_meta': {'trace': 'cancel'},
        },
        {
          'action': 'future_action',
          'custom': {
            'nested': [1, false],
          },
          '_meta': {'trace': 'custom'},
        },
      ];

      for (final expected in cases) {
        final decoded = CreateElicitationResponse.fromJson(expected);
        expect(jsonDecode(jsonEncode(decoded.toJson())), equals(expected));
      }
    });

    test(
      'accept action validates values and custom actions stay extensible',
      () {
        expect(
          () => CreateElicitationResponse.fromJson({
            'action': 'accept',
            'content': {
              'bad': [1, 'mixed'],
            },
          }),
          throwsFormatException,
        );
        expect(
          () => CreateElicitationResponse.fromJson({
            'action': 'accept',
            'content': [],
          }),
          throwsFormatException,
        );
        expect(
          CreateElicitationResponse.fromJson({
            'action': 'future_action',
            'content': [],
          }).toJson()['content'],
          isEmpty,
        );
        expect(
          () => CreateElicitationResponse.fromJson({}),
          throwsFormatException,
        );
      },
    );

    test('complete elicitation notification round-trips metadata', () {
      const payload = {
        'elicitationId': 'elic-1',
        '_meta': {'source': 'test'},
      };
      expect(
        jsonDecode(
          jsonEncode(
            CompleteElicitationNotification.fromJson(payload).toJson(),
          ),
        ),
        equals(payload),
      );
    });

    test('complete elicitation notification requires its identifier', () {
      expect(
        () => CompleteElicitationNotification.fromJson({}),
        throwsFormatException,
      );
    });

    test(
      'session update variants preserve discriminators and extension fields',
      () {
        final cases = <Map<String, dynamic>>[
          {
            'sessionUpdate': 'plan_update',
            'plan': {
              'type': 'markdown',
              'planId': 'plan-1',
              'content': '# Plan',
            },
            '_meta': {'source': 'test'},
          },
          {'sessionUpdate': 'plan_removed', 'planId': 'plan-1'},
          {
            'sessionUpdate': 'notice',
            'severity': 'warning',
            'title': 'Attention',
            'description': 'Review this',
          },
          {
            'sessionUpdate': 'compaction_update',
            'compactionId': 'compact-1',
            'status': 'completed',
            'summary': [
              {'type': 'text', 'text': 'Summary'},
            ],
          },
          {
            'sessionUpdate': 'compaction_summary_chunk',
            'compactionId': 'compact-1',
            'content': {'type': 'text', 'text': 'Summary chunk'},
          },
          {
            'sessionUpdate': 'future_update',
            'vendor': {'extra': 42},
          },
        ];

        for (final expected in cases) {
          final decoded = SessionUpdateV15.fromJson(expected);
          expect(decoded.sessionUpdate, expected['sessionUpdate']);
          expect(jsonDecode(jsonEncode(decoded.toJson())), equals(expected));
        }
      },
    );

    test('session update requires its discriminator', () {
      expect(() => SessionUpdateV15.fromJson({}), throwsFormatException);
    });

    test(
      'elicitation property schemas serialize every upstream property form',
      () {
        final properties = <String, ElicitationPropertySchema>{
          'name': StringPropertySchema(
            minLength: 1,
            maxLength: 40,
            format: StringFormat.email,
            defaultValue: 'agent@example.com',
          ),
          'choice': StringPropertySchema(
            oneOf: [
              EnumOption(constValue: 'a', title: 'Option A'),
              EnumOption(constValue: 'b', title: 'Option B'),
            ],
          ),
          'rating': NumberPropertySchema(minimum: 0.0, maximum: 1.0),
          'count': IntegerPropertySchema(defaultValue: 2),
          'enabled': BooleanPropertySchema(defaultValue: true),
          'tags': MultiSelectPropertySchema(
            items: StringMultiSelectItems(enumValues: ['one', 'two']),
            minItems: 1,
            maxItems: 2,
          ),
          'titledTags': MultiSelectPropertySchema(
            items: TitledMultiSelectItems(
              anyOf: [EnumOption(constValue: 'x', title: 'X')],
            ),
          ),
        };
        expect(properties['enabled']!.toJson(), {
          'type': 'boolean',
          'default': true,
        });
        expect(properties['tags']!.toJson(), {
          'type': 'array',
          'items': {
            'type': 'string',
            'enum': ['one', 'two'],
          },
          'minItems': 1,
          'maxItems': 2,
        });
        expect(properties['choice']!.toJson()['type'], 'string');
        expect(properties['rating']!.toJson()['minimum'], 0.0);
        expect(properties['count']!.toJson()['type'], 'integer');
        expect(properties['name']!.toJson()['format'], 'email');
        expect(properties['titledTags']!.toJson()['type'], 'array');
      },
    );

    test('typed notice update round-trips upstream session update shape', () {
      const notice = NoticeSessionUpdateV15(
        severity: 'warning',
        title: 'Attention',
        description: 'Review this',
      );
      expect(notice.toJson(), {
        'sessionUpdate': 'notice',
        'severity': 'warning',
        'title': 'Attention',
        'description': 'Review this',
      });
      expect(
        NoticeSessionUpdateV15.fromJson(notice.toJson()).title,
        'Attention',
      );
    });
  });
}
