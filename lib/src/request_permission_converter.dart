import 'package:json_annotation/json_annotation.dart';
import 'package:acp_dart/src/schema.dart';

class RequestPermissionOutcomeConverter
    implements JsonConverter<RequestPermissionOutcome, Map<String, dynamic>> {
  const RequestPermissionOutcomeConverter();

  @override
  RequestPermissionOutcome fromJson(Map<String, dynamic> json) {
    final type = json['outcome'] as String?;
    if (type == null) {
      throw ArgumentError('Missing or null "outcome" field in RequestPermissionOutcome JSON: $json');
    }
    switch (type) {
      case 'cancelled':
        return CancelledOutcome.fromJson(json);
      case 'selected':
        return SelectedOutcome.fromJson(json);
      default:
        throw ArgumentError('Unknown RequestPermissionOutcome type: $type');
    }
  }

  @override
  Map<String, dynamic> toJson(RequestPermissionOutcome object) {
    if (object is CancelledOutcome) {
      return object.toJson();
    }
    if (object is SelectedOutcome) {
      return object.toJson();
    }
    throw ArgumentError('Unknown RequestPermissionOutcome type: ${object.runtimeType}');
  }
}
