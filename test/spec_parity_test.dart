import 'dart:async';

import 'package:acp_dart/acp_dart.dart';
import 'package:acp_dart/src/elicitation_converters.dart';
import 'package:test/test.dart';

/// Minimal Agent that only implements what a given test exercises.
///
/// Declaring `noSuchMethod` lets the analyzer synthesise forwarders for the
/// rest of the interface, so these mocks don't have to restate every member.
class _StubAgent implements Agent {
  final bool handleLifecycle;

  _StubAgent({this.handleLifecycle = true});

  CloseSessionRequest? closedWith;
  DeleteSessionRequest? deletedWith;
  LogoutRequest? loggedOutWith;

  @override
  Future<CloseSessionResponse>? closeSession(CloseSessionRequest params) {
    if (!handleLifecycle) return null;
    closedWith = params;
    return Future.value(CloseSessionResponse());
  }

  @override
  Future<DeleteSessionResponse>? deleteSession(DeleteSessionRequest params) {
    if (!handleLifecycle) return null;
    deletedWith = params;
    return Future.value(DeleteSessionResponse());
  }

  @override
  Future<LogoutResponse>? logout(LogoutRequest params) {
    if (!handleLifecycle) return null;
    loggedOutWith = params;
    return Future.value(LogoutResponse());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubClient implements Client {
  final CreateElicitationResponse? elicitationResult;

  _StubClient({this.elicitationResult});

  CreateElicitationRequest? elicitedWith;
  CompleteElicitationNotification? completedWith;

  @override
  Future<CreateElicitationResponse>? createElicitation(
    CreateElicitationRequest params,
  ) {
    if (elicitationResult == null) return null;
    elicitedWith = params;
    return Future.value(elicitationResult);
  }

  @override
  Future<void>? completeElicitation(CompleteElicitationNotification params) {
    completedWith = params;
    return Future.value();
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
    // Deliberately not awaited: closing a single-subscription controller that
    // was never listened to returns a future that never completes, which the
    // tests here that build no connection would otherwise hang on.
    unawaited(readable.close());
    unawaited(writable.close());
  });

  /// Drives an agent-handled request through the wire and returns the reply.
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
    return reply;
  }

  group('Session lifecycle dispatch', () {
    test('session/close reaches the agent', () async {
      final agent = _StubAgent();
      final reply = await callAgent(agent, 'session/close', {
        'sessionId': 'sess-1',
      });

      expect(agent.closedWith?.sessionId, equals('sess-1'));
      expect(reply['error'], isNull);
    });

    test('session/delete reaches the agent', () async {
      final agent = _StubAgent();
      final reply = await callAgent(agent, 'session/delete', {
        'sessionId': 'sess-2',
      });

      expect(agent.deletedWith?.sessionId, equals('sess-2'));
      expect(reply['error'], isNull);
    });

    test('logout reaches the agent', () async {
      final agent = _StubAgent();
      final reply = await callAgent(agent, 'logout', <String, dynamic>{});

      expect(agent.loggedOutWith, isNotNull);
      expect(reply['error'], isNull);
    });

    test('an agent that does not handle them reports method not found', () async {
      final agent = _StubAgent(handleLifecycle: false);
      final reply = await callAgent(agent, 'session/delete', {
        'sessionId': 'sess-3',
      });

      expect(reply['error']['code'], equals(-32601));
    });
  });

  group('Session lifecycle senders', () {
    late ClientSideConnection connection;

    setUp(() {
      connection = ClientSideConnection((_) => _StubClient(), stream);
    });

    /// Issues an outbound request, answers it, and returns the wire message.
    ///
    /// Answering matters: an unanswered request leaves a pending future that
    /// never completes and wedges the test isolate.
    Future<Map<String, dynamic>> exchange(Future<Object?> Function() send) async {
      final sent = writable.stream.first;
      final pending = send();
      final message = await sent;
      readable.add({
        'jsonrpc': '2.0',
        'id': message['id'],
        'result': <String, dynamic>{},
      });
      await pending;
      return message;
    }

    test('closeSession uses the spec method name', () async {
      final message = await exchange(
        () => connection.closeSession(CloseSessionRequest(sessionId: 'sess-1'))!,
      );

      expect(message['method'], equals('session/close'));
      expect(message['params']['sessionId'], equals('sess-1'));
    });

    test('deleteSession uses the spec method name', () async {
      final message = await exchange(
        () =>
            connection.deleteSession(DeleteSessionRequest(sessionId: 'sess-2'))!,
      );

      expect(message['method'], equals('session/delete'));
      expect(message['params']['sessionId'], equals('sess-2'));
    });

    test('logout uses the spec method name', () async {
      final message = await exchange(() => connection.logout(LogoutRequest())!);

      expect(message['method'], equals('logout'));
    });
  });

  group('Elicitation dispatch', () {
    test('elicitation/create reaches the client and returns its answer', () async {
      final client = _StubClient(
        elicitationResult: ElicitationAcceptResponse(
          content: {'path': '/tmp/out.txt'},
        ),
      );
      ClientSideConnection((_) => client, stream);

      final reply = writable.stream.first;
      readable.add({
        'jsonrpc': '2.0',
        'id': 7,
        'method': 'elicitation/create',
        'params': {
          'mode': 'form',
          'message': 'Where to?',
          'sessionId': 'sess-1',
          'requestedSchema': {
            'type': 'object',
            'properties': {
              'path': {'type': 'string'},
            },
          },
        },
      });

      final result = await reply;
      expect(result['error'], isNull);
      expect(result['result']['action'], equals('accept'));
      expect(result['result']['content']['path'], equals('/tmp/out.txt'));

      final received = client.elicitedWith;
      expect(received, isA<ElicitationFormRequest>());
      expect(
        (received as ElicitationFormRequest).requestedSchema.properties,
        contains('path'),
      );
    });

    test('a client without elicitation support reports method not found', () async {
      ClientSideConnection((_) => _StubClient(), stream);

      final reply = writable.stream.first;
      readable.add({
        'jsonrpc': '2.0',
        'id': 8,
        'method': 'elicitation/create',
        'params': {
          'mode': 'url',
          'message': 'Sign in',
          'sessionId': 'sess-1',
          'elicitationId': 'elic-1',
          'url': 'https://example.com',
        },
      });

      final result = await reply;
      expect(result['error']['code'], equals(-32601));
    });

    test('elicitation/complete reaches the client', () async {
      final client = _StubClient();
      ClientSideConnection((_) => client, stream);

      readable.add({
        'jsonrpc': '2.0',
        'method': 'elicitation/complete',
        'params': {'elicitationId': 'elic-1'},
      });

      await Future<void>.delayed(Duration.zero);
      expect(client.completedWith?.elicitationId, equals('elic-1'));
    });

    test('agent-side sender emits elicitation/create and parses the union', () async {
      final connection = AgentSideConnection((_) => _StubAgent(), stream);

      final sent = writable.stream.first;
      final pending = connection.createElicitation(
        ElicitationUrlRequest(
          message: 'Sign in',
          sessionId: 'sess-1',
          elicitationId: 'elic-1',
          url: 'https://example.com',
        ),
      );

      final message = await sent;
      expect(message['method'], equals('elicitation/create'));
      expect(message['params']['mode'], equals('url'));
      expect(message['params']['url'], equals('https://example.com'));

      readable.add({
        'jsonrpc': '2.0',
        'id': message['id'],
        'result': {'action': 'cancel'},
      });

      expect(await pending, isA<ElicitationCancelResponse>());
    });
  });

  group('Schema round-trips', () {
    test('lifecycle requests and responses survive a round-trip', () {
      expect(
        DeleteSessionRequest.fromJson(
          DeleteSessionRequest(sessionId: 'a', meta: {'k': 'v'}).toJson(),
        ).sessionId,
        equals('a'),
      );
      expect(
        CloseSessionRequest.fromJson(
          CloseSessionRequest(sessionId: 'b').toJson(),
        ).sessionId,
        equals('b'),
      );
      expect(
        LogoutRequest.fromJson(LogoutRequest(meta: {'k': 'v'}).toJson()).meta,
        equals({'k': 'v'}),
      );
      expect(DeleteSessionResponse.fromJson(<String, dynamic>{}).meta, isNull);
      expect(CloseSessionResponse.fromJson(<String, dynamic>{}).meta, isNull);
      expect(LogoutResponse.fromJson(<String, dynamic>{}).meta, isNull);
    });
  });

  group('RPC unions', () {
    test('client requests map to the new lifecycle variants', () {
      expect(
        ClientRequestUnion.fromMethod('session/close', {'sessionId': 's'}),
        isA<ClientCloseSessionRequest>(),
      );
      expect(
        ClientRequestUnion.fromMethod('session/delete', {'sessionId': 's'}),
        isA<ClientDeleteSessionRequest>(),
      );
      expect(
        ClientRequestUnion.fromMethod('logout', <String, dynamic>{}),
        isA<ClientLogoutRequest>(),
      );
    });

    test('agent responses map to the new lifecycle variants', () {
      expect(
        // Note: the agent-side factory is `fromJson`, while the client-side
        // one is `fromMethod`. Both take (method, result).
        AgentResponseUnion.fromJson('session/close', null),
        isA<AgentCloseSessionResponse>(),
      );
      expect(
        // Note: the agent-side factory is `fromJson`, while the client-side
        // one is `fromMethod`. Both take (method, result).
        AgentResponseUnion.fromJson('session/delete', null),
        isA<AgentDeleteSessionResponse>(),
      );
      expect(
        // Note: the agent-side factory is `fromJson`, while the client-side
        // one is `fromMethod`. Both take (method, result).
        AgentResponseUnion.fromJson('logout', null),
        isA<AgentLogoutResponse>(),
      );
    });

    test('elicitation request and response map to their variants', () {
      final request = AgentRequestUnion.fromMethod('elicitation/create', {
        'mode': 'form',
        'message': 'Hi',
        'sessionId': 's',
        'requestedSchema': {'type': 'object'},
      });
      expect(request, isA<AgentCreateElicitationRequest>());
      expect(request.method, equals('elicitation/create'));
      expect(request.toJson()['mode'], equals('form'));

      final response = ClientResponseUnion.fromMethod('elicitation/create', {
        'action': 'decline',
      });
      expect(response, isA<ClientCreateElicitationResponse>());
      expect(
        (response as ClientCreateElicitationResponse).response,
        isA<ElicitationDeclineResponse>(),
      );
    });

    test('fromMethod distinguishes agent notifications by method name', () {
      expect(
        AgentNotificationUnion.fromMethod('elicitation/complete', {
          'elicitationId': 'elic-1',
        }),
        isA<AgentCompleteElicitationNotification>(),
      );
      expect(
        AgentNotificationUnion.fromMethod('session/update', {
          'sessionId': 's',
          'update': {
            'sessionUpdate': 'agent_message_chunk',
            'content': {'type': 'text', 'text': 'hi'},
          },
        }),
        isA<SessionAgentNotification>(),
      );
    });
  });

  group('Method inventory', () {
    test('agent methods cover the stable session lifecycle', () {
      expect(agentMethods['logout'], equals('logout'));
      expect(agentMethods['sessionClose'], equals('session/close'));
      expect(agentMethods['sessionDelete'], equals('session/delete'));
    });
  });

  // Referenced so the converter import is used even if assertions move.
  test('converters are const-constructible', () {
    expect(const CreateElicitationRequestConverter(), isNotNull);
    expect(const CreateElicitationResponseConverter(), isNotNull);
  });
}
