import 'dart:async';

import 'package:acp_dart/src/acp.dart';
import 'package:acp_dart/src/schema.dart';
import 'package:acp_dart/src/stream.dart';

typedef AppRequestHandler =
    FutureOr<dynamic> Function(dynamic params, AppContext context);
typedef AppNotificationHandler =
    FutureOr<void> Function(dynamic params, AppContext context);
typedef AppConnectHandler = FutureOr<void> Function(AppContext context);
typedef AppOperation<T> = FutureOr<T> Function(AppContext context);

/// Context for making ACP requests and notifications on an active connection.
class AppContext {
  final Connection _connection;
  final Future<ActiveSession> Function(NewSessionRequest request)? _newSession;

  AppContext._(this._connection, [this._newSession]);

  Future<T> request<T>(String method, [dynamic params]) =>
      _connection.sendRequest<T>(method, params);

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
  final Future<PromptResponse> Function(List<ContentBlock> prompt) _prompt;
  final Future<void> Function() _dispose;

  ActiveSession._(this.response, this.updates, this._prompt, this._dispose);

  String get sessionId => response.sessionId;

  Future<PromptResponse> prompt(String text) =>
      _prompt([TextContentBlock(text: text)]);

  Future<void> dispose() => _dispose();
}

/// Builder for starting a session.
class SessionBuilder {
  NewSessionRequest _request;
  final Future<ActiveSession> Function(NewSessionRequest request) _start;

  SessionBuilder._(this._request, this._start);

  NewSessionRequest get request => _request;

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

  AgentApp onNotification(String method, AppNotificationHandler handler) {
    _notifications[method] = handler;
    return this;
  }

  AgentApp onConnect(AppConnectHandler handler) {
    _connectHandlers.add(handler);
    return this;
  }

  AppContext connect(AcpStream stream) {
    late final AppContext context;
    final connection = Connection(
      (method, params) async {
        final handler = _requests[method];
        if (handler == null) throw RequestError.methodNotFound(method);
        return handler(params, context);
      },
      (method, params) async {
        final handler = _notifications[method];
        if (handler != null) await handler(params, context);
      },
      stream,
    );
    context = AppContext._(connection);
    for (final handler in _connectHandlers) {
      unawaited(Future<void>.sync(() => handler(context)));
    }
    return context;
  }

  Future<T> connectWith<T>(AcpStream stream, AppOperation<T> operation) async {
    return await operation(connect(stream));
  }
}

/// Client-side app with request and notification handlers.
class ClientApp {
  final Map<String, AppRequestHandler> _requests = {};
  final Map<String, AppNotificationHandler> _notifications = {};
  final List<AppConnectHandler> _connectHandlers = [];
  final Map<String, StreamController<SessionNotification>> _sessions = {};

  ClientApp onRequest(String method, AppRequestHandler handler) {
    _requests[method] = handler;
    return this;
  }

  ClientApp onNotification(String method, AppNotificationHandler handler) {
    _notifications[method] = handler;
    return this;
  }

  ClientApp onConnect(AppConnectHandler handler) {
    _connectHandlers.add(handler);
    return this;
  }

  AppContext connect(AcpStream stream) => _connect(stream);

  Future<T> connectWith<T>(AcpStream stream, AppOperation<T> operation) async {
    return await operation(_connect(stream));
  }

  AppContext _connect(AcpStream stream) {
    late final AppContext context;
    final connection = Connection(
      (method, params) async {
        final handler = _requests[method];
        if (handler == null) throw RequestError.methodNotFound(method);
        return handler(params, context);
      },
      (method, params) async {
        if (method == clientMethods['sessionUpdate'] && params != null) {
          final notification = params is SessionNotification
              ? params
              : SessionNotification.fromJson(params as Map<String, dynamic>);
          _sessions[notification.sessionId]?.add(notification);
        }
        final handler = _notifications[method];
        if (handler != null) await handler(params, context);
      },
      stream,
    );
    context = AppContext._(
      connection,
      (request) => _startSession(connection, request),
    );
    for (final handler in _connectHandlers) {
      unawaited(Future<void>.sync(() => handler(context)));
    }
    return context;
  }

  Future<ActiveSession> _startSession(
    Connection connection,
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
    _sessions[parsed.sessionId] = updates;
    return ActiveSession._(
      parsed,
      updates.stream,
      (prompt) async {
        final result = await connection.sendRequest<dynamic>(
          agentMethods['sessionPrompt']!,
          {
            'sessionId': parsed.sessionId,
            'prompt': prompt
                .map(
                  (block) => switch (block) {
                    TextContentBlock(:final text) => {
                      'type': 'text',
                      'text': text,
                    },
                    _ => throw ArgumentError.value(
                      block,
                      'prompt',
                      'Unsupported content block',
                    ),
                  },
                )
                .toList(),
          },
        );
        return result is PromptResponse
            ? result
            : PromptResponse.fromJson(result as Map<String, dynamic>);
      },
      () async {
        if (identical(_sessions[parsed.sessionId], updates)) {
          _sessions.remove(parsed.sessionId);
        }
        await updates.close();
      },
    );
  }
}

AgentApp agent() => AgentApp();
ClientApp client() => ClientApp();
