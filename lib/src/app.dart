import 'dart:async';

import 'package:acp_dart/src/acp.dart';
import 'package:acp_dart/src/content_block_converter.dart';
import 'package:acp_dart/src/schema.dart';
import 'package:acp_dart/src/stream.dart';

typedef AppRequestHandler =
    FutureOr<dynamic> Function(dynamic params, AppContext context);
typedef AppNotificationHandler =
    FutureOr<void> Function(dynamic params, AppContext context);
typedef AppConnectHandler = FutureOr<void> Function(AppContext context);
typedef AppOperation<T> = FutureOr<T> Function(AppContext context);
typedef AppParamsParser<Params> = Params Function(Object? params);
typedef AppResponseEncoder<Response> = Object? Function(Response response);
typedef ParsedAppRequestHandler<Params, Response> =
    FutureOr<Response> Function(Params params, AppContext context);
typedef ParsedAppNotificationHandler<Params> =
    FutureOr<void> Function(Params params, AppContext context);

/// Context for making ACP requests and notifications on an active connection.
class AppContext {
  final Connection _connection;
  final Future<ActiveSession> Function(NewSessionRequest request)? _newSession;
  final RequestContext? _requestContext;
  Future<void> _ready = Future<void>.value();

  AppContext._(this._connection, [this._newSession, this._requestContext]);

  Future<void> get ready => _ready;
  Future<void> get closed => _connection.closed;
  bool get isClosed => _connection.isClosed;
  Object? get closeReason => _connection.closeReason;
  Object? get requestId => _requestContext?.requestId;
  bool get isCancelled => _requestContext?.isCancelled ?? false;
  Future<void>? get cancelled => _requestContext?.cancelled;
  Object? get cancelReason => _requestContext?.cancelReason;

  void close([Object? error]) => _connection.close(error);

  void _setReady(Future<void> ready) {
    _ready = ready;
  }

  Future<T> request<T>(
    String method, {
    dynamic params,
    Future<void>? cancellation,
  }) => cancellation == null
      ? _connection.sendRequest<T>(method, params)
      : _connection.sendRequestWithCancellation<T>(
          method,
          cancellation: cancellation,
          params: params,
        );

  Future<void> notify(String method, [dynamic params]) =>
      _connection.sendNotification(method, params);

  SessionBuilder buildSession(String cwd) {
    final start = _newSession;
    if (start == null) {
      throw StateError('Session creation is available from a client context.');
    }
    return SessionBuilder._(NewSessionRequest(cwd: cwd, mcpServers: []), start);
  }
}

/// A started session and its stream of session updates.
class ActiveSession {
  final NewSessionResponse response;
  final Stream<SessionNotification> updates;
  final Future<PromptResponse> Function(
    List<ContentBlock> prompt,
    Future<void>? cancellation,
  )
  _prompt;
  final Future<void> Function() _dispose;

  ActiveSession._(this.response, this.updates, this._prompt, this._dispose);

  String get sessionId => response.sessionId;

  Future<PromptResponse> prompt(Object prompt, {Future<void>? cancellation}) =>
      _prompt(_promptBlocks(prompt), cancellation);

  Future<void> dispose() => _dispose();
}

/// Builder for starting a session.
class SessionBuilder {
  NewSessionRequest _request;
  final Future<ActiveSession> Function(NewSessionRequest request) _start;

  SessionBuilder._(this._request, this._start);

  NewSessionRequest get request => toRequest();

  SessionBuilder withMcpServer(McpServerBase server) {
    _request = NewSessionRequest(
      meta: _request.meta,
      cwd: _request.cwd,
      mcpServers: [..._request.mcpServers, server],
    );
    return this;
  }

  NewSessionRequest toRequest() => NewSessionRequest(
    meta: _request.meta,
    cwd: _request.cwd,
    mcpServers: List.unmodifiable(_request.mcpServers),
  );

  Future<ActiveSession> start() => _start(toRequest());
}

/// Agent-side app with request and notification handlers.
class AgentApp {
  final Map<String, AppRequestHandler> _requests = {};
  final Map<String, AppNotificationHandler> _notifications = {};
  final List<AppConnectHandler> _connectHandlers = [];

  AgentApp onRequest(String method, AppRequestHandler handler) {
    _requests[method] = handler;
    return this;
  }

  AgentApp onRequestParsed<Params, Response>({
    required String method,
    required AppParamsParser<Params> parse,
    required ParsedAppRequestHandler<Params, Response> handler,
    AppResponseEncoder<Response>? encodeResponse,
  }) => onRequest(method, (params, context) async {
    final response = await handler(parse(params), context);
    return encodeResponse == null ? response : encodeResponse(response);
  });

  AgentApp onNotification(String method, AppNotificationHandler handler) {
    _notifications[method] = handler;
    return this;
  }

  AgentApp onNotificationParsed<Params>({
    required String method,
    required AppParamsParser<Params> parse,
    required ParsedAppNotificationHandler<Params> handler,
  }) => onNotification(
    method,
    (params, context) => handler(parse(params), context),
  );

  AgentApp onConnect(AppConnectHandler handler) {
    _connectHandlers.add(handler);
    return this;
  }

  AppContext connect(AcpStream stream) {
    late final AppContext context;
    late final Connection connection;
    Future<dynamic> dispatch(
      String method,
      dynamic params,
      RequestContext? requestContext,
    ) async {
      final handler = _requests[method];
      if (handler == null) throw RequestError.methodNotFound(method);
      return handler(params, AppContext._(connection, null, requestContext));
    }

    connection = Connection(
      (method, params) => dispatch(method, params, null),
      (method, params) async {
        final handler = _notifications[method];
        if (handler != null) await handler(params, context);
      },
      stream,
      requestContextHandler: (method, params, requestContext) =>
          dispatch(method, params, requestContext),
    );
    context = AppContext._(connection);
    _observeReady(
      context,
      _runConnectHandlers(_connectHandlers, context, connection),
    );
    return context;
  }

  Future<T> connectWith<T>(AcpStream stream, AppOperation<T> operation) async {
    final context = connect(stream);
    try {
      await context.ready;
      return await operation(context);
    } finally {
      context.close();
    }
  }
}

/// Client-side app with request and notification handlers.
class ClientApp {
  final Map<String, AppRequestHandler> _requests = {};
  final Map<String, AppNotificationHandler> _notifications = {};
  final List<AppConnectHandler> _connectHandlers = [];

  ClientApp onRequest(String method, AppRequestHandler handler) {
    _requests[method] = handler;
    return this;
  }

  ClientApp onRequestParsed<Params, Response>({
    required String method,
    required AppParamsParser<Params> parse,
    required ParsedAppRequestHandler<Params, Response> handler,
    AppResponseEncoder<Response>? encodeResponse,
  }) => onRequest(method, (params, context) async {
    final response = await handler(parse(params), context);
    return encodeResponse == null ? response : encodeResponse(response);
  });

  ClientApp onNotification(String method, AppNotificationHandler handler) {
    _notifications[method] = handler;
    return this;
  }

  ClientApp onNotificationParsed<Params>({
    required String method,
    required AppParamsParser<Params> parse,
    required ParsedAppNotificationHandler<Params> handler,
  }) => onNotification(
    method,
    (params, context) => handler(parse(params), context),
  );

  ClientApp onConnect(AppConnectHandler handler) {
    _connectHandlers.add(handler);
    return this;
  }

  AppContext connect(AcpStream stream) => _connect(stream);

  Future<T> connectWith<T>(AcpStream stream, AppOperation<T> operation) async {
    final context = _connect(stream);
    try {
      await context.ready;
      return await operation(context);
    } finally {
      context.close();
    }
  }

  AppContext _connect(AcpStream stream) {
    late final AppContext context;
    final sessions = <String, StreamController<SessionNotification>>{};
    late final Connection connection;
    Future<dynamic> dispatch(
      String method,
      dynamic params,
      RequestContext? requestContext,
    ) async {
      final handler = _requests[method];
      if (handler == null) throw RequestError.methodNotFound(method);
      return handler(
        params,
        AppContext._(
          connection,
          (request) => _startSession(connection, sessions, request),
          requestContext,
        ),
      );
    }

    connection = Connection(
      (method, params) => dispatch(method, params, null),
      (method, params) async {
        if (method == clientMethods['sessionUpdate'] && params != null) {
          final notification = params is SessionNotification
              ? params
              : SessionNotification.fromJson(params as Map<String, dynamic>);
          sessions[notification.sessionId]?.add(notification);
        }
        final handler = _notifications[method];
        if (handler != null) await handler(params, context);
      },
      stream,
      requestContextHandler: (method, params, requestContext) =>
          dispatch(method, params, requestContext),
    );
    unawaited(
      connection.closed.then((_) async {
        final controllers = sessions.values.toList();
        sessions.clear();
        for (final controller in controllers) {
          await controller.close();
        }
      }),
    );
    context = AppContext._(
      connection,
      (request) => _startSession(connection, sessions, request),
    );
    _observeReady(
      context,
      _runConnectHandlers(_connectHandlers, context, connection),
    );
    return context;
  }

  Future<ActiveSession> _startSession(
    Connection connection,
    Map<String, StreamController<SessionNotification>> sessions,
    NewSessionRequest request,
  ) async {
    final response = await connection.sendRequest<dynamic>(
      agentMethods['sessionNew']!,
      request.toJson(),
    );
    final parsed = response is NewSessionResponse
        ? response
        : NewSessionResponse.fromJson(response as Map<String, dynamic>);
    final updates = StreamController<SessionNotification>.broadcast();
    sessions[parsed.sessionId] = updates;
    return ActiveSession._(
      parsed,
      updates.stream,
      (prompt, cancellation) async {
        final params = {
          'sessionId': parsed.sessionId,
          'prompt': prompt.map(_encodeContentBlock).toList(),
        };
        final result = cancellation == null
            ? await connection.sendRequest<dynamic>(
                agentMethods['sessionPrompt']!,
                params,
              )
            : await connection.sendRequestWithCancellation<dynamic>(
                agentMethods['sessionPrompt']!,
                cancellation: cancellation,
                params: params,
              );
        return result is PromptResponse
            ? result
            : PromptResponse.fromJson(result as Map<String, dynamic>);
      },
      () async {
        if (identical(sessions[parsed.sessionId], updates)) {
          sessions.remove(parsed.sessionId);
        }
        await updates.close();
      },
    );
  }
}

Future<void> _runConnectHandlers(
  List<AppConnectHandler> handlers,
  AppContext context,
  Connection connection,
) async {
  try {
    for (final handler in handlers) {
      await handler(context);
    }
  } catch (error) {
    connection.close(error);
    rethrow;
  }
}

void _observeReady(AppContext context, Future<void> ready) {
  context._setReady(ready);
  unawaited(ready.catchError((Object _) {}));
}

AgentApp agent() => AgentApp();
ClientApp client() => ClientApp();

List<ContentBlock> _promptBlocks(Object prompt) {
  if (prompt is String) return [TextContentBlock(text: prompt)];
  if (prompt is ContentBlock) return [prompt];
  if (prompt is List<ContentBlock>) return List.of(prompt);
  throw ArgumentError.value(prompt, 'prompt', 'Unsupported prompt content');
}

Map<String, dynamic> _encodeContentBlock(ContentBlock block) =>
    _removeNullFields(const ContentBlockConverter().toJson(block));

Map<String, dynamic> _removeNullFields(Map<String, dynamic> source) {
  final result = <String, dynamic>{};
  for (final entry in source.entries) {
    final value = entry.value;
    if (value == null) continue;
    result[entry.key] = switch (value) {
      Map<String, dynamic>() => _removeNullFields(value),
      List<dynamic>() => value.map(_removeNullValue).toList(),
      _ => value,
    };
  }
  return result;
}

dynamic _removeNullValue(dynamic value) => switch (value) {
  Map<String, dynamic>() => _removeNullFields(value),
  List<dynamic>() => value.map(_removeNullValue).toList(),
  _ => value,
};
