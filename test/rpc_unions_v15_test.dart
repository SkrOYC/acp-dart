import 'package:acp_dart/src/rpc_unions.dart';
import 'package:acp_dart/src/schema.dart';
import 'package:acp_dart/src/schema_v15_client.dart';
import 'package:acp_dart/src/schema_v15_experimental.dart';
import 'package:test/test.dart';

void main() {
  test('method inventories exactly match TypeScript v1.5', () {
    expect(
      V15AgentMethods.all,
      unorderedEquals(const {
        'initialize',
        'authenticate',
        'providers/list',
        'providers/set',
        'providers/disable',
        'session/new',
        'session/load',
        'session/set_mode',
        'session/set_config_option',
        'session/prompt',
        'session/cancel',
        'mcp/message',
        'session/list',
        'session/delete',
        'session/fork',
        'session/resume',
        'session/close',
        'logout',
        'nes/start',
        'nes/suggest',
        'nes/accept',
        'nes/reject',
        'nes/close',
        'document/didOpen',
        'document/didChange',
        'document/didClose',
        'document/didSave',
        'document/didFocus',
      }),
    );
    expect(
      V15ClientMethods.all,
      unorderedEquals(const {
        'session/request_permission',
        'session/update',
        'fs/write_text_file',
        'fs/read_text_file',
        'terminal/create',
        'terminal/output',
        'terminal/release',
        'terminal/wait_for_exit',
        'terminal/kill',
        'mcp/connect',
        'mcp/message',
        'mcp/disconnect',
        'elicitation/create',
        'elicitation/complete',
      }),
    );
    expect(V15AgentMethods.all, hasLength(28));
    expect(V15ClientMethods.all, hasLength(14));
  });

  test('typed request round-trips with its method and request id', () {
    final request = V15ClientRequest.fromJson({
      'id': 7,
      'method': 'session/new',
      'params': {
        'cwd': '/work',
        'mcpServers': [],
        '_meta': {'trace': 'abc'},
      },
    });
    expect(request.params, isA<NewSessionRequest>());
    expect(request.toJson(), {
      'id': 7,
      'method': 'session/new',
      'params': {
        'cwd': '/work',
        'mcpServers': [],
        '_meta': {'trace': 'abc'},
      },
    });
  });

  test('agent request decodes the existing permission model', () {
    final request = V15AgentRequest.fromJson({
      'id': 9,
      'method': 'session/request_permission',
      'params': {
        'sessionId': 's1',
        'toolCall': {'toolCallId': 't1'},
        'options': [
          {'optionId': 'allow', 'name': 'Allow once', 'kind': 'allow_once'},
        ],
      },
    });
    expect(request.params, isA<RequestPermissionRequest>());
    expect(request.toJson()['method'], 'session/request_permission');
  });

  test('v1.5 experimental request remains identified and round-trips', () {
    final request = V15ClientRequest.fromJson({
      'id': 'p1',
      'method': 'providers/list',
      'params': {},
    });
    expect(request.method, 'providers/list');
    expect(request.params, isA<V15ListProvidersRequest>());
    expect(request.isExperimental, isTrue);
    expect(request.toJson()['params'], {});
  });

  test('unsupported complex known method uses explicit raw JSON payload', () {
    final request = V15ClientRequest.fromJson({
      'id': 2,
      'method': 'nes/suggest',
      'params': {
        'sessionId': 's',
        'document': {'uri': 'file:///a'},
      },
    });
    expect(request.params, isA<V15RawJsonPayload>());
    expect(request.toJson()['params'], {
      'sessionId': 's',
      'document': {'uri': 'file:///a'},
    });
  });

  test('unknown extension methods are preserved as raw payloads', () {
    final request = V15AgentRequest.fromJson({
      'id': 'x',
      'method': 'vendor/do_thing',
      'params': {'value': 1},
    });
    expect(request.isKnownMethod, isFalse);
    expect(request.params, isA<V15RawJsonPayload>());
    expect(request.toJson()['method'], 'vendor/do_thing');
  });

  test('request and notification directions are distinct', () {
    expect(
      () => V15ClientRequest.fromJson({
        'method': 'session/cancel',
        'params': {'sessionId': 's'},
      }),
      throwsFormatException,
    );
    final notification = V15ClientNotification.fromJson({
      'method': 'session/cancel',
      'params': {'sessionId': 's'},
    });
    expect(notification.params, isA<CancelNotification>());
    expect(notification.toJson()['method'], 'session/cancel');
    expect(
      () => V15AgentNotification.fromJson({
        'id': 1,
        'method': 'session/update',
        'params': {},
      }),
      throwsFormatException,
    );
  });

  test('response success and error envelopes round-trip', () {
    final response = V15AgentResponse.fromJson({
      'id': 3,
      'result': {'protocolVersion': 1},
    });
    expect(response.result, isA<InitializeResponse>());
    expect(response.toJson(), {
      'id': 3,
      'result': {'protocolVersion': 1},
    });
    final error = V15AgentResponse.fromJson({
      'id': 3,
      'error': {'code': -32601, 'message': 'Method not found'},
    });
    expect(error.error, isA<V15RawJsonPayload>());
    expect(error.toJson()['error'], {
      'code': -32601,
      'message': 'Method not found',
    });
  });

  test('client notification supports experimental v1.5 completion', () {
    final notification = V15AgentNotification.fromJson({
      'method': 'elicitation/complete',
      'params': {'elicitationId': 'e1'},
    });
    expect(notification.params, isA<CompleteElicitationNotification>());
    expect(notification.toJson(), {
      'method': 'elicitation/complete',
      'params': {'elicitationId': 'e1'},
    });
  });
}
