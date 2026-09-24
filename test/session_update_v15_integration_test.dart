import 'package:acp_dart/acp_dart.dart';
import 'package:test/test.dart';

void main() {
  final cases = <(String, Map<String, dynamic>, Type)>[
    (
      'plan_update',
      {
        'plan': {'type': 'markdown', 'planId': 'p1', 'content': '# Plan'},
      },
      PlanUpdateSessionUpdateV15,
    ),
    ('plan_removed', {'planId': 'p1'}, PlanRemovedSessionUpdateV15),
    (
      'notice',
      {'severity': 'warning', 'title': 'Check the plan'},
      NoticeSessionUpdateV15,
    ),
    (
      'compaction_update',
      {'compactionId': 'c1', 'status': 'completed'},
      CompactionUpdateSessionUpdateV15,
    ),
    (
      'compaction_summary_chunk',
      {
        'compactionId': 'c1',
        'content': {'type': 'text', 'text': 'Summary'},
      },
      CompactionSummaryChunkSessionUpdateV15,
    ),
  ];

  for (final (discriminator, payload, expectedType) in cases) {
    test('$discriminator uses its typed session update', () {
      final json = {
        'sessionId': 's1',
        'update': {'sessionUpdate': discriminator, ...payload},
      };
      final parsed = SessionNotification.fromJson(json);
      expect(parsed.update.runtimeType, expectedType);
      expect(parsed.toJson(), json);
    });
  }
}
