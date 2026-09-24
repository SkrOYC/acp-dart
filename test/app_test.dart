import 'dart:async';

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
      ..onNotification('test/notice', (params, context) async {
        noticeReceived.complete(params);
      });

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
        {'value': 42},
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
      return context.request<Map<String, dynamic>>('test/reverse', 'hello');
    });

    expect(result, {'reply': 'hello'});
    await clientToAgent.close();
    await agentToClient.close();
    expect(clientContext, isNotNull);
  });

  test('client session builder starts session and receives updates', () async {
    final clientToAgent = StreamController<Map<String, dynamic>>();
    final agentToClient = StreamController<Map<String, dynamic>>();
    Map<String, dynamic>? newSessionParams;
    Map<String, dynamic>? promptParams;
    final agentContext = Completer<AppContext>();
    final agent = AgentApp()
      ..onConnect((context) => agentContext.complete(context))
      ..onRequest(agentMethods['sessionNew']!, (params, context) async {
        newSessionParams = params as Map<String, dynamic>;
        return NewSessionResponse(sessionId: 's1');
      })
      ..onRequest(agentMethods['sessionPrompt']!, (params, context) async {
        promptParams = params as Map<String, dynamic>;
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
      final activeSession = await context.buildSession('/workspace').start();
      final update = activeSession.updates.first;
      final response = await activeSession.prompt('hello');
      await (await agentContext.future).notify(
        clientMethods['sessionUpdate']!,
        {
          'sessionId': 's1',
          'update': {'sessionUpdate': 'session_info_update', 'title': 'Hello'},
        },
      );
      return (activeSession, response, await update);
    });

    expect(session.$1.sessionId, 's1');
    expect(session.$2.stopReason, StopReason.endTurn);
    expect(promptParams?['sessionId'], 's1');
    expect(promptParams?['prompt'], [
      {'type': 'text', 'text': 'hello'},
    ]);
    expect(session.$3.update, isA<SessionInfoUpdate>());
    expect((session.$3.update as SessionInfoUpdate).title, 'Hello');
    await session.$1.dispose();
    expect(newSessionParams?['cwd'], '/workspace');
    await clientToAgent.close();
    await agentToClient.close();
  });
}
