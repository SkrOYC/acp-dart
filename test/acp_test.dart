import 'package:acp_dart/src/acp.dart';
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
}