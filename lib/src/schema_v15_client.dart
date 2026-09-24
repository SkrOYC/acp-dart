import 'dart:convert';

import 'schema.dart';

/// Response to an ACP `elicitation/create` request.
///
/// Unknown action values and their fields are preserved for forward
/// compatibility.
class CreateElicitationResponse {
  final String action;
  final Map<String, dynamic> _wire;

  CreateElicitationResponse.fromJson(Map<String, dynamic> json)
    : action = _requiredString(json, 'action'),
      _wire = _copyObject(json) {
    if (action == 'accept') _validateAcceptedContent(_wire['content']);
  }

  CreateElicitationResponse.accept({
    Map<String, Object?>? content,
    Map<String, dynamic>? meta,
  }) : action = 'accept',
       _wire = {
         'action': 'accept',
         if (content != null) 'content': content,
         if (meta != null) '_meta': meta,
       } {
    _validateAcceptedContent(_wire['content']);
  }

  CreateElicitationResponse.decline({Map<String, dynamic>? meta})
    : action = 'decline',
      _wire = {'action': 'decline', if (meta != null) '_meta': meta};

  CreateElicitationResponse.cancel({Map<String, dynamic>? meta})
    : action = 'cancel',
      _wire = {'action': 'cancel', if (meta != null) '_meta': meta};

  CreateElicitationResponse.custom({
    required this.action,
    required Map<String, dynamic> fields,
  }) : _wire = _customActionWire(action, fields) {
    if (action == 'accept' || action == 'decline' || action == 'cancel') {
      throw ArgumentError.value(action, 'action', 'Must be a custom action');
    }
  }

  Map<String, dynamic> toJson() => _copyObject(_wire);

  Map<String, dynamic>? get meta => _optionalObject(_wire['_meta']);

  Map<String, dynamic>? get content => _optionalObject(_wire['content']);
}

/// Compatibility name for early v1.5 model users.
typedef ElicitationResponseV15 = CreateElicitationResponse;

/// Notification sent when a URL-based elicitation completes.
class CompleteElicitationNotification {
  final String elicitationId;
  final Map<String, dynamic>? meta;

  CompleteElicitationNotification.fromJson(Map<String, dynamic> json)
    : elicitationId = _requiredString(json, 'elicitationId'),
      meta = _optionalObject(json['_meta']);

  const CompleteElicitationNotification({
    this.meta,
    required this.elicitationId,
  });

  Map<String, dynamic> toJson() => {
    'elicitationId': elicitationId,
    if (meta != null) '_meta': meta,
  };
}

typedef CompleteElicitationNotificationV15 = CompleteElicitationNotification;

/// Property schema supported by ACP elicitation forms.
abstract class ElicitationPropertySchema {
  const ElicitationPropertySchema();
  Map<String, dynamic> toJson();
}

enum StringFormat { email, uri, date, dateTime }

class EnumOption {
  final String constValue;
  final String title;
  final String? description;
  final Map<String, dynamic>? meta;

  const EnumOption({
    required this.constValue,
    required this.title,
    this.description,
    this.meta,
  });

  Map<String, dynamic> toJson() => {
    'const': constValue,
    'title': title,
    if (description != null) 'description': description,
    if (meta != null) '_meta': meta,
  };
}

class StringPropertySchema extends ElicitationPropertySchema {
  final String? title;
  final String? description;
  final num? minLength;
  final num? maxLength;
  final String? pattern;
  final StringFormat? format;
  final String? defaultValue;
  final List<String>? enumValues;
  final List<EnumOption>? oneOf;
  final Map<String, dynamic>? meta;

  const StringPropertySchema({
    this.title,
    this.description,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.format,
    this.defaultValue,
    this.enumValues,
    this.oneOf,
    this.meta,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'string',
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (minLength != null) 'minLength': minLength,
    if (maxLength != null) 'maxLength': maxLength,
    if (pattern != null) 'pattern': pattern,
    if (format != null) 'format': _stringFormat(format!),
    if (defaultValue != null) 'default': defaultValue,
    if (enumValues != null) 'enum': enumValues,
    if (oneOf != null)
      'oneOf': oneOf!.map((option) => option.toJson()).toList(),
    if (meta != null) '_meta': meta,
  };
}

class NumberPropertySchema extends ElicitationPropertySchema {
  final String? title;
  final String? description;
  final num? minimum;
  final num? maximum;
  final num? defaultValue;
  final Map<String, dynamic>? meta;

  const NumberPropertySchema({
    this.title,
    this.description,
    this.minimum,
    this.maximum,
    this.defaultValue,
    this.meta,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'number',
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (minimum != null) 'minimum': minimum,
    if (maximum != null) 'maximum': maximum,
    if (defaultValue != null) 'default': defaultValue,
    if (meta != null) '_meta': meta,
  };
}

class IntegerPropertySchema extends ElicitationPropertySchema {
  final String? title;
  final String? description;
  final num? minimum;
  final num? maximum;
  final num? defaultValue;
  final Map<String, dynamic>? meta;

  const IntegerPropertySchema({
    this.title,
    this.description,
    this.minimum,
    this.maximum,
    this.defaultValue,
    this.meta,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'integer',
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (minimum != null) 'minimum': minimum,
    if (maximum != null) 'maximum': maximum,
    if (defaultValue != null) 'default': defaultValue,
    if (meta != null) '_meta': meta,
  };
}

class BooleanPropertySchema extends ElicitationPropertySchema {
  final String? title;
  final String? description;
  final bool? defaultValue;
  final Map<String, dynamic>? meta;

  const BooleanPropertySchema({
    this.title,
    this.description,
    this.defaultValue,
    this.meta,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'boolean',
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (defaultValue != null) 'default': defaultValue,
    if (meta != null) '_meta': meta,
  };
}

abstract class MultiSelectItems {
  const MultiSelectItems();
  Map<String, dynamic> toJson();
}

class StringMultiSelectItems extends MultiSelectItems {
  final List<String> enumValues;
  final Map<String, dynamic>? meta;

  const StringMultiSelectItems({required this.enumValues, this.meta});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'string',
    'enum': enumValues,
    if (meta != null) '_meta': meta,
  };
}

class TitledMultiSelectItems extends MultiSelectItems {
  final List<EnumOption> anyOf;
  final Map<String, dynamic>? meta;

  const TitledMultiSelectItems({required this.anyOf, this.meta});

  @override
  Map<String, dynamic> toJson() => {
    'anyOf': anyOf.map((option) => option.toJson()).toList(),
    if (meta != null) '_meta': meta,
  };
}

class CustomMultiSelectItems extends MultiSelectItems {
  final String type;
  final Map<String, dynamic> fields;

  CustomMultiSelectItems({required this.type, this.fields = const {}}) {
    if (fields.containsKey('type')) {
      throw ArgumentError.value(fields, 'fields', 'Must not override type');
    }
  }

  @override
  Map<String, dynamic> toJson() => {'type': type, ...fields};
}

class MultiSelectPropertySchema extends ElicitationPropertySchema {
  final String? title;
  final String? description;
  final num? minItems;
  final num? maxItems;
  final MultiSelectItems items;
  final List<String>? defaultValues;
  final Map<String, dynamic>? meta;

  const MultiSelectPropertySchema({
    this.title,
    this.description,
    this.minItems,
    this.maxItems,
    required this.items,
    this.defaultValues,
    this.meta,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'array',
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (minItems != null) 'minItems': minItems,
    if (maxItems != null) 'maxItems': maxItems,
    'items': items.toJson(),
    if (defaultValues != null) 'default': defaultValues,
    if (meta != null) '_meta': meta,
  };
}

class CustomElicitationPropertySchema extends ElicitationPropertySchema {
  final String type;
  final Map<String, dynamic> fields;

  CustomElicitationPropertySchema({
    required this.type,
    this.fields = const {},
  }) {
    if (fields.containsKey('type')) {
      throw ArgumentError.value(fields, 'fields', 'Must not override type');
    }
  }

  @override
  Map<String, dynamic> toJson() => {'type': type, ...fields};
}

/// Extensible v1.5 session update payload preservation helper.
class SessionUpdateV15 {
  final String sessionUpdate;
  final Map<String, dynamic> _wire;

  SessionUpdateV15.fromJson(Map<String, dynamic> json)
    : sessionUpdate = _requiredString(json, 'sessionUpdate'),
      _wire = _copyObject(json);

  Map<String, dynamic> toJson() => _copyObject(_wire);
}

/// A v1.5 advisory notice session update.
class NoticeSessionUpdateV15 extends SessionUpdate {
  final String severity;
  final String title;
  final String? description;
  final Map<String, dynamic>? meta;

  NoticeSessionUpdateV15({
    required this.severity,
    required this.title,
    this.description,
    this.meta,
  });

  factory NoticeSessionUpdateV15.fromJson(Map<String, dynamic> json) {
    if (json['sessionUpdate'] != 'notice') {
      throw FormatException('Expected sessionUpdate to be "notice"');
    }
    final title = _requiredString(json, 'title');
    if (title.isEmpty) {
      throw FormatException('Expected a non-empty notice title');
    }
    return NoticeSessionUpdateV15(
      severity: _requiredString(json, 'severity'),
      title: title,
      description: json['description'] as String?,
      meta: _optionalObject(json['_meta']),
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionUpdate': 'notice',
    'severity': severity,
    'title': title,
    if (description != null) 'description': description,
    if (meta != null) '_meta': meta,
  };
}

String _stringFormat(StringFormat format) => switch (format) {
  StringFormat.email => 'email',
  StringFormat.uri => 'uri',
  StringFormat.date => 'date',
  StringFormat.dateTime => 'date-time',
};

Map<String, dynamic> _customActionWire(
  String action,
  Map<String, dynamic> fields,
) {
  if (fields.containsKey('action')) {
    throw ArgumentError.value(fields, 'fields', 'Must not override action');
  }
  return {'action': action, ...fields};
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Expected "$key" to be a string');
  }
  return value;
}

void _validateAcceptedContent(Object? content) {
  if (content == null) return;
  if (content is! Map) {
    throw FormatException('Expected accepted content to be an object or null');
  }
  for (final entry in content.entries) {
    final value = entry.value;
    final valid =
        value is String ||
        value is bool ||
        (value is num && value.isFinite) ||
        (value is List && value.every((item) => item is String));
    if (entry.key is! String || !valid) {
      throw FormatException('Invalid elicitation content value');
    }
  }
}

Map<String, dynamic> _copyObject(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

Map<String, dynamic>? _optionalObject(Object? value) {
  if (value == null) return null;
  if (value is! Map) throw FormatException('Expected an object or null');
  return Map<String, dynamic>.from(value);
}
