/// Error response for JSON-RPC 2.0
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