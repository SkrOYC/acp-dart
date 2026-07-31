import 'dart:async';
import 'dart:convert';

import 'package:acp_dart/acp_dart.dart';
import 'package:acp_dart/src/nes_converters.dart';
import 'package:test/test.dart';

class _NesAgent implements Agent {
  final bool handle;
  final List<NesSuggestion> suggestions;
  _NesAgent({this.handle = true, this.suggestions = const []});

  StartNesRequest? startedWith;
  SuggestNesRequest? suggestedWith;
  AcceptNesNotification? acceptedWith;
  RejectNesNotification? rejectedWith;
  CloseNesRequest? closedWith;

  @override
  Future<StartNesResponse>? startNes(StartNesRequest params) {
    if (!handle) return null;
    startedWith = params;
    return Future.value(StartNesResponse(sessionId: 'nes-1'));
  }

  @override
  Future<SuggestNesResponse>? suggestNes(SuggestNesRequest params) {
    if (!handle) return null;
    suggestedWith = params;
    return Future.value(SuggestNesResponse(suggestions: suggestions));
  }

  @override
  Future<void>? acceptNes(AcceptNesNotification params) {
    acceptedWith = params;
    return Future.value();
  }

  @override
  Future<void>? rejectNes(RejectNesNotification params) {
    rejectedWith = params;
    return Future.value();
  }

  @override
  Future<CloseNesResponse>? closeNes(CloseNesRequest params) {
    if (!handle) return null;
    closedWith = params;
    return Future.value(CloseNesResponse());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Range _range(int l1, int c1, int l2, int c2) => Range(
  start: Position(line: l1, character: c1),
  end: Position(line: l2, character: c2),
);

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

  Future<Map<String, dynamic>> callAgent(
    Agent agent,
    String method,
    Map<String, dynamic> params,
  ) async {
    AgentSideConnection((_) => agent, stream);
    final reply = writable.stream.first;
    readable.add({
      'jsonrpc': '2.0',
      'id': 1,
      'method': method,
      'params': params,
    });
    return jsonDecode(jsonEncode(await reply)) as Map<String, dynamic>;
  }

  group('NES lifecycle dispatch', () {
    test('nes/start returns a session id distinct from prompt sessions', () async {
      final agent = _NesAgent();
      final reply = await callAgent(agent, 'nes/start', {
        'workspaceUri': 'file:///workspace',
        'workspaceFolders': [
          {'uri': 'file:///workspace/app', 'name': 'app'},
        ],
        'repository': {
          'name': 'acp-dart',
          'owner': 'SkrOYC',
          'remoteUrl': 'https://github.com/SkrOYC/acp-dart',
        },
      });

      expect(reply['result']['sessionId'], equals('nes-1'));
      expect(agent.startedWith?.workspaceFolders?.single.name, equals('app'));
      expect(agent.startedWith?.repository?.owner, equals('SkrOYC'));
    });

    test('nes/close tears the session down', () async {
      final agent = _NesAgent();
      final reply = await callAgent(agent, 'nes/close', {'sessionId': 'nes-1'});

      expect(reply['error'], isNull);
      expect(agent.closedWith?.sessionId, equals('nes-1'));
    });

    test('an agent without NES support reports method not found', () async {
      final reply = await callAgent(
        _NesAgent(handle: false),
        'nes/start',
        <String, dynamic>{},
      );

      expect(reply['error']['code'], equals(-32601));
    });
  });

  group('nes/suggest', () {
    test('carries trigger kind, cursor, selection, and context', () async {
      final agent = _NesAgent();
      await callAgent(agent, 'nes/suggest', {
        'sessionId': 'nes-1',
        'uri': 'file:///a.dart',
        'version': 7,
        'position': {'line': 3, 'character': 5},
        'selection': {
          'start': {'line': 3, 'character': 0},
          'end': {'line': 3, 'character': 8},
        },
        'triggerKind': 'diagnostic',
        'context': {
          'recentFiles': [
            {'uri': 'file:///b.dart', 'languageId': 'dart', 'text': 'x'},
          ],
          'diagnostics': [
            {
              'uri': 'file:///a.dart',
              'range': {
                'start': {'line': 3, 'character': 0},
                'end': {'line': 3, 'character': 8},
              },
              'severity': 'warning',
              'message': 'unused',
            },
          ],
          'editHistory': [
            {'uri': 'file:///a.dart', 'diff': '@@ -1 +1 @@'},
          ],
        },
      });

      final req = agent.suggestedWith!;
      expect(req.triggerKind, equals(NesTriggerKind.diagnostic));
      expect(req.position.line, equals(3));
      expect(req.selection?.end.character, equals(8));
      expect(req.context?.recentFiles?.single.languageId, equals('dart'));
      expect(
        req.context?.diagnostics?.single.severity,
        equals(NesDiagnosticSeverity.warning),
      );
      expect(req.context?.editHistory?.single.diff, equals('@@ -1 +1 @@'));
      // Context kinds the client did not send stay null.
      expect(req.context?.userActions, isNull);
    });

    test('returns all four suggestion kinds with their discriminators', () async {
      final agent = _NesAgent(
        suggestions: [
          NesEditSuggestion(
            id: 's1',
            uri: 'file:///a.dart',
            edits: [NesTextEdit(range: _range(0, 0, 0, 3), newText: 'final')],
            cursorPosition: Position(line: 0, character: 5),
          ),
          NesJumpSuggestion(
            id: 's2',
            uri: 'file:///b.dart',
            position: Position(line: 9, character: 0),
          ),
          NesRenameSuggestion(
            id: 's3',
            uri: 'file:///c.dart',
            position: Position(line: 1, character: 1),
            newName: 'betterName',
          ),
          NesSearchAndReplaceSuggestion(
            id: 's4',
            uri: 'file:///d.dart',
            search: r'foo\d+',
            replace: 'bar',
            isRegex: true,
          ),
        ],
      );

      final reply = await callAgent(agent, 'nes/suggest', {
        'sessionId': 'nes-1',
        'uri': 'file:///a.dart',
        'version': 1,
        'position': {'line': 0, 'character': 0},
        'triggerKind': 'automatic',
      });

      final wire = reply['result']['suggestions'] as List;
      expect(
        wire.map((s) => s['kind']),
        equals(['edit', 'jump', 'rename', 'searchAndReplace']),
      );
      expect(wire[0]['edits'][0]['newText'], equals('final'));
      expect(wire[2]['newName'], equals('betterName'));
      expect(wire[3]['isRegex'], isTrue);
    });
  });

  group('nes/accept and nes/reject', () {
    test('accept reaches the agent', () async {
      final agent = _NesAgent();
      AgentSideConnection((_) => agent, stream);

      readable.add({
        'jsonrpc': '2.0',
        'method': 'nes/accept',
        'params': {'sessionId': 'nes-1', 'id': 's1'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(agent.acceptedWith?.id, equals('s1'));
    });

    test('reject carries the reason', () async {
      final agent = _NesAgent();
      AgentSideConnection((_) => agent, stream);

      readable.add({
        'jsonrpc': '2.0',
        'method': 'nes/reject',
        'params': {'sessionId': 'nes-1', 'id': 's1', 'reason': 'replaced'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(agent.rejectedWith?.reason, equals(NesRejectReason.replaced));
    });

    test('reject without a reason leaves it null', () async {
      final agent = _NesAgent();
      AgentSideConnection((_) => agent, stream);

      readable.add({
        'jsonrpc': '2.0',
        'method': 'nes/reject',
        'params': {'sessionId': 'nes-1', 'id': 's1'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(agent.rejectedWith?.id, equals('s1'));
      expect(agent.rejectedWith?.reason, isNull);
    });
  });

  group('NES suggestion union', () {
    const converter = NesSuggestionConverter();

    test('each kind round-trips', () {
      final cases = <NesSuggestion>[
        NesEditSuggestion(
          id: 'a',
          uri: 'u',
          edits: [NesTextEdit(range: _range(0, 0, 1, 1), newText: 'x')],
        ),
        NesJumpSuggestion(
          id: 'b',
          uri: 'u',
          position: Position(line: 2, character: 2),
        ),
        NesRenameSuggestion(
          id: 'c',
          uri: 'u',
          position: Position(line: 3, character: 3),
          newName: 'n',
        ),
        NesSearchAndReplaceSuggestion(
          id: 'd',
          uri: 'u',
          search: 's',
          replace: 'r',
        ),
      ];

      for (final original in cases) {
        final encoded =
            jsonDecode(jsonEncode(converter.toJson(original)))
                as Map<String, dynamic>;
        final decoded = converter.fromJson(encoded);

        expect(decoded.runtimeType, equals(original.runtimeType));
        expect(decoded.id, equals(original.id));
        expect(decoded.uri, equals(original.uri));
      }
    });

    test('an unknown kind is preserved rather than dropped', () {
      final raw = {
        'kind': '_vendorKind',
        'id': 'z',
        'uri': 'file:///z',
        'extra': 1,
      };
      final decoded = converter.fromJson(raw);

      expect(decoded, isA<UnknownNesSuggestion>());
      expect(decoded.id, equals('z'));
      expect(decoded.uri, equals('file:///z'));
      expect(converter.toJson(decoded), equals(raw));
    });

    test('a suggestion list survives a full response round-trip', () {
      final response = SuggestNesResponse(
        suggestions: [
          NesJumpSuggestion(
            id: 'j',
            uri: 'u',
            position: Position(line: 1, character: 1),
          ),
          UnknownNesSuggestion(
            rawJson: {'kind': '_future', 'id': 'f', 'uri': 'u'},
          ),
        ],
      );

      final decoded = SuggestNesResponse.fromJson(
        jsonDecode(jsonEncode(response.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.suggestions, hasLength(2));
      expect(decoded.suggestions[0], isA<NesJumpSuggestion>());
      expect(decoded.suggestions[1], isA<UnknownNesSuggestion>());
    });
  });

  group('NES capabilities and constants', () {
    test('the agent and client capability trees round-trip', () {
      final agentCaps = NesCapabilities(
        events: NesEventCapabilities(
          document: NesDocumentEventCapabilities(
            didOpen: NesDocumentDidOpenCapabilities(),
            didChange: NesDocumentDidChangeCapabilities(),
          ),
        ),
        context: NesContextCapabilities(
          recentFiles: NesRecentFilesCapabilities(),
          diagnostics: NesDiagnosticsCapabilities(),
        ),
      );
      final decodedAgent = NesCapabilities.fromJson(
        jsonDecode(jsonEncode(agentCaps.toJson())) as Map<String, dynamic>,
      );

      expect(decodedAgent.events?.document?.didOpen, isNotNull);
      expect(decodedAgent.events?.document?.didClose, isNull);
      expect(decodedAgent.context?.recentFiles, isNotNull);
      expect(decodedAgent.context?.openFiles, isNull);

      final clientCaps = ClientNesCapabilities(jump: NesJumpCapabilities());
      final decodedClient = ClientNesCapabilities.fromJson(
        jsonDecode(jsonEncode(clientCaps.toJson())) as Map<String, dynamic>,
      );

      expect(decodedClient.jump, isNotNull);
      expect(decodedClient.rename, isNull);
      expect(decodedClient.searchAndReplace, isNull);
    });

    test('requests, responses, and notifications map to their variants', () {
      expect(
        ClientRequestUnion.fromMethod('nes/start', <String, dynamic>{}),
        isA<ClientStartNesRequest>(),
      );
      expect(
        ClientRequestUnion.fromMethod('nes/close', {'sessionId': 's'}),
        isA<ClientCloseNesRequest>(),
      );
      expect(
        AgentResponseUnion.fromJson('nes/start', {'sessionId': 's'}),
        isA<AgentStartNesResponse>(),
      );
      expect(
        AgentResponseUnion.fromJson('nes/suggest', {
          'suggestions': <dynamic>[],
        }),
        isA<AgentSuggestNesResponse>(),
      );
      expect(
        ClientNotificationUnion.fromMethod('nes/accept', {
          'sessionId': 's',
          'id': 'x',
        }),
        isA<ClientAcceptNesNotification>(),
      );
      expect(
        ClientNotificationUnion.fromMethod('nes/reject', {
          'sessionId': 's',
          'id': 'x',
        }),
        isA<ClientRejectNesNotification>(),
      );
    });

    test('method constants are registered', () {
      expect(agentMethods['nesStart'], equals('nes/start'));
      expect(agentMethods['nesSuggest'], equals('nes/suggest'));
      expect(agentMethods['nesAccept'], equals('nes/accept'));
      expect(agentMethods['nesReject'], equals('nes/reject'));
      expect(agentMethods['nesClose'], equals('nes/close'));
    });
  });
}
