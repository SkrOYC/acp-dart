import 'dart:convert';

import 'package:acp_dart/src/schema_v15_experimental.dart';
import 'package:test/test.dart';

void main() {
  test('provider models preserve metadata, nulls, and unrecognized fields', () {
    const input = {
      'providers': [
        {
          'providerId': 'main',
          'supported': ['openai', '_custom'],
          'required': true,
          'current': {'apiType': 'openai', 'baseUrl': 'https://api.example'},
          '_meta': {
            'trace': {'id': 4},
          },
          'futureField': false,
        },
      ],
      '_meta': null,
    };
    final decoded = V15ListProvidersResponse.fromJson(input);
    expect(decoded.providers.single.supported, ['openai', '_custom']);
    expect(decoded.toJson(), input);
  });

  test('nullable experimental fields retain explicit null on the wire', () {
    const input = {
      'connectionId': 'connection-1',
      'method': 'notifications/initialized',
      'params': null,
      '_meta': null,
    };
    expect(V15MessageMcpRequest.fromJson(input).toJson(), input);
    expect(
      V15ProviderInfo.fromJson({
        'providerId': 'main',
        'supported': [],
        'required': false,
        'current': null,
      }).toJson()['current'],
      isNull,
    );
  });

  test(
    'MCP messages accept arbitrary JSON result and preserve params metadata',
    () {
      const input = {
        'connectionId': 'connection-1',
        'method': 'tools/call',
        'params': {
          'arguments': {'count': 2},
        },
        '_meta': {'trace': 'x'},
      };
      final request = V15MessageMcpRequest.fromJson(input);
      expect(jsonDecode(jsonEncode(request.toJson())), input);
      expect(V15MessageMcpResponse.fromJson([1, true, null]).toJson(), [
        1,
        true,
        null,
      ]);
      expect(V15ConnectMcpRequest.fromJson({'serverId': 'server'}).toJson(), {
        'serverId': 'server',
      });
      expect(V15ConnectMcpResponse.fromJson({'connectionId': 'c'}).toJson(), {
        'connectionId': 'c',
      });
      expect(V15DisconnectMcpRequest.fromJson({'connectionId': 'c'}).toJson(), {
        'connectionId': 'c',
      });
      expect(
        V15DisconnectMcpResponse.fromJson({}).toJson(),
        <String, dynamic>{},
      );
    },
  );

  test('provider mutation payloads round-trip with exact header types', () {
    const set = {
      'providerId': 'main',
      'apiType': 'openai',
      'baseUrl': 'https://example.com',
      'headers': {'Authorization': 'Bearer secret'},
    };
    expect(V15SetProviderRequest.fromJson(set).toJson(), set);
    expect(
      V15DisableProviderRequest.fromJson({'providerId': 'main'}).toJson(),
      {'providerId': 'main'},
    );
    expect(V15ListProvidersRequest.fromJson({}).toJson(), <String, dynamic>{});
    expect(
      V15ProviderMutationResponse.fromJson({}).toJson(),
      <String, dynamic>{},
    );
  });

  test('document notifications round-trip text document changes', () {
    const input = {
      'sessionId': 'session-1',
      'uri': 'file:///src/a.dart',
      'version': 3,
      'contentChanges': [
        {
          'range': {
            'start': {'line': 1, 'character': 2},
            'end': {'line': 1, 'character': 2},
          },
          'text': 'x',
        },
      ],
      '_meta': {'client': 'editor'},
    };
    expect(V15DidChangeDocumentNotification.fromJson(input).toJson(), input);
    const opened = {
      'sessionId': 'session-1',
      'uri': 'file:///src/a.dart',
      'languageId': 'dart',
      'version': 3,
      'text': 'void main() {}',
    };
    expect(V15DidOpenDocumentNotification.fromJson(opened).toJson(), opened);
    const closed = {'sessionId': 'session-1', 'uri': 'file:///src/a.dart'};
    expect(V15DidCloseDocumentNotification.fromJson(closed).toJson(), closed);
    expect(V15DidSaveDocumentNotification.fromJson(closed).toJson(), closed);
    const focused = {
      'sessionId': 'session-1',
      'uri': 'file:///src/a.dart',
      'version': 3,
      'position': {'line': 1, 'character': 2},
      'visibleRange': {
        'start': {'line': 0, 'character': 0},
        'end': {'line': 3, 'character': 0},
      },
    };
    expect(V15DidFocusDocumentNotification.fromJson(focused).toJson(), focused);
  });

  test('NES suggestion variants and requests round-trip', () {
    final suggestions = [
      {
        'kind': 'edit',
        'id': 's1',
        'uri': 'file:///src/a.dart',
        'edits': [
          {
            'range': {
              'start': {'line': 0, 'character': 0},
              'end': {'line': 0, 'character': 1},
            },
            'newText': 'value',
          },
        ],
      },
      {
        'kind': 'jump',
        'id': 's2',
        'uri': 'file:///src/a.dart',
        'position': {'line': 2, 'character': 4},
      },
      {
        'kind': 'rename',
        'id': 's3',
        'uri': 'file:///src/a.dart',
        'position': {'line': 2, 'character': 4},
        'newName': 'updated',
      },
      {
        'kind': 'searchAndReplace',
        'id': 's4',
        'uri': 'file:///src/a.dart',
        'search': 'before',
        'replace': 'after',
        'isRegex': false,
      },
    ];
    for (final suggestion in suggestions) {
      expect(V15NesSuggestion.fromJson(suggestion).toJson(), suggestion);
    }
    expect(
      V15AcceptNesNotification.fromJson({
        'sessionId': 's',
        'id': 's1',
      }).toJson(),
      {'sessionId': 's', 'id': 's1'},
    );
    const rejection = {'sessionId': 's', 'id': 's1', 'reason': 'ignored'};
    expect(V15RejectNesNotification.fromJson(rejection).toJson(), rejection);
    const request = {
      'sessionId': 'nes-1',
      'uri': 'file:///src/a.dart',
      'version': 2,
      'position': {'line': 1, 'character': 5},
      'triggerKind': 'manual',
    };
    expect(V15SuggestNesRequest.fromJson(request).toJson(), request);
  });

  test(
    'plan updates and compaction notifications preserve patch-shaped fields',
    () {
      final plans = [
        {
          'type': 'items',
          'planId': 'p1',
          'entries': [
            {
              'content': 'Implement',
              'priority': 'high',
              'status': 'in_progress',
              '_meta': {'id': 1},
            },
          ],
        },
        {'type': 'file', 'planId': 'p2', 'uri': 'file:///plan.md'},
        {'type': 'markdown', 'planId': 'p3', 'content': '# Plan'},
      ];
      for (final plan in plans) {
        expect(V15PlanUpdateContent.fromJson(plan).toJson(), plan);
      }
      expect(V15PlanRemoved.fromJson({'planId': 'p4'}).toJson(), {
        'planId': 'p4',
      });
      const compaction = {
        'compactionId': 'c1',
        'status': 'completed',
        'summary': [
          {'type': 'text', 'text': 'Summary'},
        ],
        '_meta': {'retained': true},
      };
      expect(V15CompactionUpdate.fromJson(compaction).toJson(), compaction);
      const chunk = {
        'compactionId': 'c1',
        'content': {'type': 'text', 'text': 'More summary'},
      };
      expect(V15CompactionSummaryChunk.fromJson(chunk).toJson(), chunk);
    },
  );
}
