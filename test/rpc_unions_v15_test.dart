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

  test('mcp/message request is accepted in both protocol directions', () {
    final payload = {'method': 'ping'};
    final agentRequest = V15AgentRequest.fromJson({
      'id': 10,
      'method': 'mcp/message',
      'params': {'connectionId': 'c1', 'method': 'ping', 'params': payload},
    });
    final clientRequest = V15ClientRequest.fromJson({
      'id': 11,
      'method': 'mcp/message',
      'params': {'connectionId': 'c1', 'method': 'ping', 'params': payload},
    });
    expect(agentRequest.params, isA<V15MessageMcpRequest>());
    expect(clientRequest.params, isA<V15MessageMcpRequest>());
    expect(agentRequest.isExperimental, isTrue);
    expect(clientRequest.isExperimental, isTrue);
    expect(agentRequest.toJson()['method'], 'mcp/message');
    expect(clientRequest.toJson()['method'], 'mcp/message');
    final response = V15AgentResponse.fromJson({
      'id': 10,
      'result': {},
    }, method: 'mcp/message');
    expect(response.result, isA<V15MessageMcpResponse>());
  });

  test('stable response methods decode to existing response models', () {
    final cases = <(bool, String, Map<String, dynamic>, Type)>[
      (false, 'authenticate', {}, AuthenticateResponse),
      (false, 'session/new', {'sessionId': 's'}, NewSessionResponse),
      (false, 'session/load', {}, LoadSessionResponse),
      (false, 'session/list', {'sessions': []}, ListSessionsResponse),
      (false, 'session/delete', {}, DeleteSessionResponse),
      (false, 'session/fork', {'sessionId': 's2'}, ForkSessionResponse),
      (false, 'session/resume', {}, ResumeSessionResponse),
      (false, 'session/close', {}, CloseSessionResponse),
      (false, 'session/set_mode', {}, SetSessionModeResponse),
      (
        false,
        'session/set_config_option',
        {'configOptions': []},
        SetSessionConfigOptionResponse,
      ),
      (false, 'session/prompt', {'stopReason': 'end_turn'}, PromptResponse),
      (
        true,
        'session/request_permission',
        {
          'outcome': {'outcome': 'cancelled'},
        },
        RequestPermissionResponse,
      ),
      (true, 'fs/write_text_file', {}, WriteTextFileResponse),
      (true, 'fs/read_text_file', {'content': 'hello'}, ReadTextFileResponse),
      (true, 'terminal/create', {'terminalId': 't'}, CreateTerminalResponse),
      (
        true,
        'terminal/output',
        {'output': '', 'truncated': false},
        TerminalOutputResponse,
      ),
      (true, 'terminal/release', {}, ReleaseTerminalResponse),
      (true, 'terminal/wait_for_exit', {}, WaitForTerminalExitResponse),
      (true, 'terminal/kill', {}, KillTerminalCommandResponse),
      (
        true,
        'elicitation/create',
        {'action': 'decline'},
        CreateElicitationResponse,
      ),
      (false, 'mcp/message', {}, V15MessageMcpResponse),
      (false, 'providers/list', {'providers': []}, V15ListProvidersResponse),
      (false, 'providers/set', {}, V15ProviderMutationResponse),
      (false, 'providers/disable', {}, V15ProviderMutationResponse),
      (true, 'mcp/connect', {'connectionId': 'c1'}, V15ConnectMcpResponse),
      (true, 'mcp/disconnect', {}, V15DisconnectMcpResponse),
    ];
    for (final (isClientResponse, method, result, expectedType) in cases) {
      final json = {'id': 1, 'result': result};
      final response = isClientResponse
          ? V15ClientResponse.fromJson(json, method: method)
          : V15AgentResponse.fromJson(json, method: method);
      expect(response.result.runtimeType, expectedType, reason: method);
      expect(response.toJson()['result'], result, reason: method);
    }
  });

  test('logout empty response has an explicit raw model gap', () {
    for (final method in const [
      'logout',
      'nes/start',
      'nes/suggest',
      'nes/close',
    ]) {
      final response = V15AgentResponse.fromJson({
        'id': 2,
        'result': {},
      }, method: method);
      expect(response.result, isA<V15RawJsonPayload>(), reason: method);
    }
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
    }, method: 'initialize');
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
