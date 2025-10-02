import 'dart:async';

import 'package:acp_dart/src/acp.dart';
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
        }
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
      final response = ErrorResponse(
        code: -32603,
        message: 'Internal error',
      );

      final json = response.toJson();
      expect(json, {
        'code': -32603,
        'message': 'Internal error',
      });

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
      final future = connection.sendRequest<String>('test.method', {'param': 'value'});

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
        (method, params) async => throw RequestError.methodNotFound('bad.method'),
        (method, params) async {},
        acpStream,
      );

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
  });
}