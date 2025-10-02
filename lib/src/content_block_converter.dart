import 'package:acp_dart/src/schema.dart';
import 'package:json_annotation/json_annotation.dart';

class ContentBlockConverter
    implements JsonConverter<ContentBlock, Map<String, dynamic>> {
  const ContentBlockConverter();

  @override
  ContentBlock fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;

    switch (type) {
      case 'text':
        return TextContentBlock.fromJson(json);
      case 'image':
        return ImageContentBlock.fromJson(json);
      case 'audio':
        return AudioContentBlock.fromJson(json);
      case 'resource_link':
        return ResourceLinkContentBlock.fromJson(json);
      case 'resource':
        return ResourceContentBlock.fromJson(json);
      default:
        throw Exception('Unknown ContentBlock type: $type');
    }
  }

  @override
  Map<String, dynamic> toJson(ContentBlock object) {
    if (object is TextContentBlock) {
      return object.toJson();
    } else if (object is ImageContentBlock) {
      return object.toJson();
    } else if (object is AudioContentBlock) {
      return object.toJson();
    } else if (object is ResourceLinkContentBlock) {
      return object.toJson();
    } else if (object is ResourceContentBlock) {
      return object.toJson();
    } else {
      throw Exception('Unknown ContentBlock type: ${object.runtimeType}');
    }
  }
}
