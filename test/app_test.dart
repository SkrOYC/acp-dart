import 'dart:async';

import 'package:acp_dart/src/acp.dart';
import 'package:acp_dart/src/app.dart';
import 'package:acp_dart/src/schema.dart';
import 'package:acp_dart/src/stream.dart';
import 'package:test/test.dart';

void main() {
  test('client connectWith calls agent handlers over paired streams', () async {
    final clientToAgent = StreamController<Map<String, dynamic>>();
    final agentToClient = StreamController<Map<String, dynamic>>();
    final noticeReceived = Completer<dynamic>();
    final agent = AgentApp()
      ..onRequest('test/echo', (params, context) async => params)
      ..onNotificationParsed<Map<String, dynamic>>(
        method: 'test/notice',
        parse: (value) => Map<String, dynamic>.from(value as Map),
        handler: (params, context) async => noticeReceived.complete(params),
      );

    agent.connect(
      AcpStream(readable: clientToAgent.stream, writable: agentToClient.sink),
    );
    final clientStream = AcpStream(
      readable: agentToClient.stream,
      writable: clientToAgent.sink,
    );

    final result = await ClientApp().connectWith(clientStream, (context) async {
      final response = await context.request<Map<String, dynamic>>(
        'test/echo',
        params: {'value': 42},
      );
      await context.notify('test/notice', {'seen': true});
      return response;
    });

    expect(result, {'value': 42});
    expect(await noticeReceived.future, {'seen': true});
    await clientToAgent.close();
    await agentToClient.close();
  });

  test('agent connectWith calls registered client request handlers', () async {
    final clientToAgent = StreamController<Map<String, dynamic>>();
    final agentToClient = StreamController<Map<String, dynamic>>();
    final clientStream = AcpStream(
      readable: agentToClient.stream,
      writable: clientToAgent.sink,
    );
    final agentStream = AcpStream(
      readable: clientToAgent.stream,
      writable: agentToClient.sink,
    );
    final clientContext = ClientApp()
        .onRequest('test/reverse', (params, context) async => {'reply': params})
        .connect(clientStream);

    final result = await AgentApp().connectWith(agentStream, (context) {
      return context.request<Map<String, dynamic>>(
        'test/reverse',
        params: 'hello',
      );
    });

    expect(result, {'reply': 'hello'});
    await clientToAgent.close();
    await agentToClient.close();
    expect(clientContext, isNotNull);
  });

  test(
    'parsed handlers map invalid params and internal errors correctly',
    () async {
      final pair = _streamPair();
      final agentConnection = AgentApp()
          .onRequestParsed<NewSessionRequest, Map<String, dynamic>>(
            method: 'test/parsed',
            parse: (value) =>
                NewSessionRequest.fromJson(value as Map<String, dynamic>),
            handler: (request, context) async => {'cwd': request.cwd},
          )
          .onRequest('test/internal', (params, context) async {
            throw StateError('handler failed');
          })
          .connect(pair.$1);
      final clientConnection = ClientApp().connect(pair.$2);

      expect(
        await clientConnection.request<Map<String, dynamic>>(
          'test/parsed',
          params: {'cwd': '/workspace', 'mcpServers': []},
        ),
        {'cwd': '/workspace'},
      );
      await expectLater(
        clientConnection.request<dynamic>('test/parsed', params: 'invalid'),
        throwsA(
          isA<RequestError>().having((error) => error.code, 'code', -32602),
        ),
      );
      await expectLater(
        clientConnection.request<dynamic>('test/internal', params: {}),
        throwsA(
          isA<RequestError>().having((error) => error.code, 'code', -32603),
        ),
      );

      agentConnection.close();
      clientConnection.close();
      await pair.$3.close();
      await pair.$4.close();
    },
  );

  test('client session builder starts session and receives updates', () async {
    final clientToAgent = StreamController<Map<String, dynamic>>();
    final agentToClient = StreamController<Map<String, dynamic>>();
    Map<String, dynamic>? newSessionParams;
    Map<String, dynamic>? promptParams;
    final updatesDone = Completer<void>();
    final agent = AgentApp()
      ..onRequest(agentMethods['sessionNew']!, (params, context) async {
        newSessionParams = params as Map<String, dynamic>;
        return NewSessionResponse(sessionId: 's1');
      })
      ..onRequest(agentMethods['sessionPrompt']!, (params, context) async {
        promptParams = params as Map<String, dynamic>;
        await context.notify(clientMethods['sessionUpdate']!, {
          'sessionId': 's1',
          'update': {'sessionUpdate': 'session_info_update', 'title': 'Hello'},
        });
        return PromptResponse(stopReason: StopReason.endTurn);
      });
    agent.connect(
      AcpStream(readable: clientToAgent.stream, writable: agentToClient.sink),
    );
    final clientStream = AcpStream(
      readable: agentToClient.stream,
      writable: clientToAgent.sink,
    );

    final session = await ClientApp().connectWith(clientStream, (
      context,
    ) async {
      final activeSession = await context
          .buildSession('/workspace')
          .withAdditionalDirectories(['/workspace/shared'])
          .withMcpServer(
            StdioMcpServer(args: [], command: 'mcp', env: [], name: 'local'),
          )
          .start();
      final update = activeSession.updates.first;
      activeSession.updates.listen((_) {}, onDone: updatesDone.complete);
      final response = await activeSession.prompt([
        TextContentBlock(text: 'hello'),
        ResourceLinkContentBlock(name: 'README', uri: 'file:///README.md'),
      ]);
      final sessionUpdate = await activeSession.nextUpdate();
      final stop = await activeSession.nextUpdate();
      return (activeSession, response, sessionUpdate, stop, await update);
    });

    expect(session.$1.sessionId, 's1');
    expect(session.$2.stopReason, StopReason.endTurn);
    expect(promptParams?['sessionId'], 's1');
    expect(promptParams?['prompt'], [
      {'type': 'text', 'text': 'hello'},
      {'type': 'resource_link', 'name': 'README', 'uri': 'file:///README.md'},
    ]);
    expect(newSessionParams?['additionalDirectories'], ['/workspace/shared']);
    expect(newSessionParams?['mcpServers'], [
      {'command': 'mcp', 'args': [], 'env': [], 'name': 'local'},
    ]);
    expect(session.$3.kind, 'session_update');
    expect(session.$3, isA<ActiveSessionUpdate>());
    expect(
      (session.$3 as ActiveSessionUpdate).update,
      isA<SessionInfoUpdate>(),
    );
    expect(
      ((session.$3 as ActiveSessionUpdate).update as SessionInfoUpdate).title,
      'Hello',
    );
    expect(session.$4.kind, 'stop');
    expect(session.$4, isA<ActiveSessionStop>());
    expect((session.$4 as ActiveSessionStop).stopReason, StopReason.endTurn);
    expect(session.$5.update, isA<SessionInfoUpdate>());
    await session.$1.dispose();
    await session.$1.dispose();
    await updatesDone.future;
    expect(newSessionParams?['cwd'], '/workspace');
    await clientToAgent.close();
    await agentToClient.close();
  });

  test(
    'session builder withSession disposes update routing on completion',
    () async {
      final pair = _streamPair();
      final agentConnection = AgentApp()
          .onRequest(agentMethods['sessionNew']!, (params, context) async {
            return NewSessionResponse(sessionId: 'scoped-session');
          })
          .connect(pair.$1);
      final clientConnection = ClientApp().connect(pair.$2);
      final updatesDone = Completer<void>();
      ActiveSession? activeSession;

      final sessionId = await clientConnection
          .buildSession('/workspace')
          .withSession((session) async {
            activeSession = session;
            session.updates.listen((_) {}, onDone: updatesDone.complete);
            return session.sessionId;
          });

      expect(sessionId, 'scoped-session');
      await updatesDone.future;
      await activeSession!.dispose();

      final failedSessionDone = Completer<void>();
      await expectLater(
        clientConnection.buildSession('/workspace').withSession((session) {
          session.updates.listen((_) {}, onDone: failedSessionDone.complete);
          throw StateError('operation failed');
        }),
        throwsA(isA<StateError>()),
      );
      await failedSessionDone.future;

      clientConnection.close();
      agentConnection.close();
      await pair.$3.close();
      await pair.$4.close();
    },
  );

  test('sessions with the same ID stay scoped to their connection', () async {
    final clientApp = ClientApp();
    final first = _openPair(clientApp);
    final second = _openPair(clientApp);
    final firstSession = await first.client.buildSession('/first').start();
    final secondSession = await second.client.buildSession('/second').start();
    expect(firstSession.sessionId, secondSession.sessionId);

    final firstUpdates = <SessionNotification>[];
    final secondUpdates = <SessionNotification>[];
    final firstSubscription = firstSession.updates.listen(firstUpdates.add);
    final secondSubscription = secondSession.updates.listen(secondUpdates.add);

    await first.agent.notify(clientMethods['sessionUpdate']!, {
      'sessionId': 'same-session',
      'update': {'sessionUpdate': 'session_info_update', 'title': 'First'},
    });
    await Future<void>.delayed(Duration.zero);

    expect(firstUpdates, hasLength(1));
    expect(secondUpdates, isEmpty);

    await firstSession.dispose();
    await first.agent.notify(clientMethods['sessionUpdate']!, {
      'sessionId': 'same-session',
      'update': {
        'sessionUpdate': 'session_info_update',
        'title': 'After dispose',
      },
    });
    await Future<void>.delayed(Duration.zero);
    expect(firstUpdates, hasLength(1));

    await firstSubscription.cancel();
    await secondSubscription.cancel();
    await secondSession.dispose();
    await first.close();
    await second.close();
  });

  test('failed connect handler closes the connection with its error', () async {
    final pair = _streamPair();
    final context = AgentApp()
        .onConnect((_) async {
          await Future<void>.delayed(Duration.zero);
          throw StateError('connect failed');
        })
        .connect(pair.$1);

    await expectLater(context.closed, completes);
    expect(context.isClosed, isTrue);
    expect(context.closeReason, isA<StateError>());
  });

  test(
    'connectWith closes its connection after the callback settles',
    () async {
      final pair = _streamPair();
      final agentConnection = AgentApp().connect(pair.$1);
      final context = await ClientApp().connectWith(
        pair.$2,
        (context) => context,
      );

      expect(context.isClosed, isTrue);
      await context.closed;
      agentConnection.close();
      await pair.$3.close();
      await pair.$4.close();
    },
  );

  test('request context exposes its ID and matching cancellation', () async {
    final pair = _streamPair();
    final requestContext = Completer<AppContext>();
    final agent = AgentApp()
      ..onRequest('test/cancellable', (params, context) async {
        requestContext.complete(context);
        await context.cancelled!;
        return 'cancelled';
      });
    final agentConnection = agent.connect(pair.$1);
    final clientConnection = ClientApp().connect(pair.$2);
    final pending = clientConnection.request<String>(
      'test/cancellable',
      params: {},
    );
    final handlerContext = await requestContext.future;

    expect(handlerContext.requestId, 0);
    await clientConnection.notify(protocolMethods['cancelRequest']!, {
      'requestId': 0,
    });

    await handlerContext.cancelled!;
    expect(handlerContext.isCancelled, isTrue);
    expect(handlerContext.cancelReason, isA<RequestError>());
    await expectLater(pending, completion('cancelled'));
    agentConnection.close();
    clientConnection.close();
    await pair.$3.close();
    await pair.$4.close();
  });

  test(
    'outbound request cancellation notifies the matching peer request',
    () async {
      final pair = _streamPair();
      final remoteRequest = Completer<AppContext>();
      final agentConnection = AgentApp()
          .onRequest('test/cancellable', (params, context) async {
            remoteRequest.complete(context);
            await context.cancelled!;
            return 'cancelled';
          })
          .connect(pair.$1);
      final clientConnection = ClientApp().connect(pair.$2);
      final cancellation = Completer<void>();
      final pending = clientConnection.request<String>(
        'test/cancellable',
        params: {},
        cancellation: cancellation.future,
      );
      final remoteContext = await remoteRequest.future;
      expect(remoteContext.requestId, 0);
      cancellation.complete();

      expect(await pending, 'cancelled');
      expect(remoteContext.isCancelled, isTrue);
      agentConnection.close();
      clientConnection.close();
      await pair.$3.close();
      await pair.$4.close();
    },
  );

  test(
    'active session update stream closes when its peer reaches EOF',
    () async {
      final pair = _streamPair();
      final agentConnection = AgentApp()
          .onRequest(agentMethods['sessionNew']!, (params, context) async {
            return NewSessionResponse(sessionId: 'eof-session');
          })
          .connect(pair.$1);
      final clientConnection = ClientApp().connect(pair.$2);
      final session = await clientConnection.buildSession('/workspace').start();
      final updatesDone = Completer<void>();
      session.updates.listen((_) {}, onDone: updatesDone.complete);

      await pair.$4.close();
      await updatesDone.future.timeout(const Duration(seconds: 1));

      expect(clientConnection.isClosed, isTrue);
      await session.dispose();
      agentConnection.close();
      await pair.$3.close();
    },
  );
}

({AppContext agent, AppContext client, Future<void> Function() close})
_openPair(ClientApp clientApp) {
  final pair = _streamPair();
  final agent = AgentApp()
    ..onRequest(agentMethods['sessionNew']!, (_, _) async {
      return NewSessionResponse(sessionId: 'same-session');
    });
  final agentContext = agent.connect(pair.$1);
  final clientContext = clientApp.connect(pair.$2);
  return (
    agent: agentContext,
    client: clientContext,
    close: () async {
      agentContext.close();
      clientContext.close();
      await pair.$3.close();
      await pair.$4.close();
    },
  );
}

(
  AcpStream,
  AcpStream,
  StreamController<Map<String, dynamic>>,
  StreamController<Map<String, dynamic>>,
)
_streamPair() {
  final clientToAgent = StreamController<Map<String, dynamic>>();
  final agentToClient = StreamController<Map<String, dynamic>>();
  return (
    AcpStream(readable: clientToAgent.stream, writable: agentToClient.sink),
    AcpStream(readable: agentToClient.stream, writable: clientToAgent.sink),
    clientToAgent,
    agentToClient,
  );
}
