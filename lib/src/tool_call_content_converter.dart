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
    // The `type` discriminator is declared as a field initializer rather than a
    // constructor parameter, so json_serializable leaves it out of the
    // generated `toJson`. Add it back here, otherwise the encoded content
    // cannot be decoded again (by `fromJson` above or by any other ACP peer).
    if (object is ContentToolCallContent) {
      return {'type': 'content', ...object.toJson()};
    }
    if (object is DiffToolCallContent) {
      return {'type': 'diff', ...object.toJson()};
    }
    if (object is TerminalToolCallContent) {
      return {'type': 'terminal', ...object.toJson()};
    }
    throw Exception('Unknown ToolCallContent type: ${object.runtimeType}');
  }
}
