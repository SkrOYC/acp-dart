import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'acp.dart';
import 'stream.dart';

const _connectionHeader = 'Acp-Connection-Id';
const _sessionHeader = 'Acp-Session-Id';

typedef AcpAgentFactory = Agent Function(AgentSideConnection connection);

/// ACP v1.5 Streamable HTTP server over a Dart [HttpServer].
class AcpHttpServer {
  AcpHttpServer._(this._server, this._agentFactory) {
    _server.listen(_handle);
  }

  final HttpServer _server;
  final AcpAgentFactory _agentFactory;
  final Map<String, _HttpConnection> _connections = {};
  int _nextConnection = 0;

  InternetAddress get address => _server.address;
  int get port => _server.port;

  static Future<AcpHttpServer> bind(
    Object address,
    int port, {
    required AcpAgentFactory agentFactory,
  }) async {
    final server = await HttpServer.bind(address, port);
    return AcpHttpServer._(server, agentFactory);
  }

  Future<void> close() async {
    await _server.close(force: true);
    for (final connection in _connections.values) {
      await connection.close();
    }
    _connections.clear();
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      switch (request.method) {
        case 'POST':
          await _post(request);
        case 'GET':
          await _get(request);
        case 'DELETE':
          await _delete(request);
        default:
          await _text(request.response, 405, 'Method Not Allowed');
      }
    } catch (_) {
      try {
        await _text(request.response, 500, 'Internal Server Error');
      } catch (_) {}
    }
  }

  Future<void> _post(HttpRequest request) async {
    if (request.headers.contentType?.mimeType != 'application/json') {
      await _text(request.response, 415, 'Unsupported Media Type');
      return;
    }
    dynamic message;
    try {
      message = jsonDecode(await utf8.decoder.bind(request).join());
    } on FormatException {
      await _text(request.response, 400, 'Invalid JSON');
      return;
    }
    if (message is List) {
      await _text(
        request.response,
        501,
        'Batch JSON-RPC requests are not implemented',
      );
      return;
    }
    if (message is! Map<String, dynamic>) {
      await _text(request.response, 400, 'Invalid JSON-RPC message');
      return;
    }
    final connectionId = request.headers.value(_connectionHeader);
    if (message['method'] == 'initialize') {
      if (connectionId != null) {
        await _text(
          request.response,
          400,
          'Initialize not allowed on existing connection',
        );
        return;
      }
      await _initialize(request, message);
      return;
    }
    if (connectionId == null) {
      await _text(request.response, 400, 'Missing Acp-Connection-Id');
      return;
    }
    final connection = _connections[connectionId];
    if (connection == null) {
      await _text(request.response, 404, 'Unknown Acp-Connection-Id');
      return;
    }
    final method = message['method'];
    final params = message['params'];
    final sessionId = request.headers.value(_sessionHeader);
    final paramsSession = params is Map ? params['sessionId'] : null;
    if ((method is String && _requiresSession(method) ||
            paramsSession != null) &&
        sessionId == null) {
      await _text(request.response, 400, 'Missing Acp-Session-Id');
      return;
    }
    if (sessionId != null &&
        paramsSession != null &&
        paramsSession != sessionId) {
      await _text(request.response, 400, 'Mismatched Acp-Session-Id');
      return;
    }
    if (message['id'] != null && message['method'] is String) {
      connection.responseRoutes[message['id']] =
          sessionId == null || message['method'] == 'session/load'
          ? null
          : sessionId;
    }
    connection.inbound.add(message);
    request.response.statusCode = 202;
    await request.response.close();
  }

  Future<void> _initialize(
    HttpRequest request,
    Map<String, dynamic> message,
  ) async {
    final id = message['id'];
    if (id == null || message['params'] is! Map<String, dynamic>) {
      await _text(
        request.response,
        400,
        'Initialize request must include an ID and params',
      );
      return;
    }
    late final _HttpConnection connection;
    try {
      connection = _HttpConnection('acp-${++_nextConnection}', _agentFactory);
      _connections[connection.id] = connection;
      connection.expectInitial(id);
      connection.inbound.add(message);
      final response = await connection.initialResponse.future.timeout(
        const Duration(seconds: 30),
      );
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      request.response.headers.set(_connectionHeader, connection.id);
      request.response.write(jsonEncode(response));
      await request.response.close();
    } catch (error) {
      if (_connections[connection.id] != null) {
        _connections.remove(connection.id);
        await connection.close();
      }
      request.response.statusCode = 500;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': id,
          'error': {
            'code': -32603,
            'message': 'Initialize failed',
            'data': '$error',
          },
        }),
      );
      await request.response.close();
    }
  }

  Future<void> _get(HttpRequest request) async {
    if (request.headers.value(HttpHeaders.upgradeHeader)?.toLowerCase() ==
        'websocket') {
      await _text(
        request.response,
        426,
        'WebSocket upgrade is not implemented',
      );
      return;
    }
    if (!(request.headers.value(HttpHeaders.acceptHeader) ?? '')
        .toLowerCase()
        .contains('text/event-stream')) {
      await _text(request.response, 406, 'Not Acceptable');
      return;
    }
    final id = request.headers.value(_connectionHeader);
    if (id == null) {
      await _text(request.response, 400, 'Missing Acp-Connection-Id');
      return;
    }
    final connection = _connections[id];
    if (connection == null) {
      await _text(request.response, 404, 'Unknown Acp-Connection-Id');
      return;
    }
    final sessionId = request.headers.value(_sessionHeader);
    final queue = sessionId == null
        ? connection.connectionQueue
        : connection.sessionQueue(sessionId);
    if (!queue.acquire()) {
      await _text(
        request.response,
        409,
        'Outbound stream already has an active receiver',
      );
      return;
    }
    final response = request.response;
    response.bufferOutput = false;
    response.statusCode = 200;
    response.headers.set(HttpHeaders.contentTypeHeader, 'text/event-stream');
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
    response.headers.set(HttpHeaders.connectionHeader, 'keep-alive');
    try {
      response.write(':\n\n');
      await response.flush();
      while (true) {
        final message = await queue.take();
        if (message == null) break;
        response.write('data: ${jsonEncode(message)}\n\n');
        await response.flush();
      }
    } on IOException {
      // Client disconnected.
    } finally {
      queue.release();
      await response.close();
    }
  }

  Future<void> _delete(HttpRequest request) async {
    final id = request.headers.value(_connectionHeader);
    if (id == null) {
      await _text(request.response, 400, 'Missing Acp-Connection-Id');
    } else {
      final connection = _connections.remove(id);
      if (connection == null) {
        await _text(request.response, 404, 'Unknown Acp-Connection-Id');
      } else {
        await connection.close();
        request.response.statusCode = 202;
        await request.response.close();
      }
    }
  }

  static Future<void> _text(
    HttpResponse response,
    int status,
    String text,
  ) async {
    response.statusCode = status;
    response.headers.contentType = ContentType.text;
    response.write(text);
    await response.close();
  }
}

bool _requiresSession(String method) => const {
  'session/cancel',
  'session/close',
  'session/delete',
  'session/fork',
  'session/load',
  'session/prompt',
  'session/resume',
  'session/set_config_option',
  'session/set_mode',
  'session/set_model',
  'nes/suggest',
  'nes/accept',
  'nes/reject',
  'nes/close',
  'document/didOpen',
  'document/didChange',
  'document/didClose',
  'document/didSave',
  'document/didFocus',
}.contains(method);

class _HttpConnection {
  _HttpConnection(this.id, AcpAgentFactory factory) {
    final outgoing = StreamController<Map<String, dynamic>>();
    outgoing.stream.listen(_handleOutgoing);
    final stream = AcpStream(readable: inbound.stream, writable: outgoing.sink);
    AgentSideConnection(factory, stream);
  }

  final String id;
  final inbound = StreamController<Map<String, dynamic>>();
  final connectionQueue = _MessageQueue();
  final Map<String, _MessageQueue> _sessionQueues = {};
  final Map<dynamic, String?> responseRoutes = {};
  final initialResponse = Completer<Map<String, dynamic>>();
  dynamic _initialId;

  void expectInitial(dynamic id) => _initialId = id;

  _MessageQueue sessionQueue(String id) =>
      _sessionQueues.putIfAbsent(id, _MessageQueue.new);

  void _handleOutgoing(Map<String, dynamic> message) {
    message = _jsonMap(message);
    if (message['id'] != null && message['id'] == _initialId) {
      _initialId = null;
      if (!initialResponse.isCompleted) initialResponse.complete(message);
      return;
    }
    if (!message.containsKey('method') && message.containsKey('id')) {
      final routeExists = responseRoutes.containsKey(message['id']);
      final route = responseRoutes.remove(message['id']);
      if (routeExists && route is String && route.isNotEmpty) {
        sessionQueue(route).add(message);
      } else {
        connectionQueue.add(message);
      }
      return;
    }
    final params = message['params'];
    final session = params is Map ? params['sessionId'] : null;
    (session is String ? sessionQueue(session) : connectionQueue).add(message);
  }

  Future<void> close() async {
    await inbound.close();
    connectionQueue.close();
    for (final queue in _sessionQueues.values) {
      queue.close();
    }
  }
}

Map<String, dynamic> _jsonMap(Map<String, dynamic> value) =>
    jsonDecode(
          jsonEncode(
            value,
            toEncodable: (object) {
              try {
                return (object as dynamic).toJson();
              } on NoSuchMethodError {
                throw UnsupportedError('ACP output value has no toJson method');
              }
            },
          ),
        )
        as Map<String, dynamic>;

class _MessageQueue {
  final List<Map<String, dynamic>> _messages = [];
  final List<Completer<Map<String, dynamic>?>> _waiters = [];
  bool _closed = false;
  bool _acquired = false;

  bool acquire() {
    if (_acquired) return false;
    _acquired = true;
    return true;
  }

  void release() => _acquired = false;

  void add(Map<String, dynamic> message) {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete(message);
    } else if (!_closed) {
      _messages.add(message);
    }
  }

  Future<Map<String, dynamic>?> take() {
    if (_messages.isNotEmpty) return Future.value(_messages.removeAt(0));
    if (_closed) return Future.value(null);
    final waiter = Completer<Map<String, dynamic>?>();
    _waiters.add(waiter);
    return waiter.future;
  }

  void close() {
    _closed = true;
    for (final waiter in _waiters) {
      waiter.complete(null);
    }
    _waiters.clear();
  }
}
