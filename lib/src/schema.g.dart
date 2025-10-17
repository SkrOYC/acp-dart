// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InitializeRequest _$InitializeRequestFromJson(Map<String, dynamic> json) =>
    InitializeRequest(
      protocolVersion: json['protocolVersion'] as num,
      capabilities: ClientCapabilities.fromJson(
        json['clientCapabilities'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$InitializeRequestToJson(InitializeRequest instance) =>
    <String, dynamic>{
      'protocolVersion': instance.protocolVersion,
      'clientCapabilities': instance.capabilities,
    };

ClientCapabilities _$ClientCapabilitiesFromJson(Map<String, dynamic> json) =>
    ClientCapabilities(
      fs: json['fs'] == null
          ? null
          : FileSystemCapability.fromJson(json['fs'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ClientCapabilitiesToJson(ClientCapabilities instance) =>
    <String, dynamic>{'fs': instance.fs};

FileSystemCapability _$FileSystemCapabilityFromJson(
  Map<String, dynamic> json,
) => FileSystemCapability(
  readTextFile: json['readTextFile'] as bool,
  writeTextFile: json['writeTextFile'] as bool,
);

Map<String, dynamic> _$FileSystemCapabilityToJson(
  FileSystemCapability instance,
) => <String, dynamic>{
  'readTextFile': instance.readTextFile,
  'writeTextFile': instance.writeTextFile,
};

AuthenticateRequest _$AuthenticateRequestFromJson(Map<String, dynamic> json) =>
    AuthenticateRequest(
      method: json['method'] as String,
      token: json['token'] as String?,
    );

Map<String, dynamic> _$AuthenticateRequestToJson(
  AuthenticateRequest instance,
) => <String, dynamic>{'method': instance.method, 'token': instance.token};

NewSessionRequest _$NewSessionRequestFromJson(Map<String, dynamic> json) =>
    NewSessionRequest(
      mcp: json['mcp'] == null
          ? null
          : McpServer.fromJson(json['mcp'] as Map<String, dynamic>),
      stdio: json['stdio'] == null
          ? null
          : Stdio.fromJson(json['stdio'] as Map<String, dynamic>),
      cwd: json['cwd'] as String?,
      mcpServers: json['mcpServers'] as List<dynamic>?,
    );

Map<String, dynamic> _$NewSessionRequestToJson(NewSessionRequest instance) =>
    <String, dynamic>{
      'mcp': instance.mcp,
      'stdio': instance.stdio,
      'cwd': instance.cwd,
      'mcpServers': instance.mcpServers,
    };

McpServer _$McpServerFromJson(Map<String, dynamic> json) => McpServer(
  host: json['host'] as String,
  port: (json['port'] as num).toInt(),
  tls: json['tls'] as bool,
  headers: (json['headers'] as List<dynamic>?)
      ?.map((e) => HttpHeader.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$McpServerToJson(McpServer instance) => <String, dynamic>{
  'host': instance.host,
  'port': instance.port,
  'tls': instance.tls,
  'headers': instance.headers,
};

HttpHeader _$HttpHeaderFromJson(Map<String, dynamic> json) =>
    HttpHeader(name: json['name'] as String, value: json['value'] as String);

Map<String, dynamic> _$HttpHeaderToJson(HttpHeader instance) =>
    <String, dynamic>{'name': instance.name, 'value': instance.value};

Stdio _$StdioFromJson(Map<String, dynamic> json) => Stdio(
  command: (json['command'] as List<dynamic>).map((e) => e as String).toList(),
  env: (json['env'] as List<dynamic>?)
      ?.map((e) => EnvVariable.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$StdioToJson(Stdio instance) => <String, dynamic>{
  'command': instance.command,
  'env': instance.env,
};

EnvVariable _$EnvVariableFromJson(Map<String, dynamic> json) =>
    EnvVariable(name: json['name'] as String, value: json['value'] as String);

Map<String, dynamic> _$EnvVariableToJson(EnvVariable instance) =>
    <String, dynamic>{'name': instance.name, 'value': instance.value};

LoadSessionRequest _$LoadSessionRequestFromJson(Map<String, dynamic> json) =>
    LoadSessionRequest(sessionId: json['sessionId'] as String);

Map<String, dynamic> _$LoadSessionRequestToJson(LoadSessionRequest instance) =>
    <String, dynamic>{'sessionId': instance.sessionId};

SetSessionModeRequest _$SetSessionModeRequestFromJson(
  Map<String, dynamic> json,
) => SetSessionModeRequest(mode: json['mode'] as String);

Map<String, dynamic> _$SetSessionModeRequestToJson(
  SetSessionModeRequest instance,
) => <String, dynamic>{'mode': instance.mode};

PromptRequest _$PromptRequestFromJson(Map<String, dynamic> json) =>
    PromptRequest(
      sessionId: json['sessionId'] as String,
      prompt: (json['prompt'] as List<dynamic>?)
          ?.map(
            (e) => const ContentBlockConverter().fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      tools: (json['tools'] as List<dynamic>?)
          ?.map((e) => ToolCall.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PromptRequestToJson(
  PromptRequest instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'prompt': instance.prompt?.map(const ContentBlockConverter().toJson).toList(),
  'tools': instance.tools,
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
    );

Map<String, dynamic> _$AudioContentBlockToJson(AudioContentBlock instance) =>
    <String, dynamic>{
      '_meta': ?instance.meta,
      'annotations': instance.annotations,
      'data': instance.data,
      'mimeType': instance.mimeType,
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
  resource: const EmbeddedResourceResourceConverter().fromJson(
    json['resource'] as Map<String, dynamic>,
  ),
  type: json['type'] as String? ?? 'resource',
);

Map<String, dynamic> _$ResourceContentBlockToJson(
  ResourceContentBlock instance,
) => <String, dynamic>{
  '_meta': ?instance.meta,
  'annotations': instance.annotations,
  'resource': const EmbeddedResourceResourceConverter().toJson(
    instance.resource,
  ),
  'type': instance.type,
};

ToolCall _$ToolCallFromJson(Map<String, dynamic> json) => ToolCall();

Map<String, dynamic> _$ToolCallToJson(ToolCall instance) => <String, dynamic>{};

SetSessionModelRequest _$SetSessionModelRequestFromJson(
  Map<String, dynamic> json,
) => SetSessionModelRequest(model: json['model'] as String);

Map<String, dynamic> _$SetSessionModelRequestToJson(
  SetSessionModelRequest instance,
) => <String, dynamic>{'model': instance.model};

WriteTextFileRequest _$WriteTextFileRequestFromJson(
  Map<String, dynamic> json,
) => WriteTextFileRequest(
  path: json['path'] as String,
  content: json['content'] as String,
);

Map<String, dynamic> _$WriteTextFileRequestToJson(
  WriteTextFileRequest instance,
) => <String, dynamic>{'path': instance.path, 'content': instance.content};

ReadTextFileRequest _$ReadTextFileRequestFromJson(Map<String, dynamic> json) =>
    ReadTextFileRequest(path: json['path'] as String);

Map<String, dynamic> _$ReadTextFileRequestToJson(
  ReadTextFileRequest instance,
) => <String, dynamic>{'path': instance.path};

RequestPermissionRequest _$RequestPermissionRequestFromJson(
  Map<String, dynamic> json,
) => RequestPermissionRequest(
  question: json['question'] as String,
  options: (json['options'] as List<dynamic>)
      .map((e) => PermissionOption.fromJson(e as Map<String, dynamic>))
      .toList(),
  toolCall: ToolCallUpdate.fromJson(json['toolCall'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RequestPermissionRequestToJson(
  RequestPermissionRequest instance,
) => <String, dynamic>{
  'question': instance.question,
  'options': instance.options,
  'toolCall': instance.toolCall,
};

PermissionOption _$PermissionOptionFromJson(Map<String, dynamic> json) =>
    PermissionOption(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$PermissionOptionToJson(PermissionOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
    };

ToolCallUpdate _$ToolCallUpdateFromJson(Map<String, dynamic> json) =>
    ToolCallUpdate(
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

CreateTerminalRequest _$CreateTerminalRequestFromJson(
  Map<String, dynamic> json,
) => CreateTerminalRequest(
  command: json['command'] as String,
  args: (json['args'] as List<dynamic>?)?.map((e) => e as String).toList(),
  cwd: json['cwd'] as String?,
  env: (json['env'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
);

Map<String, dynamic> _$CreateTerminalRequestToJson(
  CreateTerminalRequest instance,
) => <String, dynamic>{
  'command': instance.command,
  'args': instance.args,
  'cwd': instance.cwd,
  'env': instance.env,
};

TerminalOutputRequest _$TerminalOutputRequestFromJson(
  Map<String, dynamic> json,
) => TerminalOutputRequest(terminalId: json['terminalId'] as String);

Map<String, dynamic> _$TerminalOutputRequestToJson(
  TerminalOutputRequest instance,
) => <String, dynamic>{'terminalId': instance.terminalId};

ReleaseTerminalRequest _$ReleaseTerminalRequestFromJson(
  Map<String, dynamic> json,
) => ReleaseTerminalRequest(terminalId: json['terminalId'] as String);

Map<String, dynamic> _$ReleaseTerminalRequestToJson(
  ReleaseTerminalRequest instance,
) => <String, dynamic>{'terminalId': instance.terminalId};

WaitForTerminalExitRequest _$WaitForTerminalExitRequestFromJson(
  Map<String, dynamic> json,
) => WaitForTerminalExitRequest(terminalId: json['terminalId'] as String);

Map<String, dynamic> _$WaitForTerminalExitRequestToJson(
  WaitForTerminalExitRequest instance,
) => <String, dynamic>{'terminalId': instance.terminalId};

KillTerminalCommandRequest _$KillTerminalCommandRequestFromJson(
  Map<String, dynamic> json,
) => KillTerminalCommandRequest(terminalId: json['terminalId'] as String);

Map<String, dynamic> _$KillTerminalCommandRequestToJson(
  KillTerminalCommandRequest instance,
) => <String, dynamic>{'terminalId': instance.terminalId};

InitializeResponse _$InitializeResponseFromJson(Map<String, dynamic> json) =>
    InitializeResponse(
      protocolVersion: json['protocolVersion'] as num,
      capabilities: json['capabilities'] == null
          ? null
          : AgentCapabilities.fromJson(
              json['capabilities'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$InitializeResponseToJson(InitializeResponse instance) =>
    <String, dynamic>{
      'protocolVersion': instance.protocolVersion,
      'capabilities': instance.capabilities,
    };

AgentCapabilities _$AgentCapabilitiesFromJson(Map<String, dynamic> json) =>
    AgentCapabilities(
      mcp: json['mcp'] == null
          ? null
          : McpCapabilities.fromJson(json['mcp'] as Map<String, dynamic>),
      prompt: json['prompt'] == null
          ? null
          : PromptCapabilities.fromJson(json['prompt'] as Map<String, dynamic>),
      loadSession: json['loadSession'] as bool,
      auth: (json['auth'] as List<dynamic>)
          .map((e) => AuthMethod.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AgentCapabilitiesToJson(AgentCapabilities instance) =>
    <String, dynamic>{
      'mcp': instance.mcp,
      'prompt': instance.prompt,
      'loadSession': instance.loadSession,
      'auth': instance.auth,
    };

McpCapabilities _$McpCapabilitiesFromJson(Map<String, dynamic> json) =>
    McpCapabilities(
      versions: (json['versions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$McpCapabilitiesToJson(McpCapabilities instance) =>
    <String, dynamic>{'versions': instance.versions};

PromptCapabilities _$PromptCapabilitiesFromJson(Map<String, dynamic> json) =>
    PromptCapabilities(
      sessionModes: (json['sessionModes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$PromptCapabilitiesToJson(PromptCapabilities instance) =>
    <String, dynamic>{'sessionModes': instance.sessionModes};

AuthMethod _$AuthMethodFromJson(Map<String, dynamic> json) => AuthMethod(
  method: json['method'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$AuthMethodToJson(AuthMethod instance) =>
    <String, dynamic>{
      'method': instance.method,
      'description': instance.description,
    };

AuthenticateResponse _$AuthenticateResponseFromJson(
  Map<String, dynamic> json,
) => AuthenticateResponse();

Map<String, dynamic> _$AuthenticateResponseToJson(
  AuthenticateResponse instance,
) => <String, dynamic>{};

NewSessionResponse _$NewSessionResponseFromJson(Map<String, dynamic> json) =>
    NewSessionResponse(
      sessionId: json['sessionId'] as String,
      modes: json['modes'] == null
          ? null
          : SessionModeState.fromJson(json['modes'] as Map<String, dynamic>),
      models: json['models'] == null
          ? null
          : SessionModelState.fromJson(json['models'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$NewSessionResponseToJson(NewSessionResponse instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'modes': instance.modes,
      'models': instance.models,
    };

SessionModeState _$SessionModeStateFromJson(Map<String, dynamic> json) =>
    SessionModeState(
      available: (json['available'] as List<dynamic>)
          .map((e) => SessionMode.fromJson(e as Map<String, dynamic>))
          .toList(),
      current: json['current'] as String,
    );

Map<String, dynamic> _$SessionModeStateToJson(SessionModeState instance) =>
    <String, dynamic>{
      'available': instance.available,
      'current': instance.current,
    };

SessionMode _$SessionModeFromJson(Map<String, dynamic> json) => SessionMode(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$SessionModeToJson(SessionMode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
    };

SessionModelState _$SessionModelStateFromJson(Map<String, dynamic> json) =>
    SessionModelState(
      available: (json['available'] as List<dynamic>)
          .map((e) => ModelInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      current: json['current'] as String,
    );

Map<String, dynamic> _$SessionModelStateToJson(SessionModelState instance) =>
    <String, dynamic>{
      'available': instance.available,
      'current': instance.current,
    };

ModelInfo _$ModelInfoFromJson(Map<String, dynamic> json) => ModelInfo(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$ModelInfoToJson(ModelInfo instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
};

LoadSessionResponse _$LoadSessionResponseFromJson(Map<String, dynamic> json) =>
    LoadSessionResponse(
      sessionId: json['sessionId'] as String,
      modes: SessionModeState.fromJson(json['modes'] as Map<String, dynamic>),
      models: json['models'] == null
          ? null
          : SessionModelState.fromJson(json['models'] as Map<String, dynamic>),
      history: (json['history'] as List<dynamic>)
          .map(
            (e) => const ContentBlockConverter().fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );

Map<String, dynamic> _$LoadSessionResponseToJson(
  LoadSessionResponse instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'modes': instance.modes,
  'models': instance.models,
  'history': instance.history
      .map(const ContentBlockConverter().toJson)
      .toList(),
};

SetSessionModeResponse _$SetSessionModeResponseFromJson(
  Map<String, dynamic> json,
) => SetSessionModeResponse();

Map<String, dynamic> _$SetSessionModeResponseToJson(
  SetSessionModeResponse instance,
) => <String, dynamic>{};

PromptResponse _$PromptResponseFromJson(Map<String, dynamic> json) =>
    PromptResponse(done: json['done'] as bool?);

Map<String, dynamic> _$PromptResponseToJson(PromptResponse instance) =>
    <String, dynamic>{'done': instance.done};

SetSessionModelResponse _$SetSessionModelResponseFromJson(
  Map<String, dynamic> json,
) => SetSessionModelResponse();

Map<String, dynamic> _$SetSessionModelResponseToJson(
  SetSessionModelResponse instance,
) => <String, dynamic>{};

WriteTextFileResponse _$WriteTextFileResponseFromJson(
  Map<String, dynamic> json,
) => WriteTextFileResponse();

Map<String, dynamic> _$WriteTextFileResponseToJson(
  WriteTextFileResponse instance,
) => <String, dynamic>{};

ReadTextFileResponse _$ReadTextFileResponseFromJson(
  Map<String, dynamic> json,
) => ReadTextFileResponse(content: json['content'] as String);

Map<String, dynamic> _$ReadTextFileResponseToJson(
  ReadTextFileResponse instance,
) => <String, dynamic>{'content': instance.content};

RequestPermissionResponse _$RequestPermissionResponseFromJson(
  Map<String, dynamic> json,
) => RequestPermissionResponse(optionId: json['optionId'] as String);

Map<String, dynamic> _$RequestPermissionResponseToJson(
  RequestPermissionResponse instance,
) => <String, dynamic>{'optionId': instance.optionId};

CreateTerminalResponse _$CreateTerminalResponseFromJson(
  Map<String, dynamic> json,
) => CreateTerminalResponse(terminalId: json['terminalId'] as String);

Map<String, dynamic> _$CreateTerminalResponseToJson(
  CreateTerminalResponse instance,
) => <String, dynamic>{'terminalId': instance.terminalId};

TerminalOutputResponse _$TerminalOutputResponseFromJson(
  Map<String, dynamic> json,
) => TerminalOutputResponse(
  stdout: json['stdout'] as String?,
  stderr: json['stderr'] as String?,
  exitStatus: json['exitStatus'] == null
      ? null
      : TerminalExitStatus.fromJson(json['exitStatus'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TerminalOutputResponseToJson(
  TerminalOutputResponse instance,
) => <String, dynamic>{
  'stdout': instance.stdout,
  'stderr': instance.stderr,
  'exitStatus': instance.exitStatus,
};

TerminalExitStatus _$TerminalExitStatusFromJson(Map<String, dynamic> json) =>
    TerminalExitStatus(code: (json['code'] as num).toInt());

Map<String, dynamic> _$TerminalExitStatusToJson(TerminalExitStatus instance) =>
    <String, dynamic>{'code': instance.code};

ReleaseTerminalResponse _$ReleaseTerminalResponseFromJson(
  Map<String, dynamic> json,
) => ReleaseTerminalResponse();

Map<String, dynamic> _$ReleaseTerminalResponseToJson(
  ReleaseTerminalResponse instance,
) => <String, dynamic>{};

WaitForTerminalExitResponse _$WaitForTerminalExitResponseFromJson(
  Map<String, dynamic> json,
) => WaitForTerminalExitResponse(exitCode: (json['exitCode'] as num).toInt());

Map<String, dynamic> _$WaitForTerminalExitResponseToJson(
  WaitForTerminalExitResponse instance,
) => <String, dynamic>{'exitCode': instance.exitCode};

KillTerminalResponse _$KillTerminalResponseFromJson(
  Map<String, dynamic> json,
) => KillTerminalResponse();

Map<String, dynamic> _$KillTerminalResponseToJson(
  KillTerminalResponse instance,
) => <String, dynamic>{};

CancelNotification _$CancelNotificationFromJson(Map<String, dynamic> json) =>
    CancelNotification(sessionId: json['sessionId'] as String);

Map<String, dynamic> _$CancelNotificationToJson(CancelNotification instance) =>
    <String, dynamic>{'sessionId': instance.sessionId};

Annotations _$AnnotationsFromJson(Map<String, dynamic> json) => Annotations(
  audience: (json['audience'] as List<dynamic>?)
      ?.map((e) => $enumDecode(_$RoleEnumMap, e))
      .toList(),
  lastModified: json['lastModified'] as String?,
  priority: (json['priority'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AnnotationsToJson(Annotations instance) =>
    <String, dynamic>{
      'audience': instance.audience?.map((e) => _$RoleEnumMap[e]!).toList(),
      'lastModified': instance.lastModified,
      'priority': instance.priority,
    };

const _$RoleEnumMap = {Role.assistant: 'assistant', Role.user: 'user'};

TextResourceContents _$TextResourceContentsFromJson(
  Map<String, dynamic> json,
) => TextResourceContents(
  mimeType: json['mimeType'] as String?,
  text: json['text'] as String,
  uri: json['uri'] as String,
);

Map<String, dynamic> _$TextResourceContentsToJson(
  TextResourceContents instance,
) => <String, dynamic>{
  'mimeType': instance.mimeType,
  'text': instance.text,
  'uri': instance.uri,
};

BlobResourceContents _$BlobResourceContentsFromJson(
  Map<String, dynamic> json,
) => BlobResourceContents(
  blob: json['blob'] as String,
  mimeType: json['mimeType'] as String?,
  uri: json['uri'] as String,
);

Map<String, dynamic> _$BlobResourceContentsToJson(
  BlobResourceContents instance,
) => <String, dynamic>{
  'blob': instance.blob,
  'mimeType': instance.mimeType,
  'uri': instance.uri,
};

ContentToolCallContent _$ContentToolCallContentFromJson(
  Map<String, dynamic> json,
) => ContentToolCallContent(
  content: const ContentBlockConverter().fromJson(
    json['content'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ContentToolCallContentToJson(
  ContentToolCallContent instance,
) => <String, dynamic>{
  'content': const ContentBlockConverter().toJson(instance.content),
};

DiffToolCallContent _$DiffToolCallContentFromJson(Map<String, dynamic> json) =>
    DiffToolCallContent(
      newText: json['newText'] as String,
      oldText: json['oldText'] as String?,
      path: json['path'] as String,
    );

Map<String, dynamic> _$DiffToolCallContentToJson(
  DiffToolCallContent instance,
) => <String, dynamic>{
  'newText': instance.newText,
  'oldText': instance.oldText,
  'path': instance.path,
};

TerminalToolCallContent _$TerminalToolCallContentFromJson(
  Map<String, dynamic> json,
) => TerminalToolCallContent(terminalId: json['terminalId'] as String);

Map<String, dynamic> _$TerminalToolCallContentToJson(
  TerminalToolCallContent instance,
) => <String, dynamic>{'terminalId': instance.terminalId};

ToolCallLocation _$ToolCallLocationFromJson(Map<String, dynamic> json) =>
    ToolCallLocation(
      line: (json['line'] as num?)?.toInt(),
      path: json['path'] as String,
    );

Map<String, dynamic> _$ToolCallLocationToJson(ToolCallLocation instance) =>
    <String, dynamic>{'line': instance.line, 'path': instance.path};

PlanEntry _$PlanEntryFromJson(Map<String, dynamic> json) => PlanEntry(
  content: json['content'] as String,
  priority: json['priority'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$PlanEntryToJson(PlanEntry instance) => <String, dynamic>{
  'content': instance.content,
  'priority': instance.priority,
  'status': instance.status,
};

UnstructuredCommandInput _$UnstructuredCommandInputFromJson(
  Map<String, dynamic> json,
) => UnstructuredCommandInput(hint: json['hint'] as String);

Map<String, dynamic> _$UnstructuredCommandInputToJson(
  UnstructuredCommandInput instance,
) => <String, dynamic>{'hint': instance.hint};

AvailableCommand _$AvailableCommandFromJson(Map<String, dynamic> json) =>
    AvailableCommand(
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
      'description': instance.description,
      'input': instance.input,
      'name': instance.name,
    };

SessionNotification _$SessionNotificationFromJson(Map<String, dynamic> json) =>
    SessionNotification(
      sessionId: json['sessionId'] as String,
      update: const SessionUpdateConverter().fromJson(
        json['update'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$SessionNotificationToJson(
  SessionNotification instance,
) => <String, dynamic>{
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
  content: _$JsonConverterFromJson<Map<String, dynamic>, ContentBlock>(
    json['content'],
    const ContentBlockConverter().fromJson,
  ),
);

Map<String, dynamic> _$AgentThoughtChunkSessionUpdateToJson(
  AgentThoughtChunkSessionUpdate instance,
) => <String, dynamic>{
  'content': _$JsonConverterToJson<Map<String, dynamic>, ContentBlock>(
    instance.content,
    const ContentBlockConverter().toJson,
  ),
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

ToolCallSessionUpdate _$ToolCallSessionUpdateFromJson(
  Map<String, dynamic> json,
) => ToolCallSessionUpdate(
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
      entries: (json['entries'] as List<dynamic>)
          .map((e) => PlanEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlanSessionUpdateToJson(PlanSessionUpdate instance) =>
    <String, dynamic>{'entries': instance.entries};

AvailableCommandsUpdateSessionUpdate
_$AvailableCommandsUpdateSessionUpdateFromJson(Map<String, dynamic> json) =>
    AvailableCommandsUpdateSessionUpdate(
      availableCommands: (json['availableCommands'] as List<dynamic>)
          .map((e) => AvailableCommand.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AvailableCommandsUpdateSessionUpdateToJson(
  AvailableCommandsUpdateSessionUpdate instance,
) => <String, dynamic>{'availableCommands': instance.availableCommands};

CurrentModeUpdateSessionUpdate _$CurrentModeUpdateSessionUpdateFromJson(
  Map<String, dynamic> json,
) => CurrentModeUpdateSessionUpdate(
  currentModeId: json['currentModeId'] as String,
);

Map<String, dynamic> _$CurrentModeUpdateSessionUpdateToJson(
  CurrentModeUpdateSessionUpdate instance,
) => <String, dynamic>{'currentModeId': instance.currentModeId};

SessionStopSessionUpdate _$SessionStopSessionUpdateFromJson(
  Map<String, dynamic> json,
) => SessionStopSessionUpdate(reason: json['reason'] as String);

Map<String, dynamic> _$SessionStopSessionUpdateToJson(
  SessionStopSessionUpdate instance,
) => <String, dynamic>{'reason': instance.reason};

UnknownSessionUpdate _$UnknownSessionUpdateFromJson(
  Map<String, dynamic> json,
) => UnknownSessionUpdate(rawJson: json['rawJson'] as Map<String, dynamic>);

Map<String, dynamic> _$UnknownSessionUpdateToJson(
  UnknownSessionUpdate instance,
) => <String, dynamic>{'rawJson': instance.rawJson};
