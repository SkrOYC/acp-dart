import 'package:acp_dart/src/schema.dart';
import 'package:json_annotation/json_annotation.dart';

class EmbeddedResourceResourceConverter
    implements JsonConverter<EmbeddedResourceResource, Map<String, dynamic>> {
  const EmbeddedResourceResourceConverter();

  @override
  EmbeddedResourceResource fromJson(Map<String, dynamic> json) {
    // Check if it has the properties of TextResourceContents
    if (json.containsKey('text') && json.containsKey('uri')) {
      return TextResourceContents.fromJson(json);
    }
    // Check if it has the properties of BlobResourceContents
    else if (json.containsKey('blob') && json.containsKey('uri')) {
      return BlobResourceContents.fromJson(json);
    }
    // If it doesn't match any known type, throw an error
    else {
      throw Exception('Unknown EmbeddedResourceResource type');
    }
  }

  @override
  Map<String, dynamic> toJson(EmbeddedResourceResource object) {
    if (object is TextResourceContents) {
      return object.toJson();
    } else if (object is BlobResourceContents) {
      return object.toJson();
    } else {
      throw Exception(
        'Unknown EmbeddedResourceResource type: ${object.runtimeType}',
      );
    }
  }
}
