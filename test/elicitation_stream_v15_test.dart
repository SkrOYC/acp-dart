import 'dart:async';

import 'package:acp_dart/src/acp.dart';
import 'package:acp_dart/src/schema_v15_client.dart';
import 'package:acp_dart/src/stream.dart';
import 'package:test/test.dart';

void main() {
  test(
    'elicitation response and completion notification cross connected streams',
    () async {
      final agentToClient = StreamController<Map<String, dynamic>>();
      final clientToAgent = StreamController<Map<String, dynamic>>();
      final completed = Completer<CompleteElicitationNotification>();

      final client = Connection(
        (method, params) async {
          expect(method, 'elicitation/create');
          final request = Map<String, dynamic>.from(params as Map);
          expect(request['mode'], 'form');
          expect(request['message'], 'Enter your name');
          return CreateElicitationResponse.accept(
            content: {'name': 'Ada'},
            meta: {'handled': true},
          ).toJson();
        },
        (method, params) async {
          expect(method, 'elicitation/complete');
          completed.complete(
            CompleteElicitationNotification.fromJson(
              Map<String, dynamic>.from(params as Map),
            ),
          );
        },
        AcpStream(readable: agentToClient.stream, writable: clientToAgent.sink),
      );

      final agent = Connection(
        (method, params) async => throw RequestError.methodNotFound(method),
        (method, params) async {},
        AcpStream(readable: clientToAgent.stream, writable: agentToClient.sink),
      );

      final responseJson = await agent
          .sendRequest<Map<String, dynamic>>('elicitation/create', {
            'sessionId': 'session-1',
            'mode': 'form',
            'message': 'Enter your name',
            'requestedSchema': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
              },
            },
          })
          .timeout(const Duration(seconds: 2));
      final response = CreateElicitationResponse.fromJson(responseJson);
      expect(response.action, 'accept');
      expect(response.content, {'name': 'Ada'});
      expect(response.meta, {'handled': true});

      await agent.sendNotification(
        'elicitation/complete',
        const CompleteElicitationNotification(elicitationId: 'elic-1').toJson(),
      );
      expect(
        (await completed.future.timeout(
          const Duration(seconds: 2),
        )).elicitationId,
        'elic-1',
      );

      await agentToClient.close();
      await clientToAgent.close();
      expect(client, isA<Connection>());
    },
  );
}
