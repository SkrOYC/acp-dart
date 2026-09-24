// Experimental payloads from the TypeScript SDK v1.5 schema.
import 'schema.dart';

typedef V15Json = Map<String, dynamic>;

V15Json _map(Object? value, String field) {
  if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
  throw FormatException('Expected an object for $field');
}

Object? _metaValue(V15Json json) {
  final value = json['_meta'];
  if (value != null) _map(value, '_meta');
  return value;
}

List<Object?> _list(Object? value, String field) {
  if (value is List) return value.cast<Object?>();
  throw FormatException('Expected an array for $field');
}

V15Json _unknownFields(V15Json source, Set<String> known) =>
    Map<String, dynamic>.fromEntries(
      source.entries.where((entry) => !known.contains(entry.key)),
    );

V15Json _extras(
  V15Json source,
  Set<String> known, [
  Set<String> preserveNull = const {},
]) => {
  ..._unknownFields(source, known),
  for (final key in preserveNull)
    if (source.containsKey(key) && source[key] == null) key: null,
  if (source.containsKey('_meta')) '_meta': source['_meta'],
};

V15Json _stringMap(Object? value, String field) => {
  for (final entry in _map(value, field).entries)
    entry.key: entry.value as String,
};

List<V15Json> _objectList(Object? value, String field) =>
    _list(value, field).map((item) => _map(item, '$field[]')).toList();

V15Json _encode(Map<String, dynamic> extras, Map<String, dynamic> known) =>
    <String, dynamic>{...extras, ...known};

class V15ListProvidersResponse {
  final List<V15ProviderInfo> providers;
  final Object? meta;
  final V15Json extras;
  V15ListProvidersResponse({
    required this.providers,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15ListProvidersResponse.fromJson(V15Json json) =>
      V15ListProvidersResponse(
        providers: _list(
          json['providers'],
          'providers',
        ).map((e) => V15ProviderInfo.fromJson(_map(e, 'providers[]'))).toList(),
        meta: _metaValue(json),
        extras: _extras(json, {'providers', '_meta'}),
      );
  V15Json toJson() => _encode(extras, {
    'providers': providers.map((e) => e.toJson()).toList(),
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15ProviderInfo {
  final String providerId;
  final List<String> supported;
  final bool required;
  final V15ProviderCurrentConfig? current;
  final Object? meta;
  final V15Json extras;
  V15ProviderInfo({
    required this.providerId,
    required this.supported,
    required this.required,
    this.current,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15ProviderInfo.fromJson(V15Json json) => V15ProviderInfo(
    providerId: json['providerId'] as String,
    supported: _list(json['supported'], 'supported').cast<String>(),
    required: json['required'] as bool,
    current: json['current'] == null
        ? null
        : V15ProviderCurrentConfig.fromJson(_map(json['current'], 'current')),
    meta: _metaValue(json),
    extras: _extras(
      json,
      {'providerId', 'supported', 'required', 'current', '_meta'},
      {'current'},
    ),
  );
  V15Json toJson() => _encode(extras, {
    'providerId': providerId,
    'supported': supported,
    'required': required,
    if (current != null || extras.containsKey('current'))
      'current': current?.toJson(),
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15ProviderCurrentConfig {
  final String apiType;
  final String baseUrl;
  final Object? meta;
  final V15Json extras;
  V15ProviderCurrentConfig({
    required this.apiType,
    required this.baseUrl,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15ProviderCurrentConfig.fromJson(V15Json json) =>
      V15ProviderCurrentConfig(
        apiType: json['apiType'] as String,
        baseUrl: json['baseUrl'] as String,
        meta: _metaValue(json),
        extras: _extras(json, {'apiType', 'baseUrl', '_meta'}),
      );
  V15Json toJson() => _encode(extras, {
    'apiType': apiType,
    'baseUrl': baseUrl,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15MessageMcpRequest {
  final String connectionId;
  final String method;
  final V15Json? params;
  final Object? meta;
  final V15Json extras;
  V15MessageMcpRequest({
    required this.connectionId,
    required this.method,
    this.params,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15MessageMcpRequest.fromJson(V15Json json) => V15MessageMcpRequest(
    connectionId: json['connectionId'] as String,
    method: json['method'] as String,
    params: json['params'] == null ? null : _map(json['params'], 'params'),
    meta: _metaValue(json),
    extras: _extras(
      json,
      {'connectionId', 'method', 'params', '_meta'},
      {'params'},
    ),
  );
  V15Json toJson() => _encode(extras, {
    'connectionId': connectionId,
    'method': method,
    if (params != null || extras.containsKey('params')) 'params': params,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15MessageMcpResponse {
  final Object? value;
  const V15MessageMcpResponse(this.value);
  factory V15MessageMcpResponse.fromJson(Object? json) =>
      V15MessageMcpResponse(json);
  Object? toJson() => value;
}

class V15ConnectMcpRequest {
  final String serverId;
  final Object? meta;
  final V15Json extras;
  V15ConnectMcpRequest({required this.serverId, this.meta, V15Json? extras})
    : extras = extras ?? {};
  factory V15ConnectMcpRequest.fromJson(V15Json json) => V15ConnectMcpRequest(
    serverId: json['serverId'] as String,
    meta: _metaValue(json),
    extras: _extras(json, {'serverId', '_meta'}),
  );
  V15Json toJson() => _encode(extras, {
    'serverId': serverId,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15DisconnectMcpRequest {
  final String connectionId;
  final Object? meta;
  final V15Json extras;
  V15DisconnectMcpRequest({
    required this.connectionId,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15DisconnectMcpRequest.fromJson(V15Json json) =>
      V15DisconnectMcpRequest(
        connectionId: json['connectionId'] as String,
        meta: _metaValue(json),
        extras: _extras(json, {'connectionId', '_meta'}),
      );
  V15Json toJson() => _encode(extras, {
    'connectionId': connectionId,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15ConnectMcpResponse {
  final String connectionId;
  final Object? meta;
  final V15Json extras;
  V15ConnectMcpResponse({
    required this.connectionId,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15ConnectMcpResponse.fromJson(V15Json json) => V15ConnectMcpResponse(
    connectionId: json['connectionId'] as String,
    meta: _metaValue(json),
    extras: _extras(json, {'connectionId', '_meta'}),
  );
  V15Json toJson() => _encode(extras, {
    'connectionId': connectionId,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15DisconnectMcpResponse {
  final Object? meta;
  final V15Json extras;
  V15DisconnectMcpResponse({this.meta, V15Json? extras})
    : extras = extras ?? {};
  factory V15DisconnectMcpResponse.fromJson(V15Json json) =>
      V15DisconnectMcpResponse(
        meta: _metaValue(json),
        extras: _extras(json, {'_meta'}),
      );
  V15Json toJson() => _encode(extras, {
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15MessageMcpNotification {
  final String connectionId;
  final String method;
  final V15Json? params;
  final Object? meta;
  final V15Json extras;
  V15MessageMcpNotification({
    required this.connectionId,
    required this.method,
    this.params,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15MessageMcpNotification.fromJson(V15Json json) =>
      V15MessageMcpNotification(
        connectionId: json['connectionId'] as String,
        method: json['method'] as String,
        params: json['params'] == null ? null : _map(json['params'], 'params'),
        meta: _metaValue(json),
        extras: _extras(
          json,
          {'connectionId', 'method', 'params', '_meta'},
          {'params'},
        ),
      );
  V15Json toJson() => _encode(extras, {
    'connectionId': connectionId,
    'method': method,
    if (params != null || extras.containsKey('params')) 'params': params,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15SetProviderRequest {
  final String providerId;
  final String apiType;
  final String baseUrl;
  final V15Json? headers;
  final Object? meta;
  final V15Json extras;
  V15SetProviderRequest({
    required this.providerId,
    required this.apiType,
    required this.baseUrl,
    this.headers,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15SetProviderRequest.fromJson(V15Json json) => V15SetProviderRequest(
    providerId: json['providerId'] as String,
    apiType: json['apiType'] as String,
    baseUrl: json['baseUrl'] as String,
    headers: json['headers'] == null
        ? null
        : _stringMap(json['headers'], 'headers'),
    meta: _metaValue(json),
    extras: _extras(
      json,
      {'providerId', 'apiType', 'baseUrl', 'headers', '_meta'},
      {'headers'},
    ),
  );
  V15Json toJson() => _encode(extras, {
    'providerId': providerId,
    'apiType': apiType,
    'baseUrl': baseUrl,
    if (headers != null || extras.containsKey('headers')) 'headers': headers,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15ListProvidersRequest {
  final Object? meta;
  final V15Json extras;
  V15ListProvidersRequest({this.meta, V15Json? extras}) : extras = extras ?? {};
  factory V15ListProvidersRequest.fromJson(V15Json json) =>
      V15ListProvidersRequest(
        meta: _metaValue(json),
        extras: _extras(json, {'_meta'}),
      );
  V15Json toJson() => _encode(extras, {
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15ProviderMutationResponse {
  final Object? meta;
  final V15Json extras;
  V15ProviderMutationResponse({this.meta, V15Json? extras})
    : extras = extras ?? {};
  factory V15ProviderMutationResponse.fromJson(V15Json json) =>
      V15ProviderMutationResponse(
        meta: _metaValue(json),
        extras: _extras(json, {'_meta'}),
      );
  V15Json toJson() => _encode(extras, {
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15DisableProviderRequest {
  final String providerId;
  final Object? meta;
  final V15Json extras;
  V15DisableProviderRequest({
    required this.providerId,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15DisableProviderRequest.fromJson(V15Json json) =>
      V15DisableProviderRequest(
        providerId: json['providerId'] as String,
        meta: _metaValue(json),
        extras: _extras(json, {'providerId', '_meta'}),
      );
  V15Json toJson() => _encode(extras, {
    'providerId': providerId,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15TextDocumentContentChangeEvent {
  final V15Range? range;
  final String text;
  final Object? meta;
  final V15Json extras;
  V15TextDocumentContentChangeEvent({
    this.range,
    required this.text,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15TextDocumentContentChangeEvent.fromJson(V15Json json) =>
      V15TextDocumentContentChangeEvent(
        range: json['range'] == null
            ? null
            : V15Range.fromJson(_map(json['range'], 'range')),
        text: json['text'] as String,
        meta: _metaValue(json),
        extras: _extras(json, {'range', 'text', '_meta'}, {'range'}),
      );
  V15Json toJson() => _encode(extras, {
    if (range != null || extras.containsKey('range')) 'range': range?.toJson(),
    'text': text,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15DidChangeDocumentNotification {
  final String sessionId;
  final String uri;
  final int version;
  final List<V15TextDocumentContentChangeEvent> contentChanges;
  final Object? meta;
  final V15Json extras;
  V15DidChangeDocumentNotification({
    required this.sessionId,
    required this.uri,
    required this.version,
    required this.contentChanges,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15DidChangeDocumentNotification.fromJson(V15Json json) =>
      V15DidChangeDocumentNotification(
        sessionId: json['sessionId'] as String,
        uri: json['uri'] as String,
        version: json['version'] as int,
        contentChanges: _list(json['contentChanges'], 'contentChanges')
            .map(
              (e) => V15TextDocumentContentChangeEvent.fromJson(
                _map(e, 'contentChanges[]'),
              ),
            )
            .toList(),
        meta: _metaValue(json),
        extras: _extras(json, {
          'sessionId',
          'uri',
          'version',
          'contentChanges',
          '_meta',
        }),
      );
  V15Json toJson() => _encode(extras, {
    'sessionId': sessionId,
    'uri': uri,
    'version': version,
    'contentChanges': contentChanges.map((e) => e.toJson()).toList(),
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15DidOpenDocumentNotification {
  final String sessionId;
  final String uri;
  final String languageId;
  final int version;
  final String text;
  final Object? meta;
  final V15Json extras;
  V15DidOpenDocumentNotification({
    required this.sessionId,
    required this.uri,
    required this.languageId,
    required this.version,
    required this.text,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15DidOpenDocumentNotification.fromJson(V15Json json) =>
      V15DidOpenDocumentNotification(
        sessionId: json['sessionId'] as String,
        uri: json['uri'] as String,
        languageId: json['languageId'] as String,
        version: json['version'] as int,
        text: json['text'] as String,
        meta: _metaValue(json),
        extras: _extras(json, {
          'sessionId',
          'uri',
          'languageId',
          'version',
          'text',
          '_meta',
        }),
      );
  V15Json toJson() => _encode(extras, {
    'sessionId': sessionId,
    'uri': uri,
    'languageId': languageId,
    'version': version,
    'text': text,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15DidCloseDocumentNotification {
  final String sessionId;
  final String uri;
  final Object? meta;
  final V15Json extras;
  V15DidCloseDocumentNotification({
    required this.sessionId,
    required this.uri,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15DidCloseDocumentNotification.fromJson(V15Json json) =>
      V15DidCloseDocumentNotification(
        sessionId: json['sessionId'] as String,
        uri: json['uri'] as String,
        meta: _metaValue(json),
        extras: _extras(json, {'sessionId', 'uri', '_meta'}),
      );
  V15Json toJson() => _encode(extras, {
    'sessionId': sessionId,
    'uri': uri,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15DidSaveDocumentNotification extends V15DidCloseDocumentNotification {
  V15DidSaveDocumentNotification({
    required super.sessionId,
    required super.uri,
    super.meta,
    super.extras,
  });
  factory V15DidSaveDocumentNotification.fromJson(V15Json json) =>
      V15DidSaveDocumentNotification(
        sessionId: json['sessionId'] as String,
        uri: json['uri'] as String,
        meta: _metaValue(json),
        extras: _extras(json, {'sessionId', 'uri', '_meta'}),
      );
}

class V15DidFocusDocumentNotification {
  final String sessionId;
  final String uri;
  final int version;
  final V15Position position;
  final V15Range visibleRange;
  final Object? meta;
  final V15Json extras;
  V15DidFocusDocumentNotification({
    required this.sessionId,
    required this.uri,
    required this.version,
    required this.position,
    required this.visibleRange,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15DidFocusDocumentNotification.fromJson(V15Json json) =>
      V15DidFocusDocumentNotification(
        sessionId: json['sessionId'] as String,
        uri: json['uri'] as String,
        version: json['version'] as int,
        position: V15Position.fromJson(_map(json['position'], 'position')),
        visibleRange: V15Range.fromJson(
          _map(json['visibleRange'], 'visibleRange'),
        ),
        meta: _metaValue(json),
        extras: _extras(json, {
          'sessionId',
          'uri',
          'version',
          'position',
          'visibleRange',
          '_meta',
        }),
      );
  V15Json toJson() => _encode(extras, {
    'sessionId': sessionId,
    'uri': uri,
    'version': version,
    'position': position.toJson(),
    'visibleRange': visibleRange.toJson(),
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15AcceptNesNotification {
  final String sessionId;
  final String id;
  final Object? meta;
  final V15Json extras;
  V15AcceptNesNotification({
    required this.sessionId,
    required this.id,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15AcceptNesNotification.fromJson(V15Json json) =>
      V15AcceptNesNotification(
        sessionId: json['sessionId'] as String,
        id: json['id'] as String,
        meta: _metaValue(json),
        extras: _extras(json, {'sessionId', 'id', '_meta'}),
      );
  V15Json toJson() => _encode(extras, {
    'sessionId': sessionId,
    'id': id,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15RejectNesNotification extends V15AcceptNesNotification {
  final String? reason;
  V15RejectNesNotification({
    required super.sessionId,
    required super.id,
    super.meta,
    super.extras,
    this.reason,
  });
  factory V15RejectNesNotification.fromJson(V15Json json) =>
      V15RejectNesNotification(
        sessionId: json['sessionId'] as String,
        id: json['id'] as String,
        reason: json['reason'] as String?,
        meta: _metaValue(json),
        extras: _extras(
          json,
          {'sessionId', 'id', 'reason', '_meta'},
          {'reason'},
        ),
      );
  @override
  V15Json toJson() => _encode(extras, {
    'sessionId': sessionId,
    'id': id,
    if (reason != null || extras.containsKey('reason')) 'reason': reason,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15Position {
  final int line;
  final int character;
  final Object? meta;
  final V15Json extras;
  V15Position({
    required this.line,
    required this.character,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15Position.fromJson(V15Json json) => V15Position(
    line: json['line'] as int,
    character: json['character'] as int,
    meta: _metaValue(json),
    extras: _extras(json, {'line', 'character', '_meta'}),
  );
  V15Json toJson() => _encode(extras, {
    'line': line,
    'character': character,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15Range {
  final V15Position start;
  final V15Position end;
  final Object? meta;
  final V15Json extras;
  V15Range({required this.start, required this.end, this.meta, V15Json? extras})
    : extras = extras ?? {};
  factory V15Range.fromJson(V15Json json) => V15Range(
    start: V15Position.fromJson(_map(json['start'], 'start')),
    end: V15Position.fromJson(_map(json['end'], 'end')),
    meta: _metaValue(json),
    extras: _extras(json, {'start', 'end', '_meta'}),
  );
  V15Json toJson() => _encode(extras, {
    'start': start.toJson(),
    'end': end.toJson(),
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

abstract class V15NesSuggestion {
  const V15NesSuggestion();
  String get kind;
  String get id;
  V15Json toJson();
  factory V15NesSuggestion.fromJson(V15Json json) {
    switch (json['kind']) {
      case 'edit':
        return V15NesEditSuggestion.fromJson(json);
      case 'jump':
        return V15NesJumpSuggestion.fromJson(json);
      case 'rename':
        return V15NesRenameSuggestion.fromJson(json);
      case 'searchAndReplace':
        return V15NesSearchAndReplaceSuggestion.fromJson(json);
      default:
        throw FormatException('Unknown NES suggestion kind: ${json['kind']}');
    }
  }
}

abstract class _V15NesSuggestionBase extends V15NesSuggestion {
  @override
  final String id;
  final String uri;
  final Object? meta;
  final V15Json extras;
  const _V15NesSuggestionBase({
    required this.id,
    required this.uri,
    this.meta,
    required this.extras,
  });
}

class V15NesTextEdit {
  final V15Range range;
  final String newText;
  final Object? meta;
  final V15Json extras;
  V15NesTextEdit({
    required this.range,
    required this.newText,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15NesTextEdit.fromJson(V15Json json) => V15NesTextEdit(
    range: V15Range.fromJson(_map(json['range'], 'range')),
    newText: json['newText'] as String,
    meta: _metaValue(json),
    extras: _extras(json, {'range', 'newText', '_meta'}),
  );
  V15Json toJson() => _encode(extras, {
    'range': range.toJson(),
    'newText': newText,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15NesEditSuggestion extends _V15NesSuggestionBase {
  final List<V15NesTextEdit> edits;
  final V15Position? cursorPosition;
  const V15NesEditSuggestion({
    required super.id,
    required super.uri,
    required this.edits,
    this.cursorPosition,
    super.meta,
    required super.extras,
  });
  @override
  String get kind => 'edit';
  factory V15NesEditSuggestion.fromJson(V15Json json) => V15NesEditSuggestion(
    id: json['id'] as String,
    uri: json['uri'] as String,
    edits: _objectList(
      json['edits'],
      'edits',
    ).map(V15NesTextEdit.fromJson).toList(),
    cursorPosition: json['cursorPosition'] == null
        ? null
        : V15Position.fromJson(_map(json['cursorPosition'], 'cursorPosition')),
    meta: _metaValue(json),
    extras: _extras(
      json,
      {'kind', 'id', 'uri', 'edits', 'cursorPosition', '_meta'},
      {'cursorPosition'},
    ),
  );
  @override
  V15Json toJson() => _encode(extras, {
    'kind': kind,
    'id': id,
    'uri': uri,
    'edits': edits.map((edit) => edit.toJson()).toList(),
    if (cursorPosition != null || extras.containsKey('cursorPosition'))
      'cursorPosition': cursorPosition?.toJson(),
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15NesJumpSuggestion extends _V15NesSuggestionBase {
  final V15Position position;
  const V15NesJumpSuggestion({
    required super.id,
    required super.uri,
    required this.position,
    super.meta,
    required super.extras,
  });
  @override
  String get kind => 'jump';
  factory V15NesJumpSuggestion.fromJson(V15Json json) => V15NesJumpSuggestion(
    id: json['id'] as String,
    uri: json['uri'] as String,
    position: V15Position.fromJson(_map(json['position'], 'position')),
    meta: _metaValue(json),
    extras: _extras(json, {'kind', 'id', 'uri', 'position', '_meta'}),
  );
  @override
  V15Json toJson() => _encode(extras, {
    'kind': kind,
    'id': id,
    'uri': uri,
    'position': position.toJson(),
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15NesRenameSuggestion extends _V15NesSuggestionBase {
  final V15Position position;
  final String newName;
  const V15NesRenameSuggestion({
    required super.id,
    required super.uri,
    required this.position,
    required this.newName,
    super.meta,
    required super.extras,
  });
  @override
  String get kind => 'rename';
  factory V15NesRenameSuggestion.fromJson(V15Json json) =>
      V15NesRenameSuggestion(
        id: json['id'] as String,
        uri: json['uri'] as String,
        position: V15Position.fromJson(_map(json['position'], 'position')),
        newName: json['newName'] as String,
        meta: _metaValue(json),
        extras: _extras(json, {
          'kind',
          'id',
          'uri',
          'position',
          'newName',
          '_meta',
        }),
      );
  @override
  V15Json toJson() => _encode(extras, {
    'kind': kind,
    'id': id,
    'uri': uri,
    'position': position.toJson(),
    'newName': newName,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15NesSearchAndReplaceSuggestion extends _V15NesSuggestionBase {
  final String search;
  final String replace;
  final bool? isRegex;
  const V15NesSearchAndReplaceSuggestion({
    required super.id,
    required super.uri,
    required this.search,
    required this.replace,
    this.isRegex,
    super.meta,
    required super.extras,
  });
  @override
  String get kind => 'searchAndReplace';
  factory V15NesSearchAndReplaceSuggestion.fromJson(V15Json json) =>
      V15NesSearchAndReplaceSuggestion(
        id: json['id'] as String,
        uri: json['uri'] as String,
        search: json['search'] as String,
        replace: json['replace'] as String,
        isRegex: json['isRegex'] as bool?,
        meta: _metaValue(json),
        extras: _extras(
          json,
          {'kind', 'id', 'uri', 'search', 'replace', 'isRegex', '_meta'},
          {'isRegex'},
        ),
      );
  @override
  V15Json toJson() => _encode(extras, {
    'kind': kind,
    'id': id,
    'uri': uri,
    'search': search,
    'replace': replace,
    if (isRegex != null || extras.containsKey('isRegex')) 'isRegex': isRegex,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15SuggestNesRequest {
  final String sessionId;
  final String uri;
  final int version;
  final V15Position position;
  final String triggerKind;
  final V15Range? selection;
  final V15NesSuggestContext? context;
  final Object? meta;
  final V15Json extras;
  V15SuggestNesRequest({
    required this.sessionId,
    required this.uri,
    required this.version,
    required this.position,
    required this.triggerKind,
    this.selection,
    this.context,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15SuggestNesRequest.fromJson(V15Json json) => V15SuggestNesRequest(
    sessionId: json['sessionId'] as String,
    uri: json['uri'] as String,
    version: json['version'] as int,
    position: V15Position.fromJson(_map(json['position'], 'position')),
    triggerKind: _nesTriggerKind(json['triggerKind']),
    selection: json['selection'] == null
        ? null
        : V15Range.fromJson(_map(json['selection'], 'selection')),
    context: json['context'] == null
        ? null
        : V15NesSuggestContext.fromJson(_map(json['context'], 'context')),
    meta: _metaValue(json),
    extras: _extras(
      json,
      {
        'sessionId',
        'uri',
        'version',
        'position',
        'triggerKind',
        'selection',
        'context',
        '_meta',
      },
      {'selection', 'context'},
    ),
  );
  V15Json toJson() => _encode(extras, {
    'sessionId': sessionId,
    'uri': uri,
    'version': version,
    'position': position.toJson(),
    'triggerKind': triggerKind,
    if (selection != null || extras.containsKey('selection'))
      'selection': selection?.toJson(),
    if (context != null || extras.containsKey('context'))
      'context': context?.toJson(),
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

abstract class V15PlanUpdateContent {
  const V15PlanUpdateContent();
  String get type;
  V15Json toJson();
  factory V15PlanUpdateContent.fromJson(V15Json json) {
    switch (json['type']) {
      case 'items':
        return V15PlanItems.fromJson(json);
      case 'file':
        return V15PlanFile.fromJson(json);
      case 'markdown':
        return V15PlanMarkdown.fromJson(json);
      default:
        throw FormatException('Unknown plan update type: ${json['type']}');
    }
  }
}

class V15PlanEntry {
  final String content;
  final String priority;
  final String status;
  final Object? meta;
  final V15Json extras;
  V15PlanEntry({
    required this.content,
    required this.priority,
    required this.status,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15PlanEntry.fromJson(V15Json json) {
    final priority = json['priority'] as String;
    final status = json['status'] as String;
    if (!{'high', 'medium', 'low'}.contains(priority)) {
      throw FormatException('Invalid plan entry priority: $priority');
    }
    if (!{'pending', 'in_progress', 'completed'}.contains(status)) {
      throw FormatException('Invalid plan entry status: $status');
    }
    return V15PlanEntry(
      content: json['content'] as String,
      priority: priority,
      status: status,
      meta: _metaValue(json),
      extras: _extras(json, {'content', 'priority', 'status', '_meta'}),
    );
  }
  V15Json toJson() => _encode(extras, {
    'content': content,
    'priority': priority,
    'status': status,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15PlanItems extends V15PlanUpdateContent {
  final String planId;
  final List<V15PlanEntry> entries;
  final Object? meta;
  final V15Json extras;
  V15PlanItems({
    required this.planId,
    required this.entries,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  @override
  String get type => 'items';
  factory V15PlanItems.fromJson(V15Json json) => V15PlanItems(
    planId: json['planId'] as String,
    entries: _objectList(
      json['entries'],
      'entries',
    ).map(V15PlanEntry.fromJson).toList(),
    meta: _metaValue(json),
    extras: _extras(json, {'type', 'planId', 'entries', '_meta'}),
  );
  @override
  V15Json toJson() => _encode(extras, {
    'type': type,
    'planId': planId,
    'entries': entries.map((entry) => entry.toJson()).toList(),
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15PlanFile extends V15PlanUpdateContent {
  final String planId;
  final String uri;
  final Object? meta;
  final V15Json extras;
  V15PlanFile({
    required this.planId,
    required this.uri,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  @override
  String get type => 'file';
  factory V15PlanFile.fromJson(V15Json json) => V15PlanFile(
    planId: json['planId'] as String,
    uri: json['uri'] as String,
    meta: _metaValue(json),
    extras: _extras(json, {'type', 'planId', 'uri', '_meta'}),
  );
  @override
  V15Json toJson() => _encode(extras, {
    'type': type,
    'planId': planId,
    'uri': uri,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15PlanMarkdown extends V15PlanUpdateContent {
  final String planId;
  final String content;
  final Object? meta;
  final V15Json extras;
  V15PlanMarkdown({
    required this.planId,
    required this.content,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  @override
  String get type => 'markdown';
  factory V15PlanMarkdown.fromJson(V15Json json) => V15PlanMarkdown(
    planId: json['planId'] as String,
    content: json['content'] as String,
    meta: _metaValue(json),
    extras: _extras(json, {'type', 'planId', 'content', '_meta'}),
  );
  @override
  V15Json toJson() => _encode(extras, {
    'type': type,
    'planId': planId,
    'content': content,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

String _nesTriggerKind(Object? value) {
  if (value is String &&
      {'automatic', 'diagnostic', 'manual'}.contains(value)) {
    return value;
  }
  throw FormatException('Invalid NES trigger kind');
}

class V15PlanUpdate {
  final V15PlanUpdateContent plan;
  final Object? meta;
  final V15Json extras;
  V15PlanUpdate({required this.plan, this.meta, V15Json? extras})
    : extras = extras ?? {};
  factory V15PlanUpdate.fromJson(V15Json json) => V15PlanUpdate(
    plan: V15PlanUpdateContent.fromJson(_map(json['plan'], 'plan')),
    meta: _metaValue(json),
    extras: _extras(json, {'plan', '_meta'}),
  );
  V15Json toJson() => _encode(extras, {
    'plan': plan.toJson(),
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15CompactionUpdate {
  final String compactionId;
  final String status;
  final List<V15Json>? summary;
  final String? error;
  final Object? meta;
  final V15Json extras;
  V15CompactionUpdate({
    required this.compactionId,
    required this.status,
    this.summary,
    this.error,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15CompactionUpdate.fromJson(V15Json json) => V15CompactionUpdate(
    compactionId: json['compactionId'] as String,
    status: json['status'] as String,
    summary: json['summary'] == null
        ? null
        : _objectList(json['summary'], 'summary'),
    error: json['error'] as String?,
    meta: _metaValue(json),
    extras: _extras(
      json,
      {'compactionId', 'status', 'summary', 'error', '_meta'},
      {'summary', 'error'},
    ),
  );
  V15Json toJson() => _encode(extras, {
    'compactionId': compactionId,
    'status': status,
    if (summary != null || extras.containsKey('summary')) 'summary': summary,
    if (error != null || extras.containsKey('error')) 'error': error,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15CompactionSummaryChunk {
  final String compactionId;
  final V15Json content;
  final Object? meta;
  final V15Json extras;
  V15CompactionSummaryChunk({
    required this.compactionId,
    required this.content,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15CompactionSummaryChunk.fromJson(V15Json json) =>
      V15CompactionSummaryChunk(
        compactionId: json['compactionId'] as String,
        content: _map(json['content'], 'content'),
        meta: _metaValue(json),
        extras: _extras(json, {'compactionId', 'content', '_meta'}),
      );
  V15Json toJson() => _encode(extras, {
    'compactionId': compactionId,
    'content': content,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15PlanRemoved {
  final String planId;
  final Object? meta;
  final V15Json extras;
  V15PlanRemoved({required this.planId, this.meta, V15Json? extras})
    : extras = extras ?? {};
  factory V15PlanRemoved.fromJson(V15Json json) => V15PlanRemoved(
    planId: json['planId'] as String,
    meta: _metaValue(json),
    extras: _extras(json, {'planId', '_meta'}),
  );
  V15Json toJson() => _encode(extras, {
    'planId': planId,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15WorkspaceFolder {
  final String uri;
  final String name;
  final Object? meta;
  final V15Json extras;
  V15WorkspaceFolder({
    required this.uri,
    required this.name,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15WorkspaceFolder.fromJson(V15Json json) => V15WorkspaceFolder(
    uri: json['uri'] as String,
    name: json['name'] as String,
    meta: _metaValue(json),
    extras: _extras(json, {'uri', 'name', '_meta'}),
  );
  V15Json toJson() => _encode(extras, {
    'uri': uri,
    'name': name,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15NesRepository {
  final String name;
  final String owner;
  final String remoteUrl;
  final Object? meta;
  final V15Json extras;
  V15NesRepository({
    required this.name,
    required this.owner,
    required this.remoteUrl,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15NesRepository.fromJson(V15Json json) => V15NesRepository(
    name: json['name'] as String,
    owner: json['owner'] as String,
    remoteUrl: json['remoteUrl'] as String,
    meta: _metaValue(json),
    extras: _extras(json, {'name', 'owner', 'remoteUrl', '_meta'}),
  );
  V15Json toJson() => _encode(extras, {
    'name': name,
    'owner': owner,
    'remoteUrl': remoteUrl,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15StartNesRequest {
  final String? workspaceUri;
  final List<V15WorkspaceFolder>? workspaceFolders;
  final V15NesRepository? repository;
  final Object? meta;
  final V15Json extras;
  V15StartNesRequest({
    this.workspaceUri,
    this.workspaceFolders,
    this.repository,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15StartNesRequest.fromJson(V15Json json) => V15StartNesRequest(
    workspaceUri: json['workspaceUri'] as String?,
    workspaceFolders: json['workspaceFolders'] == null
        ? null
        : _objectList(
            json['workspaceFolders'],
            'workspaceFolders',
          ).map(V15WorkspaceFolder.fromJson).toList(),
    repository: json['repository'] == null
        ? null
        : V15NesRepository.fromJson(_map(json['repository'], 'repository')),
    meta: _metaValue(json),
    extras: _extras(
      json,
      {'workspaceUri', 'workspaceFolders', 'repository', '_meta'},
      {'workspaceUri', 'workspaceFolders', 'repository'},
    ),
  );
  V15Json toJson() => _encode(extras, {
    if (workspaceUri != null || extras.containsKey('workspaceUri'))
      'workspaceUri': workspaceUri,
    if (workspaceFolders != null || extras.containsKey('workspaceFolders'))
      'workspaceFolders': workspaceFolders
          ?.map((folder) => folder.toJson())
          .toList(),
    if (repository != null || extras.containsKey('repository'))
      'repository': repository?.toJson(),
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15StartNesResponse {
  final String sessionId;
  final Object? meta;
  final V15Json extras;
  V15StartNesResponse({required this.sessionId, this.meta, V15Json? extras})
    : extras = extras ?? {};
  factory V15StartNesResponse.fromJson(V15Json json) => V15StartNesResponse(
    sessionId: json['sessionId'] as String,
    meta: _metaValue(json),
    extras: _extras(json, {'sessionId', '_meta'}),
  );
  V15Json toJson() => _encode(extras, {
    'sessionId': sessionId,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15SuggestNesResponse {
  final List<V15NesSuggestion> suggestions;
  final Object? meta;
  final V15Json extras;
  V15SuggestNesResponse({required this.suggestions, this.meta, V15Json? extras})
    : extras = extras ?? {};
  factory V15SuggestNesResponse.fromJson(V15Json json) => V15SuggestNesResponse(
    suggestions: _objectList(
      json['suggestions'],
      'suggestions',
    ).map(V15NesSuggestion.fromJson).toList(),
    meta: _metaValue(json),
    extras: _extras(json, {'suggestions', '_meta'}),
  );
  V15Json toJson() => _encode(extras, {
    'suggestions': suggestions
        .map((suggestion) => suggestion.toJson())
        .toList(),
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15NesSuggestContext {
  final List<V15NesRecentFile>? recentFiles;
  final List<V15NesRelatedSnippet>? relatedSnippets;
  final List<V15NesEditHistoryEntry>? editHistory;
  final List<V15NesUserAction>? userActions;
  final List<V15NesOpenFile>? openFiles;
  final List<V15NesDiagnostic>? diagnostics;
  final Object? meta;
  final V15Json extras;
  V15NesSuggestContext({
    this.recentFiles,
    this.relatedSnippets,
    this.editHistory,
    this.userActions,
    this.openFiles,
    this.diagnostics,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15NesSuggestContext.fromJson(V15Json json) {
    final recentFiles = _optionalObjectList(
      json,
      'recentFiles',
    )?.map(V15NesRecentFile.fromJson).toList();
    final relatedSnippets = _optionalObjectList(
      json,
      'relatedSnippets',
    )?.map(V15NesRelatedSnippet.fromJson).toList();
    final editHistory = _optionalObjectList(
      json,
      'editHistory',
    )?.map(V15NesEditHistoryEntry.fromJson).toList();
    final userActions = _optionalObjectList(
      json,
      'userActions',
    )?.map(V15NesUserAction.fromJson).toList();
    final openFiles = _optionalObjectList(
      json,
      'openFiles',
    )?.map(V15NesOpenFile.fromJson).toList();
    final diagnostics = _optionalObjectList(
      json,
      'diagnostics',
    )?.map(V15NesDiagnostic.fromJson).toList();
    return V15NesSuggestContext(
      recentFiles: recentFiles,
      relatedSnippets: relatedSnippets,
      editHistory: editHistory,
      userActions: userActions,
      openFiles: openFiles,
      diagnostics: diagnostics,
      meta: _metaValue(json),
      extras: _extras(
        json,
        {
          'recentFiles',
          'relatedSnippets',
          'editHistory',
          'userActions',
          'openFiles',
          'diagnostics',
          '_meta',
        },
        {
          'recentFiles',
          'relatedSnippets',
          'editHistory',
          'userActions',
          'openFiles',
          'diagnostics',
        },
      ),
    );
  }
  V15Json toJson() => _encode(extras, {
    if (recentFiles != null || extras.containsKey('recentFiles'))
      'recentFiles': recentFiles?.map((file) => file.toJson()).toList(),
    if (relatedSnippets != null || extras.containsKey('relatedSnippets'))
      'relatedSnippets': relatedSnippets
          ?.map((snippet) => snippet.toJson())
          .toList(),
    if (editHistory != null || extras.containsKey('editHistory'))
      'editHistory': editHistory?.map((entry) => entry.toJson()).toList(),
    if (userActions != null || extras.containsKey('userActions'))
      'userActions': userActions?.map((action) => action.toJson()).toList(),
    if (openFiles != null || extras.containsKey('openFiles'))
      'openFiles': openFiles?.map((file) => file.toJson()).toList(),
    if (diagnostics != null || extras.containsKey('diagnostics'))
      'diagnostics': diagnostics
          ?.map((diagnostic) => diagnostic.toJson())
          .toList(),
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

List<V15Json>? _optionalObjectList(V15Json json, String key) =>
    json[key] == null ? null : _objectList(json[key], key);

class V15NesRecentFile {
  final String uri;
  final String languageId;
  final String text;
  final Object? meta;
  final V15Json extras;
  V15NesRecentFile({
    required this.uri,
    required this.languageId,
    required this.text,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15NesRecentFile.fromJson(V15Json json) => V15NesRecentFile(
    uri: json['uri'] as String,
    languageId: json['languageId'] as String,
    text: json['text'] as String,
    meta: _metaValue(json),
    extras: _extras(json, {'uri', 'languageId', 'text', '_meta'}),
  );
  V15Json toJson() => _encode(extras, {
    'uri': uri,
    'languageId': languageId,
    'text': text,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15NesExcerpt {
  final int startLine;
  final int endLine;
  final String text;
  final Object? meta;
  final V15Json extras;
  V15NesExcerpt({
    required this.startLine,
    required this.endLine,
    required this.text,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15NesExcerpt.fromJson(V15Json json) => V15NesExcerpt(
    startLine: json['startLine'] as int,
    endLine: json['endLine'] as int,
    text: json['text'] as String,
    meta: _metaValue(json),
    extras: _extras(json, {'startLine', 'endLine', 'text', '_meta'}),
  );
  V15Json toJson() => _encode(extras, {
    'startLine': startLine,
    'endLine': endLine,
    'text': text,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15NesRelatedSnippet {
  final String uri;
  final List<V15NesExcerpt> excerpts;
  final Object? meta;
  final V15Json extras;
  V15NesRelatedSnippet({
    required this.uri,
    required this.excerpts,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15NesRelatedSnippet.fromJson(V15Json json) => V15NesRelatedSnippet(
    uri: json['uri'] as String,
    excerpts: _objectList(
      json['excerpts'],
      'excerpts',
    ).map(V15NesExcerpt.fromJson).toList(),
    meta: _metaValue(json),
    extras: _extras(json, {'uri', 'excerpts', '_meta'}),
  );
  V15Json toJson() => _encode(extras, {
    'uri': uri,
    'excerpts': excerpts.map((excerpt) => excerpt.toJson()).toList(),
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15NesEditHistoryEntry {
  final String uri;
  final String diff;
  final Object? meta;
  final V15Json extras;
  V15NesEditHistoryEntry({
    required this.uri,
    required this.diff,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15NesEditHistoryEntry.fromJson(V15Json json) =>
      V15NesEditHistoryEntry(
        uri: json['uri'] as String,
        diff: json['diff'] as String,
        meta: _metaValue(json),
        extras: _extras(json, {'uri', 'diff', '_meta'}),
      );
  V15Json toJson() => _encode(extras, {
    'uri': uri,
    'diff': diff,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15NesUserAction {
  final String action;
  final String uri;
  final V15Position position;
  final num timestampMs;
  final Object? meta;
  final V15Json extras;
  V15NesUserAction({
    required this.action,
    required this.uri,
    required this.position,
    required this.timestampMs,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15NesUserAction.fromJson(V15Json json) => V15NesUserAction(
    action: json['action'] as String,
    uri: json['uri'] as String,
    position: V15Position.fromJson(_map(json['position'], 'position')),
    timestampMs: json['timestampMs'] as num,
    meta: _metaValue(json),
    extras: _extras(json, {
      'action',
      'uri',
      'position',
      'timestampMs',
      '_meta',
    }),
  );
  V15Json toJson() => _encode(extras, {
    'action': action,
    'uri': uri,
    'position': position.toJson(),
    'timestampMs': timestampMs,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15NesOpenFile {
  final String uri;
  final String languageId;
  final V15Range? visibleRange;
  final num? lastFocusedMs;
  final Object? meta;
  final V15Json extras;
  V15NesOpenFile({
    required this.uri,
    required this.languageId,
    this.visibleRange,
    this.lastFocusedMs,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15NesOpenFile.fromJson(V15Json json) => V15NesOpenFile(
    uri: json['uri'] as String,
    languageId: json['languageId'] as String,
    visibleRange: json['visibleRange'] == null
        ? null
        : V15Range.fromJson(_map(json['visibleRange'], 'visibleRange')),
    lastFocusedMs: json['lastFocusedMs'] as num?,
    meta: _metaValue(json),
    extras: _extras(
      json,
      {'uri', 'languageId', 'visibleRange', 'lastFocusedMs', '_meta'},
      {'visibleRange', 'lastFocusedMs'},
    ),
  );
  V15Json toJson() => _encode(extras, {
    'uri': uri,
    'languageId': languageId,
    if (visibleRange != null || extras.containsKey('visibleRange'))
      'visibleRange': visibleRange?.toJson(),
    if (lastFocusedMs != null || extras.containsKey('lastFocusedMs'))
      'lastFocusedMs': lastFocusedMs,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15NesDiagnostic {
  final String uri;
  final V15Range range;
  final String severity;
  final String message;
  final Object? meta;
  final V15Json extras;
  V15NesDiagnostic({
    required this.uri,
    required this.range,
    required this.severity,
    required this.message,
    this.meta,
    V15Json? extras,
  }) : extras = extras ?? {};
  factory V15NesDiagnostic.fromJson(V15Json json) {
    final severity = json['severity'] as String;
    if (!{'error', 'warning', 'information', 'hint'}.contains(severity)) {
      throw FormatException('Invalid diagnostic severity: $severity');
    }
    return V15NesDiagnostic(
      uri: json['uri'] as String,
      range: V15Range.fromJson(_map(json['range'], 'range')),
      severity: severity,
      message: json['message'] as String,
      meta: _metaValue(json),
      extras: _extras(json, {'uri', 'range', 'severity', 'message', '_meta'}),
    );
  }
  V15Json toJson() => _encode(extras, {
    'uri': uri,
    'range': range.toJson(),
    'severity': severity,
    'message': message,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15CloseNesRequest {
  final String sessionId;
  final Object? meta;
  final V15Json extras;
  V15CloseNesRequest({required this.sessionId, this.meta, V15Json? extras})
    : extras = extras ?? {};
  factory V15CloseNesRequest.fromJson(V15Json json) => V15CloseNesRequest(
    sessionId: json['sessionId'] as String,
    meta: _metaValue(json),
    extras: _extras(json, {'sessionId', '_meta'}),
  );
  V15Json toJson() => _encode(extras, {
    'sessionId': sessionId,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

typedef V15CloseNesResponse = V15ProviderMutationResponse;
typedef V15SetProviderResponse = V15ProviderMutationResponse;
typedef V15DisableProviderResponse = V15ProviderMutationResponse;

class PlanUpdateSessionUpdateV15 extends SessionUpdate {
  final V15PlanUpdate update;
  PlanUpdateSessionUpdateV15({required this.update});
  factory PlanUpdateSessionUpdateV15.fromJson(V15Json json) {
    _checkSessionUpdate(json, 'plan_update');
    return PlanUpdateSessionUpdateV15(
      update: V15PlanUpdate.fromJson(_sessionUpdatePayload(json)),
    );
  }
  V15Json toJson() => update.toJson();
}

class PlanRemovedSessionUpdateV15 extends SessionUpdate {
  final V15PlanRemoved update;
  PlanRemovedSessionUpdateV15({required this.update});
  factory PlanRemovedSessionUpdateV15.fromJson(V15Json json) {
    _checkSessionUpdate(json, 'plan_removed');
    return PlanRemovedSessionUpdateV15(
      update: V15PlanRemoved.fromJson(_sessionUpdatePayload(json)),
    );
  }
  V15Json toJson() => update.toJson();
}

class CompactionUpdateSessionUpdateV15 extends SessionUpdate {
  final V15CompactionUpdate update;
  CompactionUpdateSessionUpdateV15({required this.update});
  factory CompactionUpdateSessionUpdateV15.fromJson(V15Json json) {
    _checkSessionUpdate(json, 'compaction_update');
    return CompactionUpdateSessionUpdateV15(
      update: V15CompactionUpdate.fromJson(_sessionUpdatePayload(json)),
    );
  }
  V15Json toJson() => update.toJson();
}

class CompactionSummaryChunkSessionUpdateV15 extends SessionUpdate {
  final V15CompactionSummaryChunk update;
  CompactionSummaryChunkSessionUpdateV15({required this.update});
  factory CompactionSummaryChunkSessionUpdateV15.fromJson(V15Json json) {
    _checkSessionUpdate(json, 'compaction_summary_chunk');
    return CompactionSummaryChunkSessionUpdateV15(
      update: V15CompactionSummaryChunk.fromJson(_sessionUpdatePayload(json)),
    );
  }
  V15Json toJson() => update.toJson();
}

void _checkSessionUpdate(V15Json json, String expected) {
  final actual = json['sessionUpdate'];
  if (actual != null && actual != expected) {
    throw FormatException(
      'Expected sessionUpdate "$expected", received "$actual"',
    );
  }
}

V15Json _sessionUpdatePayload(V15Json json) =>
    Map<String, dynamic>.from(json)..remove('sessionUpdate');
