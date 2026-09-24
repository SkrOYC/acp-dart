import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp_dart/src/acp.dart';
import 'package:acp_dart/src/schema.dart';
import 'package:acp_dart/src/stream.dart';
import 'package:test/test.dart';

Future<Map<String, dynamic>> _data() async =>
    jsonDecode(
          await File('test/fixtures/v1_5/schema_variants.json').readAsString(),
        )
        as Map<String, dynamic>;

dynamic _withoutNulls(dynamic value) {
  if (value is Map) {
    return value.map((key, child) => MapEntry(key, _withoutNulls(child)))
      ..removeWhere((_, child) => child == null);
  }
  if (value is List) return value.map(_withoutNulls).toList();
  return value;
}

Future<dynamic> _wireRequest(
  String method,
  Map<String, dynamic> params,
  dynamic result,
) async {
  final aToB = StreamController<List<int>>();
  final bToA = StreamController<List<int>>();
  final a = Connection(
    (method, params) async => null,
    (method, params) async {},
    ndJsonStream(bToA.stream, aToB.sink),
  );
  Connection(
    (receivedMethod, receivedParams) async {
      expect(receivedMethod, method);
      expect(receivedParams, params);
      return result;
    },
    (method, params) async {},
    ndJsonStream(aToB.stream, bToA.sink),
  );
  final response = await a.sendRequest<dynamic>(method, params);
  await aToB.close();
  await bToA.close();
  return response;
}

void main() {
  group('ACP v1.5 schema variants', () {
    test('all content blocks decode and preserve protocol metadata', () async {
      final data = await _data();
      final content = data['contentBlocks'] as List<dynamic>;
      final prompt = PromptRequest.fromJson({
        'sessionId': 'sess-1',
        'prompt': content,
      });
      final encoded = _withoutNulls(prompt.toJson()) as Map<String, dynamic>;

      expect(encoded['prompt'], hasLength(5));
      expect(
        (encoded['prompt'] as List).map((block) => block['type']).toList(),
        ['text', 'image', 'audio', 'resource_link', 'resource'],
      );
      expect(encoded['prompt'][0]['_meta'], {'vendor': 'keep me'});
      expect(encoded['prompt'][0].containsKey('unknown'), isFalse);
    });

    test(
      'all tool-call content variants retain their discriminators',
      () async {
        final data = await _data();
        final variants = data['toolCallContent'] as List<dynamic>;
        final toolCall = ToolCall.fromJson({
          'toolCallId': 'tool-1',
          'title': 'Inspect',
          'content': variants,
        });

        expect(_withoutNulls(toolCall.toJson())['content'], variants);
      },
    );

    test('permission outcome variants round trip', () async {
      final data = await _data();
      final outcomes = data['permissionOutcomes'] as List<dynamic>;
      for (final outcome in outcomes) {
        final response = RequestPermissionResponse.fromJson({
          'outcome': outcome,
        });
        expect(
          _withoutNulls(response.toJson())['outcome'],
          outcome,
          reason: outcome['outcome'],
        );
      }
    });

    test(
      'agent and terminal authentication methods retain all fields',
      () async {
        final data = await _data();
        final methods = data['authMethods'] as List<dynamic>;
      final response = InitializeResponse.fromJson({
        'protocolVersion': 1,
        'authMethods': methods,
      });
      expect(
        response.authMethods
            .map((method) => _withoutNulls(method.toJson()))
            .toList(),
        methods,
      );
      },
    );

    test(
      'select configuration supports ungrouped and grouped options',
      () async {
        final data = await _data();
        final configs = data['configOptions'] as List<dynamic>;
        for (final config in configs.skip(1)) {
          expect(
            _withoutNulls(SessionConfigOption.fromJson(config).toJson()),
            config,
          );
        }
      },
    );

    test('boolean configuration option decodes and round trips', () async {
      final data = await _data();
      final config = (data['configOptions'] as List<dynamic>).first;
      expect(
        _withoutNulls(SessionConfigOption.fromJson(config).toJson()),
        config,
      );
    });

    test(
      'every upstream session update discriminator decodes and round trips',
      () async {
        final data = await _data();
        for (final update in data['sessionUpdates'] as List<dynamic>) {
          final notification = SessionNotification.fromJson({
            'sessionId': 'sess-1',
            'update': update,
          });
          expect(
            _withoutNulls(notification.toJson())['update'],
            update,
            reason: update['sessionUpdate'],
          );
        }
      },
    );

    test('required schema fields reject malformed values', () async {
      final invalid = (await _data())['requiredFieldInvalid'];
      expect(
        () => PromptRequest.fromJson(invalid['promptWithoutContent']),
        throwsA(anything),
      );
      expect(
        () => TextContentBlock.fromJson(invalid['textWithoutText']),
        throwsA(anything),
      );
      expect(
        () => RequestPermissionResponse.fromJson({
          'outcome': invalid['selectedPermissionWithoutOptionId'],
        }),
        throwsA(anything),
      );
    });

    test(
      'known object extras are dropped and _meta values are preserved',
      () async {
        final input = (await _data())['unknownFields']['knownContentBlock'];
        final block = TextContentBlock.fromJson(input);
        expect(_withoutNulls(block.toJson()), {
          'type': 'text',
          'text': 'known',
          '_meta': {'vendorKey': 'keep'},
        });
      },
    );

    test(
      'content variants survive a session prompt over connected NDJSON',
      () async {
        final data = await _data();
        final params = {'sessionId': 'sess-1', 'prompt': data['contentBlocks']};
        final result = {'stopReason': 'end_turn'};
        expect(await _wireRequest('session/prompt', params, result), result);
      },
    );

    test(
      'custom elicitation payloads survive connected JSON-RPC unchanged',
      () async {
        final custom = (await _data())['customElicitation'];
        final response = custom['response'] as Map<String, dynamic>;
        expect(
          await _wireRequest(
            'elicitation/create',
            custom['request'] as Map<String, dynamic>,
            response,
          ),
          response,
        );
      },
    );
  });
}
