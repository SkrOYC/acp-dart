import 'dart:async';
import 'dart:convert';

import 'package:acp_dart/acp_dart.dart';
import 'package:test/test.dart';

void main() {
  test('agent dispatches session delete and close over NDJSON', () async {
    final peer = _Peer();
    AgentSideConnection((_) => _SupportedAgent(), peer.stream);

    peer.send({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'session/delete',
      'params': {'sessionId': 's1'},
    });
    expect(await peer.next(), {'jsonrpc': '2.0', 'id': 1, 'result': {}});
    peer.send({
      'jsonrpc': '2.0',
      'id': 2,
      'method': 'session/close',
      'params': {'sessionId': 's1'},
    });
    expect(await peer.next(), {'jsonrpc': '2.0', 'id': 2, 'result': {}});
    await peer.close();
  });

  test('agent dispatches logout over NDJSON', () async {
    final peer = _Peer();
    AgentSideConnection((_) => _SupportedAgent(), peer.stream);
    peer.send({'jsonrpc': '2.0', 'id': 1, 'method': 'logout', 'params': {}});
    expect(await peer.next(), {'jsonrpc': '2.0', 'id': 1, 'result': {}});
    await peer.close();
  });

  test(
    'client dispatches elicitation create and complete over NDJSON',
    () async {
      final peer = _Peer();
      ClientSideConnection((_) => _Client(), peer.stream);
      peer.send({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'elicitation/create',
        'params': {
          'mode': 'url',
          'sessionId': 's1',
          'elicitationId': 'e1',
          'url': 'https://example.test',
          'message': 'Continue?',
        },
      });
      expect(await peer.next(), {
        'jsonrpc': '2.0',
        'id': 1,
        'result': {
          'action': 'accept',
          'content': {'ok': true},
        },
      });
      peer.send({
        'jsonrpc': '2.0',
        'method': 'elicitation/complete',
        'params': {'elicitationId': 'e1'},
      });
      await Future<void>.delayed(Duration.zero);
      expect((_clientCompletion).isCompleted, isTrue);
      await peer.close();
    },
  );

  test(
    'agent elicitation methods send request and notification directions',
    () async {
      final peer = _Peer();
      final client = AgentSideConnection((_) => _Agent(), peer.stream);
      final response = client.createElicitation(
        CreateElicitationRequest(
          mode: 'url',
          sessionId: 's1',
          elicitationId: 'e1',
          url: 'https://example.test',
          message: 'Continue?',
        ),
      );
      final request = await peer.next();
      expect(request['method'], 'elicitation/create');
      peer.respond(request, {'action': 'decline'});
      expect((await response).action, 'decline');

      await client.completeElicitation(
        const CompleteElicitationNotification(elicitationId: 'e1'),
      );
      final notification = await peer.next();
      expect(notification['method'], 'elicitation/complete');
      expect(notification['params'], {'elicitationId': 'e1'});
      await peer.close();
    },
  );

  test('absent optional methods return JSON-RPC method-not-found', () async {
    final peer = _Peer();
    AgentSideConnection((_) => _Agent(), peer.stream);
    peer.send({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'session/delete',
      'params': {'sessionId': 's1'},
    });
    expect(await peer.next(), {
      'jsonrpc': '2.0',
      'id': 1,
      'error': {
        'code': -32601,
        'message': 'Method not found',
        'data': {'method': 'session/delete'},
      },
    });
    await peer.close();
  });

  test('stable session and logout wrappers use v1.5 method names', () async {
    final peer = _Peer();
    final client = ClientSideConnection((_) => _Client(), peer.stream);

    final listed = client.listSessions(ListSessionsRequest());
    final listRequest = await peer.next();
    expect(listRequest['method'], 'session/list');
    peer.respond(listRequest, {'sessions': []});
    expect((await listed).sessions, isEmpty);

    final resumed = client.resumeSession(
      ResumeSessionRequest(sessionId: 's1', cwd: '/workspace'),
    );
    final resumeRequest = await peer.next();
    expect(resumeRequest['method'], 'session/resume');
    peer.respond(resumeRequest, {});
    expect(await resumed, isA<ResumeSessionResponse>());

    final deleted = client.deleteSession(DeleteSessionRequest(sessionId: 's1'));
    final deleteRequest = await peer.next();
    expect(deleteRequest['method'], 'session/delete');
    peer.respond(deleteRequest, {});
    expect(await deleted, isA<DeleteSessionResponse>());

    final closed = client.closeSession(CloseSessionRequest(sessionId: 's1'));
    final closeRequest = await peer.next();
    expect(closeRequest['method'], 'session/close');
    peer.respond(closeRequest, {});
    expect(await closed, isA<CloseSessionResponse>());

    final loggedOut = client.logout(const LogoutRequest());
    final logoutRequest = await peer.next();
    expect(logoutRequest['method'], 'logout');
    peer.respond(logoutRequest, {});
    expect(await loggedOut, isA<LogoutResponse>());
    await peer.close();
  });

  test('v1.5 defaults retain legacy list and resume handlers', () async {
    final peer = _Peer();
    AgentSideConnection((_) => _LegacyV15Agent(), peer.stream);

    peer.send({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'session/list',
      'params': {},
    });
    expect(await peer.next(), {
      'jsonrpc': '2.0',
      'id': 1,
      'result': {'nextCursor': null, 'sessions': []},
    });

    peer.send({
      'jsonrpc': '2.0',
      'id': 2,
      'method': 'session/resume',
      'params': {'sessionId': 's1', 'cwd': '/workspace'},
    });
    expect(await peer.next(), {
      'jsonrpc': '2.0',
      'id': 2,
      'result': {'modes': null, 'models': null},
    });
    await peer.close();
  });

  test('typed wrappers accept typed in-memory stream responses', () async {
    final incoming = StreamController<Map<String, dynamic>>();
    final outgoing = StreamController<Map<String, dynamic>>();
    final connection = ClientSideConnection(
      (_) => _Client(),
      AcpStream(readable: incoming.stream, writable: outgoing.sink),
    );
    final request = outgoing.stream.first;
    final listed = connection.listSessions(ListSessionsRequest());
    final message = await request;
    incoming.add({
      'jsonrpc': '2.0',
      'id': message['id'],
      'result': ListSessionsResponse(sessions: []),
    });
    expect((await listed).sessions, isEmpty);
    await incoming.close();
    await outgoing.close();
  });

  test('experimental agent providers and NES requests dispatch', () async {
    final peer = _Peer();
    AgentSideConnection((_) => _ExperimentalAgent(), peer.stream);
    final requests = <(String, Map<String, dynamic>, Map<String, dynamic>)>[
      ('providers/list', {}, {'providers': []}),
      (
        'providers/set',
        {
          'providerId': 'p',
          'apiType': 'openai',
          'baseUrl': 'https://example.test',
        },
        {},
      ),
      ('providers/disable', {'providerId': 'p'}, {}),
      (
        'mcp/message',
        {'connectionId': 'c', 'method': 'tools/list', 'params': {}},
        {'tools': []},
      ),
      ('nes/start', {}, {'sessionId': 's1'}),
      (
        'nes/suggest',
        {
          'sessionId': 's1',
          'uri': 'file:///a.dart',
          'version': 1,
          'position': {'line': 0, 'character': 0},
          'triggerKind': 'automatic',
        },
        {'suggestions': []},
      ),
      ('nes/close', {'sessionId': 's1'}, {}),
    ];
    var id = 1;
    for (final (method, params, result) in requests) {
      peer.send({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      });
      expect(await peer.next(), {'jsonrpc': '2.0', 'id': id, 'result': result});
      id++;
    }
    peer.send({
      'jsonrpc': '2.0',
      'method': 'document/didOpen',
      'params': {
        'sessionId': 's1',
        'uri': 'file:///a.dart',
        'languageId': 'dart',
        'version': 1,
        'text': 'x',
      },
    });
    expect((await _documentOpened.future).uri, 'file:///a.dart');
    await peer.close();
  });

  test('experimental client MCP requests use client direction', () async {
    final peer = _Peer();
    ClientSideConnection((_) => _Client(), peer.stream);
    peer.send({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'mcp/connect',
      'params': {'serverId': 'srv'},
    });
    expect(await peer.next(), {
      'jsonrpc': '2.0',
      'id': 1,
      'result': {'connectionId': 'conn'},
    });
    peer.send({
      'jsonrpc': '2.0',
      'id': 2,
      'method': 'mcp/message',
      'params': {'connectionId': 'conn', 'method': 'tools/list'},
    });
    expect(await peer.next(), {
      'jsonrpc': '2.0',
      'id': 2,
      'result': {'tools': []},
    });
    peer.send({
      'jsonrpc': '2.0',
      'id': 3,
      'method': 'mcp/disconnect',
      'params': {'connectionId': 'conn'},
    });
    expect(await peer.next(), {'jsonrpc': '2.0', 'id': 3, 'result': {}});
    await peer.close();
  });

  test('experimental agent MCP wrappers send client method requests', () async {
    final peer = _Peer();
    final client = AgentSideConnection((_) => _Agent(), peer.stream);
    final connected = client.unstableConnectMcp(
      V15ConnectMcpRequest(serverId: 'srv'),
    );
    var request = await peer.next();
    expect(request['method'], 'mcp/connect');
    peer.respond(request, {'connectionId': 'conn'});
    expect((await connected).connectionId, 'conn');

    final message = client.unstableMessageMcp(
      V15MessageMcpRequest(connectionId: 'conn', method: 'tools/list'),
    );
    request = await peer.next();
    expect(request['method'], 'mcp/message');
    peer.respond(request, {'tools': []});
    expect((await message).value, {'tools': []});

    final disconnected = client.unstableDisconnectMcp(
      V15DisconnectMcpRequest(connectionId: 'conn'),
    );
    request = await peer.next();
    expect(request['method'], 'mcp/disconnect');
    peer.respond(request, {});
    expect(await disconnected, isA<V15DisconnectMcpResponse>());
    await peer.close();
  });

  test('MCP wrappers preserve arbitrary JSON responses', () async {
    final results = <Object?>[
      'ok',
      [1, true, null],
      null,
    ];
    for (final result in results) {
      final peer = _Peer();
      final client = AgentSideConnection((_) => _Agent(), peer.stream);
      final response = client.unstableMessageMcp(
        V15MessageMcpRequest(connectionId: 'conn', method: 'tools/list'),
      );
      final request = await peer.next();
      peer.respond(request, result);
      expect((await response).value, result);
      await peer.close();
    }
    for (final result in results) {
      final peer = _Peer();
      final agent = ClientSideConnection((_) => _Client(), peer.stream);
      final response = agent.unstableMessageMcp(
        V15MessageMcpRequest(connectionId: 'conn', method: 'tools/list'),
      );
      final request = await peer.next();
      peer.respond(request, result);
      expect((await response).value, result);
      await peer.close();
    }
  });

  test('MCP notifications work in both ACP directions over NDJSON', () async {
    final toAgentPeer = _Peer();
    final clientSide = ClientSideConnection(
      (_) => _Client(),
      toAgentPeer.stream,
    );
    await clientSide.unstableNotifyMcpMessage(
      V15MessageMcpNotification(
        connectionId: 'a',
        method: 'notifications/initialized',
      ),
    );
    expect((await toAgentPeer.next())['method'], 'mcp/message');
    toAgentPeer.send({
      'jsonrpc': '2.0',
      'method': 'mcp/message',
      'params': {'connectionId': 'a', 'method': 'notifications/changed'},
    });
    expect(
      (await _clientMcpNotification.future).method,
      'notifications/changed',
    );
    await toAgentPeer.close();

    final toClientPeer = _Peer();
    final agentSide = AgentSideConnection(
      (_) => _ExperimentalAgent(),
      toClientPeer.stream,
    );
    await agentSide.unstableNotifyMcpMessage(
      V15MessageMcpNotification(
        connectionId: 'b',
        method: 'notifications/initialized',
      ),
    );
    expect((await toClientPeer.next())['method'], 'mcp/message');
    toClientPeer.send({
      'jsonrpc': '2.0',
      'method': 'mcp/message',
      'params': {'connectionId': 'b', 'method': 'notifications/changed'},
    });
    expect(
      (await _agentMcpNotification.future).method,
      'notifications/changed',
    );
    await toClientPeer.close();
  });

  test(
    'experimental client wrappers use provider and notification methods',
    () async {
      final peer = _Peer();
      final agent = ClientSideConnection((_) => _Client(), peer.stream);
      final providers = agent.unstableListProviders(V15ListProvidersRequest());
      var request = await peer.next();
      expect(request['method'], 'providers/list');
      peer.respond(request, {'providers': []});
      expect((await providers).providers, isEmpty);

      final setProvider = agent.unstableSetProvider(
        V15SetProviderRequest(
          providerId: 'p',
          apiType: 'openai',
          baseUrl: 'https://example.test',
        ),
      );
      request = await peer.next();
      expect(request['method'], 'providers/set');
      peer.respond(request, {});
      await setProvider;

      final disableProvider = agent.unstableDisableProvider(
        V15DisableProviderRequest(providerId: 'p'),
      );
      request = await peer.next();
      expect(request['method'], 'providers/disable');
      peer.respond(request, {});
      await disableProvider;

      final message = agent.unstableMessageMcp(
        V15MessageMcpRequest(connectionId: 'c', method: 'tools/list'),
      );
      request = await peer.next();
      expect(request['method'], 'mcp/message');
      peer.respond(request, {'tools': []});
      expect((await message).value, {'tools': []});

      final started = agent.unstableStartNes(V15StartNesRequest());
      request = await peer.next();
      expect(request['method'], 'nes/start');
      peer.respond(request, {'sessionId': 's1'});
      expect((await started).sessionId, 's1');

      final suggestions = agent.unstableSuggestNes(
        V15SuggestNesRequest(
          sessionId: 's1',
          uri: 'file:///a.dart',
          version: 1,
          position: V15Position(line: 0, character: 0),
          triggerKind: 'automatic',
        ),
      );
      request = await peer.next();
      expect(request['method'], 'nes/suggest');
      peer.respond(request, {'suggestions': []});
      expect((await suggestions).suggestions, isEmpty);

      final closed = agent.unstableCloseNes(
        V15CloseNesRequest(sessionId: 's1'),
      );
      request = await peer.next();
      expect(request['method'], 'nes/close');
      peer.respond(request, {});
      await closed;

      await agent.unstableDidOpenDocument(
        V15DidOpenDocumentNotification(
          sessionId: 's1',
          uri: 'file:///a.dart',
          languageId: 'dart',
          version: 1,
          text: 'x',
        ),
      );
      expect((await peer.next())['method'], 'document/didOpen');
      await agent.unstableDidChangeDocument(
        V15DidChangeDocumentNotification(
          sessionId: 's1',
          uri: 'file:///a.dart',
          version: 2,
          contentChanges: [V15TextDocumentContentChangeEvent(text: 'y')],
        ),
      );
      expect((await peer.next())['method'], 'document/didChange');
      await agent.unstableDidCloseDocument(
        V15DidCloseDocumentNotification(sessionId: 's1', uri: 'file:///a.dart'),
      );
      expect((await peer.next())['method'], 'document/didClose');
      await agent.unstableDidSaveDocument(
        V15DidSaveDocumentNotification(sessionId: 's1', uri: 'file:///a.dart'),
      );
      expect((await peer.next())['method'], 'document/didSave');
      await agent.unstableDidFocusDocument(
        V15DidFocusDocumentNotification(
          sessionId: 's1',
          uri: 'file:///a.dart',
          version: 2,
          position: V15Position(line: 0, character: 1),
          visibleRange: V15Range(
            start: V15Position(line: 0, character: 0),
            end: V15Position(line: 1, character: 0),
          ),
        ),
      );
      expect((await peer.next())['method'], 'document/didFocus');
      await agent.unstableAcceptNes(
        V15AcceptNesNotification(sessionId: 's1', id: 'n1'),
      );
      expect((await peer.next())['method'], 'nes/accept');
      await agent.unstableRejectNes(
        V15RejectNesNotification(sessionId: 's1', id: 'n1', reason: 'stale'),
      );
      expect((await peer.next())['method'], 'nes/reject');
      await peer.close();
    },
  );
}

final _clientCompletion = Completer<void>();
final _documentOpened = Completer<V15DidOpenDocumentNotification>();
final _clientMcpNotification = Completer<V15MessageMcpNotification>();
final _agentMcpNotification = Completer<V15MessageMcpNotification>();

class _Agent extends Agent {
  @override
  Future<InitializeResponse> initialize(InitializeRequest params) async =>
      InitializeResponse(protocolVersion: 1);
  @override
  Future<NewSessionResponse> newSession(NewSessionRequest params) async =>
      NewSessionResponse(sessionId: 's');
  @override
  Future<LoadSessionResponse>? loadSession(LoadSessionRequest params) async =>
      LoadSessionResponse();
  @override
  Future<PromptResponse> prompt(PromptRequest params) async =>
      PromptResponse(stopReason: StopReason.endTurn);
  @override
  Future<void> cancel(CancelNotification params) async {}
  @override
  Future<Map<String, dynamic>>? extMethod(
    String method,
    Map<String, dynamic> params,
  ) => null;
  @override
  Future<void>? extNotification(
    String method,
    Map<String, dynamic> params,
  ) async {}
  @override
  Future<AuthenticateResponse?>? authenticate(
    AuthenticateRequest params,
  ) async => null;
  @override
  Future<SetSessionModeResponse?>? setSessionMode(
    SetSessionModeRequest params,
  ) async => null;
  @override
  Future<SetSessionModelResponse?>? setSessionModel(
    SetSessionModelRequest params,
  ) async => null;
}

class _SupportedAgent extends _Agent with AgentV15Handler {
  @override
  Future<DeleteSessionResponse>? deleteSession(
    DeleteSessionRequest params,
  ) async => DeleteSessionResponse();
  @override
  Future<CloseSessionResponse>? closeSession(
    CloseSessionRequest params,
  ) async => CloseSessionResponse();
  @override
  Future<LogoutResponse>? logout(LogoutRequest params) async =>
      LogoutResponse();
}

class _LegacyV15Agent extends _Agent with AgentV15Handler {
  @override
  Future<ListSessionsResponse>? unstableListSessions(
    ListSessionsRequest params,
  ) async => ListSessionsResponse(sessions: []);

  @override
  Future<ResumeSessionResponse>? unstableResumeSession(
    ResumeSessionRequest params,
  ) async => ResumeSessionResponse();
}

class _ExperimentalAgent extends _SupportedAgent {
  @override
  Future<V15ListProvidersResponse>? unstableListProviders(
    V15ListProvidersRequest params,
  ) async => V15ListProvidersResponse(providers: []);
  @override
  Future<V15SetProviderResponse>? unstableSetProvider(
    V15SetProviderRequest params,
  ) async => V15SetProviderResponse();
  @override
  Future<V15DisableProviderResponse>? unstableDisableProvider(
    V15DisableProviderRequest params,
  ) async => V15DisableProviderResponse();
  @override
  Future<V15MessageMcpResponse>? unstableMessageMcp(
    V15MessageMcpRequest params,
  ) async => const V15MessageMcpResponse({'tools': []});
  @override
  Future<V15StartNesResponse>? unstableStartNes(
    V15StartNesRequest params,
  ) async => V15StartNesResponse(sessionId: 's1');
  @override
  Future<V15SuggestNesResponse>? unstableSuggestNes(
    V15SuggestNesRequest params,
  ) async => V15SuggestNesResponse(suggestions: []);
  @override
  Future<V15CloseNesResponse>? unstableCloseNes(
    V15CloseNesRequest params,
  ) async => V15CloseNesResponse();
  @override
  Future<void> unstableDidOpenDocument(
    V15DidOpenDocumentNotification params,
  ) async => _documentOpened.complete(params);
  @override
  Future<void> unstableHandleMcpNotification(
    V15MessageMcpNotification params,
  ) async => _agentMcpNotification.complete(params);
}

class _Client extends Client with ClientV15Handler {
  @override
  Future<RequestPermissionResponse> requestPermission(
    RequestPermissionRequest params,
  ) async => throw UnimplementedError();
  @override
  Future<void> sessionUpdate(SessionNotification params) async {}
  @override
  Future<Map<String, dynamic>>? extMethod(
    String method,
    Map<String, dynamic> params,
  ) => null;
  @override
  Future<void>? extNotification(
    String method,
    Map<String, dynamic> params,
  ) async {}
  @override
  Future<WriteTextFileResponse>? writeTextFile(WriteTextFileRequest params) =>
      null;
  @override
  Future<ReadTextFileResponse>? readTextFile(ReadTextFileRequest params) =>
      null;
  @override
  Future<CreateTerminalResponse>? createTerminal(
    CreateTerminalRequest params,
  ) => null;
  @override
  Future<TerminalOutputResponse>? terminalOutput(
    TerminalOutputRequest params,
  ) => null;
  @override
  Future<ReleaseTerminalResponse?>? releaseTerminal(
    ReleaseTerminalRequest params,
  ) => null;
  @override
  Future<WaitForTerminalExitResponse>? waitForTerminalExit(
    WaitForTerminalExitRequest params,
  ) => null;
  @override
  Future<KillTerminalCommandResponse?>? killTerminal(
    KillTerminalCommandRequest params,
  ) => null;
  @override
  Future<CreateElicitationResponse> createElicitation(
    CreateElicitationRequest params,
  ) async => CreateElicitationResponse.accept(content: {'ok': true});
  @override
  Future<void> completeElicitation(
    CompleteElicitationNotification params,
  ) async => _clientCompletion.complete();
  @override
  Future<V15ConnectMcpResponse>? unstableConnectMcp(
    V15ConnectMcpRequest params,
  ) async => V15ConnectMcpResponse(connectionId: 'conn');
  @override
  Future<V15MessageMcpResponse>? unstableMessageMcp(
    V15MessageMcpRequest params,
  ) async => const V15MessageMcpResponse({'tools': []});
  @override
  Future<V15DisconnectMcpResponse>? unstableDisconnectMcp(
    V15DisconnectMcpRequest params,
  ) async => V15DisconnectMcpResponse();
  @override
  Future<void> unstableHandleMcpNotification(
    V15MessageMcpNotification params,
  ) async => _clientMcpNotification.complete(params);
}

class _Peer {
  _Peer() {
    subscription;
  }

  final _toServer = StreamController<List<int>>();
  final _fromServer = StreamController<List<int>>();
  final _received = <Map<String, dynamic>>[];
  final _waiters = <Completer<Map<String, dynamic>>>[];
  late final AcpStream stream = ndJsonStream(
    _toServer.stream,
    _fromServer.sink,
  );
  late final StreamSubscription<List<int>> subscription = _fromServer.stream
      .listen((bytes) {
        for (final line
            in utf8
                .decode(bytes)
                .split('\n')
                .where((line) => line.isNotEmpty)) {
          final message = jsonDecode(line) as Map<String, dynamic>;
          if (_waiters.isEmpty) {
            _received.add(message);
          } else {
            _waiters.removeAt(0).complete(message);
          }
        }
      });
  void send(Map<String, dynamic> message) =>
      _toServer.add(utf8.encode('${jsonEncode(message)}\n'));
  void respond(Map<String, dynamic> request, Object? result) =>
      send({'jsonrpc': '2.0', 'id': request['id'], 'result': result});
  Future<Map<String, dynamic>> next() {
    if (_received.isNotEmpty) return Future.value(_received.removeAt(0));
    final waiter = Completer<Map<String, dynamic>>();
    _waiters.add(waiter);
    return waiter.future.timeout(const Duration(seconds: 2));
  }

  Future<void> close() async {
    await _toServer.close();
    await subscription.cancel();
    await _fromServer.close();
  }
}
