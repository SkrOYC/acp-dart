import 'package:json_annotation/json_annotation.dart';

import 'schema.dart';

class McpServerConverter
    implements JsonConverter<McpServerBase, Map<String, dynamic>> {
  const McpServerConverter();

  @override
  McpServerBase fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == 'http') {
      return HttpMcpServer.fromJson(json);
    }
    if (type == 'sse') {
      return SseMcpServer.fromJson(json);
    }
    if (json.containsKey('command')) {
      return StdioMcpServer.fromJson(json);
    }
    throw ArgumentError('Unknown McpServer type: $json');
  }

  @override
  Map<String, dynamic> toJson(McpServerBase object) {
    if (object is HttpMcpServer) {
      return object.toJson();
    }
    if (object is SseMcpServer) {
      return object.toJson();
    }
    if (object is StdioMcpServer) {
      return object.toJson();
    }
    throw ArgumentError('Unknown McpServerBase type: $object');
  }
}
