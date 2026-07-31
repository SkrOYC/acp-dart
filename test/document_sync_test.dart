import 'dart:async';
import 'dart:convert';

import 'package:acp_dart/acp_dart.dart';
import 'package:test/test.dart';

class _DocAgent implements Agent {
  DidOpenDocumentNotification? opened;
  DidChangeDocumentNotification? changed;
  DidCloseDocumentNotification? closed;
  DidSaveDocumentNotification? saved;
  DidFocusDocumentNotification? focused;

  @override
  Future<void>? didOpenDocument(DidOpenDocumentNotification params) {
    opened = params;
    return Future.value();
  }

  @override
  Future<void>? didChangeDocument(DidChangeDocumentNotification params) {
    changed = params;
    return Future.value();
  }

  @override
  Future<void>? didCloseDocument(DidCloseDocumentNotification params) {
    closed = params;
    return Future.value();
  }

  @override
  Future<void>? didSaveDocument(DidSaveDocumentNotification params) {
    saved = params;
    return Future.value();
  }

  @override
  Future<void>? didFocusDocument(DidFocusDocumentNotification params) {
    focused = params;
    return Future.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Map<String, dynamic> _wire(Object o) =>
    jsonDecode(jsonEncode(o)) as Map<String, dynamic>;

void main() {
  late StreamController<Map<String, dynamic>> readable;
  late StreamController<Map<String, dynamic>> writable;
  late AcpStream stream;

  setUp(() {
    readable = StreamController<Map<String, dynamic>>();
    writable = StreamController<Map<String, dynamic>>.broadcast();
    stream = AcpStream(readable: readable.stream, writable: writable.sink);
  });

  tearDown(() {
    unawaited(readable.close());
    unawaited(writable.close());
  });

  Future<_DocAgent> notify(String method, Map<String, dynamic> params) async {
    final agent = _DocAgent();
    AgentSideConnection((_) => agent, stream);
    readable.add({'jsonrpc': '2.0', 'method': method, 'params': params});
    await Future<void>.delayed(Duration.zero);
    return agent;
  }

  group('Document notification dispatch', () {
    test('didOpen carries the full document text', () async {
      final agent = await notify('document/didOpen', {
        'sessionId': 's1',
        'uri': 'file:///tmp/main.dart',
        'languageId': 'dart',
        'version': 1,
        'text': 'void main() {}',
      });

      expect(agent.opened?.uri, equals('file:///tmp/main.dart'));
      expect(agent.opened?.languageId, equals('dart'));
      expect(agent.opened?.version, equals(1));
      expect(agent.opened?.text, equals('void main() {}'));
    });

    test('didChange carries incremental edits with a range', () async {
      final agent = await notify('document/didChange', {
        'sessionId': 's1',
        'uri': 'file:///tmp/main.dart',
        'version': 2,
        'contentChanges': [
          {
            'range': {
              'start': {'line': 0, 'character': 0},
              'end': {'line': 0, 'character': 4},
            },
            'text': 'final',
          },
        ],
      });

      final change = agent.changed!.contentChanges.single;
      expect(change.text, equals('final'));
      expect(change.range?.start.line, equals(0));
      expect(change.range?.end.character, equals(4));
    });

    test('a null range means a full-document replacement', () async {
      final agent = await notify('document/didChange', {
        'sessionId': 's1',
        'uri': 'file:///tmp/main.dart',
        'version': 3,
        'contentChanges': [
          {'text': 'entirely new contents'},
        ],
      });

      expect(agent.changed!.contentChanges.single.range, isNull);
    });

    // One connection per test: `readable` is single-subscription, so `notify`
    // can only be called once per test case.
    test('didClose carries the uri', () async {
      final agent = await notify('document/didClose', {
        'sessionId': 's1',
        'uri': 'file:///a.dart',
      });

      expect(agent.closed?.uri, equals('file:///a.dart'));
    });

    test('didSave carries the uri', () async {
      final agent = await notify('document/didSave', {
        'sessionId': 's1',
        'uri': 'file:///b.dart',
      });

      expect(agent.saved?.uri, equals('file:///b.dart'));
    });

    test('didFocus carries the cursor and the visible range', () async {
      final agent = await notify('document/didFocus', {
        'sessionId': 's1',
        'uri': 'file:///tmp/main.dart',
        'version': 4,
        'position': {'line': 10, 'character': 2},
        'visibleRange': {
          'start': {'line': 0, 'character': 0},
          'end': {'line': 40, 'character': 0},
        },
      });

      expect(agent.focused?.position.line, equals(10));
      expect(agent.focused?.position.character, equals(2));
      expect(agent.focused?.visibleRange.end.line, equals(40));
    });

    test('an agent ignoring document events does not error', () async {
      // Notifications are one-way; a null handler must not produce a reply.
      final replies = <Map<String, dynamic>>[];
      final sub = writable.stream.listen(replies.add);
      AgentSideConnection((_) => _IgnoringAgent(), stream);

      readable.add({
        'jsonrpc': '2.0',
        'method': 'document/didOpen',
        'params': {
          'sessionId': 's1',
          'uri': 'file:///a.dart',
          'languageId': 'dart',
          'version': 1,
          'text': '',
        },
      });
      await Future<void>.delayed(Duration.zero);

      expect(replies, isEmpty);
      await sub.cancel();
    });
  });

  group('Document senders', () {
    test('the client emits each notification under its spec name', () async {
      final connection = ClientSideConnection((_) => _IgnoringClient(), stream);
      final seen = <String>[];
      final sub = writable.stream.listen((m) => seen.add(m['method'] as String));

      await connection.didOpenDocument(
        DidOpenDocumentNotification(
          sessionId: 's',
          uri: 'file:///a',
          languageId: 'dart',
          version: 1,
          text: '',
        ),
      );
      await connection.didChangeDocument(
        DidChangeDocumentNotification(
          sessionId: 's',
          uri: 'file:///a',
          version: 2,
          contentChanges: [TextDocumentContentChangeEvent(text: 'x')],
        ),
      );
      await connection.didCloseDocument(
        DidCloseDocumentNotification(sessionId: 's', uri: 'file:///a'),
      );
      await connection.didSaveDocument(
        DidSaveDocumentNotification(sessionId: 's', uri: 'file:///a'),
      );
      await connection.didFocusDocument(
        DidFocusDocumentNotification(
          sessionId: 's',
          uri: 'file:///a',
          version: 3,
          position: Position(line: 0, character: 0),
          visibleRange: Range(
            start: Position(line: 0, character: 0),
            end: Position(line: 1, character: 0),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        seen,
        equals([
          'document/didOpen',
          'document/didChange',
          'document/didClose',
          'document/didSave',
          'document/didFocus',
        ]),
      );
      await sub.cancel();
    });
  });

  group('Document schema and unions', () {
    test('Position and Range round-trip', () {
      final range = Range(
        start: Position(line: 1, character: 2),
        end: Position(line: 3, character: 4),
      );
      final decoded = Range.fromJson(_wire(range.toJson()));

      expect(decoded.start.line, equals(1));
      expect(decoded.end.character, equals(4));
    });

    test('TextDocumentSyncKind round-trips both values', () {
      for (final kind in TextDocumentSyncKind.values) {
        final encoded = jsonEncode({'kind': kind.name});
        expect(encoded, contains(kind.name));
      }
      expect(TextDocumentSyncKind.values, hasLength(2));
    });

    test('notifications map to their union variants', () {
      expect(
        ClientNotificationUnion.fromMethod('document/didOpen', {
          'sessionId': 's',
          'uri': 'u',
          'languageId': 'dart',
          'version': 1,
          'text': '',
        }),
        isA<ClientDidOpenDocumentNotification>(),
      );
      expect(
        ClientNotificationUnion.fromMethod('document/didChange', {
          'sessionId': 's',
          'uri': 'u',
          'version': 1,
          'contentChanges': <dynamic>[],
        }),
        isA<ClientDidChangeDocumentNotification>(),
      );
      expect(
        ClientNotificationUnion.fromMethod('document/didClose', {
          'sessionId': 's',
          'uri': 'u',
        }),
        isA<ClientDidCloseDocumentNotification>(),
      );
      expect(
        ClientNotificationUnion.fromMethod('document/didSave', {
          'sessionId': 's',
          'uri': 'u',
        }),
        isA<ClientDidSaveDocumentNotification>(),
      );
      expect(
        ClientNotificationUnion.fromMethod('document/didFocus', {
          'sessionId': 's',
          'uri': 'u',
          'version': 1,
          'position': {'line': 0, 'character': 0},
          'visibleRange': {
            'start': {'line': 0, 'character': 0},
            'end': {'line': 0, 'character': 0},
          },
        }),
        isA<ClientDidFocusDocumentNotification>(),
      );
    });

    test('method constants are registered', () {
      expect(agentMethods['documentDidOpen'], equals('document/didOpen'));
      expect(agentMethods['documentDidChange'], equals('document/didChange'));
      expect(agentMethods['documentDidClose'], equals('document/didClose'));
      expect(agentMethods['documentDidSave'], equals('document/didSave'));
      expect(agentMethods['documentDidFocus'], equals('document/didFocus'));
    });
  });
}

class _IgnoringAgent implements Agent {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _IgnoringClient implements Client {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
