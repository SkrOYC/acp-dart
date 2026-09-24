/// Error response for JSON-RPC 2.0

library;

import 'dart:async';
import 'dart:convert';

import 'package:acp_dart/src/schema.dart';
import 'package:acp_dart/src/schema_v15_experimental.dart';
import 'package:acp_dart/src/schema_v15_client.dart';
import 'package:acp_dart/src/stream.dart';

class LogoutRequest {
  final Map<String, dynamic>? meta;
  const LogoutRequest({this.meta});
  factory LogoutRequest.fromJson(Map<String, dynamic> json) =>
      LogoutRequest(meta: json['_meta'] as Map<String, dynamic>?);
  Map<String, dynamic> toJson() => {if (meta != null) '_meta': meta};
}

class LogoutResponse {
  final Map<String, dynamic>? meta;
  const LogoutResponse({this.meta});
  factory LogoutResponse.fromJson(Map<String, dynamic> json) =>
      LogoutResponse(meta: json['_meta'] as Map<String, dynamic>?);
  Map<String, dynamic> toJson() => {if (meta != null) '_meta': meta};
}

class ErrorResponse {
  final int code;
  final String message;
  final dynamic data;

  ErrorResponse({required this.code, required this.message, this.data});

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
typedef RequestHandler =
    Future<dynamic> Function(String method, dynamic params);
typedef RequestContextHandler =
    Future<dynamic> Function(
      String method,
      dynamic params,
      RequestContext context,
    );

/// Cancellation state associated with one incoming JSON-RPC request.
class RequestContext {
  final Object? requestId;
  final Completer<void> _cancelled = Completer<void>();
  Object? _reason;

  RequestContext({required this.requestId});

  bool get isCancelled => _cancelled.isCompleted;
  Future<void> get cancelled => _cancelled.future;
  Object? get cancelReason => _reason;

  void cancel([Object? reason]) {
    if (_cancelled.isCompleted) return;
    _reason = reason ?? RequestError.requestCancelled();
    _cancelled.complete();
  }
}

/// Type alias for notification handler function
typedef NotificationHandler =
    Future<void> Function(String method, dynamic params);

bool _isValidRequestId(Object? value) =>
    value == null || value is String || (value is num && value.isFinite);

typedef _RawResponseDecoder<T> = T Function(Object? value);

T _decodeTypedResponse<T>(
  Object? value,
  T Function(Map<String, dynamic>) fromJson, {
  _RawResponseDecoder<T>? fromRawJson,
}) {
  if (value is T) return value;
  if (fromRawJson != null) return fromRawJson(value);
  if (value is Map) return fromJson(Map<String, dynamic>.from(value));
  throw FormatException('Expected ${T.toString()} response object');
}

/// Optional interface for participants that handle `$/cancel_request`.
abstract class ProtocolCancellationHandler {
  Future<void> cancelRequest(CancelRequestNotification params);
}

/// Optional v1.5 agent request handlers.
mixin AgentV15Handler on Agent {
  Future<ListSessionsResponse>? listSessions(ListSessionsRequest params) =>
      unstableListSessions(params);
  Future<ResumeSessionResponse>? resumeSession(ResumeSessionRequest params) =>
      unstableResumeSession(params);
  Future<DeleteSessionResponse>? deleteSession(DeleteSessionRequest params) =>
      null;
  Future<CloseSessionResponse>? closeSession(CloseSessionRequest params) =>
      null;
  Future<LogoutResponse>? logout(LogoutRequest params) => null;
  Future<V15ListProvidersResponse>? unstableListProviders(
    V15ListProvidersRequest params,
  ) => null;
  Future<V15SetProviderResponse>? unstableSetProvider(
    V15SetProviderRequest params,
  ) => null;
  Future<V15DisableProviderResponse>? unstableDisableProvider(
    V15DisableProviderRequest params,
  ) => null;
  Future<V15MessageMcpResponse>? unstableMessageMcp(
    V15MessageMcpRequest params,
  ) => null;
  Future<void> unstableHandleMcpNotification(
    V15MessageMcpNotification params,
  ) async {}
  Future<V15StartNesResponse>? unstableStartNes(V15StartNesRequest params) =>
      null;
  Future<V15SuggestNesResponse>? unstableSuggestNes(
    V15SuggestNesRequest params,
  ) => null;
  Future<V15CloseNesResponse>? unstableCloseNes(V15CloseNesRequest params) =>
      null;
  Future<void> unstableDidOpenDocument(
    V15DidOpenDocumentNotification params,
  ) async {}
  Future<void> unstableDidChangeDocument(
    V15DidChangeDocumentNotification params,
  ) async {}
  Future<void> unstableDidCloseDocument(
    V15DidCloseDocumentNotification params,
  ) async {}
  Future<void> unstableDidSaveDocument(
    V15DidSaveDocumentNotification params,
  ) async {}
  Future<void> unstableDidFocusDocument(
    V15DidFocusDocumentNotification params,
  ) async {}
  Future<void> unstableAcceptNes(V15AcceptNesNotification params) async {}
  Future<void> unstableRejectNes(V15RejectNesNotification params) async {}
}

/// Optional v1.5 elicitation handlers for clients.
mixin ClientV15Handler {
  Future<CreateElicitationResponse>? createElicitation(
    CreateElicitationRequest params,
  ) => null;
  Future<void> completeElicitation(
    CompleteElicitationNotification params,
  ) async {}
  Future<V15ConnectMcpResponse>? unstableConnectMcp(
    V15ConnectMcpRequest params,
  ) => null;
  Future<V15MessageMcpResponse>? unstableMessageMcp(
    V15MessageMcpRequest params,
  ) => null;
  Future<void> unstableHandleMcpNotification(
    V15MessageMcpNotification params,
  ) async {}
  Future<V15DisconnectMcpResponse>? unstableDisconnectMcp(
    V15DisconnectMcpRequest params,
  ) => null;
}

/// Pending response promise container
class _PendingResponse {
  final void Function(dynamic) resolve;
  final void Function(dynamic) reject;

  _PendingResponse(this.resolve, this.reject);
}

/// Request error for ACP/JSON-RPC communication
class RequestError implements Exception {
  static const int requestCancelledCode = -32800;

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
    return RequestError(
      -32002,
      'Resource not found',
      uri != null ? {'uri': uri} : null,
    );
  }

  /// The request was cancelled.
  static RequestError requestCancelled([dynamic data]) {
    return RequestError(requestCancelledCode, 'Cancelled', data);
  }

  /// Converts this error to a JSON-RPC Result type (error variant)
  Map<String, dynamic> toResult() {
    return {'error': toErrorResponse().toJson()};
  }

  /// Converts this error to an ErrorResponse
  ErrorResponse toErrorResponse() {
    return ErrorResponse(code: code, message: message, data: data);
  }
}

/// Base connection class for managing JSON-RPC communication over ACP streams
class Connection {
  final Map<dynamic, _PendingResponse> _pendingResponses = {};
  final Map<dynamic, RequestContext> _incomingRequests = {};
  int _nextRequestId = 0;
  final RequestHandler _requestHandler;
  final RequestContextHandler? _requestContextHandler;
  final NotificationHandler _notificationHandler;
  final AcpStream _stream;
  Future<void> _writeQueue = Future.value();
  final Completer<void> _closedCompleter = Completer<void>();
  StreamSubscription<Map<String, dynamic>>? _subscription;
  bool _isClosed = false;
  Object? _closeReason;

  Connection(
    this._requestHandler,
    this._notificationHandler,
    this._stream, {
    RequestContextHandler? requestContextHandler,
  }) : _requestContextHandler = requestContextHandler {
    _receive();
  }

  /// Completes when the underlying stream ends or [close] is called.
  Future<void> get closed => _closedCompleter.future;

  /// Whether this connection has stopped accepting messages.
  bool get isClosed => _isClosed;

  /// The reason the connection closed, if it closed with an error.
  Object? get closeReason => _closeReason;

  /// Closes the connection and rejects every pending request.
  void close([Object? error]) {
    if (_isClosed) return;
    _isClosed = true;
    _closeReason = error ?? StateError('ACP connection closed');
    for (final pending in _pendingResponses.values) {
      pending.reject(_closeReason);
    }
    _pendingResponses.clear();
    for (final context in _incomingRequests.values) {
      context.cancel(_closeReason);
    }
    _incomingRequests.clear();
    final subscription = _subscription;
    if (subscription != null) {
      scheduleMicrotask(subscription.cancel);
    }
    if (!_closedCompleter.isCompleted) _closedCompleter.complete();
  }

  /// Sends a request and returns a future that completes with the response
  Future<T> sendRequest<T>(String method, [dynamic params]) {
    return _sendRequest<T>(method, params);
  }

  /// Sends a request and notifies the peer when [cancellation] completes.
  /// The response future remains pending until the peer responds or closes.
  Future<T> sendRequestWithCancellation<T>(
    String method, {
    required Future<void> cancellation,
    dynamic params,
  }) {
    return _sendRequest<T>(method, params, cancellation: cancellation);
  }

  Future<T> _sendRequest<T>(
    String method,
    dynamic params, {
    Future<void>? cancellation,
  }) {
    if (_isClosed) return Future<T>.error(_closeReason!);
    final id = _nextRequestId++;
    final completer = Completer<T>();
    _pendingResponses[id] = _PendingResponse(
      (value) => completer.complete(value as T),
      (error) => completer.completeError(error),
    );
    _sendMessage({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    }).catchError((Object error) {
      final pending = _pendingResponses.remove(id);
      pending?.reject(error);
      close(error);
    });
    if (cancellation != null) {
      unawaited(
        cancellation
            .then<void>((_) async {
              if (_pendingResponses.containsKey(id) && !_isClosed) {
                await sendCancelRequestNotification(
                  CancelRequestNotification(requestId: id),
                );
              }
            })
            .catchError((Object error) async {
              close(error);
            }),
      );
    }
    return completer.future;
  }

  /// Sends a notification (no response expected)
  Future<void> sendNotification(String method, [dynamic params]) {
    if (_isClosed) return Future<void>.error(_closeReason!);
    return _sendMessage({
      'jsonrpc': '2.0',
      'method': method,
      if (params != null) 'params': params,
    });
  }

  /// Sends the protocol-level cancellation notification `$/cancel_request`.
  Future<void> sendCancelRequestNotification(
    CancelRequestNotification params,
  ) async {
    if (!_isValidRequestId(params.requestId)) {
      throw ArgumentError.value(params.requestId, 'requestId');
    }
    await sendNotification(protocolMethods['cancelRequest']!, params.toJson());
  }

  /// Cancels a pending outbound request and notifies the peer.
  ///
  /// Returns `true` if the request ID was still pending locally.
  Future<bool> cancelPendingRequest(
    RequestId requestId, {
    Map<String, dynamic>? meta,
  }) async {
    final pending = _pendingResponses.containsKey(requestId);
    await sendCancelRequestNotification(
      CancelRequestNotification(meta: meta, requestId: requestId),
    );
    return pending;
  }

  /// Starts receiving messages from the stream
  void _receive() {
    _subscription = _stream.readable.listen(
      _processMessage,
      onError: (error) {
        close(error as Object);
      },
      onDone: () {
        close();
      },
    );
  }

  /// Processes an incoming message
  void _processMessage(Map<String, dynamic> message) {
    if (_isClosed) return;
    try {
      if (!_isValidMessage(message)) {
        final id = message['id'];
        if (!message.containsKey('method') && message.containsKey('id')) {
          final pending = _pendingResponses.remove(id);
          pending?.reject(RequestError.invalidRequest(message));
          return;
        }
        if (message.containsKey('id')) {
          final validId = _isValidRequestId(id);
          _sendMessage({
            'jsonrpc': '2.0',
            'id': validId ? id : null,
            'error': RequestError.invalidRequest(
              message,
            ).toErrorResponse().toJson(),
          }).catchError((Object error) => close(error));
        }
        return;
      }
      if (message.containsKey('method') && message.containsKey('id')) {
        // It's a request
        unawaited(_handleRequest(message));
      } else if (message.containsKey('method')) {
        // It's a notification
        _handleNotification(message);
      } else if (message.containsKey('id')) {
        // It's a response
        _handleResponse(message);
      } else {
        return;
      }
    } catch (error) {
      if (message.containsKey('id')) {
        _sendMessage({
          'jsonrpc': '2.0',
          'id': message['id'],
          'error': RequestError.internalError().toErrorResponse().toJson(),
        }).catchError((Object writeError) => close(writeError));
      } else {
        close(error);
      }
    }
  }

  bool _isValidMessage(Map<String, dynamic> message) {
    if (message['jsonrpc'] != '2.0') return false;
    final id = message['id'];
    final validId = _isValidRequestId(id);
    if (message.containsKey('method')) {
      return message['method'] is String &&
          (!message.containsKey('id') || validId);
    }
    if (!message.containsKey('id') || !validId) return false;
    final hasResult = message.containsKey('result');
    final hasError = message.containsKey('error');
    if (hasResult == hasError) return false;
    if (!hasError) return true;
    final error = message['error'];
    return error is Map && error['code'] is int && error['message'] is String;
  }

  /// Handles incoming request
  Future<void> _handleRequest(Map<String, dynamic> message) async {
    final method = message['method'] as String;
    final params = message['params'];
    final id = message['id'];

    final context = RequestContext(requestId: id);
    _incomingRequests[id] = context;
    try {
      dynamic result;
      try {
        result = _requestContextHandler == null
            ? await _requestHandler(method, params)
            : await _requestContextHandler(method, params, context);
      } catch (error) {
        final errorResponse = _mapRequestError(
          error,
        ).toErrorResponse().toJson();
        await _sendMessage({
          'jsonrpc': '2.0',
          'id': id,
          'error': errorResponse,
        });
        return;
      }
      await _sendMessage({'jsonrpc': '2.0', 'id': id, 'result': result});
    } catch (error) {
      close(error);
    } finally {
      if (identical(_incomingRequests[id], context)) {
        _incomingRequests.remove(id);
      }
    }
  }

  RequestError _mapRequestError(Object error) {
    if (error is RequestError) {
      return error;
    }

    if (error is TypeError ||
        error is FormatException ||
        error is ArgumentError) {
      final errorData = _extractErrorData(error);
      return RequestError.invalidParams(errorData);
    }
    return RequestError.internalError();
  }

  dynamic _extractErrorData(Object error) {
    final message = switch (error) {
      FormatException() => error.message.toString(),
      ArgumentError() => error.message?.toString() ?? error.toString(),
      _ => error.toString(),
    };
    try {
      return jsonDecode(message);
    } catch (_) {
      return message;
    }
  }

  /// Handles incoming notification
  void _handleNotification(Map<String, dynamic> message) async {
    final method = message['method'] as String;
    final params = message['params'];

    if (method == r'$/cancel_request' && params is Map) {
      final requestId = params['requestId'];
      final context = _incomingRequests[requestId];
      context?.cancel(RequestError.requestCancelled({'requestId': requestId}));
    }

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
        final error = message['error'] as Map<String, dynamic>;
        pending.reject(
          RequestError(
            error['code'] as int,
            error['message'] as String,
            error['data'],
          ),
        );
      }
    } else {
      print('Received response for unknown request id: $id');
    }
  }

  /// Sends a message through the stream with queuing
  Future<void> _sendMessage(Map<String, dynamic> message) {
    if (_isClosed) return Future<void>.error(_closeReason!);
    final write = _writeQueue.then<void>((_) async {
      if (_isClosed) throw _closeReason!;
      _stream.writable.add(message);
    });
    _writeQueue = write.catchError((Object error) async {
      close(error);
    });
    return write;
  }
}

/// Abstract base class defining the Client interface for ACP connections.
///
/// Clients implement this interface to handle requests from agents, including
/// file system operations, permission requests, terminal management, and
/// session updates.
abstract class Client {
  /// Requests permission from the user for a tool call operation.
  ///
  /// Called by the agent when it needs user authorization before executing
  /// a potentially sensitive operation. The client should present the options
  /// to the user and return their decision.
  ///
  /// If the client cancels the prompt turn via `session/cancel`, it MUST
  /// respond to this request with `RequestPermissionOutcome::Cancelled`.
  Future<RequestPermissionResponse> requestPermission(
    RequestPermissionRequest params,
  );

  /// Handles session update notifications from the agent.
  ///
  /// This is a notification endpoint (no response expected) that receives
  /// real-time updates about session progress, including message chunks,
  /// tool calls, and execution plans.
  ///
  /// Note: Clients SHOULD continue accepting tool call updates even after
  /// sending a `session/cancel` notification, as the agent may send final
  /// updates before responding with the cancelled stop reason.
  Future<void> sessionUpdate(SessionNotification params);

  /// Writes content to a text file in the client's file system.
  ///
  /// Only available if the client advertises the `fs.writeTextFile` capability.
  /// Allows the agent to create or modify files within the client's environment.
  Future<WriteTextFileResponse>? writeTextFile(WriteTextFileRequest params);

  /// Reads content from a text file in the client's file system.
  ///
  /// Only available if the client advertises the `fs.readTextFile` capability.
  /// Allows the agent to access file contents within the client's environment.
  Future<ReadTextFileResponse>? readTextFile(ReadTextFileRequest params);

  /// Creates a new terminal to execute a command.
  ///
  /// Only available if the `terminal` capability is set to `true`.
  ///
  /// The Agent must call `releaseTerminal` when done with the terminal
  /// to free resources.
  Future<CreateTerminalResponse>? createTerminal(CreateTerminalRequest params);

  /// Gets the current output and exit status of a terminal.
  ///
  /// Returns immediately without waiting for the command to complete.
  /// If the command has already exited, the exit status is included.
  Future<TerminalOutputResponse>? terminalOutput(TerminalOutputRequest params);

  /// Releases a terminal and frees all associated resources.
  ///
  /// The command is killed if it hasn't exited yet. After release,
  /// the terminal ID becomes invalid for all other terminal methods.
  ///
  /// Tool calls that already contain the terminal ID continue to
  /// display its output.
  Future<ReleaseTerminalResponse?>? releaseTerminal(
    ReleaseTerminalRequest params,
  );

  /// Waits for a terminal command to exit and returns its exit status.
  ///
  /// This method returns once the command completes, providing the
  /// exit code and/or signal that terminated the process.
  Future<WaitForTerminalExitResponse>? waitForTerminalExit(
    WaitForTerminalExitRequest params,
  );

  /// Kills a terminal command without releasing the terminal.
  ///
  /// While `releaseTerminal` also kills the command, this method keeps
  /// the terminal ID valid so it can be used with other methods.
  ///
  /// Useful for implementing command timeouts that terminate the command
  /// and then retrieve the final output.
  ///
  /// Note: Call `releaseTerminal` when the terminal is no longer needed.
  Future<KillTerminalCommandResponse?>? killTerminal(
    KillTerminalCommandRequest params,
  );

  /// Extension method
  ///
  /// Allows the Agent to send an arbitrary request that is not part of the ACP spec.
  ///
  /// The method name is sent exactly as provided and is not rewritten.
  /// ACP reserves extension methods under the `_` prefix, so callers should
  /// include the leading underscore explicitly when needed.
  Future<Map<String, dynamic>>? extMethod(
    String method,
    Map<String, dynamic> params,
  );

  /// Extension notification
  ///
  /// Allows the Agent to send an arbitrary notification that is not part of the ACP spec.
  Future<void>? extNotification(String method, Map<String, dynamic> params);
}

/// An agent-side connection to a client.
///
/// This class provides the agent's view of an ACP connection, allowing
/// agents to communicate with clients. It implements the Client interface
/// to provide methods for requesting permissions, accessing the file system,
/// and sending session updates.
class AgentSideConnection implements Client {
  late final Connection _connection;

  /// Creates a new agent-side connection to a client.
  ///
  /// This establishes the communication channel from the agent's perspective
  /// following the ACP specification.
  ///
  /// [toAgent] - A function that creates an Agent handler to process incoming client requests
  /// [stream] - The bidirectional message stream for communication. Typically created using
  ///            ndJsonStream for stdio-based connections.
  AgentSideConnection(
    Agent Function(AgentSideConnection) toAgent,
    AcpStream stream,
  ) {
    final agent = toAgent(this);

    Future<dynamic> handleOptionalRequest<T>(
      String method,
      dynamic params,
      T Function(Map<String, dynamic>) fromJson,
      Future<dynamic>? Function(T) handler,
    ) async {
      final validatedParams = fromJson(params as Map<String, dynamic>);
      final result = await handler(validatedParams);
      if (result == null) {
        throw RequestError.methodNotFound(method);
      }
      return result;
    }

    Future<dynamic> requestHandler(String method, dynamic params) async {
      switch (method) {
        case 'initialize':
          final validatedParams = InitializeRequest.fromJson(
            params as Map<String, dynamic>,
          );
          return agent.initialize(validatedParams);
        case 'session/new':
          final validatedParams = NewSessionRequest.fromJson(
            params as Map<String, dynamic>,
          );
          return agent.newSession(validatedParams);
        case 'session/load':
          return handleOptionalRequest(
            method,
            params,
            LoadSessionRequest.fromJson,
            agent.loadSession,
          );
        case 'session/list':
          return handleOptionalRequest(
            method,
            params,
            ListSessionsRequest.fromJson,
            agent is AgentV15Handler
                ? agent.listSessions
                : agent.unstableListSessions,
          );
        case 'session/delete':
          return handleOptionalRequest(
            method,
            params,
            DeleteSessionRequest.fromJson,
            agent is AgentV15Handler ? agent.deleteSession : (_) => null,
          );
        case 'session/close':
          return handleOptionalRequest(
            method,
            params,
            CloseSessionRequest.fromJson,
            agent is AgentV15Handler ? agent.closeSession : (_) => null,
          );
        case 'logout':
          return handleOptionalRequest(
            method,
            params,
            LogoutRequest.fromJson,
            agent is AgentV15Handler ? agent.logout : (_) => null,
          );
        case 'providers/list':
          return handleOptionalRequest(
            method,
            params,
            V15ListProvidersRequest.fromJson,
            agent is AgentV15Handler
                ? agent.unstableListProviders
                : (_) => null,
          );
        case 'providers/set':
          return handleOptionalRequest(
            method,
            params,
            V15SetProviderRequest.fromJson,
            agent is AgentV15Handler ? agent.unstableSetProvider : (_) => null,
          );
        case 'providers/disable':
          return handleOptionalRequest(
            method,
            params,
            V15DisableProviderRequest.fromJson,
            agent is AgentV15Handler
                ? agent.unstableDisableProvider
                : (_) => null,
          );
        case 'mcp/message':
          return handleOptionalRequest(
            method,
            params,
            V15MessageMcpRequest.fromJson,
            agent is AgentV15Handler ? agent.unstableMessageMcp : (_) => null,
          );
        case 'nes/start':
          return handleOptionalRequest(
            method,
            params,
            V15StartNesRequest.fromJson,
            agent is AgentV15Handler ? agent.unstableStartNes : (_) => null,
          );
        case 'nes/suggest':
          return handleOptionalRequest(
            method,
            params,
            V15SuggestNesRequest.fromJson,
            agent is AgentV15Handler ? agent.unstableSuggestNes : (_) => null,
          );
        case 'nes/close':
          return handleOptionalRequest(
            method,
            params,
            V15CloseNesRequest.fromJson,
            agent is AgentV15Handler ? agent.unstableCloseNes : (_) => null,
          );
        case 'session/fork':
          return handleOptionalRequest(
            method,
            params,
            ForkSessionRequest.fromJson,
            agent.unstableForkSession,
          );
        case 'session/resume':
          return handleOptionalRequest(
            method,
            params,
            ResumeSessionRequest.fromJson,
            agent is AgentV15Handler
                ? agent.resumeSession
                : agent.unstableResumeSession,
          );
        case 'session/set_mode':
          final validatedParams = SetSessionModeRequest.fromJson(
            params as Map<String, dynamic>,
          );
          final result = await agent.setSessionMode(validatedParams);
          return result ?? {};
        case 'session/set_config_option':
          return handleOptionalRequest(
            method,
            params,
            SetSessionConfigOptionRequest.fromJson,
            agent.setSessionConfigOption,
          );
        case 'session/set_model':
          final validatedParams = SetSessionModelRequest.fromJson(
            params as Map<String, dynamic>,
          );
          final result = await agent.setSessionModel(validatedParams);
          return result ?? {};
        case 'authenticate':
          final validatedParams = AuthenticateRequest.fromJson(
            params as Map<String, dynamic>,
          );
          final result = await agent.authenticate(validatedParams);
          return result ?? {};
        case 'session/prompt':
          final validatedParams = PromptRequest.fromJson(
            params as Map<String, dynamic>,
          );
          return agent.prompt(validatedParams);
        default:
          if (method.startsWith('_')) {
            final result = await agent.extMethod(
              method,
              params as Map<String, dynamic>,
            );
            if (result == null) {
              throw RequestError.methodNotFound(method);
            }
            return result;
          }
          throw RequestError.methodNotFound(method);
      }
    }

    Future<void> notificationHandler(String method, dynamic params) async {
      switch (method) {
        case 'session/cancel':
          final validatedParams = CancelNotification.fromJson(
            params as Map<String, dynamic>,
          );
          return agent.cancel(validatedParams);
        case 'mcp/message':
          if (agent is AgentV15Handler) {
            await agent.unstableHandleMcpNotification(
              V15MessageMcpNotification.fromJson(
                params as Map<String, dynamic>,
              ),
            );
          }
          return;
        case 'document/didOpen':
          if (agent is AgentV15Handler) {
            await agent.unstableDidOpenDocument(
              V15DidOpenDocumentNotification.fromJson(
                params as Map<String, dynamic>,
              ),
            );
          }
          return;
        case 'document/didChange':
          if (agent is AgentV15Handler) {
            await agent.unstableDidChangeDocument(
              V15DidChangeDocumentNotification.fromJson(
                params as Map<String, dynamic>,
              ),
            );
          }
          return;
        case 'document/didClose':
          if (agent is AgentV15Handler) {
            await agent.unstableDidCloseDocument(
              V15DidCloseDocumentNotification.fromJson(
                params as Map<String, dynamic>,
              ),
            );
          }
          return;
        case 'document/didSave':
          if (agent is AgentV15Handler) {
            await agent.unstableDidSaveDocument(
              V15DidSaveDocumentNotification.fromJson(
                params as Map<String, dynamic>,
              ),
            );
          }
          return;
        case 'document/didFocus':
          if (agent is AgentV15Handler) {
            await agent.unstableDidFocusDocument(
              V15DidFocusDocumentNotification.fromJson(
                params as Map<String, dynamic>,
              ),
            );
          }
          return;
        case 'nes/accept':
          if (agent is AgentV15Handler) {
            await agent.unstableAcceptNes(
              V15AcceptNesNotification.fromJson(params as Map<String, dynamic>),
            );
          }
          return;
        case 'nes/reject':
          if (agent is AgentV15Handler) {
            await agent.unstableRejectNes(
              V15RejectNesNotification.fromJson(params as Map<String, dynamic>),
            );
          }
          return;
        case r'$/cancel_request':
          final validatedParams = CancelRequestNotification.fromJson(
            params as Map<String, dynamic>,
          );
          if (agent is ProtocolCancellationHandler) {
            return (agent as ProtocolCancellationHandler).cancelRequest(
              validatedParams,
            );
          }
          return;
        default:
          if (method.startsWith('_')) {
            await agent.extNotification(method, params as Map<String, dynamic>);
            return;
          }
          if (method.startsWith(r'$/')) {
            // Protocol-level notifications may be ignored by implementations.
            return;
          }
          throw RequestError.methodNotFound(method);
      }
    }

    _connection = Connection(requestHandler, notificationHandler, stream);
  }

  @override
  Future<void> sessionUpdate(SessionNotification params) async {
    return _connection.sendNotification(
      clientMethods['sessionUpdate']!,
      params.toJson(),
    );
  }

  Future<CreateElicitationResponse> createElicitation(
    CreateElicitationRequest params,
  ) async {
    final result = await _connection.sendRequest(
      'elicitation/create',
      params.toJson(),
    );
    return _decodeTypedResponse(result, CreateElicitationResponse.fromJson);
  }

  Future<void> completeElicitation(CompleteElicitationNotification params) =>
      _connection.sendNotification('elicitation/complete', params.toJson());

  Future<V15ConnectMcpResponse> unstableConnectMcp(
    V15ConnectMcpRequest params,
  ) async => _decodeTypedResponse(
    await _connection.sendRequest('mcp/connect', params.toJson()),
    V15ConnectMcpResponse.fromJson,
  );

  Future<V15MessageMcpResponse> unstableMessageMcp(
    V15MessageMcpRequest params,
  ) async => _decodeTypedResponse(
    await _connection.sendRequest('mcp/message', params.toJson()),
    V15MessageMcpResponse.fromJson,
    fromRawJson: V15MessageMcpResponse.fromJson,
  );

  Future<V15DisconnectMcpResponse> unstableDisconnectMcp(
    V15DisconnectMcpRequest params,
  ) async => _decodeTypedResponse(
    await _connection.sendRequest('mcp/disconnect', params.toJson()),
    V15DisconnectMcpResponse.fromJson,
  );

  Future<void> unstableNotifyMcpMessage(V15MessageMcpNotification params) =>
      _connection.sendNotification('mcp/message', params.toJson());

  @override
  Future<RequestPermissionResponse> requestPermission(
    RequestPermissionRequest params,
  ) async {
    final result = await _connection.sendRequest(
      clientMethods['sessionRequestPermission']!,
      params.toJson(),
    );
    return _decodeTypedResponse(result, RequestPermissionResponse.fromJson);
  }

  @override
  Future<ReadTextFileResponse> readTextFile(ReadTextFileRequest params) async {
    final result = await _connection.sendRequest(
      clientMethods['fsReadTextFile']!,
      params.toJson(),
    );
    return _decodeTypedResponse(result, ReadTextFileResponse.fromJson);
  }

  @override
  Future<WriteTextFileResponse> writeTextFile(
    WriteTextFileRequest params,
  ) async {
    final result = await _connection.sendRequest(
      clientMethods['fsWriteTextFile']!,
      params.toJson(),
    );
    return _decodeTypedResponse(result, WriteTextFileResponse.fromJson);
  }

  @override
  Future<CreateTerminalResponse>? createTerminal(
    CreateTerminalRequest params,
  ) async {
    final result = await _connection.sendRequest(
      clientMethods['terminalCreate']!,
      params.toJson(),
    );
    return _decodeTypedResponse(result, CreateTerminalResponse.fromJson);
  }

  @override
  Future<TerminalOutputResponse>? terminalOutput(
    TerminalOutputRequest params,
  ) async {
    final result = await _connection.sendRequest(
      clientMethods['terminalOutput']!,
      params.toJson(),
    );
    return _decodeTypedResponse(result, TerminalOutputResponse.fromJson);
  }

  @override
  Future<ReleaseTerminalResponse?>? releaseTerminal(
    ReleaseTerminalRequest params,
  ) async {
    final result = await _connection.sendRequest(
      clientMethods['terminalRelease']!,
      params.toJson(),
    );
    return _decodeTypedResponse(result, ReleaseTerminalResponse.fromJson);
  }

  @override
  Future<WaitForTerminalExitResponse>? waitForTerminalExit(
    WaitForTerminalExitRequest params,
  ) async {
    final result = await _connection.sendRequest(
      clientMethods['terminalWaitForExit']!,
      params.toJson(),
    );
    return _decodeTypedResponse(result, WaitForTerminalExitResponse.fromJson);
  }

  @override
  Future<KillTerminalCommandResponse?>? killTerminal(
    KillTerminalCommandRequest params,
  ) async {
    final result = await _connection.sendRequest(
      clientMethods['terminalKill']!,
      params.toJson(),
    );
    return _decodeTypedResponse(result, KillTerminalCommandResponse.fromJson);
  }

  @override
  Future<Map<String, dynamic>>? extMethod(
    String method,
    Map<String, dynamic> params,
  ) async {
    final result = await _connection.sendRequest(method, params);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void>? extNotification(
    String method,
    Map<String, dynamic> params,
  ) async {
    return _connection.sendNotification(method, params);
  }

  /// Sends the protocol-level `$/cancel_request` notification.
  Future<void> sendCancelRequest(CancelRequestNotification params) {
    return _connection.sendCancelRequestNotification(params);
  }

  /// Cancels a pending outbound request and sends `$/cancel_request`.
  Future<bool> cancelPendingRequest(
    RequestId requestId, {
    Map<String, dynamic>? meta,
  }) {
    return _connection.cancelPendingRequest(requestId, meta: meta);
  }
}

/// A client-side connection to an agent.
///
/// This class provides the client's view of an ACP connection, allowing
/// clients (such as code editors) to communicate with agents. It implements
/// the Agent interface to provide methods for initializing sessions, sending
/// prompts, and managing the agent lifecycle.
class ClientSideConnection implements Agent {
  late final Connection _connection;

  /// Creates a new client-side connection to an agent.
  ///
  /// This establishes the communication channel between a client and agent
  /// following the ACP specification.
  ///
  /// [toClient] - A function that creates a Client handler to process incoming agent requests
  /// [stream] - The bidirectional message stream for communication. Typically created using
  ///            ndJsonStream for stdio-based connections.
  ClientSideConnection(
    Client Function(ClientSideConnection) toAgent,
    AcpStream stream,
  ) {
    final client = toAgent(this);

    Future<dynamic> requestHandler(String method, dynamic params) async {
      switch (method) {
        case 'fs/write_text_file':
          final validatedParams = WriteTextFileRequest.fromJson(
            params as Map<String, dynamic>,
          );
          return client.writeTextFile(validatedParams);
        case 'fs/read_text_file':
          final validatedParams = ReadTextFileRequest.fromJson(
            params as Map<String, dynamic>,
          );
          return client.readTextFile(validatedParams);
        case 'session/request_permission':
          final validatedParams = RequestPermissionRequest.fromJson(
            params as Map<String, dynamic>,
          );
          return client.requestPermission(validatedParams);
        case 'elicitation/create':
          if (client is! ClientV15Handler) {
            throw RequestError.methodNotFound(method);
          }
          final result = await (client as ClientV15Handler).createElicitation(
            CreateElicitationRequest.fromJson(params as Map<String, dynamic>),
          );
          if (result == null) throw RequestError.methodNotFound(method);
          return result;
        case 'mcp/connect':
          if (client is! ClientV15Handler) {
            throw RequestError.methodNotFound(method);
          }
          final connected = await (client as ClientV15Handler)
              .unstableConnectMcp(
                V15ConnectMcpRequest.fromJson(params as Map<String, dynamic>),
              );
          if (connected == null) throw RequestError.methodNotFound(method);
          return connected;
        case 'mcp/message':
          if (client is! ClientV15Handler) {
            throw RequestError.methodNotFound(method);
          }
          final response = await (client as ClientV15Handler)
              .unstableMessageMcp(
                V15MessageMcpRequest.fromJson(params as Map<String, dynamic>),
              );
          if (response == null) throw RequestError.methodNotFound(method);
          return response.toJson();
        case 'mcp/disconnect':
          if (client is! ClientV15Handler) {
            throw RequestError.methodNotFound(method);
          }
          final disconnected = await (client as ClientV15Handler)
              .unstableDisconnectMcp(
                V15DisconnectMcpRequest.fromJson(
                  params as Map<String, dynamic>,
                ),
              );
          if (disconnected == null) throw RequestError.methodNotFound(method);
          return disconnected;
        case 'terminal/create':
          final validatedParams = CreateTerminalRequest.fromJson(
            params as Map<String, dynamic>,
          );
          final result = await client.createTerminal(validatedParams);
          if (result == null) {
            throw RequestError.methodNotFound(method);
          }
          return result;
        case 'terminal/output':
          final validatedParams = TerminalOutputRequest.fromJson(
            params as Map<String, dynamic>,
          );
          final result = await client.terminalOutput(validatedParams);
          if (result == null) {
            throw RequestError.methodNotFound(method);
          }
          return result;
        case 'terminal/release':
          final validatedParams = ReleaseTerminalRequest.fromJson(
            params as Map<String, dynamic>,
          );
          final result = await client.releaseTerminal(validatedParams);
          return result ?? {};
        case 'terminal/wait_for_exit':
          final validatedParams = WaitForTerminalExitRequest.fromJson(
            params as Map<String, dynamic>,
          );
          final result = await client.waitForTerminalExit(validatedParams);
          if (result == null) {
            throw RequestError.methodNotFound(method);
          }
          return result;
        case 'terminal/kill':
          final validatedParams = KillTerminalCommandRequest.fromJson(
            params as Map<String, dynamic>,
          );
          final result = await client.killTerminal(validatedParams);
          return result ?? {};
        default:
          if (method.startsWith('_')) {
            final result = await client.extMethod(
              method,
              params as Map<String, dynamic>,
            );
            if (result == null) {
              throw RequestError.methodNotFound(method);
            }
            return result;
          }
          throw RequestError.methodNotFound(method);
      }
    }

    Future<void> notificationHandler(String method, dynamic params) async {
      switch (method) {
        case 'session/update':
          final validatedParams = SessionNotification.fromJson(
            params as Map<String, dynamic>,
          );
          return client.sessionUpdate(validatedParams);
        case 'elicitation/complete':
          if (client is ClientV15Handler) {
            return (client as ClientV15Handler).completeElicitation(
              CompleteElicitationNotification.fromJson(
                params as Map<String, dynamic>,
              ),
            );
          }
          return;
        case 'mcp/message':
          if (client is ClientV15Handler) {
            await (client as ClientV15Handler).unstableHandleMcpNotification(
              V15MessageMcpNotification.fromJson(
                params as Map<String, dynamic>,
              ),
            );
          }
          return;
        case r'$/cancel_request':
          final validatedParams = CancelRequestNotification.fromJson(
            params as Map<String, dynamic>,
          );
          if (client is ProtocolCancellationHandler) {
            return (client as ProtocolCancellationHandler).cancelRequest(
              validatedParams,
            );
          }
          return;
        default:
          if (method.startsWith('_')) {
            await client.extNotification(
              method,
              params as Map<String, dynamic>,
            );
            return;
          }
          if (method.startsWith(r'$/')) {
            // Protocol-level notifications may be ignored by implementations.
            return;
          }
          throw RequestError.methodNotFound(method);
      }
    }

    _connection = Connection(requestHandler, notificationHandler, stream);
  }

  Future<T> _sendTypedRequest<T>(
    String method,
    Map<String, dynamic> params,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final result = await _connection.sendRequest(method, params);
    return _decodeTypedResponse(result, fromJson);
  }

  @override
  Future<InitializeResponse> initialize(InitializeRequest params) async {
    return _sendTypedRequest(
      agentMethods['initialize']!,
      params.toJson(),
      InitializeResponse.fromJson,
    );
  }

  @override
  Future<NewSessionResponse> newSession(NewSessionRequest params) async {
    return _sendTypedRequest(
      agentMethods['sessionNew']!,
      params.toJson(),
      NewSessionResponse.fromJson,
    );
  }

  @override
  Future<LoadSessionResponse>? loadSession(LoadSessionRequest params) async {
    return _sendTypedRequest(
      agentMethods['sessionLoad']!,
      params.toJson(),
      LoadSessionResponse.fromJson,
    );
  }

  @override
  Future<ListSessionsResponse> unstableListSessions(
    ListSessionsRequest params,
  ) async {
    return _sendTypedRequest(
      agentMethods['sessionList']!,
      params.toJson(),
      ListSessionsResponse.fromJson,
    );
  }

  Future<ListSessionsResponse> listSessions(ListSessionsRequest params) =>
      unstableListSessions(params);

  @override
  Future<ForkSessionResponse> unstableForkSession(
    ForkSessionRequest params,
  ) async {
    return _sendTypedRequest(
      agentMethods['sessionFork']!,
      params.toJson(),
      ForkSessionResponse.fromJson,
    );
  }

  @override
  Future<ResumeSessionResponse> unstableResumeSession(
    ResumeSessionRequest params,
  ) async {
    return _sendTypedRequest(
      agentMethods['sessionResume']!,
      params.toJson(),
      ResumeSessionResponse.fromJson,
    );
  }

  Future<ResumeSessionResponse> resumeSession(ResumeSessionRequest params) =>
      unstableResumeSession(params);

  Future<DeleteSessionResponse> deleteSession(
    DeleteSessionRequest params,
  ) async => _decodeTypedResponse(
    await _connection.sendRequest('session/delete', params.toJson()),
    DeleteSessionResponse.fromJson,
  );

  Future<CloseSessionResponse> closeSession(CloseSessionRequest params) async =>
      _decodeTypedResponse(
        await _connection.sendRequest('session/close', params.toJson()),
        CloseSessionResponse.fromJson,
      );

  Future<LogoutResponse> logout(LogoutRequest params) async =>
      _decodeTypedResponse(
        await _connection.sendRequest('logout', params.toJson()),
        LogoutResponse.fromJson,
      );

  Future<V15ListProvidersResponse> unstableListProviders(
    V15ListProvidersRequest params,
  ) async => _decodeTypedResponse(
    await _connection.sendRequest('providers/list', params.toJson()),
    V15ListProvidersResponse.fromJson,
  );

  Future<V15SetProviderResponse> unstableSetProvider(
    V15SetProviderRequest params,
  ) async => _decodeTypedResponse(
    await _connection.sendRequest('providers/set', params.toJson()),
    V15SetProviderResponse.fromJson,
  );

  Future<V15DisableProviderResponse> unstableDisableProvider(
    V15DisableProviderRequest params,
  ) async => _decodeTypedResponse(
    await _connection.sendRequest('providers/disable', params.toJson()),
    V15DisableProviderResponse.fromJson,
  );

  Future<V15MessageMcpResponse> unstableMessageMcp(
    V15MessageMcpRequest params,
  ) async => _decodeTypedResponse(
    await _connection.sendRequest('mcp/message', params.toJson()),
    V15MessageMcpResponse.fromJson,
    fromRawJson: V15MessageMcpResponse.fromJson,
  );

  Future<void> unstableNotifyMcpMessage(V15MessageMcpNotification params) =>
      _connection.sendNotification('mcp/message', params.toJson());

  Future<V15StartNesResponse> unstableStartNes(
    V15StartNesRequest params,
  ) async => _decodeTypedResponse(
    await _connection.sendRequest('nes/start', params.toJson()),
    V15StartNesResponse.fromJson,
  );

  Future<V15SuggestNesResponse> unstableSuggestNes(
    V15SuggestNesRequest params,
  ) async => _decodeTypedResponse(
    await _connection.sendRequest('nes/suggest', params.toJson()),
    V15SuggestNesResponse.fromJson,
  );

  Future<V15CloseNesResponse> unstableCloseNes(
    V15CloseNesRequest params,
  ) async => _decodeTypedResponse(
    await _connection.sendRequest('nes/close', params.toJson()),
    V15CloseNesResponse.fromJson,
  );

  Future<void> unstableDidOpenDocument(V15DidOpenDocumentNotification params) =>
      _connection.sendNotification('document/didOpen', params.toJson());

  Future<void> unstableDidChangeDocument(
    V15DidChangeDocumentNotification params,
  ) => _connection.sendNotification('document/didChange', params.toJson());

  Future<void> unstableDidCloseDocument(
    V15DidCloseDocumentNotification params,
  ) => _connection.sendNotification('document/didClose', params.toJson());

  Future<void> unstableDidSaveDocument(V15DidSaveDocumentNotification params) =>
      _connection.sendNotification('document/didSave', params.toJson());

  Future<void> unstableDidFocusDocument(
    V15DidFocusDocumentNotification params,
  ) => _connection.sendNotification('document/didFocus', params.toJson());

  Future<void> unstableAcceptNes(V15AcceptNesNotification params) =>
      _connection.sendNotification('nes/accept', params.toJson());

  Future<void> unstableRejectNes(V15RejectNesNotification params) =>
      _connection.sendNotification('nes/reject', params.toJson());

  @override
  Future<SetSessionModeResponse?>? setSessionMode(
    SetSessionModeRequest params,
  ) async {
    return _sendTypedRequest(
      agentMethods['sessionSetMode']!,
      params.toJson(),
      SetSessionModeResponse.fromJson,
    );
  }

  @override
  Future<SetSessionConfigOptionResponse> setSessionConfigOption(
    SetSessionConfigOptionRequest params,
  ) async {
    return _sendTypedRequest(
      agentMethods['sessionSetConfigOption']!,
      params.toJson(),
      SetSessionConfigOptionResponse.fromJson,
    );
  }

  @override
  Future<SetSessionModelResponse?>? setSessionModel(
    SetSessionModelRequest params,
  ) async {
    return _sendTypedRequest(
      agentMethods['modelSelect']!,
      params.toJson(),
      SetSessionModelResponse.fromJson,
    );
  }

  @override
  Future<AuthenticateResponse?>? authenticate(
    AuthenticateRequest params,
  ) async {
    return _sendTypedRequest(
      agentMethods['authenticate']!,
      params.toJson(),
      AuthenticateResponse.fromJson,
    );
  }

  @override
  Future<PromptResponse> prompt(PromptRequest params) async {
    return _sendTypedRequest(
      agentMethods['sessionPrompt']!,
      params.toJson(),
      PromptResponse.fromJson,
    );
  }

  @override
  Future<void> cancel(CancelNotification params) async {
    return _connection.sendNotification(
      agentMethods['sessionCancel']!,
      params.toJson(),
    );
  }

  @override
  Future<Map<String, dynamic>>? extMethod(
    String method,
    Map<String, dynamic> params,
  ) async {
    final result = await _connection.sendRequest(method, params);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void>? extNotification(
    String method,
    Map<String, dynamic> params,
  ) async {
    return _connection.sendNotification(method, params);
  }

  /// Sends the protocol-level `$/cancel_request` notification.
  Future<void> sendCancelRequest(CancelRequestNotification params) {
    return _connection.sendCancelRequestNotification(params);
  }

  /// Cancels a pending outbound request and sends `$/cancel_request`.
  Future<bool> cancelPendingRequest(
    RequestId requestId, {
    Map<String, dynamic>? meta,
  }) {
    return _connection.cancelPendingRequest(requestId, meta: meta);
  }
}

/// Abstract base class defining the Agent interface for ACP connections.
///
/// Agents implement this interface to handle requests from clients, including
/// initialization, session management, authentication, and prompt processing.
abstract class Agent {
  /// Establishes the connection with a client and negotiates protocol capabilities.
  ///
  /// This method is called once at the beginning of the connection to:
  /// - Negotiate the protocol version to use
  /// - Exchange capability information between client and agent
  /// - Determine available authentication methods
  ///
  /// The agent should respond with its supported protocol version and capabilities.
  Future<InitializeResponse> initialize(InitializeRequest params);

  /// Creates a new conversation session with the agent.
  ///
  /// Sessions represent independent conversation contexts with their own history and state.
  ///
  /// The agent should:
  /// - Create a new session context
  /// - Connect to any specified MCP servers
  /// - Return a unique session ID for future requests
  ///
  /// May return an `auth_required` error if the agent requires authentication.
  Future<NewSessionResponse> newSession(NewSessionRequest params);

  /// Loads an existing session to resume a previous conversation.
  ///
  /// This method is only available if the agent advertises the `loadSession` capability.
  ///
  /// The agent should:
  /// - Restore the session context and conversation history
  /// - Connect to the specified MCP servers
  /// - Stream the entire conversation history back to the client via notifications
  Future<LoadSessionResponse>? loadSession(LoadSessionRequest params);

  /// Lists existing sessions from the agent.
  ///
  /// **UNSTABLE:** This capability is not part of the spec yet, and may be removed or changed at any point.
  Future<ListSessionsResponse>? unstableListSessions(
    ListSessionsRequest params,
  ) => null;

  /// Forks an existing session to create a new independent session.
  ///
  /// **UNSTABLE:** This capability is not part of the spec yet, and may be removed or changed at any point.
  Future<ForkSessionResponse>? unstableForkSession(ForkSessionRequest params) =>
      null;

  /// Resumes an existing session without replaying previous messages.
  ///
  /// **UNSTABLE:** This capability is not part of the spec yet, and may be removed or changed at any point.
  Future<ResumeSessionResponse>? unstableResumeSession(
    ResumeSessionRequest params,
  ) => null;

  /// Sets the operational mode for a session.
  ///
  /// Allows switching between different agent modes (e.g., "ask", "architect", "code")
  /// that affect system prompts, tool availability, and permission behaviors.
  ///
  /// The mode must be one of the modes advertised in `availableModes` during session
  /// creation or loading. Agents may also change modes autonomously and notify the
  /// client via `current_mode_update` notifications.
  ///
  /// This method can be called at any time during a session, whether the Agent is
  /// idle or actively generating a turn.
  Future<SetSessionModeResponse?>? setSessionMode(SetSessionModeRequest params);

  /// Sets the current value for a session configuration option.
  ///
  /// This method is available when the agent exposes session config options.
  /// The response returns the complete, updated configuration state.
  Future<SetSessionConfigOptionResponse>? setSessionConfigOption(
    SetSessionConfigOptionRequest params,
  ) => null;

  /// Selects the model for a given session.
  ///
  /// **UNSTABLE:** This capability is not part of the spec yet, and may be removed or changed at any point.
  Future<SetSessionModelResponse?>? setSessionModel(
    SetSessionModelRequest params,
  );

  /// Authenticates the client using the specified authentication method.
  ///
  /// Called when the agent requires authentication before allowing session creation.
  /// The client provides the authentication method ID that was advertised during initialization.
  ///
  /// After successful authentication, the client can proceed to create sessions with
  /// `newSession` without receiving an `auth_required` error.
  Future<AuthenticateResponse?>? authenticate(AuthenticateRequest params);

  /// Processes a user prompt within a session.
  ///
  /// This method handles the whole lifecycle of a prompt:
  /// - Receives user messages with optional context (files, images, etc.)
  /// - Processes the prompt using language models
  /// - Reports language model content and tool calls to the Clients
  /// - Requests permission to run tools
  /// - Executes any requested tool calls
  /// - Returns when the turn is complete with a stop reason
  Future<PromptResponse> prompt(PromptRequest params);

  /// Cancels ongoing operations for a session.
  ///
  /// This is a notification sent by the client to cancel an ongoing prompt turn.
  ///
  /// Upon receiving this notification, the Agent SHOULD:
  /// - Stop all language model requests as soon as possible
  /// - Abort all tool call invocations in progress
  /// - Send any pending `session/update` notifications
  /// - Respond to the original `session/prompt` request with `StopReason::Cancelled`
  Future<void> cancel(CancelNotification params);

  /// Extension method
  ///
  /// Allows the Client to send an arbitrary request that is not part of the ACP spec.
  ///
  /// The method name is sent exactly as provided and is not rewritten.
  /// ACP reserves extension methods under the `_` prefix, so callers should
  /// include the leading underscore explicitly when needed.
  Future<Map<String, dynamic>>? extMethod(
    String method,
    Map<String, dynamic> params,
  );

  /// Extension notification
  ///
  /// Allows the Client to send an arbitrary notification that is not part of the ACP spec.
  Future<void>? extNotification(String method, Map<String, dynamic> params);
}

/// Interface for objects that can be asynchronously disposed.
abstract class AsyncDisposable {
  Future<void> dispose();
}

/// A handle for managing terminal operations within a session.
///
/// This class provides methods to interact with a terminal created by an agent,
/// including getting output, waiting for completion, killing processes, and
/// releasing resources.
///
/// Terminal handles are typically created by agents and provided to clients
/// for terminal management operations.
class TerminalHandle implements AsyncDisposable {
  /// The unique identifier for this terminal instance.
  final String id;

  /// Private session identifier for routing requests.
  final String _sessionId;

  /// The connection used to send terminal-related requests.
  final Connection _connection;

  /// Creates a new terminal handle.
  ///
  /// [id] - The unique terminal identifier
  /// [sessionId] - The session this terminal belongs to
  /// [connection] - The connection for sending requests
  TerminalHandle(this.id, this._sessionId, this._connection);

  /// Gets the current terminal output without waiting for the command to exit.
  ///
  /// Returns the current stdout, stderr, and exit status if the command
  /// has already completed.
  Future<TerminalOutputResponse> currentOutput() async {
    final result = await _connection.sendRequest<dynamic>(
      clientMethods['terminalOutput']!,
      {'sessionId': _sessionId, 'terminalId': id},
    );
    if (result is TerminalOutputResponse) return result;
    return TerminalOutputResponse.fromJson(result as Map<String, dynamic>);
  }

  /// Waits for the terminal command to complete and returns its exit status.
  ///
  /// This method blocks until the command finishes execution, then returns
  /// the exit code that indicates the command's success or failure.
  Future<WaitForTerminalExitResponse> waitForExit() async {
    final result = await _connection.sendRequest<dynamic>(
      clientMethods['terminalWaitForExit']!,
      {'sessionId': _sessionId, 'terminalId': id},
    );
    if (result is WaitForTerminalExitResponse) return result;
    return WaitForTerminalExitResponse.fromJson(result as Map<String, dynamic>);
  }

  /// Kills the terminal command without releasing the terminal.
  ///
  /// The terminal remains valid after killing, allowing you to:
  /// - Get the final output with `currentOutput()`
  /// - Check the exit status
  /// - Release the terminal when done
  ///
  /// Useful for implementing timeouts or cancellation.
  Future<KillTerminalCommandResponse> kill() async {
    final result = await _connection.sendRequest<dynamic>(
      clientMethods['terminalKill']!,
      {'sessionId': _sessionId, 'terminalId': id},
    );
    if (result is KillTerminalCommandResponse) return result;
    return KillTerminalCommandResponse.fromJson(result as Map<String, dynamic>);
  }

  /// Releases the terminal and frees all associated resources.
  ///
  /// If the command is still running, it will be killed.
  /// After release, the terminal ID becomes invalid and cannot be used
  /// with other terminal methods.
  ///
  /// Tool calls that already reference this terminal will continue to
  /// display its output.
  ///
  /// **Important:** Always call this method when done with the terminal.
  Future<ReleaseTerminalResponse> release() async {
    final result = await _connection.sendRequest<dynamic>(
      clientMethods['terminalRelease']!,
      {'sessionId': _sessionId, 'terminalId': id},
    );
    return result is ReleaseTerminalResponse
        ? result
        : ReleaseTerminalResponse.fromJson(result as Map<String, dynamic>);
  }

  /// Disposes of the terminal handle and releases resources.
  ///
  /// This is the Dart equivalent of TypeScript's [Symbol.asyncDispose].
  /// It ensures proper cleanup by calling release().
  @override
  Future<void> dispose() async {
    await release();
  }
}
