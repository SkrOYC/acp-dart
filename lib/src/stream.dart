import 'dart:async';
import 'dart:convert';

class _UnsupportedJsonRpcBatchError extends TypeError {
  @override
  String toString() => 'JSON-RPC batches are unsupported on ACP v1 connections';
}

/// Stream interface for ACP connections.
///
/// This type powers the bidirectional communication for an ACP connection,
/// providing readable and writable streams of messages.
///
/// The most common way to create an `AcpStream` is using `ndJsonStream`.
class AcpStream {
  final Stream<Map<String, dynamic>> readable;
  final StreamSink<Map<String, dynamic>> writable;

  AcpStream({required this.readable, required this.writable});
}

/// Creates an ACP Stream from a pair of newline-delimited JSON streams.
///
/// This is the typical way to handle ACP connections over stdio, converting
/// between `Map<String, dynamic>` objects and newline-delimited JSON.
///
/// `input` - The readable stream to receive encoded messages from
/// `output` - The writable stream to send encoded messages to
/// `onParseError` - Optional callback invoked when a non-empty line cannot be
/// parsed as a JSON object.
/// Returns an AcpStream for bidirectional ACP communication
AcpStream ndJsonStream(
  Stream<List<int>> input,
  StreamSink<List<int>> output, {
  void Function(String line, Object error)? onParseError,
  int? maxLineBytes,
}) {
  if (maxLineBytes != null && maxLineBytes < 1) {
    throw ArgumentError.value(maxLineBytes, 'maxLineBytes');
  }
  final pending = <int>[];
  var overlong = false;

  void protocolError(int code, String message, [Object? data]) {
    output.add(
      utf8.encode(
        '${jsonEncode({
          'jsonrpc': '2.0',
          'id': null,
          'error': {'code': code, 'message': message, if (data != null) 'data': data},
        })}\n',
      ),
    );
  }

  void report(String line, Object error) {
    onParseError?.call(line, error);
  }

  void consume(List<int> bytes, EventSink<Map<String, dynamic>> sink) {
    final line = utf8.decode(bytes, allowMalformed: false).trim();
    if (line.isEmpty) return;
    dynamic decoded;
    try {
      decoded = jsonDecode(line);
    } on FormatException catch (error) {
      report(line, error);
      protocolError(-32700, 'Parse error');
      return;
    }
    if (decoded is Map<String, dynamic>) {
      sink.add(decoded);
    } else if (decoded is List) {
      sink.addError(_UnsupportedJsonRpcBatchError());
    } else {
      report(line, const FormatException('Expected JSON object'));
      protocolError(-32600, 'Invalid request', decoded);
    }
  }

  final readable = input.transform(
    StreamTransformer<List<int>, Map<String, dynamic>>.fromHandlers(
      handleData: (chunk, sink) {
        for (final byte in chunk) {
          if (byte == 10) {
            if (overlong) {
              report(
                '',
                const FormatException('NDJSON line exceeds maxLineBytes'),
              );
              overlong = false;
              pending.clear();
            } else {
              try {
                consume(pending, sink);
              } on FormatException catch (error) {
                report('', error);
                protocolError(-32700, 'Parse error');
              }
              pending.clear();
            }
          } else if (!overlong) {
            if (maxLineBytes != null && pending.length >= maxLineBytes) {
              overlong = true;
              pending.clear();
            } else {
              pending.add(byte);
            }
          }
        }
      },
      handleError: (error, stackTrace, sink) =>
          sink.addError(error, stackTrace),
      handleDone: (sink) {
        if (overlong) {
          report('', const FormatException('NDJSON line exceeds maxLineBytes'));
        } else if (pending.isNotEmpty) {
          try {
            consume(pending, sink);
          } on FormatException catch (error) {
            report('', error);
            protocolError(-32700, 'Parse error');
          }
        }
        sink.close();
      },
    ),
  );

  // Create writable stream: transform messages to bytes
  final writableController = StreamController<Map<String, dynamic>>();
  final writable = writableController.sink;

  // Listen to messages and encode them to NDJSON
  writableController.stream.listen(
    (message) {
      final jsonString = '${jsonEncode(message)}\n';
      final bytes = utf8.encode(jsonString);
      output.add(bytes);
    },
    onError: (error, stackTrace) {
      // Handle encoding errors
      output.addError(error, stackTrace);
    },
    onDone: () {
      output.close();
    },
  );

  return AcpStream(readable: readable, writable: writable);
}
