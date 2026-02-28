import 'package:json_annotation/json_annotation.dart';

import 'schema.dart';

class SessionConfigSelectOptionsConverter
    implements JsonConverter<SessionConfigSelectOptions, List<dynamic>> {
  const SessionConfigSelectOptionsConverter();

  @override
  SessionConfigSelectOptions fromJson(List<dynamic> json) {
    if (json.isEmpty) {
      return UngroupedSessionConfigSelectOptions(options: const []);
    }

    final normalized = json
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final isGrouped = normalized.every(
      (item) => item.containsKey('group') && item.containsKey('options'),
    );
    final isUngrouped = normalized.every(
      (item) => item.containsKey('value') && item.containsKey('name'),
    );

    if (isGrouped && !isUngrouped) {
      return GroupedSessionConfigSelectOptions(
        groups: normalized.map(SessionConfigSelectGroup.fromJson).toList(),
      );
    }
    if (isUngrouped && !isGrouped) {
      return UngroupedSessionConfigSelectOptions(
        options: normalized.map(SessionConfigSelectOption.fromJson).toList(),
      );
    }

    throw ArgumentError(
      'Invalid SessionConfigSelectOptions payload. '
      'Expected grouped or ungrouped options: $json',
    );
  }

  @override
  List<dynamic> toJson(SessionConfigSelectOptions object) {
    if (object is UngroupedSessionConfigSelectOptions) {
      return object.options.map((option) => option.toJson()).toList();
    }
    if (object is GroupedSessionConfigSelectOptions) {
      return object.groups.map((group) => group.toJson()).toList();
    }
    throw ArgumentError(
      'Unknown SessionConfigSelectOptions type: ${object.runtimeType}',
    );
  }
}
