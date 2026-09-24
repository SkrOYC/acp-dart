import 'dart:async';
import 'dart:convert';

import 'package:acp_dart/acp_dart.dart';
import 'package:acp_dart/src/acp.dart'
    show AgentV15Handler, ClientV15Handler, LogoutRequest, LogoutResponse;
import 'package:acp_dart/src/schema_v15_client.dart';
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
}

final _clientCompletion = Completer<void>();

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
  void respond(Map<String, dynamic> request, Map<String, dynamic> result) =>
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
