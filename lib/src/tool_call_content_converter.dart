import 'package:acp_dart/src/schema.dart';
import 'package:json_annotation/json_annotation.dart';

class ToolCallContentConverter
    implements JsonConverter<ToolCallContent, Map<String, dynamic>> {
  const ToolCallContentConverter();

  @override
  ToolCallContent fromJson(Map<String, dynamic> json) {
    if (json.containsKey('content')) {
      return ContentToolCallContent.fromJson(
          json['content'] as Map<String, dynamic>);
    }
    if (json.containsKey('diff')) {
      return DiffToolCallContent.fromJson(
          json['diff'] as Map<String, dynamic>);
    }
    if (json.containsKey('terminal')) {
      return TerminalToolCallContent.fromJson(
          json['terminal'] as Map<String, dynamic>);
    }
    throw Exception('Unknown ToolCallContent type');
  }

  @override
  Map<String, dynamic> toJson(ToolCallContent object) {
    if (object is ContentToolCallContent) {
      return {
        'content': object.toJson(),
      };
    }
    if (object is DiffToolCallContent) {
      return {
        'diff': object.toJson(),
      };
    }
    if (object is TerminalToolCallContent) {
      return {
        'terminal': object.toJson(),
      };
    }
    throw Exception('Unknown ToolCallContent type');
  }
}
