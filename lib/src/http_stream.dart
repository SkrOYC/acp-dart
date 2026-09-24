import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'cookie_store.dart';
import 'stream.dart';

class _UnsupportedSseJsonRpcBatchError extends HttpException {
  _UnsupportedSseJsonRpcBatchError()
    : super('ACP SSE JSON-RPC batches are unsupported');
}

/// Configuration for [createHttpStream].
class HttpStreamOptions {
  final Map<String, String> headers;
  final String cookies;
  final AcpCookieStore? cookieStore;

  const HttpStreamOptions({
    this.headers = const {},
    this.cookies = 'include',
    this.cookieStore,
  }) : assert(cookies == 'include' || cookies == 'omit');
}

/// Opens a Streamable HTTP ACP connection with a POST and a server sent event
/// stream, as defined by ACP v1.5.
AcpStream createHttpStream(
  String serverUrl, {
  HttpStreamOptions options = const HttpStreamOptions(),
}) => _HttpAcpStream(serverUrl, options).stream;

class _HttpAcpStream {
  static const _connectionHeader = 'Acp-Connection-Id';
  final Uri _uri;
  final HttpStreamOptions _options;
  final HttpClient _client = HttpClient();
  final AcpCookieStore _cookieStore;
  final bool _ownsCookieStore;
  final StreamController<Map<String, dynamic>> _readable =
      StreamController<Map<String, dynamic>>();
  final StreamController<Map<String, dynamic>> _writable =
      StreamController<Map<String, dynamic>>();
  String? _connectionId;
  Future<void> _writes = Future<void>.value();
  final Map<String?, Future<void>> _eventStreams = {};
  final Map<String, String> _pendingServerRequestSessions = {};
  final Map<String, String> _pendingSessionRequestSessions = {};
  Future<void>? _closeFuture;
  bool _closed = false;

  _HttpAcpStream(String url, this._options)
    : _uri = Uri.parse(url),
      _cookieStore = optionsStore(_options),
      _ownsCookieStore = _options.cookieStore == null {
    _writable.stream.listen(
      (message) {
        _writes = _writes
            .then((_) => _write(message))
            .catchError(
              (Object error, StackTrace stack) => _fail(error, stack),
            );
      },
      onError: (Object error, StackTrace stack) => _fail(error, stack),
      onDone: _close,
    );
    _readable.onCancel = _close;
  }

  AcpStream get stream =>
      AcpStream(readable: _readable.stream, writable: _writable.sink);

  Future<void> _write(Map<String, dynamic> message) async {
    if (_closed) throw StateError('ACP HTTP stream is closed');
    if (_connectionId == null) {
      if (message['method'] != 'initialize' || !message.containsKey('id')) {
        throw StateError('ACP HTTP stream first message must be initialize');
      }
      final response = await _post(message);
      _storeCookies(response);
      final id = response.headers.value(_connectionHeader);
      if (id == null || id.isEmpty) {
        throw const HttpException(
          'Initialize response missing Acp-Connection-Id',
        );
      }
      _connectionId = id;
      final body = await utf8.decoder.bind(response).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic> ||
          decoded['jsonrpc'] != '2.0' ||
          decoded['id'] != message['id'] ||
          decoded.containsKey('method')) {
        throw const FormatException('Invalid initialize response');
      }
      _readable.add(decoded);
      unawaited(_openEvents(null));
      return;
    }
    final sessionId = _sessionId(message);
    if (sessionId != null) await _openEvents(sessionId);
    final responseId = _responseId(message);
    final routedSession =
        sessionId ??
        (responseId == null ? null : _pendingServerRequestSessions[responseId]);
    if (sessionId != null &&
        message.containsKey('method') &&
        message.containsKey('id')) {
      final requestId = _messageId(message['id']);
      if (requestId != null) {
        _pendingSessionRequestSessions[requestId] = sessionId;
      }
    }
    final request = await _client.postUrl(_uri);
    _setHeaders(request, 'application/json');
    request.headers.set(_connectionHeader, _connectionId!);
    if (routedSession != null) {
      request.headers.set('Acp-Session-Id', routedSession);
    }
    request.write(jsonEncode(message));
    final response = await request.close();
    _storeCookies(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final text = await utf8.decoder.bind(response).join();
      throw HttpException('ACP POST failed: ${response.statusCode} $text');
    }
    await response.drain<void>();
    if (responseId != null && !message.containsKey('method')) {
      _pendingServerRequestSessions.remove(responseId);
    }
  }

  Future<HttpClientResponse> _post(Map<String, dynamic> message) async {
    final request = await _client.postUrl(_uri);
    _setHeaders(request, 'application/json');
    request.write(jsonEncode(message));
    final response = await request.close();
    _storeCookies(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final text = await utf8.decoder.bind(response).join();
      throw HttpException(
        'ACP initialize failed: ${response.statusCode} $text',
      );
    }
    return response;
  }

  void _setHeaders(HttpClientRequest request, String contentType) {
    for (final header in _options.headers.entries) {
      request.headers.set(header.key, header.value);
    }
    request.headers.set(HttpHeaders.contentTypeHeader, contentType);
    _applyCookies(request);
  }

  Future<void> _openEvents(String? sessionId) {
    final existing = _eventStreams[sessionId];
    if (existing != null) return existing;
    final ready = Completer<void>();
    _eventStreams[sessionId] = ready.future;
    ready.future.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    unawaited(_consumeEvents(sessionId, ready));
    return ready.future;
  }

  Future<void> _consumeEvents(String? sessionId, Completer<void> ready) async {
    try {
      final request = await _client.getUrl(_uri);
      for (final header in _options.headers.entries) {
        request.headers.set(header.key, header.value);
      }
      request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      request.headers.set(_connectionHeader, _connectionId!);
      request.headers.removeAll('Acp-Session-Id');
      if (sessionId != null) request.headers.set('Acp-Session-Id', sessionId);
      _applyCookies(request);
      final response = await request.close();
      _storeCookies(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final text = await utf8.decoder.bind(response).join();
        throw HttpException('ACP SSE failed: ${response.statusCode} $text');
      }
      ready.complete();
      var data = <String>[];
      await for (final line
          in response.transform(utf8.decoder).transform(const LineSplitter())) {
        if (_closed) return;
        if (line.isEmpty) {
          _emitEvent(data, sessionId);
          data = [];
        } else if (line.startsWith('data:')) {
          var value = line.substring(5);
          if (value.startsWith(' ')) value = value.substring(1);
          data.add(value);
        }
      }
      _emitEvent(data, sessionId);
      if (!_closed) {
        _eventStreams.remove(sessionId);
        if (sessionId == null) {
          throw const HttpException('ACP connection SSE stream closed');
        }
        if (_pendingSessionRequestSessions.containsValue(sessionId)) {
          throw const HttpException('ACP session SSE stream closed');
        }
      }
    } catch (error, stack) {
      if (!ready.isCompleted) ready.completeError(error, stack);
      if (!_closed) _fail(error, stack);
    }
  }

  void _emitEvent(List<String> data, String? streamSessionId) {
    if (data.isEmpty) return;
    Map<String, dynamic> decoded;
    try {
      final value = jsonDecode(data.join('\n'));
      if (value is List) throw _UnsupportedSseJsonRpcBatchError();
      if (value is! Map<String, dynamic>) return;
      decoded = value;
    } on FormatException {
      return;
    }
    final responseId = _responseId(decoded);
    if (responseId != null) _pendingSessionRequestSessions.remove(responseId);
    if (decoded.containsKey('method') &&
        decoded.containsKey('id') &&
        streamSessionId != null) {
      final requestId = _messageId(decoded['id']);
      if (requestId != null) {
        _pendingServerRequestSessions[requestId] = streamSessionId;
      }
    }
    final responseSessionId = _sessionIdFromResult(decoded);
    if (responseSessionId != null) unawaited(_openEvents(responseSessionId));
    _readable.add(decoded);
  }

  String? _sessionId(Map<String, dynamic> message) {
    final params = message['params'];
    return params is Map<String, dynamic> && params['sessionId'] is String
        ? params['sessionId'] as String
        : null;
  }

  String? _sessionIdFromResult(Map<String, dynamic> message) {
    final result = message['result'];
    return result is Map<String, dynamic> && result['sessionId'] is String
        ? result['sessionId'] as String
        : null;
  }

  String? _responseId(Map<String, dynamic> message) =>
      !message.containsKey('method') ? _messageId(message['id']) : null;

  String? _messageId(dynamic id) => switch (id) {
    String value => 's:$value',
    num value => 'n:$value',
    _ => null,
  };

  void _fail(Object error, StackTrace stack) {
    if (_closed) return;
    _closed = true;
    unawaited(_disposeAfterFailure());
    if (!_readable.isClosed) _readable.addError(error, stack);
    unawaited(_readable.close());
  }

  Future<void> _disposeAfterFailure() async {
    final id = _connectionId;
    if (id != null) {
      try {
        final request = await _client.deleteUrl(_uri);
        for (final header in _options.headers.entries) {
          request.headers.set(header.key, header.value);
        }
        request.headers.set(_connectionHeader, id);
        request.headers.removeAll('Acp-Session-Id');
        _applyCookies(request);
        final response = await request.close();
        _storeCookies(response);
        await response.drain<void>();
      } catch (_) {}
    }
    _client.close(force: true);
    _clearOwnedCookies();
  }

  Future<void> _close() => _closeFuture ??= _closeImpl();

  Future<void> _closeImpl() async {
    await _writes;
    if (_closed) return;
    _closed = true;
    final id = _connectionId;
    if (id != null) {
      try {
        final request = await _client.deleteUrl(_uri);
        for (final header in _options.headers.entries) {
          request.headers.set(header.key, header.value);
        }
        request.headers.set(_connectionHeader, id);
        request.headers.removeAll('Acp-Session-Id');
        _applyCookies(request);
        final response = await request.close();
        _storeCookies(response);
        await response.drain<void>();
      } finally {
        _client.close(force: true);
        _clearOwnedCookies();
      }
    } else {
      _client.close(force: true);
      _clearOwnedCookies();
    }
    if (!_readable.isClosed) await _readable.close();
  }

  void _applyCookies(HttpClientRequest request) {
    if (_options.cookies == 'omit') return;
    final managed = _cookieStore.cookieHeader;
    final supplied = request.headers.value(HttpHeaders.cookieHeader);
    if (managed == null && supplied == null) return;
    final values = <String, String>{};
    for (final cookie in [managed, supplied].whereType<String>()) {
      for (final pair in cookie.split(';')) {
        final separator = pair.indexOf('=');
        if (separator > 0) {
          values[pair.substring(0, separator).trim()] = pair
              .substring(separator + 1)
              .trim();
        }
      }
    }
    request.headers.set(
      HttpHeaders.cookieHeader,
      values.entries.map((entry) => '${entry.key}=${entry.value}').join('; '),
    );
  }

  void _storeCookies(HttpClientResponse response) {
    if (_options.cookies == 'include') {
      _cookieStore.store(
        response.headers[HttpHeaders.setCookieHeader] ?? const [],
      );
    }
  }

  void _clearOwnedCookies() {
    if (_ownsCookieStore) _cookieStore.clear();
  }
}

AcpCookieStore optionsStore(HttpStreamOptions options) =>
    options.cookieStore ?? MemoryAcpCookieStore();
