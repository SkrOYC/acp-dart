import 'package:acp_dart/src/schema.dart';
import 'package:json_annotation/json_annotation.dart';

/// Converts a single Next Edit Suggestion, discriminated on `kind`.
///
/// Unrecognised kinds round-trip through [UnknownNesSuggestion] so a client
/// on an older build can pass a newer suggestion through untouched instead of
/// dropping it.
class NesSuggestionConverter
    implements JsonConverter<NesSuggestion, Map<String, dynamic>> {
  const NesSuggestionConverter();

  @override
  NesSuggestion fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String?;
    if (kind == null) {
      return UnknownNesSuggestion(rawJson: json);
    }
    final data = Map<String, dynamic>.from(json)..remove('kind');
    switch (kind) {
      case 'edit':
        return NesEditSuggestion.fromJson(data);
      case 'jump':
        return NesJumpSuggestion.fromJson(data);
      case 'rename':
        return NesRenameSuggestion.fromJson(data);
      case 'searchAndReplace':
        return NesSearchAndReplaceSuggestion.fromJson(data);
      default:
        return UnknownNesSuggestion(rawJson: json);
    }
  }

  @override
  Map<String, dynamic> toJson(NesSuggestion object) {
    if (object is NesEditSuggestion) {
      return {'kind': 'edit', ...object.toJson()};
    }
    if (object is NesJumpSuggestion) {
      return {'kind': 'jump', ...object.toJson()};
    }
    if (object is NesRenameSuggestion) {
      return {'kind': 'rename', ...object.toJson()};
    }
    if (object is NesSearchAndReplaceSuggestion) {
      return {'kind': 'searchAndReplace', ...object.toJson()};
    }
    if (object is UnknownNesSuggestion) {
      return object.rawJson;
    }
    throw ArgumentError.value(
      object,
      'object',
      'Unknown NesSuggestion variant',
    );
  }
}

/// Converts the `suggestions` list on a `nes/suggest` response.
class NesSuggestionListConverter
    implements JsonConverter<List<NesSuggestion>, List<dynamic>> {
  const NesSuggestionListConverter();

  static const _entry = NesSuggestionConverter();

  @override
  List<NesSuggestion> fromJson(List<dynamic> json) => json
      .map((value) => _entry.fromJson(value as Map<String, dynamic>))
      .toList();

  @override
  List<dynamic> toJson(List<NesSuggestion> object) =>
      object.map(_entry.toJson).toList();
}
