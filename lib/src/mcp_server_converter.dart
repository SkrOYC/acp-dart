import 'package:json_annotation/json_annotation.dart';

import 'schema.dart';

class McpServerConverter implements JsonConverter<McpServerBase, Map<String, dynamic>> {
  const McpServerConverter();

  @override
  McpServerBase fromJson(Map<String, dynamic> json) {
    if (json.containsKey('type')) {
      final type = json['type'] as String;
      if (type == 'http' || type == 'sse') {
        return HttpSseMcpServer.fromJson(json);
      }
    }
    // Assume Stdio if 'command' is present and 'type' is not.
    if (json.containsKey('command')) {
      return Stdio.fromJson(json);
    }

    throw ArgumentError('Unknown McpServer type: $json');
  }

  @override
  Map<String, dynamic> toJson(McpServerBase object) {
    if (object is HttpSseMcpServer) {
      return object.toJson();
    }
    if (object is Stdio) {
      return object.toJson();
    }
    throw ArgumentError('Unknown McpServerBase type: $object');
  }
}
