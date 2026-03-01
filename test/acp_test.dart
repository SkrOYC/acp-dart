import 'dart:async';

import 'package:acp_dart/src/acp.dart';
import 'package:acp_dart/src/schema.dart';
import 'package:acp_dart/src/stream.dart';
import 'package:test/test.dart';

void main() {
  group('RequestError', () {
    test('parseError creates correct error', () {
      final error = RequestError.parseError({'some': 'data'});

      expect(error.code, -32700);
      expect(error.message, 'Parse error');
      expect(error.data, {'some': 'data'});
    });

    test('invalidRequest creates correct error', () {
      final error = RequestError.invalidRequest();

      expect(error.code, -32600);
      expect(error.message, 'Invalid request');
      expect(error.data, isNull);
    });

    test('methodNotFound creates correct error', () {
      final error = RequestError.methodNotFound('unknown.method');

      expect(error.code, -32601);
      expect(error.message, 'Method not found');
      expect(error.data, {'method': 'unknown.method'});
    });

    test('invalidParams creates correct error', () {
      final error = RequestError.invalidParams({'param': 'invalid'});

      expect(error.code, -32602);
      expect(error.message, 'Invalid params');
      expect(error.data, {'param': 'invalid'});
    });

    test('internalError creates correct error', () {
      final error = RequestError.internalError();

      expect(error.code, -32603);
      expect(error.message, 'Internal error');
      expect(error.data, isNull);
    });

    test('authRequired creates correct error', () {
      final error = RequestError.authRequired({'token': 'required'});

      expect(error.code, -32000);
      expect(error.message, 'Authentication required');
      expect(error.data, {'token': 'required'});
    });

    test('resourceNotFound creates correct error', () {
      final error = RequestError.resourceNotFound('/path/to/file');

      expect(error.code, -32002);
      expect(error.message, 'Resource not found');
      expect(error.data, {'uri': '/path/to/file'});
    });

    test('resourceNotFound without uri creates correct error', () {
      final error = RequestError.resourceNotFound();

      expect(error.code, -32002);
      expect(error.message, 'Resource not found');
      expect(error.data, isNull);
    });

    test('requestCancelled creates correct error', () {
      final error = RequestError.requestCancelled({'requestId': 9});

      expect(error.code, -32800);
      expect(error.message, 'Cancelled');
      expect(error.data, {'requestId': 9});
    });

    test('toErrorResponse converts correctly', () {
      final error = RequestError.methodNotFound('test.method');
      final response = error.toErrorResponse();

      expect(response.code, -32601);
      expect(response.message, 'Method not found');
      expect(response.data, {'method': 'test.method'});
    });

    test('toResult converts correctly', () {
      final error = RequestError.invalidParams({'field': 'required'});
      final result = error.toResult();

      expect(result, {
        'error': {
          'code': -32602,
          'message': 'Invalid params',
          'data': {'field': 'required'},
        },
      });
    });

    test('ErrorResponse serialization works', () {
      final response = ErrorResponse(
        code: -32601,
        message: 'Method not found',
        data: {'method': 'test'},
      );

      final json = response.toJson();
      final decoded = ErrorResponse.fromJson(json);

      expect(decoded.code, response.code);
      expect(decoded.message, response.message);
      expect(decoded.data, response.data);
    });

    test('ErrorResponse without data serializes correctly', () {
      final response = ErrorResponse(code: -32603, message: 'Internal error');

      final json = response.toJson();
      expect(json, {'code': -32603, 'message': 'Internal error'});

      final decoded = ErrorResponse.fromJson(json);
      expect(decoded.data, isNull);
    });
  });

  group('Connection', () {
    test('sendRequest sends correct message and receives response', () async {
      final readableController = StreamController<Map<String, dynamic>>();
      final writableController = StreamController<Map<String, dynamic>>();
      final acpStream = AcpStream(
        readable: readableController.stream,
        writable: writableController.sink,
      );

      final connection = Connection(
        (method, params) async => 'response to $method',
        (method, params) async => print('notification: $method'),
        acpStream,
      );

      // Send a request
      final future = connection.sendRequest<String>('test.method', {
        'param': 'value',
      });

      // Simulate receiving the request and sending response
      await Future.delayed(Duration.zero); // Let the message be sent

      // Check that a message was sent
      final sentMessage = await writableController.stream.first;
      expect(sentMessage, {
        'jsonrpc': '2.0',
        'id': 0,
        'method': 'test.method',
        'params': {'param': 'value'},
      });

      // Simulate response
      readableController.add({
        'jsonrpc': '2.0',
        'id': 0,
        'result': 'test response',
      });

      final result = await future;
      expect(result, 'test response');

      await readableController.close();
      await writableController.close();
    });

    test('sendNotification sends correct message', () async {
      final readableController = StreamController<Map<String, dynamic>>();
      final writableController = StreamController<Map<String, dynamic>>();
      final acpStream = AcpStream(
        readable: readableController.stream,
        writable: writableController.sink,
      );

      final connection = Connection(
        (method, params) async => 'response to $method',
        (method, params) async => print('notification: $method'),
        acpStream,
      );

      connection.sendNotification('test.notification', {'param': 'value'});

      await Future.delayed(Duration.zero); // Let the message be sent

      final sentMessage = await writableController.stream.first;
      expect(sentMessage, {
        'jsonrpc': '2.0',
        'method': 'test.notification',
        'params': {'param': 'value'},
      });

      await readableController.close();
      await writableController.close();
    });

    test(
      'sendCancelRequestNotification sends protocol cancellation message',
      () async {
        final readableController = StreamController<Map<String, dynamic>>();
        final writableController = StreamController<Map<String, dynamic>>();
        final acpStream = AcpStream(
          readable: readableController.stream,
          writable: writableController.sink,
        );

        final connection = Connection(
          (method, params) async => 'response to $method',
          (method, params) async {},
          acpStream,
        );

        await connection.sendCancelRequestNotification(
          CancelRequestNotification(requestId: 5, meta: {'reason': 'timeout'}),
        );
        await Future.delayed(Duration.zero);

        final sentMessage = await writableController.stream.first;
        expect(sentMessage['method'], equals(r'$/cancel_request'));
        expect(sentMessage['params'], {
          'requestId': 5,
          '_meta': {'reason': 'timeout'},
        });

        await readableController.close();
        await writableController.close();
      },
    );

    test(
      'cancelPendingRequest rejects local future and ignores late response',
      () async {
        final readableController = StreamController<Map<String, dynamic>>();
        final writableController = StreamController<Map<String, dynamic>>();
        final acpStream = AcpStream(
          readable: readableController.stream,
          writable: writableController.sink,
        );

        final connection = Connection(
          (method, params) async => 'response to $method',
          (method, params) async {},
          acpStream,
        );

        final sentMessages = <Map<String, dynamic>>[];
        final subscription = writableController.stream.listen(sentMessages.add);

        final responseFuture = connection.sendRequest<String>('long.running');
        final responseErrorExpectation = expectLater(
          responseFuture,
          throwsA(
            predicate(
              (error) =>
                  error is Map<String, dynamic> &&
                  error['code'] == -32800 &&
                  error['message'] == 'Cancelled',
            ),
          ),
        );
        await Future.delayed(Duration.zero);

        final requestMessage = sentMessages.first;
        final requestId = requestMessage['id'];
        expect(requestMessage['method'], equals('long.running'));

        final wasPending = await connection.cancelPendingRequest(requestId);
        await Future.delayed(Duration.zero);

        expect(wasPending, isTrue);
        expect(sentMessages[1]['method'], equals(r'$/cancel_request'));
        expect(sentMessages[1]['params'], {'requestId': requestId});

        await responseErrorExpectation;

        readableController.add({
          'jsonrpc': '2.0',
          'id': requestId,
          'result': 'late response',
        });
        await Future.delayed(Duration(milliseconds: 20));

        await subscription.cancel();
        await readableController.close();
        await writableController.close();
      },
    );

    test('handles incoming request correctly', () async {
      final readableController = StreamController<Map<String, dynamic>>();
      final writableController = StreamController<Map<String, dynamic>>();
      final acpStream = AcpStream(
        readable: readableController.stream,
        writable: writableController.sink,
      );

      final connection = Connection(
        (method, params) async => 'response to $method',
        (method, params) async => print('notification: $method'),
        acpStream,
      );
      // ignore: unused_local_variable
      final _ =
          connection; // Connection is used for its side effects (message handlers)

      // Send a request message
      readableController.add({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'test.request',
        'params': {'input': 'data'},
      });

      // Wait for response
      final response = await writableController.stream.first;
      expect(response, {
        'jsonrpc': '2.0',
        'id': 1,
        'result': 'response to test.request',
      });

      await readableController.close();
      await writableController.close();
    });

    test('handles incoming notification correctly', () async {
      final readableController = StreamController<Map<String, dynamic>>();
      final writableController = StreamController<Map<String, dynamic>>();
      final acpStream = AcpStream(
        readable: readableController.stream,
        writable: writableController.sink,
      );

      final connection = Connection(
        (method, params) async => 'response to $method',
        (method, params) async => print('notification: $method'),
        acpStream,
      );
      // ignore: unused_local_variable
      final _ =
          connection; // Connection is used for its side effects (message handlers)

      // Send a notification message
      readableController.add({
        'jsonrpc': '2.0',
        'method': 'test.notification',
        'params': {'data': 'value'},
      });

      // Notifications don't produce responses, just ensure no errors
      await Future.delayed(Duration(milliseconds: 10));

      // Check that no message was sent (notifications don't get responses)
      // by collecting any messages sent in a short time
      final messages = <Map<String, dynamic>>[];
      final subscription = writableController.stream.listen(messages.add);

      await Future.delayed(Duration(milliseconds: 50));
      await subscription.cancel();

      expect(messages, isEmpty); // No messages should be sent

      await readableController.close();
      await writableController.close();
    });

    test('handles request handler errors', () async {
      final readableController = StreamController<Map<String, dynamic>>();
      final writableController = StreamController<Map<String, dynamic>>();
      final acpStream = AcpStream(
        readable: readableController.stream,
        writable: writableController.sink,
      );

      final errorConnection = Connection(
        (method, params) async =>
            throw RequestError.methodNotFound('bad.method'),
        (method, params) async {},
        acpStream,
      );
      // ignore: unused_local_variable
      final _ =
          errorConnection; // Connection is used for its side effects (message handlers)

      // Send a request that will error
      readableController.add({
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'bad.method',
      });

      final response = await writableController.stream.first;
      expect(response['jsonrpc'], '2.0');
      expect(response['id'], 2);
      expect(response['error']['code'], -32601);
      expect(response['error']['message'], 'Method not found');

      await readableController.close();
      await writableController.close();
    });

    test('maps validation-like exceptions to invalid params', () async {
      final readableController = StreamController<Map<String, dynamic>>();
      final writableController = StreamController<Map<String, dynamic>>();
      final acpStream = AcpStream(
        readable: readableController.stream,
        writable: writableController.sink,
      );

      final connection = Connection(
        (method, params) async =>
            throw FormatException('{"field":"cwd","reason":"required"}'),
        (method, params) async {},
        acpStream,
      );
      // ignore: unused_local_variable
      final _ = connection;

      readableController.add({
        'jsonrpc': '2.0',
        'id': 3,
        'method': 'test.validation',
      });

      final response = await writableController.stream.first;
      expect(response['jsonrpc'], '2.0');
      expect(response['id'], 3);
      expect(response['error']['code'], -32602);
      expect(response['error']['message'], 'Invalid params');
      expect(response['error']['data'], {'field': 'cwd', 'reason': 'required'});

      await readableController.close();
      await writableController.close();
    });

    test('maps unexpected exceptions to internal error', () async {
      final readableController = StreamController<Map<String, dynamic>>();
      final writableController = StreamController<Map<String, dynamic>>();
      final acpStream = AcpStream(
        readable: readableController.stream,
        writable: writableController.sink,
      );

      final connection = Connection(
        (method, params) async => throw StateError('unexpected failure'),
        (method, params) async {},
        acpStream,
      );
      // ignore: unused_local_variable
      final _ = connection;

      readableController.add({
        'jsonrpc': '2.0',
        'id': 4,
        'method': 'test.internal',
      });

      final response = await writableController.stream.first;
      expect(response['jsonrpc'], '2.0');
      expect(response['id'], 4);
      expect(response['error']['code'], -32603);
      expect(response['error']['message'], 'Internal error');
      expect(response['error']['data'], isNull);

      await readableController.close();
      await writableController.close();
    });
  });

  group('AgentSideConnection', () {
    late StreamController<Map<String, dynamic>> readableController;
    late StreamController<Map<String, dynamic>> writableController;
    late AcpStream acpStream;

    setUp(() {
      readableController = StreamController<Map<String, dynamic>>();
      writableController = StreamController<Map<String, dynamic>>();
      acpStream = AcpStream(
        readable: readableController.stream,
        writable: writableController.sink,
      );
    });

    tearDown(() {
      readableController.close();
      writableController.close();
    });

    test('constructor creates connection with agent', () {
      final agentSideConnection = AgentSideConnection(
        (conn) => MockAgent(),
        acpStream,
      );

      // Verify the connection was created
      expect(agentSideConnection, isNotNull);
    });

    test('implements Client interface', () {
      final agentSideConnection = AgentSideConnection(
        (conn) => MockAgent(),
        acpStream,
      );

      // Verify it implements Client interface
      expect(agentSideConnection, isA<Client>());
    });

    test('requestPermission sends typed request and parses response', () async {
      final connection = AgentSideConnection((conn) => MockAgent(), acpStream);
      final future = connection.requestPermission(
        RequestPermissionRequest(
          sessionId: 'session-1',
          toolCall: ToolCallUpdate(toolCallId: 'tool-1'),
          options: [
            PermissionOption(
              optionId: 'allow',
              name: 'Allow once',
              kind: PermissionOptionKind.allowOnce,
            ),
          ],
        ),
      );

      await Future.delayed(Duration.zero);
      final sentMessage = await writableController.stream.first;
      expect(sentMessage['method'], equals('session/request_permission'));
      expect(sentMessage['params']['sessionId'], equals('session-1'));

      readableController.add({
        'jsonrpc': '2.0',
        'id': sentMessage['id'],
        'result': RequestPermissionResponse(
          outcome: SelectedOutcome(optionId: 'allow'),
        ).toJson(),
      });

      final response = await future;
      expect((response.outcome as SelectedOutcome).optionId, equals('allow'));
    });

    test('readTextFile sends typed request and parses response', () async {
      final connection = AgentSideConnection((conn) => MockAgent(), acpStream);
      final future = connection.readTextFile(
        ReadTextFileRequest(sessionId: 'session-1', path: '/tmp/readme.md'),
      );

      await Future.delayed(Duration.zero);
      final sentMessage = await writableController.stream.first;
      expect(sentMessage['method'], equals('fs/read_text_file'));
      expect(sentMessage['params']['path'], equals('/tmp/readme.md'));

      readableController.add({
        'jsonrpc': '2.0',
        'id': sentMessage['id'],
        'result': ReadTextFileResponse(content: 'hello').toJson(),
      });

      final response = await future;
      expect(response.content, equals('hello'));
    });

    test('createTerminal sends typed request and parses response', () async {
      final connection = AgentSideConnection((conn) => MockAgent(), acpStream);
      final future = connection.createTerminal(
        CreateTerminalRequest(
          sessionId: 'session-1',
          command: 'echo',
          args: ['hi'],
        ),
      );

      await Future.delayed(Duration.zero);
      final sentMessage = await writableController.stream.first;
      expect(sentMessage['method'], equals('terminal/create'));
      expect(sentMessage['params']['command'], equals('echo'));

      readableController.add({
        'jsonrpc': '2.0',
        'id': sentMessage['id'],
        'result': CreateTerminalResponse(terminalId: 'term-1').toJson(),
      });

      final response = await future;
      expect(response?.terminalId, equals('term-1'));
    });

    test('sessionUpdate sends notification payload', () async {
      final connection = AgentSideConnection((conn) => MockAgent(), acpStream);
      await connection.sessionUpdate(
        SessionNotification(
          sessionId: 'session-1',
          update: AgentMessageChunkSessionUpdate(
            content: TextContentBlock(text: 'hello'),
          ),
        ),
      );
      await Future.delayed(Duration.zero);

      final sentMessage = await writableController.stream.first;
      expect(sentMessage['method'], equals('session/update'));
      expect(sentMessage['params']['sessionId'], equals('session-1'));
      expect(
        sentMessage['params']['update']['sessionUpdate'],
        equals('agent_message_chunk'),
      );
    });

    test('maps invalid request params to invalid params error', () async {
      final _ = AgentSideConnection((conn) => MockAgent(), acpStream);

      readableController.add({
        'jsonrpc': '2.0',
        'id': 109,
        'method': 'initialize',
        'params': 'not-a-map',
      });

      final response = await writableController.stream.first;
      expect(response['id'], equals(109));
      expect(response['error']['code'], equals(-32602));
      expect(response['error']['message'], equals('Invalid params'));
    });

    test('dispatches session/set_config_option requests to Agent', () async {
      final agent = ConfigurableMockAgent();
      final _ = AgentSideConnection((conn) => agent, acpStream);

      readableController.add({
        'jsonrpc': '2.0',
        'id': 99,
        'method': 'session/set_config_option',
        'params': {'sessionId': 's1', 'configId': 'mode', 'value': 'code'},
      });

      final response = await writableController.stream.first;
      expect(response['id'], equals(99));
      expect(agent.lastSetConfigRequest, isNotNull);
      expect(agent.lastSetConfigRequest?.configId, equals('mode'));
      expect(agent.lastSetConfigRequest?.value, equals('code'));
    });

    test('dispatches session/load requests to Agent', () async {
      final agent = MockAgent();
      final _ = AgentSideConnection((conn) => agent, acpStream);

      readableController.add({
        'jsonrpc': '2.0',
        'id': 98,
        'method': 'session/load',
        'params': {'sessionId': 's1', 'cwd': '/workspace', 'mcpServers': []},
      });

      final response = await writableController.stream.first;
      expect(response['id'], equals(98));
      expect(response['result'], isA<LoadSessionResponse>());
    });

    test(
      'returns method_not_found when session/load is unimplemented',
      () async {
        final _ = AgentSideConnection(
          (conn) => UnimplementedLoadAgent(),
          acpStream,
        );

        readableController.add({
          'jsonrpc': '2.0',
          'id': 97,
          'method': 'session/load',
          'params': {'sessionId': 's1', 'cwd': '/workspace', 'mcpServers': []},
        });

        final response = await writableController.stream.first;
        expect(response['id'], equals(97));
        expect(response['error']['code'], equals(-32601));
        expect(response['error']['data']['method'], equals('session/load'));
      },
    );

    test('dispatches session/set_model requests to Agent', () async {
      final _ = AgentSideConnection((conn) => MockAgent(), acpStream);

      readableController.add({
        'jsonrpc': '2.0',
        'id': 96,
        'method': 'session/set_model',
        'params': {'sessionId': 's1', 'modelId': 'gpt-5'},
      });

      final response = await writableController.stream.first;
      expect(response['id'], equals(96));
      expect(response['result'], isA<SetSessionModelResponse>());
    });

    test(
      'returns method_not_found when session/set_config_option is unimplemented',
      () async {
        final _ = AgentSideConnection((conn) => MockAgent(), acpStream);

        readableController.add({
          'jsonrpc': '2.0',
          'id': 100,
          'method': 'session/set_config_option',
          'params': {'sessionId': 's1', 'configId': 'mode', 'value': 'code'},
        });

        final response = await writableController.stream.first;
        expect(response['id'], equals(100));
        expect(response['error']['code'], equals(-32601));
        expect(
          response['error']['data']['method'],
          equals('session/set_config_option'),
        );
      },
    );

    test('dispatches session/list requests to Agent', () async {
      final agent = ConfigurableMockAgent();
      final _ = AgentSideConnection((conn) => agent, acpStream);

      readableController.add({
        'jsonrpc': '2.0',
        'id': 101,
        'method': 'session/list',
        'params': {'cwd': '/workspace'},
      });

      final response = await writableController.stream.first;
      expect(response['id'], equals(101));
      expect(agent.lastListSessionsRequest, isNotNull);
      expect(agent.lastListSessionsRequest?.cwd, equals('/workspace'));
    });

    test(
      'returns method_not_found when session/list is unimplemented',
      () async {
        final _ = AgentSideConnection((conn) => MockAgent(), acpStream);

        readableController.add({
          'jsonrpc': '2.0',
          'id': 102,
          'method': 'session/list',
          'params': {'cwd': '/workspace'},
        });

        final response = await writableController.stream.first;
        expect(response['id'], equals(102));
        expect(response['error']['code'], equals(-32601));
        expect(response['error']['data']['method'], equals('session/list'));
      },
    );

    test('dispatches session/fork requests to Agent', () async {
      final agent = ConfigurableMockAgent();
      final _ = AgentSideConnection((conn) => agent, acpStream);

      readableController.add({
        'jsonrpc': '2.0',
        'id': 103,
        'method': 'session/fork',
        'params': {'sessionId': 's1', 'cwd': '/workspace'},
      });

      final response = await writableController.stream.first;
      expect(response['id'], equals(103));
      expect(agent.lastForkSessionRequest, isNotNull);
      expect(agent.lastForkSessionRequest?.sessionId, equals('s1'));
      expect(agent.lastForkSessionRequest?.cwd, equals('/workspace'));
    });

    test(
      'returns method_not_found when session/fork is unimplemented',
      () async {
        final _ = AgentSideConnection((conn) => MockAgent(), acpStream);

        readableController.add({
          'jsonrpc': '2.0',
          'id': 104,
          'method': 'session/fork',
          'params': {'sessionId': 's1', 'cwd': '/workspace'},
        });

        final response = await writableController.stream.first;
        expect(response['id'], equals(104));
        expect(response['error']['code'], equals(-32601));
        expect(response['error']['data']['method'], equals('session/fork'));
      },
    );

    test('dispatches session/resume requests to Agent', () async {
      final agent = ConfigurableMockAgent();
      final _ = AgentSideConnection((conn) => agent, acpStream);

      readableController.add({
        'jsonrpc': '2.0',
        'id': 105,
        'method': 'session/resume',
        'params': {'sessionId': 's1', 'cwd': '/workspace'},
      });

      final response = await writableController.stream.first;
      expect(response['id'], equals(105));
      expect(agent.lastResumeSessionRequest, isNotNull);
      expect(agent.lastResumeSessionRequest?.sessionId, equals('s1'));
      expect(agent.lastResumeSessionRequest?.cwd, equals('/workspace'));
    });

    test(
      'returns method_not_found when session/resume is unimplemented',
      () async {
        final _ = AgentSideConnection((conn) => MockAgent(), acpStream);

        readableController.add({
          'jsonrpc': '2.0',
          'id': 106,
          'method': 'session/resume',
          'params': {'sessionId': 's1', 'cwd': '/workspace'},
        });

        final response = await writableController.stream.first;
        expect(response['id'], equals(106));
        expect(response['error']['code'], equals(-32601));
        expect(response['error']['data']['method'], equals('session/resume'));
      },
    );

    test('dispatches protocol cancel notification to Agent', () async {
      final agent = ConfigurableMockAgent();
      final _ = AgentSideConnection((conn) => agent, acpStream);
      final sentMessages = <Map<String, dynamic>>[];
      final subscription = writableController.stream.listen(sentMessages.add);

      readableController.add({
        'jsonrpc': '2.0',
        'method': r'$/cancel_request',
        'params': {'requestId': 77},
      });
      await Future.delayed(Duration(milliseconds: 20));

      expect(agent.lastCancelRequestNotification?.requestId, equals(77));
      expect(sentMessages, isEmpty);
      await subscription.cancel();
    });

    test(
      'sendCancelRequest sends protocol cancellation notification',
      () async {
        final connection = AgentSideConnection(
          (conn) => MockAgent(),
          acpStream,
        );
        await connection.sendCancelRequest(
          CancelRequestNotification(requestId: 'req-2'),
        );
        await Future.delayed(Duration.zero);

        final sentMessage = await writableController.stream.first;
        expect(sentMessage['method'], equals(r'$/cancel_request'));
        expect(sentMessage['params'], {'requestId': 'req-2'});
      },
    );

    test('extMethod sends provided extension method name as-is', () async {
      final connection = AgentSideConnection((conn) => MockAgent(), acpStream);
      final responseFuture = connection.extMethod('_acme/ping', {'value': 1});

      await Future.delayed(Duration.zero);
      final sentMessage = await writableController.stream.first;
      expect(sentMessage['method'], equals('_acme/ping'));
      expect(sentMessage['params'], equals({'value': 1}));

      readableController.add({
        'jsonrpc': '2.0',
        'id': sentMessage['id'],
        'result': {'ok': true},
      });

      final response = await responseFuture;
      expect(response, equals({'ok': true}));
    });

    test(
      'extNotification sends provided extension method name as-is',
      () async {
        final connection = AgentSideConnection(
          (conn) => MockAgent(),
          acpStream,
        );
        await connection.extNotification('_acme/notify', {'value': 2});
        await Future.delayed(Duration.zero);

        final sentMessage = await writableController.stream.first;
        expect(sentMessage['method'], equals('_acme/notify'));
        expect(sentMessage['params'], equals({'value': 2}));
      },
    );

    test(
      'dispatches extension request with full method name to Agent',
      () async {
        final agent = ExtensionTrackingAgent();
        final _ = AgentSideConnection((conn) => agent, acpStream);

        readableController.add({
          'jsonrpc': '2.0',
          'id': 107,
          'method': '_acme/request',
          'params': {'value': 3},
        });

        final response = await writableController.stream.first;
        expect(response['id'], equals(107));
        expect(response['result'], equals({'handledMethod': '_acme/request'}));
        expect(agent.lastExtMethodName, equals('_acme/request'));
        expect(agent.lastExtMethodParams, equals({'value': 3}));
      },
    );

    test(
      'handled extension notification does not log method-not-found error',
      () async {
        final logs = <String>[];

        await runZoned(
          () async {
            final agent = ExtensionTrackingAgent();
            final _ = AgentSideConnection((conn) => agent, acpStream);

            readableController.add({
              'jsonrpc': '2.0',
              'method': '_acme/notify',
              'params': {'value': 4},
            });

            await Future.delayed(Duration(milliseconds: 20));
            expect(agent.lastExtNotificationName, equals('_acme/notify'));
            expect(agent.lastExtNotificationParams, equals({'value': 4}));
          },
          zoneSpecification: ZoneSpecification(
            print: (self, parent, zone, line) {
              logs.add(line);
            },
          ),
        );

        expect(
          logs.where((line) => line.startsWith('Error handling notification')),
          isEmpty,
        );
      },
    );

    test(
      'unknown non-extension request still returns method_not_found',
      () async {
        final _ = AgentSideConnection((conn) => MockAgent(), acpStream);

        readableController.add({
          'jsonrpc': '2.0',
          'id': 108,
          'method': 'acme/request',
          'params': {'value': 5},
        });

        final response = await writableController.stream.first;
        expect(response['id'], equals(108));
        expect(response['error']['code'], equals(-32601));
        expect(response['error']['data']['method'], equals('acme/request'));
      },
    );
  });

  group('ClientSideConnection', () {
    late StreamController<Map<String, dynamic>> readableController;
    late StreamController<Map<String, dynamic>> writableController;
    late AcpStream acpStream;

    setUp(() {
      readableController = StreamController<Map<String, dynamic>>();
      writableController = StreamController<Map<String, dynamic>>();
      acpStream = AcpStream(
        readable: readableController.stream,
        writable: writableController.sink,
      );
    });

    tearDown(() {
      readableController.close();
      writableController.close();
    });

    test('constructor creates connection with client', () {
      final clientSideConnection = ClientSideConnection(
        (conn) => MockClient(),
        acpStream,
      );

      // Verify the connection was created
      expect(clientSideConnection, isNotNull);
    });

    test('implements Agent interface', () {
      final clientSideConnection = ClientSideConnection(
        (conn) => MockClient(),
        acpStream,
      );

      // Verify it implements Agent interface
      expect(clientSideConnection, isA<Agent>());
    });

    test('initialize sends typed request and parses response', () async {
      final connection = ClientSideConnection(
        (conn) => MockClient(),
        acpStream,
      );
      final future = connection.initialize(
        InitializeRequest(
          protocolVersion: 1,
          clientCapabilities: ClientCapabilities(),
        ),
      );

      await Future.delayed(Duration.zero);
      final sentMessage = await writableController.stream.first;
      expect(sentMessage['method'], equals('initialize'));

      readableController.add({
        'jsonrpc': '2.0',
        'id': sentMessage['id'],
        'result': {
          'protocolVersion': 1,
          'agentCapabilities': {'loadSession': false},
          'authMethods': const [],
        },
      });

      final response = await future;
      expect(response.protocolVersion, equals(1));
    });

    test('newSession sends typed request and parses response', () async {
      final connection = ClientSideConnection(
        (conn) => MockClient(),
        acpStream,
      );
      final future = connection.newSession(
        NewSessionRequest(cwd: '/workspace', mcpServers: []),
      );

      await Future.delayed(Duration.zero);
      final sentMessage = await writableController.stream.first;
      expect(sentMessage['method'], equals('session/new'));
      expect(sentMessage['params']['cwd'], equals('/workspace'));

      readableController.add({
        'jsonrpc': '2.0',
        'id': sentMessage['id'],
        'result': NewSessionResponse(sessionId: 'session-1').toJson(),
      });

      final response = await future;
      expect(response.sessionId, equals('session-1'));
    });

    test('prompt sends typed request and parses response', () async {
      final connection = ClientSideConnection(
        (conn) => MockClient(),
        acpStream,
      );
      final future = connection.prompt(
        PromptRequest(
          sessionId: 'session-1',
          prompt: [TextContentBlock(text: 'hello')],
        ),
      );

      await Future.delayed(Duration.zero);
      final sentMessage = await writableController.stream.first;
      expect(sentMessage['method'], equals('session/prompt'));
      expect(sentMessage['params']['sessionId'], equals('session-1'));

      readableController.add({
        'jsonrpc': '2.0',
        'id': sentMessage['id'],
        'result': PromptResponse(stopReason: StopReason.endTurn).toJson(),
      });

      final response = await future;
      expect(response.stopReason, equals(StopReason.endTurn));
    });

    test('cancel sends session/cancel notification payload', () async {
      final connection = ClientSideConnection(
        (conn) => MockClient(),
        acpStream,
      );
      await connection.cancel(CancelNotification(sessionId: 'session-1'));
      await Future.delayed(Duration.zero);

      final sentMessage = await writableController.stream.first;
      expect(sentMessage['method'], equals('session/cancel'));
      expect(sentMessage['params']['sessionId'], equals('session-1'));
    });

    test(
      'setSessionConfigOption sends typed request and parses response',
      () async {
        final connection = ClientSideConnection(
          (conn) => MockClient(),
          acpStream,
        );
        final future = connection.setSessionConfigOption(
          SetSessionConfigOptionRequest(
            sessionId: 'session-123',
            configId: 'mode',
            value: 'code',
          ),
        );

        await Future.delayed(Duration.zero);
        final sentMessage = await writableController.stream.first;
        expect(sentMessage['method'], equals('session/set_config_option'));
        expect(sentMessage['params']['configId'], equals('mode'));

        readableController.add({
          'jsonrpc': '2.0',
          'id': sentMessage['id'],
          'result': {
            'configOptions': [
              {
                'id': 'mode',
                'name': 'Session Mode',
                'type': 'select',
                'currentValue': 'code',
                'options': [
                  {'value': 'ask', 'name': 'Ask'},
                  {'value': 'code', 'name': 'Code'},
                ],
              },
            ],
          },
        });

        final response = await future;
        expect(response.configOptions.first.id, equals('mode'));
        expect(response.configOptions.first.currentValue, equals('code'));
      },
    );

    test('dispatches fs/write_text_file requests to Client', () async {
      final _ = ClientSideConnection((conn) => MockClient(), acpStream);

      readableController.add({
        'jsonrpc': '2.0',
        'id': 90,
        'method': 'fs/write_text_file',
        'params': {
          'sessionId': 's1',
          'path': '/workspace/lib/main.dart',
          'content': 'void main() {}',
        },
      });

      final response = await writableController.stream.first;
      expect(response['id'], equals(90));
      expect(response['result'], isA<WriteTextFileResponse>());
    });

    test(
      'returns method_not_found when terminal/create is unimplemented',
      () async {
        final _ = ClientSideConnection(
          (conn) => UnimplementedTerminalClient(),
          acpStream,
        );

        readableController.add({
          'jsonrpc': '2.0',
          'id': 91,
          'method': 'terminal/create',
          'params': {'sessionId': 's1', 'command': 'echo', 'args': []},
        });

        final response = await writableController.stream.first;
        expect(response['id'], equals(91));
        expect(response['error']['code'], equals(-32601));
        expect(response['error']['data']['method'], equals('terminal/create'));
      },
    );

    test('dispatches session/update notifications to Client', () async {
      final client = SessionUpdateTrackingClient();
      final _ = ClientSideConnection((conn) => client, acpStream);
      final sentMessages = <Map<String, dynamic>>[];
      final subscription = writableController.stream.listen(sentMessages.add);

      readableController.add({
        'jsonrpc': '2.0',
        'method': 'session/update',
        'params': {
          'sessionId': 'session-1',
          'update': {
            'sessionUpdate': 'agent_message_chunk',
            'content': {'type': 'text', 'text': 'hello'},
          },
        },
      });
      await Future.delayed(Duration(milliseconds: 20));

      expect(client.lastSessionUpdate?.sessionId, equals('session-1'));
      expect(sentMessages, isEmpty);
      await subscription.cancel();
    });

    test(
      'unstableListSessions sends typed request and parses response',
      () async {
        final connection = ClientSideConnection(
          (conn) => MockClient(),
          acpStream,
        );
        final future = connection.unstableListSessions(
          ListSessionsRequest(cwd: '/workspace'),
        );

        await Future.delayed(Duration.zero);
        final sentMessage = await writableController.stream.first;
        expect(sentMessage['method'], equals('session/list'));
        expect(sentMessage['params']['cwd'], equals('/workspace'));

        readableController.add({
          'jsonrpc': '2.0',
          'id': sentMessage['id'],
          'result': {
            'sessions': [
              {'sessionId': 's1', 'cwd': '/workspace', 'title': 'Session 1'},
            ],
            'nextCursor': 'next',
          },
        });

        final response = await future;
        expect(response.sessions.first.sessionId, equals('s1'));
        expect(response.nextCursor, equals('next'));
      },
    );

    test(
      'unstableForkSession sends typed request and parses response',
      () async {
        final connection = ClientSideConnection(
          (conn) => MockClient(),
          acpStream,
        );
        final future = connection.unstableForkSession(
          ForkSessionRequest(sessionId: 's1', cwd: '/workspace'),
        );

        await Future.delayed(Duration.zero);
        final sentMessage = await writableController.stream.first;
        expect(sentMessage['method'], equals('session/fork'));
        expect(sentMessage['params']['sessionId'], equals('s1'));

        readableController.add({
          'jsonrpc': '2.0',
          'id': sentMessage['id'],
          'result': {'sessionId': 's2'},
        });

        final response = await future;
        expect(response.sessionId, equals('s2'));
      },
    );

    test(
      'unstableResumeSession sends typed request and parses response',
      () async {
        final connection = ClientSideConnection(
          (conn) => MockClient(),
          acpStream,
        );
        final future = connection.unstableResumeSession(
          ResumeSessionRequest(sessionId: 's1', cwd: '/workspace'),
        );

        await Future.delayed(Duration.zero);
        final sentMessage = await writableController.stream.first;
        expect(sentMessage['method'], equals('session/resume'));
        expect(sentMessage['params']['sessionId'], equals('s1'));

        readableController.add({
          'jsonrpc': '2.0',
          'id': sentMessage['id'],
          'result': {'modes': null, 'models': null},
        });

        final response = await future;
        expect(response, isA<ResumeSessionResponse>());
      },
    );

    test(
      'sendCancelRequest sends protocol cancellation notification',
      () async {
        final connection = ClientSideConnection(
          (conn) => MockClient(),
          acpStream,
        );
        await connection.sendCancelRequest(
          CancelRequestNotification(requestId: 3, meta: {'reason': 'user'}),
        );
        await Future.delayed(Duration.zero);

        final sentMessage = await writableController.stream.first;
        expect(sentMessage['method'], equals(r'$/cancel_request'));
        expect(sentMessage['params'], {
          'requestId': 3,
          '_meta': {'reason': 'user'},
        });
      },
    );

    test('dispatches protocol cancel notification to Client', () async {
      final client = ConfigurableMockClient();
      final _ = ClientSideConnection((conn) => client, acpStream);
      final sentMessages = <Map<String, dynamic>>[];
      final subscription = writableController.stream.listen(sentMessages.add);

      readableController.add({
        'jsonrpc': '2.0',
        'method': r'$/cancel_request',
        'params': {'requestId': 'req-5'},
      });
      await Future.delayed(Duration(milliseconds: 20));

      expect(client.lastCancelRequestNotification?.requestId, equals('req-5'));
      expect(sentMessages, isEmpty);
      await subscription.cancel();
    });

    test('extMethod sends provided extension method name as-is', () async {
      final connection = ClientSideConnection(
        (conn) => MockClient(),
        acpStream,
      );
      final responseFuture = connection.extMethod('_acme/ping', {'value': 1});

      await Future.delayed(Duration.zero);
      final sentMessage = await writableController.stream.first;
      expect(sentMessage['method'], equals('_acme/ping'));
      expect(sentMessage['params'], equals({'value': 1}));

      readableController.add({
        'jsonrpc': '2.0',
        'id': sentMessage['id'],
        'result': {'ok': true},
      });

      final response = await responseFuture;
      expect(response, equals({'ok': true}));
    });

    test(
      'extNotification sends provided extension method name as-is',
      () async {
        final connection = ClientSideConnection(
          (conn) => MockClient(),
          acpStream,
        );
        await connection.extNotification('_acme/notify', {'value': 2});
        await Future.delayed(Duration.zero);

        final sentMessage = await writableController.stream.first;
        expect(sentMessage['method'], equals('_acme/notify'));
        expect(sentMessage['params'], equals({'value': 2}));
      },
    );

    test(
      'dispatches extension request with full method name to Client',
      () async {
        final client = ExtensionTrackingClient();
        final _ = ClientSideConnection((conn) => client, acpStream);

        readableController.add({
          'jsonrpc': '2.0',
          'id': 109,
          'method': '_acme/request',
          'params': {'value': 3},
        });

        final response = await writableController.stream.first;
        expect(response['id'], equals(109));
        expect(response['result'], equals({'handledMethod': '_acme/request'}));
        expect(client.lastExtMethodName, equals('_acme/request'));
        expect(client.lastExtMethodParams, equals({'value': 3}));
      },
    );

    test(
      'handled extension notification does not log method-not-found error',
      () async {
        final logs = <String>[];

        await runZoned(
          () async {
            final client = ExtensionTrackingClient();
            final _ = ClientSideConnection((conn) => client, acpStream);

            readableController.add({
              'jsonrpc': '2.0',
              'method': '_acme/notify',
              'params': {'value': 4},
            });

            await Future.delayed(Duration(milliseconds: 20));
            expect(client.lastExtNotificationName, equals('_acme/notify'));
            expect(client.lastExtNotificationParams, equals({'value': 4}));
          },
          zoneSpecification: ZoneSpecification(
            print: (self, parent, zone, line) {
              logs.add(line);
            },
          ),
        );

        expect(
          logs.where((line) => line.startsWith('Error handling notification')),
          isEmpty,
        );
      },
    );

    test(
      'unknown non-extension request still returns method_not_found',
      () async {
        final _ = ClientSideConnection((conn) => MockClient(), acpStream);

        readableController.add({
          'jsonrpc': '2.0',
          'id': 110,
          'method': 'acme/request',
          'params': {'value': 5},
        });

        final response = await writableController.stream.first;
        expect(response['id'], equals(110));
        expect(response['error']['code'], equals(-32601));
        expect(response['error']['data']['method'], equals('acme/request'));
      },
    );
  });

  group('TerminalHandle', () {
    late MockConnection mockConnection;
    late TerminalHandle terminalHandle;

    setUp(() {
      mockConnection = MockConnection();
      terminalHandle = TerminalHandle(
        'terminal-123',
        'test-session',
        mockConnection,
      );
    });

    test('constructor sets id, sessionId and connection', () {
      expect(terminalHandle.id, 'terminal-123');
      // Note: sessionId and connection are private, so we can't directly test them
    });

    test('currentOutput sends terminalOutput request', () async {
      mockConnection.mockResponse = TerminalOutputResponse(
        output: '',
        truncated: false,
      );

      final result = await terminalHandle.currentOutput();

      expect(mockConnection.lastMethod, 'terminal/output');
      expect(mockConnection.lastParams, {
        'sessionId': 'test-session',
        'terminalId': 'terminal-123',
      });
      expect(result, isA<TerminalOutputResponse>());
    });

    test('waitForExit sends terminalWaitForExit request', () async {
      mockConnection.mockResponse = WaitForTerminalExitResponse(exitCode: 0);

      final result = await terminalHandle.waitForExit();

      expect(mockConnection.lastMethod, 'terminal/wait_for_exit');
      expect(mockConnection.lastParams, {
        'sessionId': 'test-session',
        'terminalId': 'terminal-123',
      });
      expect(result, isA<WaitForTerminalExitResponse>());
      expect(result.exitCode, 0);
    });

    test('kill sends terminalKill request', () async {
      mockConnection.mockResponse = KillTerminalCommandResponse();

      final result = await terminalHandle.kill();

      expect(mockConnection.lastMethod, 'terminal/kill');
      expect(mockConnection.lastParams, {
        'sessionId': 'test-session',
        'terminalId': 'terminal-123',
      });
      expect(result, isA<KillTerminalCommandResponse>());
    });

    test('release sends terminalRelease request', () async {
      mockConnection.mockResponse = ReleaseTerminalResponse();

      final result = await terminalHandle.release();

      expect(mockConnection.lastMethod, 'terminal/release');
      expect(mockConnection.lastParams, {
        'sessionId': 'test-session',
        'terminalId': 'terminal-123',
      });
      expect(result, isA<ReleaseTerminalResponse>());
    });

    test('dispose completes without error', () async {
      mockConnection.mockResponse = ReleaseTerminalResponse();
      await expectLater(terminalHandle.dispose(), completes);
    });
  });
}

/// Mock agent implementation for testing
class MockAgent implements Agent {
  @override
  Future<InitializeResponse> initialize(InitializeRequest params) async {
    return InitializeResponse(
      protocolVersion: 1,
      agentCapabilities: AgentCapabilities(loadSession: true),
      authMethods: const [],
    );
  }

  @override
  Future<NewSessionResponse> newSession(NewSessionRequest params) async {
    return NewSessionResponse(
      sessionId: 'test-session',
      modes: SessionModeState(
        availableModes: [SessionMode(id: 'code', name: 'Code')],
        currentModeId: 'code',
      ),
    );
  }

  @override
  Future<LoadSessionResponse>? loadSession(LoadSessionRequest params) async {
    return LoadSessionResponse(
      modes: SessionModeState(
        availableModes: [SessionMode(id: 'code', name: 'Code')],
        currentModeId: 'code',
      ),
    );
  }

  @override
  Future<ListSessionsResponse>? unstableListSessions(
    ListSessionsRequest params,
  ) {
    return null;
  }

  @override
  Future<ForkSessionResponse>? unstableForkSession(ForkSessionRequest params) {
    return null;
  }

  @override
  Future<ResumeSessionResponse>? unstableResumeSession(
    ResumeSessionRequest params,
  ) {
    return null;
  }

  @override
  Future<SetSessionModeResponse?>? setSessionMode(
    SetSessionModeRequest params,
  ) async {
    return SetSessionModeResponse();
  }

  @override
  Future<SetSessionConfigOptionResponse>? setSessionConfigOption(
    SetSessionConfigOptionRequest params,
  ) {
    return null;
  }

  @override
  Future<SetSessionModelResponse?>? setSessionModel(
    SetSessionModelRequest params,
  ) async {
    return SetSessionModelResponse();
  }

  @override
  Future<AuthenticateResponse?>? authenticate(
    AuthenticateRequest params,
  ) async {
    return AuthenticateResponse();
  }

  @override
  Future<PromptResponse> prompt(PromptRequest params) async {
    return PromptResponse(stopReason: StopReason.endTurn);
  }

  @override
  Future<void> cancel(CancelNotification params) async {
    // Mock implementation
  }

  @override
  Future<Map<String, dynamic>>? extMethod(
    String method,
    Map<String, dynamic> params,
  ) async {
    return {'result': 'mock'};
  }

  @override
  Future<void>? extNotification(
    String method,
    Map<String, dynamic> params,
  ) async {
    // Mock implementation
  }
}

class UnimplementedLoadAgent extends MockAgent {
  @override
  Future<LoadSessionResponse>? loadSession(LoadSessionRequest params) {
    return null;
  }
}

class ConfigurableMockAgent extends MockAgent
    implements ProtocolCancellationHandler {
  SetSessionConfigOptionRequest? lastSetConfigRequest;
  ListSessionsRequest? lastListSessionsRequest;
  ForkSessionRequest? lastForkSessionRequest;
  ResumeSessionRequest? lastResumeSessionRequest;
  CancelRequestNotification? lastCancelRequestNotification;

  @override
  Future<ListSessionsResponse>? unstableListSessions(
    ListSessionsRequest params,
  ) async {
    lastListSessionsRequest = params;
    return ListSessionsResponse(
      sessions: [
        SessionInfo(
          sessionId: 'session-1',
          cwd: params.cwd ?? '/workspace',
          title: 'Session 1',
        ),
      ],
    );
  }

  @override
  Future<ForkSessionResponse>? unstableForkSession(
    ForkSessionRequest params,
  ) async {
    lastForkSessionRequest = params;
    return ForkSessionResponse(sessionId: 'forked-session');
  }

  @override
  Future<ResumeSessionResponse>? unstableResumeSession(
    ResumeSessionRequest params,
  ) async {
    lastResumeSessionRequest = params;
    return ResumeSessionResponse();
  }

  @override
  Future<SetSessionConfigOptionResponse>? setSessionConfigOption(
    SetSessionConfigOptionRequest params,
  ) async {
    lastSetConfigRequest = params;
    return SetSessionConfigOptionResponse(
      configOptions: [
        SessionConfigOption(
          id: params.configId,
          name: 'Session Mode',
          category: 'mode',
          currentValue: params.value,
          options: UngroupedSessionConfigSelectOptions(
            options: [
              SessionConfigSelectOption(value: 'ask', name: 'Ask'),
              SessionConfigSelectOption(value: 'code', name: 'Code'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Future<void> cancelRequest(CancelRequestNotification params) async {
    lastCancelRequestNotification = params;
  }
}

/// Mock client implementation for testing
class MockClient implements Client {
  @override
  Future<RequestPermissionResponse> requestPermission(
    RequestPermissionRequest params,
  ) async {
    return RequestPermissionResponse(outcome: SelectedOutcome(optionId: 'yes'));
  }

  @override
  Future<void> sessionUpdate(SessionNotification params) async {
    // Mock implementation
  }

  @override
  Future<WriteTextFileResponse> writeTextFile(
    WriteTextFileRequest params,
  ) async {
    return WriteTextFileResponse();
  }

  @override
  Future<ReadTextFileResponse> readTextFile(ReadTextFileRequest params) async {
    return ReadTextFileResponse(content: 'mock content');
  }

  @override
  Future<CreateTerminalResponse>? createTerminal(
    CreateTerminalRequest params,
  ) async {
    return CreateTerminalResponse(terminalId: 'mock-terminal');
  }

  @override
  Future<TerminalOutputResponse>? terminalOutput(
    TerminalOutputRequest params,
  ) async {
    return TerminalOutputResponse(output: '', truncated: false);
  }

  @override
  Future<ReleaseTerminalResponse?>? releaseTerminal(
    ReleaseTerminalRequest params,
  ) async {
    return ReleaseTerminalResponse();
  }

  @override
  Future<WaitForTerminalExitResponse>? waitForTerminalExit(
    WaitForTerminalExitRequest params,
  ) async {
    return WaitForTerminalExitResponse(exitCode: 0);
  }

  @override
  Future<KillTerminalCommandResponse?>? killTerminal(
    KillTerminalCommandRequest params,
  ) async {
    return KillTerminalCommandResponse();
  }

  @override
  Future<Map<String, dynamic>>? extMethod(
    String method,
    Map<String, dynamic> params,
  ) async {
    return {'result': 'mock'};
  }

  @override
  Future<void>? extNotification(
    String method,
    Map<String, dynamic> params,
  ) async {
    // Mock implementation
  }
}

class UnimplementedTerminalClient extends MockClient {
  @override
  Future<CreateTerminalResponse>? createTerminal(CreateTerminalRequest params) {
    return null;
  }
}

class SessionUpdateTrackingClient extends MockClient {
  SessionNotification? lastSessionUpdate;

  @override
  Future<void> sessionUpdate(SessionNotification params) async {
    lastSessionUpdate = params;
  }
}

class ConfigurableMockClient extends MockClient
    implements ProtocolCancellationHandler {
  CancelRequestNotification? lastCancelRequestNotification;

  @override
  Future<void> cancelRequest(CancelRequestNotification params) async {
    lastCancelRequestNotification = params;
  }
}

class ExtensionTrackingAgent extends MockAgent {
  String? lastExtMethodName;
  Map<String, dynamic>? lastExtMethodParams;
  String? lastExtNotificationName;
  Map<String, dynamic>? lastExtNotificationParams;

  @override
  Future<Map<String, dynamic>>? extMethod(
    String method,
    Map<String, dynamic> params,
  ) async {
    lastExtMethodName = method;
    lastExtMethodParams = params;
    return {'handledMethod': method};
  }

  @override
  Future<void>? extNotification(
    String method,
    Map<String, dynamic> params,
  ) async {
    lastExtNotificationName = method;
    lastExtNotificationParams = params;
  }
}

class ExtensionTrackingClient extends MockClient {
  String? lastExtMethodName;
  Map<String, dynamic>? lastExtMethodParams;
  String? lastExtNotificationName;
  Map<String, dynamic>? lastExtNotificationParams;

  @override
  Future<Map<String, dynamic>>? extMethod(
    String method,
    Map<String, dynamic> params,
  ) async {
    lastExtMethodName = method;
    lastExtMethodParams = params;
    return {'handledMethod': method};
  }

  @override
  Future<void>? extNotification(
    String method,
    Map<String, dynamic> params,
  ) async {
    lastExtNotificationName = method;
    lastExtNotificationParams = params;
  }
}

/// Mock connection for testing TerminalHandle
class MockConnection implements Connection {
  dynamic mockResponse;
  String? lastMethod;
  dynamic lastParams;

  @override
  Future<T> sendRequest<T>(String method, [dynamic params]) async {
    lastMethod = method;
    lastParams = params;
    return mockResponse as T;
  }

  @override
  Future<void> sendNotification(String method, [dynamic params]) async {
    lastMethod = method;
    lastParams = params;
  }

  @override
  Future<void> sendCancelRequestNotification(CancelRequestNotification params) {
    lastMethod = r'$/cancel_request';
    lastParams = params.toJson();
    return Future.value();
  }

  @override
  Future<bool> cancelPendingRequest(
    RequestId requestId, {
    Map<String, dynamic>? meta,
  }) {
    lastMethod = 'cancelPendingRequest';
    lastParams = {'requestId': requestId, if (meta != null) '_meta': meta};
    return Future.value(false);
  }
}
