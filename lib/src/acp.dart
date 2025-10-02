/// Error response for JSON-RPC 2.0

import 'dart:async';

import 'package:acp_dart/src/stream.dart';
class ErrorResponse {
  final int code;
  final String message;
  final dynamic data;

  ErrorResponse({
    required this.code,
    required this.message,
    this.data,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        if (data != null) 'data': data,
      };

  factory ErrorResponse.fromJson(Map<String, dynamic> json) => ErrorResponse(
        code: json['code'] as int,
        message: json['message'] as String,
        data: json['data'],
      );
}

/// Type alias for request handler function
typedef RequestHandler = Future<dynamic> Function(String method, dynamic params);

/// Type alias for notification handler function
typedef NotificationHandler = Future<void> Function(String method, dynamic params);

/// Pending response promise container
class _PendingResponse {
  final void Function(dynamic) resolve;
  final void Function(dynamic) reject;

  _PendingResponse(this.resolve, this.reject);
}

/// Request error for ACP/JSON-RPC communication
class RequestError implements Exception {
  final int code;
  final String message;
  final dynamic data;

  RequestError(this.code, this.message, [this.data]);

  /// Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.
  static RequestError parseError([dynamic data]) {
    return RequestError(-32700, 'Parse error', data);
  }

  /// The JSON sent is not a valid Request object.
  static RequestError invalidRequest([dynamic data]) {
    return RequestError(-32600, 'Invalid request', data);
  }

  /// The method does not exist / is not available.
  static RequestError methodNotFound(String method) {
    return RequestError(-32601, 'Method not found', {'method': method});
  }

  /// Invalid method parameter(s).
  static RequestError invalidParams([dynamic data]) {
    return RequestError(-32602, 'Invalid params', data);
  }

  /// Internal JSON-RPC error.
  static RequestError internalError([dynamic data]) {
    return RequestError(-32603, 'Internal error', data);
  }

  /// Authentication required.
  static RequestError authRequired([dynamic data]) {
    return RequestError(-32000, 'Authentication required', data);
  }

  /// Resource, such as a file, was not found
  static RequestError resourceNotFound([String? uri]) {
    return RequestError(-32002, 'Resource not found', uri != null ? {'uri': uri} : null);
  }

  /// Converts this error to a JSON-RPC Result type (error variant)
  Map<String, dynamic> toResult() {
    return {
      'error': toErrorResponse().toJson(),
    };
  }

  /// Converts this error to an ErrorResponse
  ErrorResponse toErrorResponse() {
    return ErrorResponse(
      code: code,
      message: message,
      data: data,
    );
  }
}

/// Base connection class for managing JSON-RPC communication over ACP streams
class Connection {
  final Map<dynamic, _PendingResponse> _pendingResponses = {};
  int _nextRequestId = 0;
  final RequestHandler _requestHandler;
  final NotificationHandler _notificationHandler;
  final AcpStream _stream;
  Future<void> _writeQueue = Future.value();

  Connection(
    this._requestHandler,
    this._notificationHandler,
    this._stream,
  ) {
    _receive();
  }

  /// Sends a request and returns a future that completes with the response
  Future<T> sendRequest<T>(String method, [dynamic params]) {
    final id = _nextRequestId++;
    final completer = Completer<T>();
    _pendingResponses[id] = _PendingResponse(
      (value) => completer.complete(value as T),
      (error) => completer.completeError(error),
    );
    _sendMessage({'jsonrpc': '2.0', 'id': id, 'method': method, if (params != null) 'params': params});
    return completer.future;
  }

  /// Sends a notification (no response expected)
  Future<void> sendNotification(String method, [dynamic params]) {
    return _sendMessage({'jsonrpc': '2.0', 'method': method, if (params != null) 'params': params});
  }

  /// Starts receiving messages from the stream
  void _receive() {
    _stream.readable.listen(
      _processMessage,
      onError: (error) {
        print('Error receiving message: $error');
      },
      onDone: () {
        // Stream closed
      },
    );
  }

  /// Processes an incoming message
  void _processMessage(Map<String, dynamic> message) {
    try {
      if (message.containsKey('method') && message.containsKey('id')) {
        // It's a request
        _handleRequest(message);
      } else if (message.containsKey('method')) {
        // It's a notification
        _handleNotification(message);
      } else if (message.containsKey('id')) {
        // It's a response
        _handleResponse(message);
      } else {
        print('Invalid message: $message');
      }
    } catch (error) {
      print('Error processing message $message: $error');
      // Send error response if it was a request
      if (message.containsKey('id')) {
        _sendMessage({
          'jsonrpc': '2.0',
          'id': message['id'],
          'error': {'code': -32700, 'message': 'Parse error'},
        });
      }
    }
  }

  /// Handles incoming request
  void _handleRequest(Map<String, dynamic> message) async {
    final method = message['method'] as String;
    final params = message['params'];
    final id = message['id'];

    try {
      final result = await _requestHandler(method, params);
      _sendMessage({
        'jsonrpc': '2.0',
        'id': id,
        'result': result ?? null,
      });
    } catch (error) {
      late Map<String, dynamic> errorResponse;
      if (error is RequestError) {
        errorResponse = error.toErrorResponse().toJson();
      } else {
        errorResponse = RequestError.internalError(error.toString()).toErrorResponse().toJson();
      }
      _sendMessage({
        'jsonrpc': '2.0',
        'id': id,
        'error': errorResponse,
      });
    }
  }

  /// Handles incoming notification
  void _handleNotification(Map<String, dynamic> message) async {
    final method = message['method'] as String;
    final params = message['params'];

    try {
      await _notificationHandler(method, params);
    } catch (error) {
      print('Error handling notification $method: $error');
    }
  }

  /// Handles incoming response
  void _handleResponse(Map<String, dynamic> message) {
    final id = message['id'];
    final pending = _pendingResponses.remove(id);

    if (pending != null) {
      if (message.containsKey('result')) {
        pending.resolve(message['result']);
      } else if (message.containsKey('error')) {
        pending.reject(message['error']);
      }
    } else {
      print('Received response for unknown request id: $id');
    }
  }

  /// Sends a message through the stream with queuing
  Future<void> _sendMessage(Map<String, dynamic> message) {
    _writeQueue = _writeQueue.then((_) async {
      try {
        _stream.writable.add(message);
      } catch (error) {
        print('Error sending message: $error');
      }
    });
    return _writeQueue;
  }
}