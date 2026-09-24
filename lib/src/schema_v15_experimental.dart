/// Experimental payloads from the TypeScript SDK v1.5 schema.
///
/// These types are additive and may change as the ACP specification evolves.
typedef V15Json = Map<String, dynamic>;

V15Json _map(Object? value, String field) {
  if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
  throw FormatException('Expected an object for $field');
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
        meta: json['_meta'],
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
    meta: json['_meta'],
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
        meta: json['_meta'],
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
    meta: json['_meta'],
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
    meta: json['_meta'],
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
        meta: json['_meta'],
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
    meta: json['_meta'],
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
        meta: json['_meta'],
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
        meta: json['_meta'],
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
    meta: json['_meta'],
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
        meta: json['_meta'],
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
        meta: json['_meta'],
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
        meta: json['_meta'],
        extras: _extras(json, {'providerId', '_meta'}),
      );
  V15Json toJson() => _encode(extras, {
    'providerId': providerId,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15TextDocumentContentChangeEvent {
  final V15Json? range;
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
        range: json['range'] == null ? null : _map(json['range'], 'range'),
        text: json['text'] as String,
        meta: json['_meta'],
        extras: _extras(json, {'range', 'text', '_meta'}, {'range'}),
      );
  V15Json toJson() => _encode(extras, {
    if (range != null || extras.containsKey('range')) 'range': range,
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
        meta: json['_meta'],
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
        meta: json['_meta'],
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
        meta: json['_meta'],
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
        meta: json['_meta'],
        extras: _extras(json, {'sessionId', 'uri', '_meta'}),
      );
}

class V15DidFocusDocumentNotification {
  final String sessionId;
  final String uri;
  final int version;
  final V15Position position;
  final V15Json visibleRange;
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
        visibleRange: _map(json['visibleRange'], 'visibleRange'),
        meta: json['_meta'],
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
    'visibleRange': visibleRange,
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
        meta: json['_meta'],
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
        meta: json['_meta'],
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
    meta: json['_meta'],
    extras: _extras(json, {'line', 'character', '_meta'}),
  );
  V15Json toJson() => _encode(extras, {
    'line': line,
    'character': character,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15NesSuggestion {
  final String kind;
  final String id;
  final V15Json data;
  const V15NesSuggestion({
    required this.kind,
    required this.id,
    required this.data,
  });
  factory V15NesSuggestion.fromJson(V15Json json) {
    final kind = json['kind'] as String;
    switch (kind) {
      case 'edit':
        json['id'] as String;
        json['uri'] as String;
        _list(json['edits'], 'edits');
      case 'jump':
        json['id'] as String;
        json['uri'] as String;
        _map(json['position'], 'position');
      case 'rename':
        json['id'] as String;
        json['uri'] as String;
        _map(json['position'], 'position');
        json['newName'] as String;
      case 'searchAndReplace':
        json['id'] as String;
        json['uri'] as String;
        json['search'] as String;
        json['replace'] as String;
      default:
        throw FormatException('Unknown NES suggestion kind: $kind');
    }
    return V15NesSuggestion(
      kind: kind,
      id: json['id'] as String,
      data: Map<String, dynamic>.from(json),
    );
  }
  V15Json toJson() => Map<String, dynamic>.from(data);
}

class V15SuggestNesRequest {
  final String sessionId;
  final String uri;
  final int version;
  final V15Position position;
  final String triggerKind;
  final Object? selection;
  final Object? context;
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
    triggerKind: json['triggerKind'] as String,
    selection: json['selection'],
    context: json['context'],
    meta: json['_meta'],
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
      'selection': selection,
    if (context != null || extras.containsKey('context')) 'context': context,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}

class V15PlanUpdateContent {
  final String type;
  final V15Json data;
  const V15PlanUpdateContent({required this.type, required this.data});
  factory V15PlanUpdateContent.fromJson(V15Json json) {
    final type = json['type'] as String;
    switch (type) {
      case 'items':
        json['planId'] as String;
        _list(json['entries'], 'entries');
      case 'file':
        json['planId'] as String;
        json['uri'] as String;
      case 'markdown':
        json['planId'] as String;
        json['content'] as String;
      default:
        throw FormatException('Unknown plan update type: $type');
    }
    return V15PlanUpdateContent(
      type: type,
      data: Map<String, dynamic>.from(json),
    );
  }
  V15Json toJson() => Map<String, dynamic>.from(data);
}

class V15CompactionUpdate {
  final String compactionId;
  final String status;
  final Object? summary;
  final Object? error;
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
    summary: json['summary'],
    error: json['error'],
    meta: json['_meta'],
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
        meta: json['_meta'],
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
    meta: json['_meta'],
    extras: _extras(json, {'planId', '_meta'}),
  );
  V15Json toJson() => _encode(extras, {
    'planId': planId,
    if (meta != null || extras.containsKey('_meta')) '_meta': meta,
  });
}
