// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Implementation _$ImplementationFromJson(Map<String, dynamic> json) =>
    Implementation(
      meta: json['_meta'] as Map<String, dynamic>?,
      name: json['name'] as String,
      title: json['title'] as String?,
      version: json['version'] as String,
    );

Map<String, dynamic> _$ImplementationToJson(Implementation instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'name': instance.name,
      'title': instance.title,
      'version': instance.version,
    };

InitializeRequest _$InitializeRequestFromJson(Map<String, dynamic> json) =>
    InitializeRequest(
      meta: json['_meta'] as Map<String, dynamic>?,
      clientCapabilities: json['clientCapabilities'] == null
          ? null
          : ClientCapabilities.fromJson(
              json['clientCapabilities'] as Map<String, dynamic>,
            ),
      clientInfo: json['clientInfo'] == null
          ? null
          : Implementation.fromJson(json['clientInfo'] as Map<String, dynamic>),
      protocolVersion: (json['protocolVersion'] as num).toInt(),
    );

Map<String, dynamic> _$InitializeRequestToJson(InitializeRequest instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'clientCapabilities': instance.clientCapabilities,
      'clientInfo': instance.clientInfo,
      'protocolVersion': instance.protocolVersion,
    };

ClientCapabilities _$ClientCapabilitiesFromJson(Map<String, dynamic> json) =>
    ClientCapabilities(
      meta: json['_meta'] as Map<String, dynamic>?,
      fs: json['fs'] == null
          ? null
          : FileSystemCapability.fromJson(json['fs'] as Map<String, dynamic>),
      terminal: json['terminal'] as bool? ?? false,
      elicitation: json['elicitation'] == null
          ? null
          : ElicitationCapabilities.fromJson(
              json['elicitation'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$ClientCapabilitiesToJson(ClientCapabilities instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'fs': instance.fs,
      'terminal': instance.terminal,
      'elicitation': instance.elicitation,
    };

FileSystemCapability _$FileSystemCapabilityFromJson(
  Map<String, dynamic> json,
) => FileSystemCapability(
  meta: json['_meta'] as Map<String, dynamic>?,
  readTextFile: json['readTextFile'] as bool? ?? false,
  writeTextFile: json['writeTextFile'] as bool? ?? false,
);

Map<String, dynamic> _$FileSystemCapabilityToJson(
  FileSystemCapability instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'readTextFile': instance.readTextFile,
  'writeTextFile': instance.writeTextFile,
};

AuthenticateRequest _$AuthenticateRequestFromJson(Map<String, dynamic> json) =>
    AuthenticateRequest(
      meta: json['_meta'] as Map<String, dynamic>?,
      methodId: json['methodId'] as String,
    );

Map<String, dynamic> _$AuthenticateRequestToJson(
  AuthenticateRequest instance,
) => <String, dynamic>{'_meta': ?instance.meta, 'methodId': instance.methodId};

NewSessionRequest _$NewSessionRequestFromJson(Map<String, dynamic> json) =>
    NewSessionRequest(
      meta: json['_meta'] as Map<String, dynamic>?,
      cwd: json['cwd'] as String,
      mcpServers: (json['mcpServers'] as List<dynamic>)
          .map(
            (e) =>
                const McpServerConverter().fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$NewSessionRequestToJson(NewSessionRequest instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'cwd': instance.cwd,
      'mcpServers': instance.mcpServers
          .map(const McpServerConverter().toJson)
          .toList(),
    };

HttpMcpServer _$HttpMcpServerFromJson(Map<String, dynamic> json) =>
    HttpMcpServer(
      meta: json['_meta'] as Map<String, dynamic>?,
      type: json['type'] as String? ?? 'http',
      name: json['name'] as String,
      url: json['url'] as String,
      headers: (json['headers'] as List<dynamic>)
          .map((e) => HttpHeader.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$HttpMcpServerToJson(HttpMcpServer instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'type': instance.type,
      'name': instance.name,
      'url': instance.url,
      'headers': instance.headers,
    };

SseMcpServer _$SseMcpServerFromJson(Map<String, dynamic> json) => SseMcpServer(
  meta: json['_meta'] as Map<String, dynamic>?,
  type: json['type'] as String? ?? 'sse',
  name: json['name'] as String,
  url: json['url'] as String,
  headers: (json['headers'] as List<dynamic>)
      .map((e) => HttpHeader.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SseMcpServerToJson(SseMcpServer instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'type': instance.type,
      'name': instance.name,
      'url': instance.url,
      'headers': instance.headers,
    };

HttpHeader _$HttpHeaderFromJson(Map<String, dynamic> json) => HttpHeader(
  meta: json['_meta'] as Map<String, dynamic>?,
  name: json['name'] as String,
  value: json['value'] as String,
);

Map<String, dynamic> _$HttpHeaderToJson(HttpHeader instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'name': instance.name,
      'value': instance.value,
    };

StdioMcpServer _$StdioMcpServerFromJson(Map<String, dynamic> json) =>
    StdioMcpServer(
      meta: json['_meta'] as Map<String, dynamic>?,
      args: (json['args'] as List<dynamic>).map((e) => e as String).toList(),
      command: json['command'] as String,
      env: (json['env'] as List<dynamic>)
          .map((e) => EnvVariable.fromJson(e as Map<String, dynamic>))
          .toList(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$StdioMcpServerToJson(StdioMcpServer instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'args': instance.args,
      'command': instance.command,
      'env': instance.env,
      'name': instance.name,
    };

EnvVariable _$EnvVariableFromJson(Map<String, dynamic> json) => EnvVariable(
  meta: json['_meta'] as Map<String, dynamic>?,
  name: json['name'] as String,
  value: json['value'] as String,
);

Map<String, dynamic> _$EnvVariableToJson(EnvVariable instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'name': instance.name,
      'value': instance.value,
    };

LoadSessionRequest _$LoadSessionRequestFromJson(Map<String, dynamic> json) =>
    LoadSessionRequest(
      meta: json['_meta'] as Map<String, dynamic>?,
      cwd: json['cwd'] as String,
      mcpServers: (json['mcpServers'] as List<dynamic>)
          .map(
            (e) =>
                const McpServerConverter().fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      sessionId: json['sessionId'] as String,
    );

Map<String, dynamic> _$LoadSessionRequestToJson(LoadSessionRequest instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'cwd': instance.cwd,
      'mcpServers': instance.mcpServers
          .map(const McpServerConverter().toJson)
          .toList(),
      'sessionId': instance.sessionId,
    };

ForkSessionRequest _$ForkSessionRequestFromJson(Map<String, dynamic> json) =>
    ForkSessionRequest(
      meta: json['_meta'] as Map<String, dynamic>?,
      cwd: json['cwd'] as String,
      mcpServers: (json['mcpServers'] as List<dynamic>?)
          ?.map(
            (e) =>
                const McpServerConverter().fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      sessionId: json['sessionId'] as String,
    );

Map<String, dynamic> _$ForkSessionRequestToJson(ForkSessionRequest instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'cwd': instance.cwd,
      'mcpServers': instance.mcpServers
          ?.map(const McpServerConverter().toJson)
          .toList(),
      'sessionId': instance.sessionId,
    };

ListSessionsRequest _$ListSessionsRequestFromJson(Map<String, dynamic> json) =>
    ListSessionsRequest(
      meta: json['_meta'] as Map<String, dynamic>?,
      cursor: json['cursor'] as String?,
      cwd: json['cwd'] as String?,
    );

Map<String, dynamic> _$ListSessionsRequestToJson(
  ListSessionsRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'cursor': instance.cursor,
  'cwd': instance.cwd,
};

ResumeSessionRequest _$ResumeSessionRequestFromJson(
  Map<String, dynamic> json,
) => ResumeSessionRequest(
  meta: json['_meta'] as Map<String, dynamic>?,
  cwd: json['cwd'] as String,
  mcpServers: (json['mcpServers'] as List<dynamic>?)
      ?.map(
        (e) => const McpServerConverter().fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  sessionId: json['sessionId'] as String,
);

Map<String, dynamic> _$ResumeSessionRequestToJson(
  ResumeSessionRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'cwd': instance.cwd,
  'mcpServers': instance.mcpServers
      ?.map(const McpServerConverter().toJson)
      .toList(),
  'sessionId': instance.sessionId,
};

SetSessionModeRequest _$SetSessionModeRequestFromJson(
  Map<String, dynamic> json,
) => SetSessionModeRequest(
  meta: json['_meta'] as Map<String, dynamic>?,
  sessionId: json['sessionId'] as String,
  modeId: json['modeId'] as String,
);

Map<String, dynamic> _$SetSessionModeRequestToJson(
  SetSessionModeRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
  'modeId': instance.modeId,
};

SetSessionConfigOptionRequest _$SetSessionConfigOptionRequestFromJson(
  Map<String, dynamic> json,
) => SetSessionConfigOptionRequest(
  meta: json['_meta'] as Map<String, dynamic>?,
  sessionId: json['sessionId'] as String,
  configId: json['configId'] as String,
  value: json['value'] as String,
);

Map<String, dynamic> _$SetSessionConfigOptionRequestToJson(
  SetSessionConfigOptionRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
  'configId': instance.configId,
  'value': instance.value,
};

PromptRequest _$PromptRequestFromJson(Map<String, dynamic> json) =>
    PromptRequest(
      meta: json['_meta'] as Map<String, dynamic>?,
      sessionId: json['sessionId'] as String,
      prompt: (json['prompt'] as List<dynamic>)
          .map(
            (e) => const ContentBlockConverter().fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );

Map<String, dynamic> _$PromptRequestToJson(
  PromptRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
  'prompt': instance.prompt.map(const ContentBlockConverter().toJson).toList(),
};

TextContentBlock _$TextContentBlockFromJson(Map<String, dynamic> json) =>
    TextContentBlock(
      meta: json['_meta'] as Map<String, dynamic>?,
      annotations: json['annotations'] == null
          ? null
          : Annotations.fromJson(json['annotations'] as Map<String, dynamic>),
      text: json['text'] as String,
      type: json['type'] as String? ?? 'text',
    );

Map<String, dynamic> _$TextContentBlockToJson(TextContentBlock instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'annotations': instance.annotations,
      'text': instance.text,
      'type': instance.type,
    };

ImageContentBlock _$ImageContentBlockFromJson(Map<String, dynamic> json) =>
    ImageContentBlock(
      meta: json['_meta'] as Map<String, dynamic>?,
      annotations: json['annotations'] == null
          ? null
          : Annotations.fromJson(json['annotations'] as Map<String, dynamic>),
      data: json['data'] as String,
      mimeType: json['mimeType'] as String,
      uri: json['uri'] as String?,
      type: json['type'] as String? ?? 'image',
    );

Map<String, dynamic> _$ImageContentBlockToJson(ImageContentBlock instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'annotations': instance.annotations,
      'data': instance.data,
      'mimeType': instance.mimeType,
      'uri': instance.uri,
      'type': instance.type,
    };

AudioContentBlock _$AudioContentBlockFromJson(Map<String, dynamic> json) =>
    AudioContentBlock(
      meta: json['_meta'] as Map<String, dynamic>?,
      annotations: json['annotations'] == null
          ? null
          : Annotations.fromJson(json['annotations'] as Map<String, dynamic>),
      data: json['data'] as String,
      mimeType: json['mimeType'] as String,
      type: json['type'] as String? ?? 'audio',
    );

Map<String, dynamic> _$AudioContentBlockToJson(AudioContentBlock instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'annotations': instance.annotations,
      'data': instance.data,
      'mimeType': instance.mimeType,
      'type': instance.type,
    };

ResourceLinkContentBlock _$ResourceLinkContentBlockFromJson(
  Map<String, dynamic> json,
) => ResourceLinkContentBlock(
  meta: json['_meta'] as Map<String, dynamic>?,
  annotations: json['annotations'] == null
      ? null
      : Annotations.fromJson(json['annotations'] as Map<String, dynamic>),
  description: json['description'] as String?,
  mimeType: json['mimeType'] as String?,
  name: json['name'] as String,
  size: (json['size'] as num?)?.toInt(),
  title: json['title'] as String?,
  uri: json['uri'] as String,
  type: json['type'] as String? ?? 'resource_link',
);

Map<String, dynamic> _$ResourceLinkContentBlockToJson(
  ResourceLinkContentBlock instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'annotations': instance.annotations,
  'description': instance.description,
  'mimeType': instance.mimeType,
  'name': instance.name,
  'size': instance.size,
  'title': instance.title,
  'uri': instance.uri,
  'type': instance.type,
};

ResourceContentBlock _$ResourceContentBlockFromJson(
  Map<String, dynamic> json,
) => ResourceContentBlock(
  meta: json['_meta'] as Map<String, dynamic>?,
  annotations: json['annotations'] == null
      ? null
      : Annotations.fromJson(json['annotations'] as Map<String, dynamic>),
  resource: EmbeddedResource.fromJson(json['resource'] as Map<String, dynamic>),
  type: json['type'] as String? ?? 'resource',
);

Map<String, dynamic> _$ResourceContentBlockToJson(
  ResourceContentBlock instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'annotations': instance.annotations,
  'resource': instance.resource,
  'type': instance.type,
};

ToolCall _$ToolCallFromJson(Map<String, dynamic> json) => ToolCall(
  meta: json['_meta'] as Map<String, dynamic>?,
  content: (json['content'] as List<dynamic>?)
      ?.map(
        (e) => const ToolCallContentConverter().fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
  kind: $enumDecodeNullable(_$ToolKindEnumMap, json['kind']),
  locations: (json['locations'] as List<dynamic>?)
      ?.map((e) => ToolCallLocation.fromJson(e as Map<String, dynamic>))
      .toList(),
  rawInput: json['rawInput'] as Map<String, dynamic>?,
  rawOutput: json['rawOutput'] as Map<String, dynamic>?,
  status: $enumDecodeNullable(_$ToolCallStatusEnumMap, json['status']),
  title: json['title'] as String,
  toolCallId: json['toolCallId'] as String,
);

Map<String, dynamic> _$ToolCallToJson(ToolCall instance) => <String, dynamic>{
  '_meta': ?instance.meta,
  'content': instance.content
      ?.map(const ToolCallContentConverter().toJson)
      .toList(),
  'kind': _$ToolKindEnumMap[instance.kind],
  'locations': instance.locations,
  'rawInput': instance.rawInput,
  'rawOutput': instance.rawOutput,
  'status': _$ToolCallStatusEnumMap[instance.status],
  'title': instance.title,
  'toolCallId': instance.toolCallId,
};

const _$ToolKindEnumMap = {
  ToolKind.read: 'read',
  ToolKind.edit: 'edit',
  ToolKind.delete: 'delete',
  ToolKind.move: 'move',
  ToolKind.search: 'search',
  ToolKind.execute: 'execute',
  ToolKind.think: 'think',
  ToolKind.fetch: 'fetch',
  ToolKind.switchMode: 'switch_mode',
  ToolKind.other: 'other',
};

const _$ToolCallStatusEnumMap = {
  ToolCallStatus.pending: 'pending',
  ToolCallStatus.inProgress: 'in_progress',
  ToolCallStatus.completed: 'completed',
  ToolCallStatus.failed: 'failed',
};

SetSessionModelRequest _$SetSessionModelRequestFromJson(
  Map<String, dynamic> json,
) => SetSessionModelRequest(
  meta: json['_meta'] as Map<String, dynamic>?,
  modelId: json['modelId'] as String,
  sessionId: json['sessionId'] as String,
);

Map<String, dynamic> _$SetSessionModelRequestToJson(
  SetSessionModelRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'modelId': instance.modelId,
  'sessionId': instance.sessionId,
};

WriteTextFileRequest _$WriteTextFileRequestFromJson(
  Map<String, dynamic> json,
) => WriteTextFileRequest(
  meta: json['_meta'] as Map<String, dynamic>?,
  sessionId: json['sessionId'] as String,
  path: json['path'] as String,
  content: json['content'] as String,
);

Map<String, dynamic> _$WriteTextFileRequestToJson(
  WriteTextFileRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
  'path': instance.path,
  'content': instance.content,
};

ReadTextFileRequest _$ReadTextFileRequestFromJson(Map<String, dynamic> json) =>
    ReadTextFileRequest(
      meta: json['_meta'] as Map<String, dynamic>?,
      sessionId: json['sessionId'] as String,
      path: json['path'] as String,
      line: (json['line'] as num?)?.toInt(),
      limit: (json['limit'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ReadTextFileRequestToJson(
  ReadTextFileRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
  'path': instance.path,
  'line': instance.line,
  'limit': instance.limit,
};

RequestPermissionRequest _$RequestPermissionRequestFromJson(
  Map<String, dynamic> json,
) => RequestPermissionRequest(
  meta: json['_meta'] as Map<String, dynamic>?,
  sessionId: json['sessionId'] as String,
  options: (json['options'] as List<dynamic>)
      .map((e) => PermissionOption.fromJson(e as Map<String, dynamic>))
      .toList(),
  toolCall: ToolCallUpdate.fromJson(json['toolCall'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RequestPermissionRequestToJson(
  RequestPermissionRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
  'options': instance.options,
  'toolCall': instance.toolCall,
};

PermissionOption _$PermissionOptionFromJson(Map<String, dynamic> json) =>
    PermissionOption(
      meta: json['_meta'] as Map<String, dynamic>?,
      optionId: json['optionId'] as String,
      name: json['name'] as String,
      kind: $enumDecode(_$PermissionOptionKindEnumMap, json['kind']),
    );

Map<String, dynamic> _$PermissionOptionToJson(PermissionOption instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'optionId': instance.optionId,
      'name': instance.name,
      'kind': _$PermissionOptionKindEnumMap[instance.kind]!,
    };

const _$PermissionOptionKindEnumMap = {
  PermissionOptionKind.allowOnce: 'allow_once',
  PermissionOptionKind.allowAlways: 'allow_always',
  PermissionOptionKind.rejectOnce: 'reject_once',
  PermissionOptionKind.rejectAlways: 'reject_always',
};

ToolCallUpdate _$ToolCallUpdateFromJson(Map<String, dynamic> json) =>
    ToolCallUpdate(
      meta: json['_meta'] as Map<String, dynamic>?,
      content: (json['content'] as List<dynamic>?)
          ?.map(
            (e) => const ToolCallContentConverter().fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      kind: $enumDecodeNullable(_$ToolKindEnumMap, json['kind']),
      locations: (json['locations'] as List<dynamic>?)
          ?.map((e) => ToolCallLocation.fromJson(e as Map<String, dynamic>))
          .toList(),
      rawInput: json['rawInput'] as Map<String, dynamic>?,
      rawOutput: json['rawOutput'] as Map<String, dynamic>?,
      status: $enumDecodeNullable(_$ToolCallStatusEnumMap, json['status']),
      title: json['title'] as String?,
      toolCallId: json['toolCallId'] as String,
    );

Map<String, dynamic> _$ToolCallUpdateToJson(ToolCallUpdate instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'content': instance.content
          ?.map(const ToolCallContentConverter().toJson)
          .toList(),
      'kind': _$ToolKindEnumMap[instance.kind],
      'locations': instance.locations,
      'rawInput': instance.rawInput,
      'rawOutput': instance.rawOutput,
      'status': _$ToolCallStatusEnumMap[instance.status],
      'title': instance.title,
      'toolCallId': instance.toolCallId,
    };

CreateTerminalRequest _$CreateTerminalRequestFromJson(
  Map<String, dynamic> json,
) => CreateTerminalRequest(
  meta: json['_meta'] as Map<String, dynamic>?,
  sessionId: json['sessionId'] as String,
  command: json['command'] as String,
  args: (json['args'] as List<dynamic>?)?.map((e) => e as String).toList(),
  cwd: json['cwd'] as String?,
  env: (json['env'] as List<dynamic>?)
      ?.map((e) => EnvVariable.fromJson(e as Map<String, dynamic>))
      .toList(),
  outputByteLimit: (json['outputByteLimit'] as num?)?.toInt(),
);

Map<String, dynamic> _$CreateTerminalRequestToJson(
  CreateTerminalRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
  'command': instance.command,
  'args': instance.args,
  'cwd': instance.cwd,
  'env': instance.env,
  'outputByteLimit': instance.outputByteLimit,
};

TerminalOutputRequest _$TerminalOutputRequestFromJson(
  Map<String, dynamic> json,
) => TerminalOutputRequest(
  meta: json['_meta'] as Map<String, dynamic>?,
  sessionId: json['sessionId'] as String,
  terminalId: json['terminalId'] as String,
);

Map<String, dynamic> _$TerminalOutputRequestToJson(
  TerminalOutputRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
  'terminalId': instance.terminalId,
};

ReleaseTerminalRequest _$ReleaseTerminalRequestFromJson(
  Map<String, dynamic> json,
) => ReleaseTerminalRequest(
  meta: json['_meta'] as Map<String, dynamic>?,
  sessionId: json['sessionId'] as String,
  terminalId: json['terminalId'] as String,
);

Map<String, dynamic> _$ReleaseTerminalRequestToJson(
  ReleaseTerminalRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
  'terminalId': instance.terminalId,
};

WaitForTerminalExitRequest _$WaitForTerminalExitRequestFromJson(
  Map<String, dynamic> json,
) => WaitForTerminalExitRequest(
  meta: json['_meta'] as Map<String, dynamic>?,
  sessionId: json['sessionId'] as String,
  terminalId: json['terminalId'] as String,
);

Map<String, dynamic> _$WaitForTerminalExitRequestToJson(
  WaitForTerminalExitRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
  'terminalId': instance.terminalId,
};

KillTerminalCommandRequest _$KillTerminalCommandRequestFromJson(
  Map<String, dynamic> json,
) => KillTerminalCommandRequest(
  meta: json['_meta'] as Map<String, dynamic>?,
  sessionId: json['sessionId'] as String,
  terminalId: json['terminalId'] as String,
);

Map<String, dynamic> _$KillTerminalCommandRequestToJson(
  KillTerminalCommandRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
  'terminalId': instance.terminalId,
};

InitializeResponse _$InitializeResponseFromJson(Map<String, dynamic> json) =>
    InitializeResponse(
      meta: json['_meta'] as Map<String, dynamic>?,
      protocolVersion: (json['protocolVersion'] as num).toInt(),
      agentCapabilities: json['agentCapabilities'] == null
          ? null
          : AgentCapabilities.fromJson(
              json['agentCapabilities'] as Map<String, dynamic>,
            ),
      agentInfo: json['agentInfo'] == null
          ? null
          : Implementation.fromJson(json['agentInfo'] as Map<String, dynamic>),
      authMethods:
          (json['authMethods'] as List<dynamic>?)
              ?.map((e) => AuthMethod.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$InitializeResponseToJson(InitializeResponse instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'protocolVersion': instance.protocolVersion,
      'agentCapabilities': instance.agentCapabilities,
      'agentInfo': instance.agentInfo,
      'authMethods': instance.authMethods,
    };

AgentCapabilities _$AgentCapabilitiesFromJson(Map<String, dynamic> json) =>
    AgentCapabilities(
      meta: json['_meta'] as Map<String, dynamic>?,
      mcpCapabilities: json['mcpCapabilities'] == null
          ? null
          : McpCapabilities.fromJson(
              json['mcpCapabilities'] as Map<String, dynamic>,
            ),
      promptCapabilities: json['promptCapabilities'] == null
          ? null
          : PromptCapabilities.fromJson(
              json['promptCapabilities'] as Map<String, dynamic>,
            ),
      sessionCapabilities: json['sessionCapabilities'] == null
          ? null
          : SessionCapabilities.fromJson(
              json['sessionCapabilities'] as Map<String, dynamic>,
            ),
      loadSession: json['loadSession'] as bool? ?? false,
    );

Map<String, dynamic> _$AgentCapabilitiesToJson(AgentCapabilities instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'mcpCapabilities': instance.mcpCapabilities,
      'promptCapabilities': instance.promptCapabilities,
      'sessionCapabilities': instance.sessionCapabilities,
      'loadSession': instance.loadSession,
    };

SessionCapabilities _$SessionCapabilitiesFromJson(
  Map<String, dynamic> json,
) => SessionCapabilities(
  meta: json['_meta'] as Map<String, dynamic>?,
  fork: json['fork'] == null
      ? null
      : SessionForkCapabilities.fromJson(json['fork'] as Map<String, dynamic>),
  list: json['list'] == null
      ? null
      : SessionListCapabilities.fromJson(json['list'] as Map<String, dynamic>),
  resume: json['resume'] == null
      ? null
      : SessionResumeCapabilities.fromJson(
          json['resume'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$SessionCapabilitiesToJson(
  SessionCapabilities instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'fork': instance.fork,
  'list': instance.list,
  'resume': instance.resume,
};

SessionForkCapabilities _$SessionForkCapabilitiesFromJson(
  Map<String, dynamic> json,
) => SessionForkCapabilities(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$SessionForkCapabilitiesToJson(
  SessionForkCapabilities instance,
) => <String, dynamic>{'_meta': ?instance.meta};

SessionListCapabilities _$SessionListCapabilitiesFromJson(
  Map<String, dynamic> json,
) => SessionListCapabilities(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$SessionListCapabilitiesToJson(
  SessionListCapabilities instance,
) => <String, dynamic>{'_meta': ?instance.meta};

SessionResumeCapabilities _$SessionResumeCapabilitiesFromJson(
  Map<String, dynamic> json,
) => SessionResumeCapabilities(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$SessionResumeCapabilitiesToJson(
  SessionResumeCapabilities instance,
) => <String, dynamic>{'_meta': ?instance.meta};

McpCapabilities _$McpCapabilitiesFromJson(Map<String, dynamic> json) =>
    McpCapabilities(
      meta: json['_meta'] as Map<String, dynamic>?,
      http: json['http'] as bool? ?? false,
      sse: json['sse'] as bool? ?? false,
    );

Map<String, dynamic> _$McpCapabilitiesToJson(McpCapabilities instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'http': instance.http,
      'sse': instance.sse,
    };

PromptCapabilities _$PromptCapabilitiesFromJson(Map<String, dynamic> json) =>
    PromptCapabilities(
      meta: json['_meta'] as Map<String, dynamic>?,
      audio: json['audio'] as bool? ?? false,
      embeddedContext: json['embeddedContext'] as bool? ?? false,
      image: json['image'] as bool? ?? false,
    );

Map<String, dynamic> _$PromptCapabilitiesToJson(PromptCapabilities instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'audio': instance.audio,
      'embeddedContext': instance.embeddedContext,
      'image': instance.image,
    };

AuthMethod _$AuthMethodFromJson(Map<String, dynamic> json) => AuthMethod(
  meta: json['_meta'] as Map<String, dynamic>?,
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$AuthMethodToJson(AuthMethod instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
    };

AuthenticateResponse _$AuthenticateResponseFromJson(
  Map<String, dynamic> json,
) => AuthenticateResponse(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$AuthenticateResponseToJson(
  AuthenticateResponse instance,
) => <String, dynamic>{'_meta': ?instance.meta};

LogoutRequest _$LogoutRequestFromJson(Map<String, dynamic> json) =>
    LogoutRequest(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$LogoutRequestToJson(LogoutRequest instance) =>
    <String, dynamic>{'_meta': ?instance.meta};

LogoutResponse _$LogoutResponseFromJson(Map<String, dynamic> json) =>
    LogoutResponse(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$LogoutResponseToJson(LogoutResponse instance) =>
    <String, dynamic>{'_meta': ?instance.meta};

DeleteSessionRequest _$DeleteSessionRequestFromJson(
  Map<String, dynamic> json,
) => DeleteSessionRequest(
  meta: json['_meta'] as Map<String, dynamic>?,
  sessionId: json['sessionId'] as String,
);

Map<String, dynamic> _$DeleteSessionRequestToJson(
  DeleteSessionRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
};

DeleteSessionResponse _$DeleteSessionResponseFromJson(
  Map<String, dynamic> json,
) => DeleteSessionResponse(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$DeleteSessionResponseToJson(
  DeleteSessionResponse instance,
) => <String, dynamic>{'_meta': ?instance.meta};

CloseSessionRequest _$CloseSessionRequestFromJson(Map<String, dynamic> json) =>
    CloseSessionRequest(
      meta: json['_meta'] as Map<String, dynamic>?,
      sessionId: json['sessionId'] as String,
    );

Map<String, dynamic> _$CloseSessionRequestToJson(
  CloseSessionRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
};

CloseSessionResponse _$CloseSessionResponseFromJson(
  Map<String, dynamic> json,
) => CloseSessionResponse(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$CloseSessionResponseToJson(
  CloseSessionResponse instance,
) => <String, dynamic>{'_meta': ?instance.meta};

NewSessionResponse _$NewSessionResponseFromJson(Map<String, dynamic> json) =>
    NewSessionResponse(
      meta: json['_meta'] as Map<String, dynamic>?,
      sessionId: json['sessionId'] as String,
      configOptions: (json['configOptions'] as List<dynamic>?)
          ?.map((e) => SessionConfigOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      modes: json['modes'] == null
          ? null
          : SessionModeState.fromJson(json['modes'] as Map<String, dynamic>),
      models: json['models'] == null
          ? null
          : SessionModelState.fromJson(json['models'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$NewSessionResponseToJson(NewSessionResponse instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'sessionId': instance.sessionId,
      'configOptions': ?instance.configOptions,
      'modes': instance.modes,
      'models': instance.models,
    };

SessionModeState _$SessionModeStateFromJson(Map<String, dynamic> json) =>
    SessionModeState(
      meta: json['_meta'] as Map<String, dynamic>?,
      availableModes: (json['availableModes'] as List<dynamic>)
          .map((e) => SessionMode.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentModeId: json['currentModeId'] as String,
    );

Map<String, dynamic> _$SessionModeStateToJson(SessionModeState instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'availableModes': instance.availableModes,
      'currentModeId': instance.currentModeId,
    };

SessionMode _$SessionModeFromJson(Map<String, dynamic> json) => SessionMode(
  meta: json['_meta'] as Map<String, dynamic>?,
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$SessionModeToJson(SessionMode instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
    };

SessionModelState _$SessionModelStateFromJson(Map<String, dynamic> json) =>
    SessionModelState(
      meta: json['_meta'] as Map<String, dynamic>?,
      availableModels: (json['availableModels'] as List<dynamic>)
          .map((e) => ModelInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentModelId: json['currentModelId'] as String,
    );

Map<String, dynamic> _$SessionModelStateToJson(SessionModelState instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'availableModels': instance.availableModels,
      'currentModelId': instance.currentModelId,
    };

SessionConfigOption _$SessionConfigOptionFromJson(Map<String, dynamic> json) =>
    SessionConfigOption(
      meta: json['_meta'] as Map<String, dynamic>?,
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      type: json['type'] as String? ?? 'select',
      currentValue: json['currentValue'] as String,
      options: const SessionConfigSelectOptionsConverter().fromJson(
        json['options'] as List,
      ),
    );

Map<String, dynamic> _$SessionConfigOptionToJson(
  SessionConfigOption instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'category': instance.category,
  'type': instance.type,
  'currentValue': instance.currentValue,
  'options': const SessionConfigSelectOptionsConverter().toJson(
    instance.options,
  ),
};

UngroupedSessionConfigSelectOptions
_$UngroupedSessionConfigSelectOptionsFromJson(Map<String, dynamic> json) =>
    UngroupedSessionConfigSelectOptions(
      options: (json['options'] as List<dynamic>)
          .map(
            (e) =>
                SessionConfigSelectOption.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$UngroupedSessionConfigSelectOptionsToJson(
  UngroupedSessionConfigSelectOptions instance,
) => <String, dynamic>{'options': instance.options};

GroupedSessionConfigSelectOptions _$GroupedSessionConfigSelectOptionsFromJson(
  Map<String, dynamic> json,
) => GroupedSessionConfigSelectOptions(
  groups: (json['groups'] as List<dynamic>)
      .map((e) => SessionConfigSelectGroup.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GroupedSessionConfigSelectOptionsToJson(
  GroupedSessionConfigSelectOptions instance,
) => <String, dynamic>{'groups': instance.groups};

SessionConfigSelectOption _$SessionConfigSelectOptionFromJson(
  Map<String, dynamic> json,
) => SessionConfigSelectOption(
  meta: json['_meta'] as Map<String, dynamic>?,
  value: json['value'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$SessionConfigSelectOptionToJson(
  SessionConfigSelectOption instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'value': instance.value,
  'name': instance.name,
  'description': instance.description,
};

SessionConfigSelectGroup _$SessionConfigSelectGroupFromJson(
  Map<String, dynamic> json,
) => SessionConfigSelectGroup(
  meta: json['_meta'] as Map<String, dynamic>?,
  group: json['group'] as String,
  name: json['name'] as String,
  options: (json['options'] as List<dynamic>)
      .map((e) => SessionConfigSelectOption.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SessionConfigSelectGroupToJson(
  SessionConfigSelectGroup instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'group': instance.group,
  'name': instance.name,
  'options': instance.options,
};

ModelInfo _$ModelInfoFromJson(Map<String, dynamic> json) => ModelInfo(
  meta: json['_meta'] as Map<String, dynamic>?,
  modelId: json['modelId'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$ModelInfoToJson(ModelInfo instance) => <String, dynamic>{
  '_meta': ?instance.meta,
  'modelId': instance.modelId,
  'name': instance.name,
  'description': instance.description,
};

SessionInfo _$SessionInfoFromJson(Map<String, dynamic> json) => SessionInfo(
  meta: json['_meta'] as Map<String, dynamic>?,
  cwd: json['cwd'] as String,
  sessionId: json['sessionId'] as String,
  title: json['title'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$SessionInfoToJson(SessionInfo instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'cwd': instance.cwd,
      'sessionId': instance.sessionId,
      'title': instance.title,
      'updatedAt': instance.updatedAt,
    };

LoadSessionResponse _$LoadSessionResponseFromJson(Map<String, dynamic> json) =>
    LoadSessionResponse(
      meta: json['_meta'] as Map<String, dynamic>?,
      configOptions: (json['configOptions'] as List<dynamic>?)
          ?.map((e) => SessionConfigOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      modes: json['modes'] == null
          ? null
          : SessionModeState.fromJson(json['modes'] as Map<String, dynamic>),
      models: json['models'] == null
          ? null
          : SessionModelState.fromJson(json['models'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoadSessionResponseToJson(
  LoadSessionResponse instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'configOptions': ?instance.configOptions,
  'modes': instance.modes,
  'models': instance.models,
};

ListSessionsResponse _$ListSessionsResponseFromJson(
  Map<String, dynamic> json,
) => ListSessionsResponse(
  meta: json['_meta'] as Map<String, dynamic>?,
  nextCursor: json['nextCursor'] as String?,
  sessions: (json['sessions'] as List<dynamic>)
      .map((e) => SessionInfo.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ListSessionsResponseToJson(
  ListSessionsResponse instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'nextCursor': instance.nextCursor,
  'sessions': instance.sessions,
};

ForkSessionResponse _$ForkSessionResponseFromJson(Map<String, dynamic> json) =>
    ForkSessionResponse(
      meta: json['_meta'] as Map<String, dynamic>?,
      configOptions: (json['configOptions'] as List<dynamic>?)
          ?.map((e) => SessionConfigOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      modes: json['modes'] == null
          ? null
          : SessionModeState.fromJson(json['modes'] as Map<String, dynamic>),
      models: json['models'] == null
          ? null
          : SessionModelState.fromJson(json['models'] as Map<String, dynamic>),
      sessionId: json['sessionId'] as String,
    );

Map<String, dynamic> _$ForkSessionResponseToJson(
  ForkSessionResponse instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'configOptions': ?instance.configOptions,
  'modes': instance.modes,
  'models': instance.models,
  'sessionId': instance.sessionId,
};

ResumeSessionResponse _$ResumeSessionResponseFromJson(
  Map<String, dynamic> json,
) => ResumeSessionResponse(
  meta: json['_meta'] as Map<String, dynamic>?,
  configOptions: (json['configOptions'] as List<dynamic>?)
      ?.map((e) => SessionConfigOption.fromJson(e as Map<String, dynamic>))
      .toList(),
  modes: json['modes'] == null
      ? null
      : SessionModeState.fromJson(json['modes'] as Map<String, dynamic>),
  models: json['models'] == null
      ? null
      : SessionModelState.fromJson(json['models'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ResumeSessionResponseToJson(
  ResumeSessionResponse instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'configOptions': ?instance.configOptions,
  'modes': instance.modes,
  'models': instance.models,
};

SetSessionModeResponse _$SetSessionModeResponseFromJson(
  Map<String, dynamic> json,
) => SetSessionModeResponse(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$SetSessionModeResponseToJson(
  SetSessionModeResponse instance,
) => <String, dynamic>{'_meta': ?instance.meta};

SetSessionConfigOptionResponse _$SetSessionConfigOptionResponseFromJson(
  Map<String, dynamic> json,
) => SetSessionConfigOptionResponse(
  meta: json['_meta'] as Map<String, dynamic>?,
  configOptions: (json['configOptions'] as List<dynamic>)
      .map((e) => SessionConfigOption.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SetSessionConfigOptionResponseToJson(
  SetSessionConfigOptionResponse instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'configOptions': instance.configOptions,
};

Usage _$UsageFromJson(Map<String, dynamic> json) => Usage(
  inputTokens: (json['inputTokens'] as num).toInt(),
  outputTokens: (json['outputTokens'] as num).toInt(),
  totalTokens: (json['totalTokens'] as num).toInt(),
  cachedReadTokens: (json['cachedReadTokens'] as num?)?.toInt(),
  cachedWriteTokens: (json['cachedWriteTokens'] as num?)?.toInt(),
  thoughtTokens: (json['thoughtTokens'] as num?)?.toInt(),
);

Map<String, dynamic> _$UsageToJson(Usage instance) => <String, dynamic>{
  'inputTokens': instance.inputTokens,
  'outputTokens': instance.outputTokens,
  'totalTokens': instance.totalTokens,
  'cachedReadTokens': instance.cachedReadTokens,
  'cachedWriteTokens': instance.cachedWriteTokens,
  'thoughtTokens': instance.thoughtTokens,
};

PromptResponse _$PromptResponseFromJson(Map<String, dynamic> json) =>
    PromptResponse(
      meta: json['_meta'] as Map<String, dynamic>?,
      stopReason: $enumDecode(_$StopReasonEnumMap, json['stopReason']),
      usage: json['usage'] == null
          ? null
          : Usage.fromJson(json['usage'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PromptResponseToJson(PromptResponse instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'stopReason': _$StopReasonEnumMap[instance.stopReason]!,
      'usage': instance.usage,
    };

const _$StopReasonEnumMap = {
  StopReason.endTurn: 'end_turn',
  StopReason.maxTokens: 'max_tokens',
  StopReason.maxTurnRequests: 'max_turn_requests',
  StopReason.refusal: 'refusal',
  StopReason.cancelled: 'cancelled',
};

Cost _$CostFromJson(Map<String, dynamic> json) => Cost(
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String,
);

Map<String, dynamic> _$CostToJson(Cost instance) => <String, dynamic>{
  'amount': instance.amount,
  'currency': instance.currency,
};

SetSessionModelResponse _$SetSessionModelResponseFromJson(
  Map<String, dynamic> json,
) => SetSessionModelResponse(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$SetSessionModelResponseToJson(
  SetSessionModelResponse instance,
) => <String, dynamic>{'_meta': ?instance.meta};

WriteTextFileResponse _$WriteTextFileResponseFromJson(
  Map<String, dynamic> json,
) => WriteTextFileResponse(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$WriteTextFileResponseToJson(
  WriteTextFileResponse instance,
) => <String, dynamic>{'_meta': ?instance.meta};

ReadTextFileResponse _$ReadTextFileResponseFromJson(
  Map<String, dynamic> json,
) => ReadTextFileResponse(
  meta: json['_meta'] as Map<String, dynamic>?,
  content: json['content'] as String,
);

Map<String, dynamic> _$ReadTextFileResponseToJson(
  ReadTextFileResponse instance,
) => <String, dynamic>{'_meta': ?instance.meta, 'content': instance.content};

CancelledOutcome _$CancelledOutcomeFromJson(Map<String, dynamic> json) =>
    CancelledOutcome(
      meta: json['_meta'] as Map<String, dynamic>?,
      outcome: json['outcome'] as String? ?? 'cancelled',
    );

Map<String, dynamic> _$CancelledOutcomeToJson(CancelledOutcome instance) =>
    <String, dynamic>{'_meta': ?instance.meta, 'outcome': instance.outcome};

SelectedOutcome _$SelectedOutcomeFromJson(Map<String, dynamic> json) =>
    SelectedOutcome(
      meta: json['_meta'] as Map<String, dynamic>?,
      outcome: json['outcome'] as String? ?? 'selected',
      optionId: json['optionId'] as String,
    );

Map<String, dynamic> _$SelectedOutcomeToJson(SelectedOutcome instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'outcome': instance.outcome,
      'optionId': instance.optionId,
    };

RequestPermissionResponse _$RequestPermissionResponseFromJson(
  Map<String, dynamic> json,
) => RequestPermissionResponse(
  meta: json['_meta'] as Map<String, dynamic>?,
  outcome: const RequestPermissionOutcomeConverter().fromJson(
    json['outcome'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$RequestPermissionResponseToJson(
  RequestPermissionResponse instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'outcome': const RequestPermissionOutcomeConverter().toJson(instance.outcome),
};

CreateTerminalResponse _$CreateTerminalResponseFromJson(
  Map<String, dynamic> json,
) => CreateTerminalResponse(
  meta: json['_meta'] as Map<String, dynamic>?,
  terminalId: json['terminalId'] as String,
);

Map<String, dynamic> _$CreateTerminalResponseToJson(
  CreateTerminalResponse instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'terminalId': instance.terminalId,
};

TerminalOutputResponse _$TerminalOutputResponseFromJson(
  Map<String, dynamic> json,
) => TerminalOutputResponse(
  meta: json['_meta'] as Map<String, dynamic>?,
  output: json['output'] as String,
  exitStatus: json['exitStatus'] == null
      ? null
      : TerminalExitStatus.fromJson(json['exitStatus'] as Map<String, dynamic>),
  truncated: json['truncated'] as bool,
);

Map<String, dynamic> _$TerminalOutputResponseToJson(
  TerminalOutputResponse instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'output': instance.output,
  'exitStatus': instance.exitStatus,
  'truncated': instance.truncated,
};

TerminalExitStatus _$TerminalExitStatusFromJson(Map<String, dynamic> json) =>
    TerminalExitStatus(
      meta: json['_meta'] as Map<String, dynamic>?,
      exitCode: (json['exitCode'] as num?)?.toInt(),
      signal: json['signal'] as String?,
    );

Map<String, dynamic> _$TerminalExitStatusToJson(TerminalExitStatus instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'exitCode': instance.exitCode,
      'signal': instance.signal,
    };

ReleaseTerminalResponse _$ReleaseTerminalResponseFromJson(
  Map<String, dynamic> json,
) => ReleaseTerminalResponse(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$ReleaseTerminalResponseToJson(
  ReleaseTerminalResponse instance,
) => <String, dynamic>{'_meta': ?instance.meta};

WaitForTerminalExitResponse _$WaitForTerminalExitResponseFromJson(
  Map<String, dynamic> json,
) => WaitForTerminalExitResponse(
  meta: json['_meta'] as Map<String, dynamic>?,
  exitCode: (json['exitCode'] as num?)?.toInt(),
  signal: json['signal'] as String?,
);

Map<String, dynamic> _$WaitForTerminalExitResponseToJson(
  WaitForTerminalExitResponse instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'exitCode': instance.exitCode,
  'signal': instance.signal,
};

KillTerminalCommandResponse _$KillTerminalCommandResponseFromJson(
  Map<String, dynamic> json,
) => KillTerminalCommandResponse(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$KillTerminalCommandResponseToJson(
  KillTerminalCommandResponse instance,
) => <String, dynamic>{'_meta': ?instance.meta};

CancelNotification _$CancelNotificationFromJson(Map<String, dynamic> json) =>
    CancelNotification(
      meta: json['_meta'] as Map<String, dynamic>?,
      sessionId: json['sessionId'] as String,
    );

Map<String, dynamic> _$CancelNotificationToJson(CancelNotification instance) =>
    <String, dynamic>{'_meta': ?instance.meta, 'sessionId': instance.sessionId};

CancelRequestNotification _$CancelRequestNotificationFromJson(
  Map<String, dynamic> json,
) => CancelRequestNotification(
  meta: json['_meta'] as Map<String, dynamic>?,
  requestId: json['requestId'],
);

Map<String, dynamic> _$CancelRequestNotificationToJson(
  CancelRequestNotification instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'requestId': instance.requestId,
};

ExtNotification _$ExtNotificationFromJson(Map<String, dynamic> json) =>
    ExtNotification();

Map<String, dynamic> _$ExtNotificationToJson(ExtNotification instance) =>
    <String, dynamic>{};

ExtMethodRequest _$ExtMethodRequestFromJson(Map<String, dynamic> json) =>
    ExtMethodRequest();

Map<String, dynamic> _$ExtMethodRequestToJson(ExtMethodRequest instance) =>
    <String, dynamic>{};

ExtMethodResponse _$ExtMethodResponseFromJson(Map<String, dynamic> json) =>
    ExtMethodResponse();

Map<String, dynamic> _$ExtMethodResponseToJson(ExtMethodResponse instance) =>
    <String, dynamic>{};

Annotations _$AnnotationsFromJson(Map<String, dynamic> json) => Annotations(
  meta: json['_meta'] as Map<String, dynamic>?,
  audience: (json['audience'] as List<dynamic>?)
      ?.map((e) => $enumDecode(_$RoleEnumMap, e))
      .toList(),
  lastModified: json['lastModified'] as String?,
  priority: (json['priority'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AnnotationsToJson(Annotations instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'audience': instance.audience?.map((e) => _$RoleEnumMap[e]!).toList(),
      'lastModified': instance.lastModified,
      'priority': instance.priority,
    };

const _$RoleEnumMap = {Role.assistant: 'assistant', Role.user: 'user'};

TextResourceContents _$TextResourceContentsFromJson(
  Map<String, dynamic> json,
) => TextResourceContents(
  meta: json['_meta'] as Map<String, dynamic>?,
  mimeType: json['mimeType'] as String?,
  text: json['text'] as String,
  uri: json['uri'] as String,
);

Map<String, dynamic> _$TextResourceContentsToJson(
  TextResourceContents instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'mimeType': instance.mimeType,
  'text': instance.text,
  'uri': instance.uri,
};

BlobResourceContents _$BlobResourceContentsFromJson(
  Map<String, dynamic> json,
) => BlobResourceContents(
  meta: json['_meta'] as Map<String, dynamic>?,
  mimeType: json['mimeType'] as String?,
  blob: json['blob'] as String,
  uri: json['uri'] as String,
);

Map<String, dynamic> _$BlobResourceContentsToJson(
  BlobResourceContents instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'mimeType': instance.mimeType,
  'blob': instance.blob,
  'uri': instance.uri,
};

EmbeddedResource _$EmbeddedResourceFromJson(Map<String, dynamic> json) =>
    EmbeddedResource(
      meta: json['_meta'] as Map<String, dynamic>?,
      annotations: json['annotations'] == null
          ? null
          : Annotations.fromJson(json['annotations'] as Map<String, dynamic>),
      resource: const EmbeddedResourceResourceConverter().fromJson(
        json['resource'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$EmbeddedResourceToJson(EmbeddedResource instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'annotations': instance.annotations,
      'resource': const EmbeddedResourceResourceConverter().toJson(
        instance.resource,
      ),
    };

ContentToolCallContent _$ContentToolCallContentFromJson(
  Map<String, dynamic> json,
) => ContentToolCallContent(
  meta: json['_meta'] as Map<String, dynamic>?,
  content: const ContentBlockConverter().fromJson(
    json['content'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ContentToolCallContentToJson(
  ContentToolCallContent instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'content': const ContentBlockConverter().toJson(instance.content),
};

DiffToolCallContent _$DiffToolCallContentFromJson(Map<String, dynamic> json) =>
    DiffToolCallContent(
      meta: json['_meta'] as Map<String, dynamic>?,
      newText: json['newText'] as String,
      oldText: json['oldText'] as String?,
      path: json['path'] as String,
    );

Map<String, dynamic> _$DiffToolCallContentToJson(
  DiffToolCallContent instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'newText': instance.newText,
  'oldText': instance.oldText,
  'path': instance.path,
};

TerminalToolCallContent _$TerminalToolCallContentFromJson(
  Map<String, dynamic> json,
) => TerminalToolCallContent(
  meta: json['_meta'] as Map<String, dynamic>?,
  terminalId: json['terminalId'] as String,
);

Map<String, dynamic> _$TerminalToolCallContentToJson(
  TerminalToolCallContent instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'terminalId': instance.terminalId,
};

ToolCallLocation _$ToolCallLocationFromJson(Map<String, dynamic> json) =>
    ToolCallLocation(
      meta: json['_meta'] as Map<String, dynamic>?,
      line: (json['line'] as num?)?.toInt(),
      path: json['path'] as String,
    );

Map<String, dynamic> _$ToolCallLocationToJson(ToolCallLocation instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'line': instance.line,
      'path': instance.path,
    };

PlanEntry _$PlanEntryFromJson(Map<String, dynamic> json) => PlanEntry(
  meta: json['_meta'] as Map<String, dynamic>?,
  content: json['content'] as String,
  priority: $enumDecode(_$PlanEntryPriorityEnumMap, json['priority']),
  status: $enumDecode(_$PlanEntryStatusEnumMap, json['status']),
);

Map<String, dynamic> _$PlanEntryToJson(PlanEntry instance) => <String, dynamic>{
  '_meta': ?instance.meta,
  'content': instance.content,
  'priority': _$PlanEntryPriorityEnumMap[instance.priority]!,
  'status': _$PlanEntryStatusEnumMap[instance.status]!,
};

const _$PlanEntryPriorityEnumMap = {
  PlanEntryPriority.high: 'high',
  PlanEntryPriority.medium: 'medium',
  PlanEntryPriority.low: 'low',
};

const _$PlanEntryStatusEnumMap = {
  PlanEntryStatus.pending: 'pending',
  PlanEntryStatus.inProgress: 'in_progress',
  PlanEntryStatus.completed: 'completed',
};

Plan _$PlanFromJson(Map<String, dynamic> json) => Plan(
  meta: json['_meta'] as Map<String, dynamic>?,
  entries: (json['entries'] as List<dynamic>)
      .map((e) => PlanEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PlanToJson(Plan instance) => <String, dynamic>{
  '_meta': ?instance.meta,
  'entries': instance.entries,
};

UnstructuredCommandInput _$UnstructuredCommandInputFromJson(
  Map<String, dynamic> json,
) => UnstructuredCommandInput(
  meta: json['_meta'] as Map<String, dynamic>?,
  hint: json['hint'] as String,
);

Map<String, dynamic> _$UnstructuredCommandInputToJson(
  UnstructuredCommandInput instance,
) => <String, dynamic>{'_meta': ?instance.meta, 'hint': instance.hint};

AvailableCommand _$AvailableCommandFromJson(Map<String, dynamic> json) =>
    AvailableCommand(
      meta: json['_meta'] as Map<String, dynamic>?,
      description: json['description'] as String,
      input: json['input'] == null
          ? null
          : UnstructuredCommandInput.fromJson(
              json['input'] as Map<String, dynamic>,
            ),
      name: json['name'] as String,
    );

Map<String, dynamic> _$AvailableCommandToJson(AvailableCommand instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'description': instance.description,
      'input': instance.input,
      'name': instance.name,
    };

SessionNotification _$SessionNotificationFromJson(Map<String, dynamic> json) =>
    SessionNotification(
      meta: json['_meta'] as Map<String, dynamic>?,
      sessionId: json['sessionId'] as String,
      update: const SessionUpdateConverter().fromJson(
        json['update'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$SessionNotificationToJson(
  SessionNotification instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
  'update': const SessionUpdateConverter().toJson(instance.update),
};

UserMessageChunkSessionUpdate _$UserMessageChunkSessionUpdateFromJson(
  Map<String, dynamic> json,
) => UserMessageChunkSessionUpdate(
  content: const ContentBlockConverter().fromJson(
    json['content'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$UserMessageChunkSessionUpdateToJson(
  UserMessageChunkSessionUpdate instance,
) => <String, dynamic>{
  'content': const ContentBlockConverter().toJson(instance.content),
};

AgentMessageChunkSessionUpdate _$AgentMessageChunkSessionUpdateFromJson(
  Map<String, dynamic> json,
) => AgentMessageChunkSessionUpdate(
  content: const ContentBlockConverter().fromJson(
    json['content'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$AgentMessageChunkSessionUpdateToJson(
  AgentMessageChunkSessionUpdate instance,
) => <String, dynamic>{
  'content': const ContentBlockConverter().toJson(instance.content),
};

AgentThoughtChunkSessionUpdate _$AgentThoughtChunkSessionUpdateFromJson(
  Map<String, dynamic> json,
) => AgentThoughtChunkSessionUpdate(
  content: const ContentBlockConverter().fromJson(
    json['content'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$AgentThoughtChunkSessionUpdateToJson(
  AgentThoughtChunkSessionUpdate instance,
) => <String, dynamic>{
  'content': const ContentBlockConverter().toJson(instance.content),
};

ToolCallSessionUpdate _$ToolCallSessionUpdateFromJson(
  Map<String, dynamic> json,
) => ToolCallSessionUpdate(
  meta: json['_meta'] as Map<String, dynamic>?,
  content: (json['content'] as List<dynamic>?)
      ?.map(
        (e) => const ToolCallContentConverter().fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
  kind: $enumDecodeNullable(_$ToolKindEnumMap, json['kind']),
  locations: (json['locations'] as List<dynamic>?)
      ?.map((e) => ToolCallLocation.fromJson(e as Map<String, dynamic>))
      .toList(),
  rawInput: json['rawInput'] as Map<String, dynamic>?,
  rawOutput: json['rawOutput'] as Map<String, dynamic>?,
  status: $enumDecodeNullable(_$ToolCallStatusEnumMap, json['status']),
  title: json['title'] as String,
  toolCallId: json['toolCallId'] as String,
);

Map<String, dynamic> _$ToolCallSessionUpdateToJson(
  ToolCallSessionUpdate instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'content': instance.content
      ?.map(const ToolCallContentConverter().toJson)
      .toList(),
  'kind': _$ToolKindEnumMap[instance.kind],
  'locations': instance.locations,
  'rawInput': instance.rawInput,
  'rawOutput': instance.rawOutput,
  'status': _$ToolCallStatusEnumMap[instance.status],
  'title': instance.title,
  'toolCallId': instance.toolCallId,
};

ToolCallUpdateSessionUpdate _$ToolCallUpdateSessionUpdateFromJson(
  Map<String, dynamic> json,
) => ToolCallUpdateSessionUpdate(
  meta: json['_meta'] as Map<String, dynamic>?,
  content: (json['content'] as List<dynamic>?)
      ?.map(
        (e) => const ToolCallContentConverter().fromJson(
          e as Map<String, dynamic>,
        ),
      )
      .toList(),
  kind: $enumDecodeNullable(_$ToolKindEnumMap, json['kind']),
  locations: (json['locations'] as List<dynamic>?)
      ?.map((e) => ToolCallLocation.fromJson(e as Map<String, dynamic>))
      .toList(),
  rawInput: json['rawInput'] as Map<String, dynamic>?,
  rawOutput: json['rawOutput'] as Map<String, dynamic>?,
  status: $enumDecodeNullable(_$ToolCallStatusEnumMap, json['status']),
  title: json['title'] as String?,
  toolCallId: json['toolCallId'] as String,
);

Map<String, dynamic> _$ToolCallUpdateSessionUpdateToJson(
  ToolCallUpdateSessionUpdate instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'content': instance.content
      ?.map(const ToolCallContentConverter().toJson)
      .toList(),
  'kind': _$ToolKindEnumMap[instance.kind],
  'locations': instance.locations,
  'rawInput': instance.rawInput,
  'rawOutput': instance.rawOutput,
  'status': _$ToolCallStatusEnumMap[instance.status],
  'title': instance.title,
  'toolCallId': instance.toolCallId,
};

PlanSessionUpdate _$PlanSessionUpdateFromJson(Map<String, dynamic> json) =>
    PlanSessionUpdate(
      meta: json['_meta'] as Map<String, dynamic>?,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => PlanEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlanSessionUpdateToJson(PlanSessionUpdate instance) =>
    <String, dynamic>{'_meta': ?instance.meta, 'entries': instance.entries};

AvailableCommandsUpdateSessionUpdate
_$AvailableCommandsUpdateSessionUpdateFromJson(Map<String, dynamic> json) =>
    AvailableCommandsUpdateSessionUpdate(
      meta: json['_meta'] as Map<String, dynamic>?,
      availableCommands: (json['availableCommands'] as List<dynamic>)
          .map((e) => AvailableCommand.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AvailableCommandsUpdateSessionUpdateToJson(
  AvailableCommandsUpdateSessionUpdate instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'availableCommands': instance.availableCommands,
};

CurrentModeUpdateSessionUpdate _$CurrentModeUpdateSessionUpdateFromJson(
  Map<String, dynamic> json,
) => CurrentModeUpdateSessionUpdate(
  meta: json['_meta'] as Map<String, dynamic>?,
  currentModeId: json['currentModeId'] as String,
);

Map<String, dynamic> _$CurrentModeUpdateSessionUpdateToJson(
  CurrentModeUpdateSessionUpdate instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'currentModeId': instance.currentModeId,
};

ConfigOptionUpdate _$ConfigOptionUpdateFromJson(Map<String, dynamic> json) =>
    ConfigOptionUpdate(
      meta: json['_meta'] as Map<String, dynamic>?,
      configOptions: (json['configOptions'] as List<dynamic>)
          .map((e) => SessionConfigOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ConfigOptionUpdateToJson(ConfigOptionUpdate instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'configOptions': instance.configOptions,
    };

SessionInfoUpdate _$SessionInfoUpdateFromJson(Map<String, dynamic> json) =>
    SessionInfoUpdate(
      meta: json['_meta'] as Map<String, dynamic>?,
      title: json['title'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$SessionInfoUpdateToJson(SessionInfoUpdate instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'title': instance.title,
      'updatedAt': instance.updatedAt,
    };

UsageUpdate _$UsageUpdateFromJson(Map<String, dynamic> json) => UsageUpdate(
  meta: json['_meta'] as Map<String, dynamic>?,
  size: (json['size'] as num).toInt(),
  used: (json['used'] as num).toInt(),
  cost: json['cost'] == null
      ? null
      : Cost.fromJson(json['cost'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UsageUpdateToJson(UsageUpdate instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'size': instance.size,
      'used': instance.used,
      'cost': instance.cost,
    };

UnknownSessionUpdate _$UnknownSessionUpdateFromJson(
  Map<String, dynamic> json,
) => UnknownSessionUpdate(rawJson: json['rawJson'] as Map<String, dynamic>);

Map<String, dynamic> _$UnknownSessionUpdateToJson(
  UnknownSessionUpdate instance,
) => <String, dynamic>{'rawJson': instance.rawJson};

EnumOption _$EnumOptionFromJson(Map<String, dynamic> json) => EnumOption(
  meta: json['_meta'] as Map<String, dynamic>?,
  constValue: json['const'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$EnumOptionToJson(EnumOption instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'const': instance.constValue,
      'title': instance.title,
      'description': instance.description,
    };

StringMultiSelectItems _$StringMultiSelectItemsFromJson(
  Map<String, dynamic> json,
) => StringMultiSelectItems(
  meta: json['_meta'] as Map<String, dynamic>?,
  enumValues: (json['enum'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$StringMultiSelectItemsToJson(
  StringMultiSelectItems instance,
) => <String, dynamic>{'_meta': ?instance.meta, 'enum': instance.enumValues};

TitledMultiSelectItems _$TitledMultiSelectItemsFromJson(
  Map<String, dynamic> json,
) => TitledMultiSelectItems(
  meta: json['_meta'] as Map<String, dynamic>?,
  anyOf: (json['anyOf'] as List<dynamic>)
      .map((e) => EnumOption.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TitledMultiSelectItemsToJson(
  TitledMultiSelectItems instance,
) => <String, dynamic>{'_meta': ?instance.meta, 'anyOf': instance.anyOf};

UnknownMultiSelectItems _$UnknownMultiSelectItemsFromJson(
  Map<String, dynamic> json,
) => UnknownMultiSelectItems(rawJson: json['rawJson'] as Map<String, dynamic>);

Map<String, dynamic> _$UnknownMultiSelectItemsToJson(
  UnknownMultiSelectItems instance,
) => <String, dynamic>{'rawJson': instance.rawJson};

StringPropertySchema _$StringPropertySchemaFromJson(
  Map<String, dynamic> json,
) => StringPropertySchema(
  meta: json['_meta'] as Map<String, dynamic>?,
  title: json['title'] as String?,
  description: json['description'] as String?,
  minLength: (json['minLength'] as num?)?.toInt(),
  maxLength: (json['maxLength'] as num?)?.toInt(),
  pattern: json['pattern'] as String?,
  format: $enumDecodeNullable(_$StringFormatEnumMap, json['format']),
  defaultValue: json['default'] as String?,
  enumValues: (json['enum'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  oneOf: (json['oneOf'] as List<dynamic>?)
      ?.map((e) => EnumOption.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$StringPropertySchemaToJson(
  StringPropertySchema instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'title': instance.title,
  'description': instance.description,
  'minLength': instance.minLength,
  'maxLength': instance.maxLength,
  'pattern': instance.pattern,
  'format': _$StringFormatEnumMap[instance.format],
  'default': instance.defaultValue,
  'enum': instance.enumValues,
  'oneOf': instance.oneOf,
};

const _$StringFormatEnumMap = {
  StringFormat.email: 'email',
  StringFormat.uri: 'uri',
  StringFormat.date: 'date',
  StringFormat.dateTime: 'date-time',
};

NumberPropertySchema _$NumberPropertySchemaFromJson(
  Map<String, dynamic> json,
) => NumberPropertySchema(
  meta: json['_meta'] as Map<String, dynamic>?,
  title: json['title'] as String?,
  description: json['description'] as String?,
  minimum: json['minimum'] as num?,
  maximum: json['maximum'] as num?,
  defaultValue: json['default'] as num?,
);

Map<String, dynamic> _$NumberPropertySchemaToJson(
  NumberPropertySchema instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'title': instance.title,
  'description': instance.description,
  'minimum': instance.minimum,
  'maximum': instance.maximum,
  'default': instance.defaultValue,
};

IntegerPropertySchema _$IntegerPropertySchemaFromJson(
  Map<String, dynamic> json,
) => IntegerPropertySchema(
  meta: json['_meta'] as Map<String, dynamic>?,
  title: json['title'] as String?,
  description: json['description'] as String?,
  minimum: (json['minimum'] as num?)?.toInt(),
  maximum: (json['maximum'] as num?)?.toInt(),
  defaultValue: (json['default'] as num?)?.toInt(),
);

Map<String, dynamic> _$IntegerPropertySchemaToJson(
  IntegerPropertySchema instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'title': instance.title,
  'description': instance.description,
  'minimum': instance.minimum,
  'maximum': instance.maximum,
  'default': instance.defaultValue,
};

BooleanPropertySchema _$BooleanPropertySchemaFromJson(
  Map<String, dynamic> json,
) => BooleanPropertySchema(
  meta: json['_meta'] as Map<String, dynamic>?,
  title: json['title'] as String?,
  description: json['description'] as String?,
  defaultValue: json['default'] as bool?,
);

Map<String, dynamic> _$BooleanPropertySchemaToJson(
  BooleanPropertySchema instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'title': instance.title,
  'description': instance.description,
  'default': instance.defaultValue,
};

MultiSelectPropertySchema _$MultiSelectPropertySchemaFromJson(
  Map<String, dynamic> json,
) => MultiSelectPropertySchema(
  meta: json['_meta'] as Map<String, dynamic>?,
  title: json['title'] as String?,
  description: json['description'] as String?,
  minItems: (json['minItems'] as num?)?.toInt(),
  maxItems: (json['maxItems'] as num?)?.toInt(),
  items: const MultiSelectItemsConverter().fromJson(
    json['items'] as Map<String, dynamic>,
  ),
  defaultValue: (json['default'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$MultiSelectPropertySchemaToJson(
  MultiSelectPropertySchema instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'title': instance.title,
  'description': instance.description,
  'minItems': instance.minItems,
  'maxItems': instance.maxItems,
  'items': const MultiSelectItemsConverter().toJson(instance.items),
  'default': instance.defaultValue,
};

UnknownPropertySchema _$UnknownPropertySchemaFromJson(
  Map<String, dynamic> json,
) => UnknownPropertySchema(rawJson: json['rawJson'] as Map<String, dynamic>);

Map<String, dynamic> _$UnknownPropertySchemaToJson(
  UnknownPropertySchema instance,
) => <String, dynamic>{'rawJson': instance.rawJson};

ElicitationSchema _$ElicitationSchemaFromJson(Map<String, dynamic> json) =>
    ElicitationSchema(
      meta: json['_meta'] as Map<String, dynamic>?,
      type: json['type'] as String? ?? 'object',
      title: json['title'] as String?,
      description: json['description'] as String?,
      properties: const ElicitationPropertySchemaMapConverter().fromJson(
        json['properties'] as Map<String, dynamic>?,
      ),
      required: (json['required'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ElicitationSchemaToJson(ElicitationSchema instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'type': instance.type,
      'title': instance.title,
      'description': instance.description,
      'properties': const ElicitationPropertySchemaMapConverter().toJson(
        instance.properties,
      ),
      'required': instance.required,
    };

ElicitationFormRequest _$ElicitationFormRequestFromJson(
  Map<String, dynamic> json,
) => ElicitationFormRequest(
  meta: json['_meta'] as Map<String, dynamic>?,
  message: json['message'] as String,
  sessionId: json['sessionId'] as String?,
  toolCallId: json['toolCallId'] as String?,
  requestId: json['requestId'],
  requestedSchema: ElicitationSchema.fromJson(
    json['requestedSchema'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ElicitationFormRequestToJson(
  ElicitationFormRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'message': instance.message,
  'sessionId': instance.sessionId,
  'toolCallId': instance.toolCallId,
  'requestId': instance.requestId,
  'requestedSchema': instance.requestedSchema,
};

ElicitationUrlRequest _$ElicitationUrlRequestFromJson(
  Map<String, dynamic> json,
) => ElicitationUrlRequest(
  meta: json['_meta'] as Map<String, dynamic>?,
  message: json['message'] as String,
  sessionId: json['sessionId'] as String?,
  toolCallId: json['toolCallId'] as String?,
  requestId: json['requestId'],
  elicitationId: json['elicitationId'] as String,
  url: json['url'] as String,
);

Map<String, dynamic> _$ElicitationUrlRequestToJson(
  ElicitationUrlRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'message': instance.message,
  'sessionId': instance.sessionId,
  'toolCallId': instance.toolCallId,
  'requestId': instance.requestId,
  'elicitationId': instance.elicitationId,
  'url': instance.url,
};

UnknownElicitationRequest _$UnknownElicitationRequestFromJson(
  Map<String, dynamic> json,
) =>
    UnknownElicitationRequest(rawJson: json['rawJson'] as Map<String, dynamic>);

Map<String, dynamic> _$UnknownElicitationRequestToJson(
  UnknownElicitationRequest instance,
) => <String, dynamic>{'rawJson': instance.rawJson};

ElicitationAcceptResponse _$ElicitationAcceptResponseFromJson(
  Map<String, dynamic> json,
) => ElicitationAcceptResponse(
  meta: json['_meta'] as Map<String, dynamic>?,
  content: json['content'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ElicitationAcceptResponseToJson(
  ElicitationAcceptResponse instance,
) => <String, dynamic>{'_meta': ?instance.meta, 'content': instance.content};

ElicitationDeclineResponse _$ElicitationDeclineResponseFromJson(
  Map<String, dynamic> json,
) => ElicitationDeclineResponse(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$ElicitationDeclineResponseToJson(
  ElicitationDeclineResponse instance,
) => <String, dynamic>{'_meta': ?instance.meta};

ElicitationCancelResponse _$ElicitationCancelResponseFromJson(
  Map<String, dynamic> json,
) => ElicitationCancelResponse(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$ElicitationCancelResponseToJson(
  ElicitationCancelResponse instance,
) => <String, dynamic>{'_meta': ?instance.meta};

UnknownElicitationResponse _$UnknownElicitationResponseFromJson(
  Map<String, dynamic> json,
) => UnknownElicitationResponse(
  rawJson: json['rawJson'] as Map<String, dynamic>,
);

Map<String, dynamic> _$UnknownElicitationResponseToJson(
  UnknownElicitationResponse instance,
) => <String, dynamic>{'rawJson': instance.rawJson};

CompleteElicitationNotification _$CompleteElicitationNotificationFromJson(
  Map<String, dynamic> json,
) => CompleteElicitationNotification(
  meta: json['_meta'] as Map<String, dynamic>?,
  elicitationId: json['elicitationId'] as String,
);

Map<String, dynamic> _$CompleteElicitationNotificationToJson(
  CompleteElicitationNotification instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'elicitationId': instance.elicitationId,
};

ElicitationFormCapabilities _$ElicitationFormCapabilitiesFromJson(
  Map<String, dynamic> json,
) => ElicitationFormCapabilities(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$ElicitationFormCapabilitiesToJson(
  ElicitationFormCapabilities instance,
) => <String, dynamic>{'_meta': ?instance.meta};

ElicitationUrlCapabilities _$ElicitationUrlCapabilitiesFromJson(
  Map<String, dynamic> json,
) => ElicitationUrlCapabilities(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$ElicitationUrlCapabilitiesToJson(
  ElicitationUrlCapabilities instance,
) => <String, dynamic>{'_meta': ?instance.meta};

ElicitationCapabilities _$ElicitationCapabilitiesFromJson(
  Map<String, dynamic> json,
) => ElicitationCapabilities(
  meta: json['_meta'] as Map<String, dynamic>?,
  form: json['form'] == null
      ? null
      : ElicitationFormCapabilities.fromJson(
          json['form'] as Map<String, dynamic>,
        ),
  url: json['url'] == null
      ? null
      : ElicitationUrlCapabilities.fromJson(
          json['url'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ElicitationCapabilitiesToJson(
  ElicitationCapabilities instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'form': instance.form,
  'url': instance.url,
};

ProviderCurrentConfig _$ProviderCurrentConfigFromJson(
  Map<String, dynamic> json,
) => ProviderCurrentConfig(
  meta: json['_meta'] as Map<String, dynamic>?,
  apiType: json['apiType'] as String,
  baseUrl: json['baseUrl'] as String,
);

Map<String, dynamic> _$ProviderCurrentConfigToJson(
  ProviderCurrentConfig instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'apiType': instance.apiType,
  'baseUrl': instance.baseUrl,
};

ProviderInfo _$ProviderInfoFromJson(Map<String, dynamic> json) => ProviderInfo(
  meta: json['_meta'] as Map<String, dynamic>?,
  providerId: json['providerId'] as String,
  supported: (json['supported'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  required: json['required'] as bool,
  current: json['current'] == null
      ? null
      : ProviderCurrentConfig.fromJson(json['current'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ProviderInfoToJson(ProviderInfo instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'providerId': instance.providerId,
      'supported': instance.supported,
      'required': instance.required,
      'current': instance.current,
    };

ProvidersCapabilities _$ProvidersCapabilitiesFromJson(
  Map<String, dynamic> json,
) => ProvidersCapabilities(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$ProvidersCapabilitiesToJson(
  ProvidersCapabilities instance,
) => <String, dynamic>{'_meta': ?instance.meta};

ListProvidersRequest _$ListProvidersRequestFromJson(
  Map<String, dynamic> json,
) => ListProvidersRequest(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$ListProvidersRequestToJson(
  ListProvidersRequest instance,
) => <String, dynamic>{'_meta': ?instance.meta};

ListProvidersResponse _$ListProvidersResponseFromJson(
  Map<String, dynamic> json,
) => ListProvidersResponse(
  meta: json['_meta'] as Map<String, dynamic>?,
  providers: (json['providers'] as List<dynamic>)
      .map((e) => ProviderInfo.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ListProvidersResponseToJson(
  ListProvidersResponse instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'providers': instance.providers,
};

SetProviderRequest _$SetProviderRequestFromJson(Map<String, dynamic> json) =>
    SetProviderRequest(
      meta: json['_meta'] as Map<String, dynamic>?,
      providerId: json['providerId'] as String,
      apiType: json['apiType'] as String,
      baseUrl: json['baseUrl'] as String,
      headers: (json['headers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$SetProviderRequestToJson(SetProviderRequest instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'providerId': instance.providerId,
      'apiType': instance.apiType,
      'baseUrl': instance.baseUrl,
      'headers': ?instance.headers,
    };

SetProviderResponse _$SetProviderResponseFromJson(Map<String, dynamic> json) =>
    SetProviderResponse(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$SetProviderResponseToJson(
  SetProviderResponse instance,
) => <String, dynamic>{'_meta': ?instance.meta};

DisableProviderRequest _$DisableProviderRequestFromJson(
  Map<String, dynamic> json,
) => DisableProviderRequest(
  meta: json['_meta'] as Map<String, dynamic>?,
  providerId: json['providerId'] as String,
);

Map<String, dynamic> _$DisableProviderRequestToJson(
  DisableProviderRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'providerId': instance.providerId,
};

DisableProviderResponse _$DisableProviderResponseFromJson(
  Map<String, dynamic> json,
) => DisableProviderResponse(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$DisableProviderResponseToJson(
  DisableProviderResponse instance,
) => <String, dynamic>{'_meta': ?instance.meta};

Position _$PositionFromJson(Map<String, dynamic> json) => Position(
  meta: json['_meta'] as Map<String, dynamic>?,
  line: (json['line'] as num).toInt(),
  character: (json['character'] as num).toInt(),
);

Map<String, dynamic> _$PositionToJson(Position instance) => <String, dynamic>{
  '_meta': ?instance.meta,
  'line': instance.line,
  'character': instance.character,
};

Range _$RangeFromJson(Map<String, dynamic> json) => Range(
  meta: json['_meta'] as Map<String, dynamic>?,
  start: Position.fromJson(json['start'] as Map<String, dynamic>),
  end: Position.fromJson(json['end'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RangeToJson(Range instance) => <String, dynamic>{
  '_meta': ?instance.meta,
  'start': instance.start,
  'end': instance.end,
};

TextDocumentContentChangeEvent _$TextDocumentContentChangeEventFromJson(
  Map<String, dynamic> json,
) => TextDocumentContentChangeEvent(
  meta: json['_meta'] as Map<String, dynamic>?,
  range: json['range'] == null
      ? null
      : Range.fromJson(json['range'] as Map<String, dynamic>),
  text: json['text'] as String,
);

Map<String, dynamic> _$TextDocumentContentChangeEventToJson(
  TextDocumentContentChangeEvent instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'range': instance.range,
  'text': instance.text,
};

DidOpenDocumentNotification _$DidOpenDocumentNotificationFromJson(
  Map<String, dynamic> json,
) => DidOpenDocumentNotification(
  meta: json['_meta'] as Map<String, dynamic>?,
  sessionId: json['sessionId'] as String,
  uri: json['uri'] as String,
  languageId: json['languageId'] as String,
  version: (json['version'] as num).toInt(),
  text: json['text'] as String,
);

Map<String, dynamic> _$DidOpenDocumentNotificationToJson(
  DidOpenDocumentNotification instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
  'uri': instance.uri,
  'languageId': instance.languageId,
  'version': instance.version,
  'text': instance.text,
};

DidChangeDocumentNotification _$DidChangeDocumentNotificationFromJson(
  Map<String, dynamic> json,
) => DidChangeDocumentNotification(
  meta: json['_meta'] as Map<String, dynamic>?,
  sessionId: json['sessionId'] as String,
  uri: json['uri'] as String,
  version: (json['version'] as num).toInt(),
  contentChanges: (json['contentChanges'] as List<dynamic>)
      .map(
        (e) =>
            TextDocumentContentChangeEvent.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$DidChangeDocumentNotificationToJson(
  DidChangeDocumentNotification instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
  'uri': instance.uri,
  'version': instance.version,
  'contentChanges': instance.contentChanges,
};

DidCloseDocumentNotification _$DidCloseDocumentNotificationFromJson(
  Map<String, dynamic> json,
) => DidCloseDocumentNotification(
  meta: json['_meta'] as Map<String, dynamic>?,
  sessionId: json['sessionId'] as String,
  uri: json['uri'] as String,
);

Map<String, dynamic> _$DidCloseDocumentNotificationToJson(
  DidCloseDocumentNotification instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
  'uri': instance.uri,
};

DidSaveDocumentNotification _$DidSaveDocumentNotificationFromJson(
  Map<String, dynamic> json,
) => DidSaveDocumentNotification(
  meta: json['_meta'] as Map<String, dynamic>?,
  sessionId: json['sessionId'] as String,
  uri: json['uri'] as String,
);

Map<String, dynamic> _$DidSaveDocumentNotificationToJson(
  DidSaveDocumentNotification instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
  'uri': instance.uri,
};

DidFocusDocumentNotification _$DidFocusDocumentNotificationFromJson(
  Map<String, dynamic> json,
) => DidFocusDocumentNotification(
  meta: json['_meta'] as Map<String, dynamic>?,
  sessionId: json['sessionId'] as String,
  uri: json['uri'] as String,
  version: (json['version'] as num).toInt(),
  position: Position.fromJson(json['position'] as Map<String, dynamic>),
  visibleRange: Range.fromJson(json['visibleRange'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DidFocusDocumentNotificationToJson(
  DidFocusDocumentNotification instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'sessionId': instance.sessionId,
  'uri': instance.uri,
  'version': instance.version,
  'position': instance.position,
  'visibleRange': instance.visibleRange,
};

AcpMcpServer _$AcpMcpServerFromJson(Map<String, dynamic> json) => AcpMcpServer(
  meta: json['_meta'] as Map<String, dynamic>?,
  name: json['name'] as String,
  serverId: json['serverId'] as String,
);

Map<String, dynamic> _$AcpMcpServerToJson(AcpMcpServer instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'name': instance.name,
      'serverId': instance.serverId,
    };

ConnectMcpRequest _$ConnectMcpRequestFromJson(Map<String, dynamic> json) =>
    ConnectMcpRequest(
      meta: json['_meta'] as Map<String, dynamic>?,
      serverId: json['serverId'] as String,
    );

Map<String, dynamic> _$ConnectMcpRequestToJson(ConnectMcpRequest instance) =>
    <String, dynamic>{'_meta': ?instance.meta, 'serverId': instance.serverId};

ConnectMcpResponse _$ConnectMcpResponseFromJson(Map<String, dynamic> json) =>
    ConnectMcpResponse(
      meta: json['_meta'] as Map<String, dynamic>?,
      connectionId: json['connectionId'] as String,
    );

Map<String, dynamic> _$ConnectMcpResponseToJson(ConnectMcpResponse instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'connectionId': instance.connectionId,
    };

MessageMcpRequest _$MessageMcpRequestFromJson(Map<String, dynamic> json) =>
    MessageMcpRequest(
      meta: json['_meta'] as Map<String, dynamic>?,
      connectionId: json['connectionId'] as String,
      method: json['method'] as String,
      params: json['params'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$MessageMcpRequestToJson(MessageMcpRequest instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'connectionId': instance.connectionId,
      'method': instance.method,
      'params': ?instance.params,
    };

MessageMcpNotification _$MessageMcpNotificationFromJson(
  Map<String, dynamic> json,
) => MessageMcpNotification(
  meta: json['_meta'] as Map<String, dynamic>?,
  connectionId: json['connectionId'] as String,
  method: json['method'] as String,
  params: json['params'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$MessageMcpNotificationToJson(
  MessageMcpNotification instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'connectionId': instance.connectionId,
  'method': instance.method,
  'params': ?instance.params,
};

DisconnectMcpRequest _$DisconnectMcpRequestFromJson(
  Map<String, dynamic> json,
) => DisconnectMcpRequest(
  meta: json['_meta'] as Map<String, dynamic>?,
  connectionId: json['connectionId'] as String,
);

Map<String, dynamic> _$DisconnectMcpRequestToJson(
  DisconnectMcpRequest instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'connectionId': instance.connectionId,
};

DisconnectMcpResponse _$DisconnectMcpResponseFromJson(
  Map<String, dynamic> json,
) => DisconnectMcpResponse(meta: json['_meta'] as Map<String, dynamic>?);

Map<String, dynamic> _$DisconnectMcpResponseToJson(
  DisconnectMcpResponse instance,
) => <String, dynamic>{'_meta': ?instance.meta};
