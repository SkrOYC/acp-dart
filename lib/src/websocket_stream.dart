import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'cookie_store.dart';
import 'stream.dart';

/// Options for [createWebSocketStream].
class WebSocketStreamOptions {
  final Iterable<String>? protocols;
  final Map<String, dynamic>? headers;
  final String cookies;
  final AcpCookieStore? cookieStore;

  const WebSocketStreamOptions({
    this.protocols,
    this.headers,
    this.cookies = 'include',
    this.cookieStore,
  }) : assert(cookies == 'include' || cookies == 'omit');
}

/// Opens a WebSocket ACP stream using JSON text frames.
///
/// The connection opens immediately. Messages use JSON text frames.
AcpStream createWebSocketStream(
  String serverUrl, {
  WebSocketStreamOptions options = const WebSocketStreamOptions(),
}) {
  return _WebSocketAcpStream(serverUrl, options).stream;
}

class _WebSocketAcpStream {
  final String serverUrl;
  final WebSocketStreamOptions options;
  final AcpCookieStore cookieStore;
  final bool ownsCookieStore;
  final _readable = StreamController<Map<String, dynamic>>();
  final _writable = StreamController<Map<String, dynamic>>();
  WebSocket? _socket;
  Future<WebSocket>? _opening;
  Future<void> _writeChain = Future<void>.value();
  bool _closed = false;

  _WebSocketAcpStream(this.serverUrl, this.options)
    : cookieStore = options.cookieStore ?? MemoryAcpCookieStore(),
      ownsCookieStore = options.cookieStore == null {
    _opening = _connect();
    _opening!.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        if (!_readable.isClosed) _readable.addError(error, stack);
      },
    );
    _writable.stream.listen(
      (message) {
        _writeChain = _writeChain.then((_) => _send(message)).catchError((
          Object error,
          StackTrace stack,
        ) {
          if (!_readable.isClosed) _readable.addError(error, stack);
        });
      },
      onError: (Object error, StackTrace stack) =>
          _readable.addError(error, stack),
      onDone: _close,
    );
    _readable.onCancel = _close;
  }

  AcpStream get stream =>
      AcpStream(readable: _readable.stream, writable: _writable.sink);

  Future<void> _send(Map<String, dynamic> message) async {
    if (_closed) throw StateError('ACP WebSocket stream is closed');
    final socket = await (_opening ??= _connect());
    if (_closed) {
      await socket.close();
      throw StateError('ACP WebSocket stream is closed');
    }
    socket.add(jsonEncode(message));
  }

  Future<WebSocket> _connect() async {
    final socket = await WebSocket.connect(
      serverUrl,
      protocols: options.protocols,
      headers: _headers(),
    );
    _socket = socket;
    socket.listen(
      _receive,
      onError: (Object error, StackTrace stack) {
        if (!_readable.isClosed) _readable.addError(error, stack);
      },
      onDone: () {
        _closed = true;
        _clearOwnedCookies();
        if (!_readable.isClosed) unawaited(_readable.close());
      },
      cancelOnError: false,
    );
    return socket;
  }

  Map<String, dynamic>? _headers() {
    final headers = Map<String, dynamic>.from(options.headers ?? const {});
    if (options.cookies == 'include' && cookieStore.cookieHeader != null) {
      final managed = <String, String>{};
      for (final pair in cookieStore.cookieHeader!.split(';')) {
        final separator = pair.indexOf('=');
        if (separator > 0) {
          managed[pair.substring(0, separator).trim()] = pair
              .substring(separator + 1)
              .trim();
        }
      }
      final caller = <String, String>{};
      final current = headers.entries.firstWhere(
        (entry) => entry.key.toLowerCase() == HttpHeaders.cookieHeader,
        orElse: () => const MapEntry('', ''),
      );
      for (final pair
          in (current.value is String ? current.value as String : '').split(
            ';',
          )) {
        final separator = pair.indexOf('=');
        if (separator > 0) {
          caller[pair.substring(0, separator).trim()] = pair
              .substring(separator + 1)
              .trim();
        }
      }
      headers.removeWhere(
        (key, _) => key.toLowerCase() == HttpHeaders.cookieHeader,
      );
      managed.addAll(caller);
      if (managed.isNotEmpty) {
        headers[HttpHeaders.cookieHeader] = managed.entries
            .map((entry) => '${entry.key}=${entry.value}')
            .join('; ');
      }
    }
    return headers.isEmpty ? null : headers;
  }

  void _clearOwnedCookies() {
    if (ownsCookieStore) cookieStore.clear();
  }

  void _receive(dynamic frame) {
    if (frame is! String) {
      _readable.addError(
        const FormatException('Expected WebSocket text frame'),
      );
      return;
    }
    try {
      final value = jsonDecode(frame);
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object');
      }
      _readable.add(value);
    } on FormatException catch (error, stack) {
      _readable.addError(error, stack);
    }
  }

  Future<void> _close() async {
    if (_closed) return;
    _closed = true;
    var socket = _socket;
    if (socket == null && _opening != null) {
      try {
        socket = await _opening;
      } catch (_) {}
    }
    if (socket != null) await socket.close();
    _clearOwnedCookies();
    if (!_readable.isClosed) await _readable.close();
  }
}
