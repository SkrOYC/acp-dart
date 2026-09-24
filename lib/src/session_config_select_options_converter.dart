import 'package:json_annotation/json_annotation.dart';

import 'schema.dart';

class SessionConfigSelectOptionsConverter
    implements JsonConverter<SessionConfigSelectOptions?, dynamic> {
  const SessionConfigSelectOptionsConverter();

  @override
  SessionConfigSelectOptions? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is! List<dynamic>) {
      throw ArgumentError('Expected session config select option list');
    }
    if (json.isEmpty) {
      return UngroupedSessionConfigSelectOptions(options: const []);
    }

    final firstItem = json.first as Map;
    final isGrouped =
        firstItem.containsKey('group') && firstItem.containsKey('options');
    final isUngrouped =
        firstItem.containsKey('value') && firstItem.containsKey('name');

    if (isGrouped) {
      return GroupedSessionConfigSelectOptions(
        groups: json
            .map(
              (item) => SessionConfigSelectGroup.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
      );
    }
    if (isUngrouped) {
      return UngroupedSessionConfigSelectOptions(
        options: json
            .map(
              (item) => SessionConfigSelectOption.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
      );
    }

    throw ArgumentError(
      'Invalid SessionConfigSelectOptions payload. '
      'Expected grouped or ungrouped options: $json',
    );
  }

  @override
  dynamic toJson(SessionConfigSelectOptions? object) {
    if (object == null) return null;
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
