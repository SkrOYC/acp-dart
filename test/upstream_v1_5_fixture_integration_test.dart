import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp_dart/src/acp.dart';
import 'package:acp_dart/src/schema.dart';
import 'package:acp_dart/src/stream.dart';
import 'package:test/test.dart';

const _fixtureDir = 'test/fixtures/v1_5';

Future<Map<String, dynamic>> _fixture(String name) async =>
    jsonDecode(await File('$_fixtureDir/$name.json').readAsString())
        as Map<String, dynamic>;

dynamic _withoutNulls(dynamic value) {
  if (value is Map) {
    return value.map((key, child) => MapEntry(key, _withoutNulls(child)))
      ..removeWhere((_, child) => child == null);
  }
  if (value is List) return value.map(_withoutNulls).toList();
  return value;
}

class _Pair {
  final StreamController<List<int>> aToB = StreamController<List<int>>();
  final StreamController<List<int>> bToA = StreamController<List<int>>();
  final Completer<Map<String, dynamic>> notification = Completer();
  late final Connection a = Connection(
    (method, params) async => null,
    (method, params) async {},
    ndJsonStream(bToA.stream, aToB.sink),
  );
  late final Connection b = Connection(
    (method, params) async {
      final results = <String, dynamic>{
        'initialize': (await _fixture('initialize_response'))['result'],
        'session/new': (await _fixture('session_new_response'))['result'],
        'session/load': (await _fixture('session_load_response'))['result'],
        'session/resume': (await _fixture('session_resume_response'))['result'],
        'session/list': (await _fixture('session_list_response'))['result'],
        'session/delete': (await _fixture('session_delete_response'))['result'],
        'session/close': (await _fixture('session_close_response'))['result'],
        'logout': (await _fixture('logout_response'))['result'],
        'elicitation/create': (await _fixture(
          'elicitation_create_response',
        ))['result'],
        'mcp/connect': (await _fixture('experimental_mcp_response'))['result'],
      };
      return results[method] ?? <String, dynamic>{};
    },
    (method, params) async {
      notification.complete({'method': method, 'params': params});
    },
    ndJsonStream(aToB.stream, bToA.sink),
  );

  Future<void> close() async {
    await aToB.close();
    await bToA.close();
  }
}

void main() {
  group('ACP v1.5 upstream JSON fixtures', () {
    test(
      'requests traverse a connected NDJSON pair and preserve wire data',
      () async {
        final pair = _Pair();
        pair.b;
        for (final name in [
          'initialize_request',
          'session_new_request',
          'session_load_request',
          'session_resume_request',
          'session_list_request',
          'session_delete_request',
          'session_close_request',
          'logout_request',
          'elicitation_create_request',
          'experimental_mcp_connect',
        ]) {
          final request = await _fixture(name);
          final response = await pair.a.sendRequest<Map<String, dynamic>>(
            request['method'] as String,
            request['params'] as Map<String, dynamic>,
          );
          final expected = await _fixture(
            name == 'experimental_mcp_connect'
                ? 'experimental_mcp_response'
                : name.replaceFirst('_request', '_response'),
          );
          expect(response, expected['result'], reason: name);
        }
        await pair.close();
      },
    );

    test('stable session update variants decode and round trip', () async {
      final message = await _fixture('session_update_agent_message');
      final notification = SessionNotification.fromJson(
        message['params'] as Map<String, dynamic>,
      );
      expect(_withoutNulls(notification.toJson()), message['params']);

      final toolCall = await _fixture('session_update_tool_call');
      expect(
        _withoutNulls(
          SessionNotification.fromJson(
            toolCall['params'] as Map<String, dynamic>,
          ).toJson(),
        ),
        toolCall['params'],
      );
    });

    test('session updates traverse the connected NDJSON pair', () async {
      final pair = _Pair();
      pair.b;
      final update = await _fixture('session_update_agent_message');
      await pair.a.sendNotification(
        update['method'] as String,
        update['params'] as Map<String, dynamic>,
      );
      expect(await pair.notification.future, {
        'method': update['method'],
        'params': update['params'],
      });
      await pair.close();
    });

    test('all checked-in fixtures are standalone JSON-RPC objects', () async {
      final files = Directory(_fixtureDir).listSync().whereType<File>();
      expect(files, isNotEmpty);
      for (final file in files.where((file) => file.path.endsWith('.json'))) {
        final decoded = jsonDecode(await file.readAsString());
        expect(decoded, isA<Map<String, dynamic>>(), reason: file.path);
        if (!file.uri.pathSegments.last.startsWith('config_')) {
          expect(decoded['jsonrpc'], '2.0', reason: file.path);
        }
      }
    });

    test('select and boolean config variants match the v1.5 schema', () async {
      final select = await _fixture('config_select');
      expect(
        _withoutNulls(SessionConfigOption.fromJson(select).toJson()),
        select,
      );

      final boolean = await _fixture('config_boolean');
      expect(
        _withoutNulls(SessionConfigOption.fromJson(boolean).toJson()),
        boolean,
      );
    });

    test('error fixture retains the JSON-RPC error envelope', () async {
      final error = await _fixture('error_method_not_found');
      expect(error, {
        'jsonrpc': '2.0',
        'id': 10,
        'error': {
          'code': -32601,
          'message': 'Method not found',
          'data': {'method': 'missing/method'},
        },
      });
      expect(ErrorResponse.fromJson(error['error']), isA<ErrorResponse>());
    });

    test(
      'elicitation and experimental MCP fixtures remain valid JSON-RPC',
      () async {
        for (final name in [
          'elicitation_create_request',
          'elicitation_create_response',
          'experimental_mcp_connect',
          'experimental_mcp_response',
        ]) {
          final message = await _fixture(name);
          expect(message['jsonrpc'], '2.0', reason: name);
          expect(message.containsKey('id'), isTrue, reason: name);
        }
      },
    );
  });
}
