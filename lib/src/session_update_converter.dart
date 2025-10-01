import 'package:acp_dart/src/schema.dart';
import 'package:json_annotation/json_annotation.dart';

class SessionUpdateConverter
    implements JsonConverter<SessionUpdate, Map<String, dynamic>> {
  const SessionUpdateConverter();

  @override
  SessionUpdate fromJson(Map<String, dynamic> json) {
    if (json.containsKey('user_message_chunk')) {
      return UserMessageChunkSessionUpdate.fromJson(
          json['user_message_chunk'] as Map<String, dynamic>);
    }
    if (json.containsKey('agent_message_chunk')) {
      return AgentMessageChunkSessionUpdate.fromJson(
          json['agent_message_chunk'] as Map<String, dynamic>);
    }
    if (json.containsKey('agent_thought_chunk')) {
      return AgentThoughtChunkSessionUpdate.fromJson(
          json['agent_thought_chunk'] as Map<String, dynamic>);
    }
    if (json.containsKey('tool_call')) {
      return ToolCallSessionUpdate.fromJson(
          json['tool_call'] as Map<String, dynamic>);
    }
    if (json.containsKey('tool_call_update')) {
      return ToolCallUpdateSessionUpdate.fromJson(
          json['tool_call_update'] as Map<String, dynamic>);
    }
    if (json.containsKey('plan')) {
      return PlanSessionUpdate.fromJson(json['plan'] as Map<String, dynamic>);
    }
    if (json.containsKey('available_commands')) {
      return AvailableCommandsUpdateSessionUpdate.fromJson(
          json['available_commands'] as Map<String, dynamic>);
    }
    if (json.containsKey('current_mode')) {
      return CurrentModeUpdateSessionUpdate.fromJson(
          json['current_mode'] as Map<String, dynamic>);
    }
    throw Exception('Unknown SessionUpdate type');
  }

  @override
  Map<String, dynamic> toJson(SessionUpdate object) {
    if (object is UserMessageChunkSessionUpdate) {
      return {
        'user_message_chunk': object.toJson(),
      };
    }
    if (object is AgentMessageChunkSessionUpdate) {
      return {
        'agent_message_chunk': object.toJson(),
      };
    }
    if (object is AgentThoughtChunkSessionUpdate) {
      return {
        'agent_thought_chunk': object.toJson(),
      };
    }
    if (object is ToolCallSessionUpdate) {
      return {
        'tool_call': object.toJson(),
      };
    }
    if (object is ToolCallUpdateSessionUpdate) {
      return {
        'tool_call_update': object.toJson(),
      };
    }
    if (object is PlanSessionUpdate) {
      return {
        'plan': object.toJson(),
      };
    }
    if (object is AvailableCommandsUpdateSessionUpdate) {
      return {
        'available_commands': object.toJson(),
      };
    }
    if (object is CurrentModeUpdateSessionUpdate) {
      return {
        'current_mode': object.toJson(),
      };
    }
    throw Exception('Unknown SessionUpdate type');
  }
}
