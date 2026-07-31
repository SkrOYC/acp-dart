import 'dart:async';
import 'dart:convert';

import 'package:acp_dart/acp_dart.dart';
import 'package:test/test.dart';

class _ProviderAgent implements Agent {
  final bool handle;
  _ProviderAgent({this.handle = true});

  SetProviderRequest? setWith;
  DisableProviderRequest? disabledWith;

  @override
  Future<ListProvidersResponse>? listProviders(ListProvidersRequest params) {
    if (!handle) return null;
    return Future.value(
      ListProvidersResponse(
        providers: [
          ProviderInfo(
            providerId: 'anthropic',
            supported: const [LlmProtocols.anthropic],
            required: true,
            current: ProviderCurrentConfig(
              apiType: LlmProtocols.anthropic,
              baseUrl: 'https://api.anthropic.com',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<SetProviderResponse>? setProvider(SetProviderRequest params) {
    if (!handle) return null;
    setWith = params;
    return Future.value(SetProviderResponse());
  }

  @override
  Future<DisableProviderResponse>? disableProvider(
    DisableProviderRequest params,
  ) {
    if (!handle) return null;
    disabledWith = params;
    return Future.value(DisableProviderResponse());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late StreamController<Map<String, dynamic>> readable;
  late StreamController<Map<String, dynamic>> writable;
  late AcpStream stream;

  setUp(() {
    readable = StreamController<Map<String, dynamic>>();
    writable = StreamController<Map<String, dynamic>>.broadcast();
    stream = AcpStream(readable: readable.stream, writable: writable.sink);
  });

  tearDown(() {
    unawaited(readable.close());
    unawaited(writable.close());
  });

  /// Drives a request through the agent and returns the reply *as it would go
  /// out on the wire*.
  ///
  /// Handlers return model objects; they are only serialized when the message
  /// reaches the NDJSON stream, so encode here to assert on the wire form.
  Future<Map<String, dynamic>> callAgent(
    Agent agent,
    String method,
    Map<String, dynamic> params,
  ) async {
    AgentSideConnection((_) => agent, stream);
    final reply = writable.stream.first;
    readable.add({
      'jsonrpc': '2.0',
      'id': 1,
      'method': method,
      'params': params,
    });
    return jsonDecode(jsonEncode(await reply)) as Map<String, dynamic>;
  }

  group('Provider dispatch', () {
    test('providers/list returns the configured providers', () async {
      final reply = await callAgent(
        _ProviderAgent(),
        'providers/list',
        <String, dynamic>{},
      );

      expect(reply['error'], isNull);
      final providers = reply['result']['providers'] as List;
      expect(providers, hasLength(1));
      expect(providers.first['providerId'], equals('anthropic'));
      expect(providers.first['required'], isTrue);
      expect(
        providers.first['current']['baseUrl'],
        equals('https://api.anthropic.com'),
      );
    });

    test('providers/set carries apiType, baseUrl, and headers', () async {
      final agent = _ProviderAgent();
      final reply = await callAgent(agent, 'providers/set', {
        'providerId': 'openai',
        'apiType': 'openai',
        'baseUrl': 'https://api.openai.com/v1',
        'headers': {'Authorization': 'Bearer sk-test'},
      });

      expect(reply['error'], isNull);
      expect(agent.setWith?.providerId, equals('openai'));
      expect(agent.setWith?.apiType, equals(LlmProtocols.openai));
      expect(
        agent.setWith?.headers,
        equals({'Authorization': 'Bearer sk-test'}),
      );
    });

    test('providers/disable carries the provider id', () async {
      final agent = _ProviderAgent();
      final reply = await callAgent(agent, 'providers/disable', {
        'providerId': 'vertex',
      });

      expect(reply['error'], isNull);
      expect(agent.disabledWith?.providerId, equals('vertex'));
    });

    test('an agent without provider support reports method not found', () async {
      final reply = await callAgent(
        _ProviderAgent(handle: false),
        'providers/list',
        <String, dynamic>{},
      );

      expect(reply['error']['code'], equals(-32601));
    });
  });

  group('Provider schema', () {
    test('round-trips with an unconfigured provider', () {
      final decoded = ListProvidersResponse.fromJson(
        jsonDecode(
              jsonEncode(
                ListProvidersResponse(
                  providers: [
                    ProviderInfo(
                      providerId: 'bedrock',
                      supported: const [LlmProtocols.bedrock],
                      required: false,
                    ),
                  ],
                ).toJson(),
              ),
            )
            as Map<String, dynamic>,
      );

      expect(decoded.providers.single.current, isNull);
      expect(decoded.providers.single.required, isFalse);
      expect(decoded.providers.single.supported, equals(['bedrock']));
    });

    test('an unknown apiType passes through as an open string union', () {
      final decoded = ProviderCurrentConfig.fromJson({
        'apiType': 'some-future-protocol',
        'baseUrl': 'https://example.com',
      });

      expect(decoded.apiType, equals('some-future-protocol'));
    });

    test('toString redacts headers so requests can be logged', () {
      final request = SetProviderRequest(
        providerId: 'openai',
        apiType: LlmProtocols.openai,
        baseUrl: 'https://api.openai.com/v1',
        headers: {'Authorization': 'Bearer sk-super-secret'},
      );

      expect(request.toString(), contains('<redacted>'));
      expect(request.toString(), isNot(contains('sk-super-secret')));
      // The wire form must still carry the real value.
      expect(
        request.toJson()['headers']['Authorization'],
        equals('Bearer sk-super-secret'),
      );
    });
  });

  group('Provider unions and constants', () {
    test('requests and responses map to their variants', () {
      expect(
        ClientRequestUnion.fromMethod('providers/list', <String, dynamic>{}),
        isA<ClientListProvidersRequest>(),
      );
      expect(
        ClientRequestUnion.fromMethod('providers/set', {
          'providerId': 'p',
          'apiType': 'openai',
          'baseUrl': 'https://x',
        }),
        isA<ClientSetProviderRequest>(),
      );
      expect(
        ClientRequestUnion.fromMethod('providers/disable', {'providerId': 'p'}),
        isA<ClientDisableProviderRequest>(),
      );
      expect(
        AgentResponseUnion.fromJson('providers/list', {'providers': []}),
        isA<AgentListProvidersResponse>(),
      );
      expect(
        AgentResponseUnion.fromJson('providers/set', null),
        isA<AgentSetProviderResponse>(),
      );
      expect(
        AgentResponseUnion.fromJson('providers/disable', null),
        isA<AgentDisableProviderResponse>(),
      );
    });

    test('method constants are registered', () {
      expect(agentMethods['providersList'], equals('providers/list'));
      expect(agentMethods['providersSet'], equals('providers/set'));
      expect(agentMethods['providersDisable'], equals('providers/disable'));
    });
  });
}
