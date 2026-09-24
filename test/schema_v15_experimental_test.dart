import 'dart:convert';

import 'package:acp_dart/src/schema.dart';
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
    for (var i = 0; i < suggestions.length; i++) {
      final decoded = V15NesSuggestion.fromJson(suggestions[i]);
      expect(decoded.toJson(), suggestions[i]);
      if (i == 0) {
        final typed = decoded as V15NesEditSuggestion;
        expect(typed.edits, isNotEmpty);
        expect(typed.edits.single.range.start.line, 0);
      } else if (i == 1) {
        expect(decoded, isA<V15NesJumpSuggestion>());
      } else if (i == 2) {
        expect(decoded, isA<V15NesRenameSuggestion>());
      } else {
        expect(decoded, isA<V15NesSearchAndReplaceSuggestion>());
      }
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

  test('NES start, context, and response models validate nested schemas', () {
    const start = {
      'workspaceUri': 'file:///workspace',
      'workspaceFolders': [
        {'uri': 'file:///workspace', 'name': 'workspace'},
      ],
      'repository': {
        'name': 'repo',
        'owner': 'owner',
        'remoteUrl': 'https://example.com/owner/repo.git',
      },
      '_meta': {'request': 1},
    };
    expect(V15StartNesRequest.fromJson(start).toJson(), start);
    const context = {
      'recentFiles': [
        {'uri': 'file:///a.dart', 'languageId': 'dart', 'text': 'main();'},
      ],
      'relatedSnippets': [
        {
          'uri': 'file:///b.dart',
          'excerpts': [
            {'startLine': 1, 'endLine': 2, 'text': 'code'},
          ],
        },
      ],
      'editHistory': [
        {'uri': 'file:///a.dart', 'diff': '+new'},
      ],
      'userActions': [
        {
          'action': 'typing',
          'uri': 'file:///a.dart',
          'position': {'line': 1, 'character': 0},
          'timestampMs': 123,
        },
      ],
      'openFiles': [
        {
          'uri': 'file:///a.dart',
          'languageId': 'dart',
          'visibleRange': null,
          'lastFocusedMs': 123,
        },
      ],
      'diagnostics': [
        {
          'uri': 'file:///a.dart',
          'range': {
            'start': {'line': 0, 'character': 0},
            'end': {'line': 0, 'character': 1},
          },
          'severity': 'warning',
          'message': 'check',
        },
      ],
      '_meta': null,
    };
    expect(V15NesSuggestContext.fromJson(context).toJson(), context);
    expect(
      V15NesSuggestContext.fromJson(context).recentFiles!.single.text,
      'main();',
    );
    expect(
      V15NesSuggestContext.fromJson(context).diagnostics!.single.severity,
      'warning',
    );
    const response = {
      'suggestions': [
        {
          'kind': 'jump',
          'id': 's1',
          'uri': 'file:///a.dart',
          'position': {'line': 1, 'character': 2},
        },
      ],
    };
    expect(V15SuggestNesResponse.fromJson(response).toJson(), response);
    expect(V15StartNesResponse.fromJson({'sessionId': 'nes-1'}).toJson(), {
      'sessionId': 'nes-1',
    });
    expect(V15CloseNesRequest.fromJson({'sessionId': 'nes-1'}).toJson(), {
      'sessionId': 'nes-1',
    });
    expect(V15CloseNesResponse.fromJson({}).toJson(), <String, dynamic>{});
    expect(
      () => V15SuggestNesRequest.fromJson({
        'sessionId': 'nes-1',
        'uri': 'file:///a.dart',
        'version': 1,
        'position': {'line': 0, 'character': 0},
        'triggerKind': 'unknown',
      }),
      throwsFormatException,
    );
  });

  test(
    'NES suggestion edit payload validates every nested edit and nullable cursor',
    () {
      const edit = {
        'kind': 'edit',
        'id': 's1',
        'uri': 'file:///a.dart',
        'edits': [
          {
            'range': {
              'start': {'line': 0, 'character': 0},
              'end': {'line': 0, 'character': 1},
            },
            'newText': 'x',
          },
        ],
        'cursorPosition': null,
        '_meta': null,
      };
      expect(V15NesSuggestion.fromJson(edit).toJson(), edit);
      expect(
        () => V15NesSuggestContext.fromJson({
          'diagnostics': [
            {'uri': 'bad'},
          ],
        }),
        throwsA(anyOf(isA<FormatException>(), isA<TypeError>())),
      );
    },
  );

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
        final decoded = V15PlanUpdateContent.fromJson(plan);
        expect(decoded.toJson(), plan);
        if (plan['type'] == 'items') {
          expect(decoded, isA<V15PlanItems>());
        } else if (plan['type'] == 'file') {
          expect(decoded, isA<V15PlanFile>());
        } else {
          expect(decoded, isA<V15PlanMarkdown>());
        }
      }
      const update = {
        'plan': {'type': 'markdown', 'planId': 'p4', 'content': '# Next'},
      };
      expect(V15PlanUpdate.fromJson(update).toJson(), update);
      final planSessionUpdate = PlanUpdateSessionUpdateV15.fromJson(update);
      expect(planSessionUpdate, isA<SessionUpdate>());
      expect(planSessionUpdate.toJson(), update);
      expect(
        () => PlanUpdateSessionUpdateV15.fromJson({
          'sessionUpdate': 'plan_removed',
          'plan': update['plan'],
        }),
        throwsFormatException,
      );
      expect(
        () => V15PlanUpdateContent.fromJson({
          'type': 'items',
          'planId': 'bad',
          'entries': [
            {'content': 'bad', 'priority': 'urgent', 'status': 'pending'},
          ],
        }),
        throwsFormatException,
      );
      expect(V15PlanRemoved.fromJson({'planId': 'p4'}).toJson(), {
        'planId': 'p4',
      });
      expect(PlanRemovedSessionUpdateV15.fromJson({'planId': 'p4'}).toJson(), {
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
      expect(
        CompactionUpdateSessionUpdateV15.fromJson(compaction).toJson(),
        compaction,
      );
      const chunk = {
        'compactionId': 'c1',
        'content': {'type': 'text', 'text': 'More summary'},
      };
      expect(V15CompactionSummaryChunk.fromJson(chunk).toJson(), chunk);
      expect(
        CompactionSummaryChunkSessionUpdateV15.fromJson(chunk).toJson(),
        chunk,
      );
    },
  );
}
