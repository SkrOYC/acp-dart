import 'dart:async';
import 'dart:convert';

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
}) {
  // Create readable stream: transform bytes to messages
  final readable = input
      .transform(utf8.decoder) // Safely decode bytes to string
      .transform(
        const LineSplitter(),
      ) // Safely split lines, handling partial UTF-8
      .transform(
        StreamTransformer<String, Map<String, dynamic>>.fromHandlers(
          handleData: (line, sink) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) {
              return;
            }

            try {
              final decoded = jsonDecode(trimmed);
              if (decoded is Map<String, dynamic>) {
                sink.add(decoded);
                return;
              }
              onParseError?.call(
                trimmed,
                const FormatException('Expected JSON object'),
              );
            } catch (e) {
              onParseError?.call(trimmed, e);
            }
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
