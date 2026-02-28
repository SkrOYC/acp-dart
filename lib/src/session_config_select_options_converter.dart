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
