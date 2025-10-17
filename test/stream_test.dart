import 'dart:async';
import 'dart:convert';

import 'package:acp_dart/src/stream.dart';
import 'package:test/test.dart';

void main() {
  group('NDJSON Stream', () {
    test('ndJsonStream transforms NDJSON bytes to messages', () async {
      final inputController = StreamController<List<int>>();
      final outputController = StreamController<List<int>>();

      final acpStream = ndJsonStream(
        inputController.stream,
        outputController.sink,
      );

      // Test messages
      final messages = [
        {'jsonrpc': '2.0', 'id': 1, 'method': 'initialize', 'params': {}},
        {
          'jsonrpc': '2.0',
          'id': 2,
          'method': 'prompt',
          'params': {'text': 'Hello'},
        },
      ];

      // Send NDJSON data
      final ndjson = '${messages.map((m) => jsonEncode(m)).join('\n')}\n';
      inputController.add(utf8.encode(ndjson));
      inputController.close();

      // Collect received messages
      final received = <Map<String, dynamic>>[];
      final completer = Completer<void>();
      acpStream.readable.listen(
        (message) {
          received.add(message);
        },
        onDone: () {
          completer.complete();
        },
      );

      await completer.future;

      expect(received, equals(messages));

      outputController.close();
    });

    test('ndJsonStream transforms messages to NDJSON bytes', () async {
      final inputController = StreamController<List<int>>();
      final outputController = StreamController<List<int>>();

      final acpStream = ndJsonStream(
        inputController.stream,
        outputController.sink,
      );

      // Test message
      final message = {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {},
      };

      // Send message
      acpStream.writable.add(message);
      acpStream.writable.close();

      // Collect output bytes
      final outputBytes = await outputController.stream.first;
      final outputString = utf8.decode(outputBytes);

      expect(outputString, equals('${jsonEncode(message)}\n'));

      inputController.close();
      outputController.close();
    });

    test('handles partial lines correctly', () async {
      final inputController = StreamController<List<int>>();
      final outputController = StreamController<List<int>>();

      final acpStream = ndJsonStream(
        inputController.stream,
        outputController.sink,
      );

      // Send partial message in chunks
      final message = {'jsonrpc': '2.0', 'id': 1, 'method': 'test'};
      final jsonStr = jsonEncode(message);
      final chunk1 = jsonStr.substring(0, 10);
      final chunk2 = '${jsonStr.substring(10)}\n';

      inputController.add(utf8.encode(chunk1));
      inputController.add(utf8.encode(chunk2));
      inputController.close();

      final received = <Map<String, dynamic>>[];
      final completer = Completer<void>();
      acpStream.readable.listen(
        (msg) => received.add(msg),
        onDone: () => completer.complete(),
      );

      await completer.future;
      expect(received, equals([message]));

      outputController.close();
    });

    test('handles multiple messages in single chunk', () async {
      final inputController = StreamController<List<int>>();
      final outputController = StreamController<List<int>>();

      final acpStream = ndJsonStream(
        inputController.stream,
        outputController.sink,
      );

      final messages = [
        {'jsonrpc': '2.0', 'id': 1, 'method': 'test1'},
        {'jsonrpc': '2.0', 'id': 2, 'method': 'test2'},
      ];

      final ndjson = '${messages.map(jsonEncode).join('\n')}\n';
      inputController.add(utf8.encode(ndjson));
      inputController.close();

      final received = <Map<String, dynamic>>[];
      final completer = Completer<void>();
      acpStream.readable.listen(
        (msg) => received.add(msg),
        onDone: () => completer.complete(),
      );

      await completer.future;
      expect(received, equals(messages));

      outputController.close();
    });

    test('ignores empty lines', () async {
      final inputController = StreamController<List<int>>();
      final outputController = StreamController<List<int>>();

      final acpStream = ndJsonStream(
        inputController.stream,
        outputController.sink,
      );

      final message = {'jsonrpc': '2.0', 'id': 1, 'method': 'test'};
      final ndjson = '\n\n${jsonEncode(message)}\n\n';
      inputController.add(utf8.encode(ndjson));
      inputController.close();

      final received = <Map<String, dynamic>>[];
      final completer = Completer<void>();
      acpStream.readable.listen(
        (msg) => received.add(msg),
        onDone: () => completer.complete(),
      );

      await completer.future;
      expect(received, equals([message]));

      outputController.close();
    });

    test('propagates JSON parsing errors and stops stream', () async {
      final inputController = StreamController<List<int>>();
      final outputController = StreamController<List<int>>();

      final acpStream = ndJsonStream(
        inputController.stream,
        outputController.sink,
      );

      // Send a valid message, then an invalid message
      inputController.add(utf8.encode('{"valid": "json"}\n'));
      inputController.add(utf8.encode('invalid json\n'));
      inputController.close();

      final received = <Map<String, dynamic>>[];
      final errorCompleter = Completer<Object?>();
      final doneCompleter = Completer<void>();
      var completed = false;

      void complete() {
        if (!completed) {
          completed = true;
          doneCompleter.complete();
        }
      }

      acpStream.readable.listen(
        (msg) => received.add(msg),
        onError: (e) {
          errorCompleter.complete(e);
          complete();
        },
        onDone: () {
          if (!errorCompleter.isCompleted) {
            errorCompleter.complete(null); // No error occurred
          }
          complete();
        },
      );

      await doneCompleter.future;

      // Expect the valid message to be received
      expect(
        received,
        equals([
          {'valid': 'json'},
        ]),
      );
      // Expect the stream to have terminated with a FormatException
      expect(errorCompleter.isCompleted, isTrue);
      expect(await errorCompleter.future, isA<FormatException>());

      outputController.close();
    });
  });
}
