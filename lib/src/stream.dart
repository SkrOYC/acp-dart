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
/// Returns an AcpStream for bidirectional ACP communication
AcpStream ndJsonStream(Stream<List<int>> input, StreamSink<List<int>> output) {
  // Create readable stream: transform bytes to messages
  final readable = input
      .transform(utf8.decoder) // Safely decode bytes to string
      .transform(const LineSplitter()) // Safely split lines, handling partial UTF-8
      .where((line) => line.trim().isNotEmpty) // Filter empty lines
      .map((line) {
        try {
          return jsonDecode(line) as Map<String, dynamic>;
        } catch (e) {
          // Propagate the error to the stream listener
          throw FormatException('Failed to parse JSON message: $line, error: $e');
        }
      });

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