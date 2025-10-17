import 'package:acp_dart/src/schema.dart';
import 'package:json_annotation/json_annotation.dart';

class ToolCallContentConverter
    implements JsonConverter<ToolCallContent, Map<String, dynamic>> {
  const ToolCallContentConverter();

  @override
  ToolCallContent fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'content':
        return ContentToolCallContent.fromJson(json);
      case 'diff':
        return DiffToolCallContent.fromJson(json);
      case 'terminal':
        return TerminalToolCallContent.fromJson(json);
      default:
        throw Exception('Unknown ToolCallContent type: $type');
    }
  }

  @override
  Map<String, dynamic> toJson(ToolCallContent object) {
    if (object is ContentToolCallContent) {
      return object.toJson();
    }
    if (object is DiffToolCallContent) {
      return object.toJson();
    }
    if (object is TerminalToolCallContent) {
      return object.toJson();
    }
    throw Exception('Unknown ToolCallContent type: ${object.runtimeType}');
  }
}
