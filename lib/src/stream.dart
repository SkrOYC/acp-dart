import 'dart:async';
import 'dart:convert';

/// Stream interface for ACP connections.
///
/// This type powers the bidirectional communication for an ACP connection,
/// providing readable and writable streams of messages.
///
/// The most common way to create an AcpStream is using [ndJsonStream].
class AcpStream {
  final Stream<Map<String, dynamic>> readable;
  final StreamSink<Map<String, dynamic>> writable;

  AcpStream({required this.readable, required this.writable});
}

/// Creates an ACP Stream from a pair of newline-delimited JSON streams.
///
/// This is the typical way to handle ACP connections over stdio, converting
/// between Map<String, dynamic> objects and newline-delimited JSON.
///
/// [input] - The readable stream to receive encoded messages from
/// [output] - The writable stream to send encoded messages to
/// Returns an AcpStream for bidirectional ACP communication
AcpStream ndJsonStream(Stream<List<int>> input, StreamSink<List<int>> output) {
  // Create readable stream: transform bytes to messages
  final readableController = StreamController<Map<String, dynamic>>();
  final decoder = _NdJsonDecoder();
  input.listen(
    (data) => decoder._handleData(data, readableController),
    onError: (error, stackTrace) => readableController.addError(error, stackTrace),
    onDone: () {
      decoder._handleDone(readableController);
      readableController.close();
    },
  );
  final readable = readableController.stream;

  // Create writable stream: transform messages to bytes
  final writableController = StreamController<Map<String, dynamic>>();
  final writable = writableController.sink;

  // Listen to messages and encode them to NDJSON
  writableController.stream.listen(
    (message) {
      final jsonString = jsonEncode(message) + '\n';
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

/// Decoder that converts NDJSON bytes to Map<String, dynamic> messages
class _NdJsonDecoder {
  String _buffer = '';

  void _handleData(List<int> data, StreamController<Map<String, dynamic>> controller) {
    _buffer += utf8.decode(data);
    final lines = _buffer.split('\n');
    _buffer = lines.removeLast(); // Keep incomplete line in buffer

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        try {
          final message = jsonDecode(trimmed) as Map<String, dynamic>;
          controller.add(message);
        } catch (e) {
          // Log parsing errors but continue
          print('Failed to parse JSON message: $trimmed, error: $e');
        }
      }
    }
  }

  void _handleDone(StreamController<Map<String, dynamic>> controller) {
    // Process any remaining data in buffer
    final trimmed = _buffer.trim();
    if (trimmed.isNotEmpty) {
      try {
        final message = jsonDecode(trimmed) as Map<String, dynamic>;
        controller.add(message);
      } catch (e) {
        print('Failed to parse final JSON message: $trimmed, error: $e');
      }
    }
  }
}