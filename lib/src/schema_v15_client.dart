import 'dart:convert';

/// Client-side payloads introduced or expanded in ACP TypeScript SDK v1.5.0.
///
/// The wire fields remain extensible so custom and future actions and update
/// variants survive a decode and encode cycle.
class ElicitationResponseV15 {
  final String action;
  final Map<String, dynamic> _wire;

  ElicitationResponseV15.fromJson(Map<String, dynamic> json)
    : action = _requiredString(json, 'action'),
      _wire = _copyObject(json) {
    if (action == 'accept') _validateAcceptedContent(_wire['content']);
  }

  Map<String, dynamic> toJson() => _copyObject(_wire);

  Map<String, dynamic>? get meta => _optionalObject(_wire['_meta']);

  Map<String, dynamic>? get content => _optionalObject(_wire['content']);
}

/// Notification that a URL-based elicitation has completed.
class CompleteElicitationNotificationV15 {
  final String elicitationId;
  final Map<String, dynamic> _wire;

  CompleteElicitationNotificationV15.fromJson(Map<String, dynamic> json)
    : elicitationId = _requiredString(json, 'elicitationId'),
      _wire = _copyObject(json);

  CompleteElicitationNotificationV15({
    required this.elicitationId,
    Map<String, dynamic>? meta,
  }) : _wire = {
         'elicitationId': elicitationId,
         if (meta != null) '_meta': meta,
       };

  Map<String, dynamic> toJson() => _copyObject(_wire);

  Map<String, dynamic>? get meta => _optionalObject(_wire['_meta']);
}

/// Extensible v1.5 session update payload.
///
/// Known variants include plan updates/removals, notices, and compaction
/// updates. Unknown variants retain their complete wire payload.
class SessionUpdateV15 {
  final String sessionUpdate;
  final Map<String, dynamic> _wire;

  SessionUpdateV15.fromJson(Map<String, dynamic> json)
    : sessionUpdate = _requiredString(json, 'sessionUpdate'),
      _wire = _copyObject(json);

  Map<String, dynamic> toJson() => _copyObject(_wire);
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
        value is num ||
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
