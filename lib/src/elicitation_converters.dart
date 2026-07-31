import 'package:acp_dart/src/schema.dart';
import 'package:json_annotation/json_annotation.dart';

/// Converts the `elicitation/create` request union, discriminated on `mode`.
///
/// Unrecognised modes round-trip through [UnknownElicitationRequest] so that
/// future ACP variants and `_`-prefixed extensions are preserved rather than
/// dropped.
class CreateElicitationRequestConverter
    implements JsonConverter<CreateElicitationRequest, Map<String, dynamic>> {
  const CreateElicitationRequestConverter();

  @override
  CreateElicitationRequest fromJson(Map<String, dynamic> json) {
    final mode = json['mode'] as String?;
    if (mode == null) {
      return UnknownElicitationRequest(rawJson: json);
    }
    final data = Map<String, dynamic>.from(json)..remove('mode');
    switch (mode) {
      case 'form':
        return ElicitationFormRequest.fromJson(data);
      case 'url':
        return ElicitationUrlRequest.fromJson(data);
      default:
        return UnknownElicitationRequest(rawJson: json);
    }
  }

  @override
  Map<String, dynamic> toJson(CreateElicitationRequest object) {
    if (object is ElicitationFormRequest) {
      return {'mode': 'form', ...object.toJson()};
    }
    if (object is ElicitationUrlRequest) {
      return {'mode': 'url', ...object.toJson()};
    }
    if (object is UnknownElicitationRequest) {
      return object.rawJson;
    }
    throw ArgumentError.value(
      object,
      'object',
      'Unknown CreateElicitationRequest variant',
    );
  }
}

/// Converts the `elicitation/create` response union, discriminated on `action`.
class CreateElicitationResponseConverter
    implements JsonConverter<CreateElicitationResponse, Map<String, dynamic>> {
  const CreateElicitationResponseConverter();

  @override
  CreateElicitationResponse fromJson(Map<String, dynamic> json) {
    final action = json['action'] as String?;
    if (action == null) {
      return UnknownElicitationResponse(rawJson: json);
    }
    final data = Map<String, dynamic>.from(json)..remove('action');
    switch (action) {
      case 'accept':
        return ElicitationAcceptResponse.fromJson(data);
      case 'decline':
        return ElicitationDeclineResponse.fromJson(data);
      case 'cancel':
        return ElicitationCancelResponse.fromJson(data);
      default:
        return UnknownElicitationResponse(rawJson: json);
    }
  }

  @override
  Map<String, dynamic> toJson(CreateElicitationResponse object) {
    if (object is ElicitationAcceptResponse) {
      return {'action': 'accept', ...object.toJson()};
    }
    if (object is ElicitationDeclineResponse) {
      return {'action': 'decline', ...object.toJson()};
    }
    if (object is ElicitationCancelResponse) {
      return {'action': 'cancel', ...object.toJson()};
    }
    if (object is UnknownElicitationResponse) {
      return object.rawJson;
    }
    throw ArgumentError.value(
      object,
      'object',
      'Unknown CreateElicitationResponse variant',
    );
  }
}

/// Converts a single elicitation property schema, discriminated on `type`.
class ElicitationPropertySchemaConverter
    implements JsonConverter<ElicitationPropertySchema, Map<String, dynamic>> {
  const ElicitationPropertySchemaConverter();

  @override
  ElicitationPropertySchema fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) {
      return UnknownPropertySchema(rawJson: json);
    }
    final data = Map<String, dynamic>.from(json)..remove('type');
    switch (type) {
      case 'string':
        return StringPropertySchema.fromJson(data);
      case 'number':
        return NumberPropertySchema.fromJson(data);
      case 'integer':
        return IntegerPropertySchema.fromJson(data);
      case 'boolean':
        return BooleanPropertySchema.fromJson(data);
      case 'array':
        return MultiSelectPropertySchema.fromJson(data);
      default:
        return UnknownPropertySchema(rawJson: json);
    }
  }

  @override
  Map<String, dynamic> toJson(ElicitationPropertySchema object) {
    if (object is StringPropertySchema) {
      return {'type': 'string', ...object.toJson()};
    }
    if (object is NumberPropertySchema) {
      return {'type': 'number', ...object.toJson()};
    }
    if (object is IntegerPropertySchema) {
      return {'type': 'integer', ...object.toJson()};
    }
    if (object is BooleanPropertySchema) {
      return {'type': 'boolean', ...object.toJson()};
    }
    if (object is MultiSelectPropertySchema) {
      return {'type': 'array', ...object.toJson()};
    }
    if (object is UnknownPropertySchema) {
      return object.rawJson;
    }
    throw ArgumentError.value(
      object,
      'object',
      'Unknown ElicitationPropertySchema variant',
    );
  }
}

/// Converts the `properties` map of an [ElicitationSchema].
class ElicitationPropertySchemaMapConverter
    implements
        JsonConverter<
          Map<String, ElicitationPropertySchema>?,
          Map<String, dynamic>?
        > {
  const ElicitationPropertySchemaMapConverter();

  static const _entry = ElicitationPropertySchemaConverter();

  @override
  Map<String, ElicitationPropertySchema>? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return json.map(
      (key, value) =>
          MapEntry(key, _entry.fromJson(value as Map<String, dynamic>)),
    );
  }

  @override
  Map<String, dynamic>? toJson(Map<String, ElicitationPropertySchema>? object) {
    if (object == null) return null;
    return object.map((key, value) => MapEntry(key, _entry.toJson(value)));
  }
}

/// Converts multi-select item constraints.
///
/// The string form carries `type: "string"` plus an `enum` list; the titled
/// form carries `anyOf` and has no `type` discriminator, so it is detected by
/// the presence of `anyOf`.
class MultiSelectItemsConverter
    implements JsonConverter<MultiSelectItems, Map<String, dynamic>> {
  const MultiSelectItemsConverter();

  @override
  MultiSelectItems fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == 'string') {
      final data = Map<String, dynamic>.from(json)..remove('type');
      return StringMultiSelectItems.fromJson(data);
    }
    if (type == null && json.containsKey('anyOf')) {
      return TitledMultiSelectItems.fromJson(json);
    }
    return UnknownMultiSelectItems(rawJson: json);
  }

  @override
  Map<String, dynamic> toJson(MultiSelectItems object) {
    if (object is StringMultiSelectItems) {
      return {'type': 'string', ...object.toJson()};
    }
    if (object is TitledMultiSelectItems) {
      return object.toJson();
    }
    if (object is UnknownMultiSelectItems) {
      return object.rawJson;
    }
    throw ArgumentError.value(
      object,
      'object',
      'Unknown MultiSelectItems variant',
    );
  }
}
