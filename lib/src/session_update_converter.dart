import 'package:acp_dart/src/schema.dart';
import 'package:acp_dart/src/schema_v15_client.dart';
import 'package:acp_dart/src/schema_v15_experimental.dart';
import 'package:json_annotation/json_annotation.dart';

class SessionUpdateConverter
    implements JsonConverter<SessionUpdate, Map<String, dynamic>> {
  const SessionUpdateConverter();

  @override
  SessionUpdate fromJson(Map<String, dynamic> json) {
    final type = json['sessionUpdate'] as String?;
    if (type == null) {
      return UnknownSessionUpdate(rawJson: json);
    }
    final data = Map<String, dynamic>.from(json)..remove('sessionUpdate');
    switch (type) {
      case 'user_message_chunk':
        return UserMessageChunkSessionUpdate.fromJson(data);
      case 'agent_message_chunk':
        return AgentMessageChunkSessionUpdate.fromJson(data);
      case 'agent_thought_chunk':
        return AgentThoughtChunkSessionUpdate.fromJson(data);
      case 'tool_call':
        return ToolCallSessionUpdate.fromJson(data);
      case 'tool_call_update':
        return ToolCallUpdateSessionUpdate.fromJson(data);
      case 'plan':
        return PlanSessionUpdate.fromJson(data);
      case 'available_commands_update':
        return AvailableCommandsUpdateSessionUpdate.fromJson(data);
      case 'current_mode_update':
        return CurrentModeUpdateSessionUpdate.fromJson(data);
      case 'config_option_update':
        return ConfigOptionUpdate.fromJson(data);
      case 'session_info_update':
        return SessionInfoUpdate.fromJson(data);
      case 'usage_update':
        return UsageUpdate.fromJson(data);
      case 'plan_update':
        return PlanUpdateSessionUpdateV15.fromJson(data);
      case 'plan_removed':
        return PlanRemovedSessionUpdateV15.fromJson(data);
      case 'notice':
        return NoticeSessionUpdateV15.fromJson(json);
      case 'compaction_update':
        return CompactionUpdateSessionUpdateV15.fromJson(data);
      case 'compaction_summary_chunk':
        return CompactionSummaryChunkSessionUpdateV15.fromJson(data);

      default:
        return UnknownSessionUpdate(rawJson: json);
    }
  }

  @override
  Map<String, dynamic> toJson(SessionUpdate object) {
    if (object is UserMessageChunkSessionUpdate) {
      return {'sessionUpdate': 'user_message_chunk', ...object.toJson()};
    }
    if (object is AgentMessageChunkSessionUpdate) {
      return {'sessionUpdate': 'agent_message_chunk', ...object.toJson()};
    }
    if (object is AgentThoughtChunkSessionUpdate) {
      return {'sessionUpdate': 'agent_thought_chunk', ...object.toJson()};
    }
    if (object is ToolCallSessionUpdate) {
      return {'sessionUpdate': 'tool_call', ...object.toJson()};
    }
    if (object is ToolCallUpdateSessionUpdate) {
      return {'sessionUpdate': 'tool_call_update', ...object.toJson()};
    }
    if (object is PlanSessionUpdate) {
      return {'sessionUpdate': 'plan', ...object.toJson()};
    }
    if (object is AvailableCommandsUpdateSessionUpdate) {
      return {'sessionUpdate': 'available_commands_update', ...object.toJson()};
    }
    if (object is CurrentModeUpdateSessionUpdate) {
      return {'sessionUpdate': 'current_mode_update', ...object.toJson()};
    }
    if (object is ConfigOptionUpdate) {
      return {'sessionUpdate': 'config_option_update', ...object.toJson()};
    }
    if (object is SessionInfoUpdate) {
      return {'sessionUpdate': 'session_info_update', ...object.toJson()};
    }
    if (object is UsageUpdate) {
      return {'sessionUpdate': 'usage_update', ...object.toJson()};
    }
    if (object is PlanUpdateSessionUpdateV15) {
      return {'sessionUpdate': 'plan_update', ...object.toJson()};
    }
    if (object is PlanRemovedSessionUpdateV15) {
      return {'sessionUpdate': 'plan_removed', ...object.toJson()};
    }
    if (object is NoticeSessionUpdateV15) {
      return object.toJson();
    }
    if (object is CompactionUpdateSessionUpdateV15) {
      return {'sessionUpdate': 'compaction_update', ...object.toJson()};
    }
    if (object is CompactionSummaryChunkSessionUpdateV15) {
      return {'sessionUpdate': 'compaction_summary_chunk', ...object.toJson()};
    }

    if (object is UnknownSessionUpdate) {
      return object.rawJson;
    }
    throw Exception('Unknown SessionUpdate type');
  }
}
