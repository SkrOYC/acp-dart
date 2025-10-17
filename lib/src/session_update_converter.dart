import 'package:acp_dart/src/schema.dart';
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

      default:
        return UnknownSessionUpdate(rawJson: json);
    }
  }

  @override
  Map<String, dynamic> toJson(SessionUpdate object) {
    if (object is UserMessageChunkSessionUpdate) {
      return {
        'sessionUpdate': 'user_message_chunk',
        ...object.toJson(),
      };
    }
    if (object is AgentMessageChunkSessionUpdate) {
      return {
        'sessionUpdate': 'agent_message_chunk',
        ...object.toJson(),
      };
    }
    if (object is AgentThoughtChunkSessionUpdate) {
      return {
        'sessionUpdate': 'agent_thought_chunk',
        ...object.toJson(),
      };
    }
    if (object is ToolCallSessionUpdate) {
      return {
        'sessionUpdate': 'tool_call',
        ...object.toJson(),
      };
    }
    if (object is ToolCallUpdateSessionUpdate) {
      return {
        'sessionUpdate': 'tool_call_update',
        ...object.toJson(),
      };
    }
    if (object is PlanSessionUpdate) {
      return {
        'sessionUpdate': 'plan',
        ...object.toJson(),
      };
    }
    if (object is AvailableCommandsUpdateSessionUpdate) {
      return {
        'sessionUpdate': 'available_commands_update',
        ...object.toJson(),
      };
    }
    if (object is CurrentModeUpdateSessionUpdate) {
      return {
        'sessionUpdate': 'current_mode_update',
        ...object.toJson(),
      };
    }

    if (object is UnknownSessionUpdate) {
      return object.rawJson;
    }
    throw Exception('Unknown SessionUpdate type');
  }
}
