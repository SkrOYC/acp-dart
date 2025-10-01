import 'package:json_annotation/json_annotation.dart';

part 'schema.g.dart';

/// The role of a message sender.
enum Role {
  assistant,
  user,
}

/// The kind of a tool.
enum ToolKind {
  read,
  edit,
  delete,
  move,
  search,
  execute,
  think,
  fetch,
  switch_mode,
  other,
}

/// The status of a tool call.
enum ToolCallStatus {
  pending,
  in_progress,
  completed,
  failed,
}

@JsonSerializable()
class InitializeRequest {
  final ClientCapabilities capabilities;

  InitializeRequest({required this.capabilities});

  factory InitializeRequest.fromJson(Map<String, dynamic> json) =>
      _$InitializeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$InitializeRequestToJson(this);
}

@JsonSerializable()
class ClientCapabilities {
  final FileSystemCapability? fs;

  ClientCapabilities({this.fs});

  factory ClientCapabilities.fromJson(Map<String, dynamic> json) =>
      _$ClientCapabilitiesFromJson(json);

  Map<String, dynamic> toJson() => _$ClientCapabilitiesToJson(this);
}

@JsonSerializable()
class FileSystemCapability {
  final bool readTextFile;
  final bool writeTextFile;

  FileSystemCapability({required this.readTextFile, required this.writeTextFile});

  factory FileSystemCapability.fromJson(Map<String, dynamic> json) =>
      _$FileSystemCapabilityFromJson(json);

  Map<String, dynamic> toJson() => _$FileSystemCapabilityToJson(this);
}

@JsonSerializable()
class AuthenticateRequest {
  final String method;
  final String? token;

  AuthenticateRequest({required this.method, this.token});

  factory AuthenticateRequest.fromJson(Map<String, dynamic> json) =>
      _$AuthenticateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AuthenticateRequestToJson(this);
}

@JsonSerializable()
class NewSessionRequest {
  final McpServer? mcp;
  final Stdio? stdio;

  NewSessionRequest({this.mcp, this.stdio});

  factory NewSessionRequest.fromJson(Map<String, dynamic> json) =>
      _$NewSessionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$NewSessionRequestToJson(this);
}

@JsonSerializable()
class McpServer {
  final String host;
  final int port;
  final bool tls;
  final List<HttpHeader>? headers;

  McpServer({required this.host, required this.port, required this.tls, this.headers});

  factory McpServer.fromJson(Map<String, dynamic> json) =>
      _$McpServerFromJson(json);

  Map<String, dynamic> toJson() => _$McpServerToJson(this);
}

@JsonSerializable()
class HttpHeader {
  final String name;
  final String value;

  HttpHeader({required this.name, required this.value});

  factory HttpHeader.fromJson(Map<String, dynamic> json) =>
      _$HttpHeaderFromJson(json);

  Map<String, dynamic> toJson() => _$HttpHeaderToJson(this);
}

@JsonSerializable()
class Stdio {
  final List<String> command;
  final List<EnvVariable>? env;

  Stdio({required this.command, this.env});

  factory Stdio.fromJson(Map<String, dynamic> json) =>
      _$StdioFromJson(json);

  Map<String, dynamic> toJson() => _$StdioToJson(this);
}

@JsonSerializable()
class EnvVariable {
  final String name;
  final String value;

  EnvVariable({required this.name, required this.value});

  factory EnvVariable.fromJson(Map<String, dynamic> json) =>
      _$EnvVariableFromJson(json);

  Map<String, dynamic> toJson() => _$EnvVariableToJson(this);
}

@JsonSerializable()
class LoadSessionRequest {
  final String sessionId;

  LoadSessionRequest({required this.sessionId});

  factory LoadSessionRequest.fromJson(Map<String, dynamic> json) =>
      _$LoadSessionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoadSessionRequestToJson(this);
}

@JsonSerializable()
class SetSessionModeRequest {
  final String mode;

  SetSessionModeRequest({required this.mode});

  factory SetSessionModeRequest.fromJson(Map<String, dynamic> json) =>
      _$SetSessionModeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetSessionModeRequestToJson(this);
}

@JsonSerializable()
class PromptRequest {
  final String? text;
  final List<ContentBlock>? content;
  final List<ToolCall>? tools;

  PromptRequest({this.text, this.content, this.tools});

  factory PromptRequest.fromJson(Map<String, dynamic> json) =>
      _$PromptRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PromptRequestToJson(this);
}

@JsonSerializable()
class ContentBlock {
  // This class is complex and has many different forms.
  // I will need to refer to the TypeScript schema to implement this correctly.
  // For now, I will leave it empty and come back to it later.
  ContentBlock();

  factory ContentBlock.fromJson(Map<String, dynamic> json) =>
      _$ContentBlockFromJson(json);

  Map<String, dynamic> toJson() => _$ContentBlockToJson(this);
}

@JsonSerializable()
class ToolCall {
  // This class is also complex. I will leave it empty for now.
  ToolCall();

  factory ToolCall.fromJson(Map<String, dynamic> json) =>
      _$ToolCallFromJson(json);

  Map<String, dynamic> toJson() => _$ToolCallToJson(this);
}

@JsonSerializable()
class SetSessionModelRequest {
  final String model;

  SetSessionModelRequest({required this.model});

  factory SetSessionModelRequest.fromJson(Map<String, dynamic> json) =>
      _$SetSessionModelRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetSessionModelRequestToJson(this);
}

@JsonSerializable()
class WriteTextFileRequest {
  final String path;
  final String content;

  WriteTextFileRequest({required this.path, required this.content});

  factory WriteTextFileRequest.fromJson(Map<String, dynamic> json) =>
      _$WriteTextFileRequestFromJson(json);

  Map<String, dynamic> toJson() => _$WriteTextFileRequestToJson(this);
}

@JsonSerializable()
class ReadTextFileRequest {
  final String path;

  ReadTextFileRequest({required this.path});

  factory ReadTextFileRequest.fromJson(Map<String, dynamic> json) =>
      _$ReadTextFileRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ReadTextFileRequestToJson(this);
}

@JsonSerializable()
class RequestPermissionRequest {
  final String question;
  final List<PermissionOption> options;
  final ToolCallUpdate toolCall;

  RequestPermissionRequest({required this.question, required this.options, required this.toolCall});

  factory RequestPermissionRequest.fromJson(Map<String, dynamic> json) =>
      _$RequestPermissionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RequestPermissionRequestToJson(this);
}

@JsonSerializable()
class PermissionOption {
  final String id;
  final String title;
  final String? description;

  PermissionOption({required this.id, required this.title, this.description});

  factory PermissionOption.fromJson(Map<String, dynamic> json) =>
      _$PermissionOptionFromJson(json);

  Map<String, dynamic> toJson() => _$PermissionOptionToJson(this);
}

@JsonSerializable()
class ToolCallUpdate {
  // This class is complex and depends on ToolCall.
  // I will leave it empty for now.
  ToolCallUpdate();

  factory ToolCallUpdate.fromJson(Map<String, dynamic> json) =>
      _$ToolCallUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$ToolCallUpdateToJson(this);
}

@JsonSerializable()
class CreateTerminalRequest {
  final String command;
  final List<String>? args;
  final String? cwd;
  final Map<String, String>? env;

  CreateTerminalRequest({required this.command, this.args, this.cwd, this.env});

  factory CreateTerminalRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTerminalRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTerminalRequestToJson(this);
}

@JsonSerializable()
class TerminalOutputRequest {
  final String terminalId;

  TerminalOutputRequest({required this.terminalId});

  factory TerminalOutputRequest.fromJson(Map<String, dynamic> json) =>
      _$TerminalOutputRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TerminalOutputRequestToJson(this);
}

@JsonSerializable()
class ReleaseTerminalRequest {
  final String terminalId;

  ReleaseTerminalRequest({required this.terminalId});

  factory ReleaseTerminalRequest.fromJson(Map<String, dynamic> json) =>
      _$ReleaseTerminalRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ReleaseTerminalRequestToJson(this);
}

@JsonSerializable()
class WaitForTerminalExitRequest {
  final String terminalId;

  WaitForTerminalExitRequest({required this.terminalId});

  factory WaitForTerminalExitRequest.fromJson(Map<String, dynamic> json) =>
      _$WaitForTerminalExitRequestFromJson(json);

  Map<String, dynamic> toJson() => _$WaitForTerminalExitRequestToJson(this);
}

@JsonSerializable()
class KillTerminalCommandRequest {
  final String terminalId;

  KillTerminalCommandRequest({required this.terminalId});

  factory KillTerminalCommandRequest.fromJson(Map<String, dynamic> json) =>
      _$KillTerminalCommandRequestFromJson(json);

  Map<String, dynamic> toJson() => _$KillTerminalCommandRequestToJson(this);
}


@JsonSerializable()
class InitializeResponse {
  final String protocolVersion;
  final AgentCapabilities capabilities;

  InitializeResponse({required this.protocolVersion, required this.capabilities});

  factory InitializeResponse.fromJson(Map<String, dynamic> json) =>
      _$InitializeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$InitializeResponseToJson(this);
}

@JsonSerializable()
class AgentCapabilities {
  final McpCapabilities? mcp;
  final PromptCapabilities? prompt;
  final bool loadSession;
  final List<AuthMethod> auth;

  AgentCapabilities({this.mcp, this.prompt, required this.loadSession, required this.auth});

  factory AgentCapabilities.fromJson(Map<String, dynamic> json) =>
      _$AgentCapabilitiesFromJson(json);

  Map<String, dynamic> toJson() => _$AgentCapabilitiesToJson(this);
}

@JsonSerializable()
class McpCapabilities {
  final List<String> versions;

  McpCapabilities({required this.versions});

  factory McpCapabilities.fromJson(Map<String, dynamic> json) =>
      _$McpCapabilitiesFromJson(json);

  Map<String, dynamic> toJson() => _$McpCapabilitiesToJson(this);
}

@JsonSerializable()
class PromptCapabilities {
  final List<String> sessionModes;

  PromptCapabilities({required this.sessionModes});

  factory PromptCapabilities.fromJson(Map<String, dynamic> json) =>
      _$PromptCapabilitiesFromJson(json);

  Map<String, dynamic> toJson() => _$PromptCapabilitiesToJson(this);
}

@JsonSerializable()
class AuthMethod {
  final String method;
  final String? description;

  AuthMethod({required this.method, this.description});

  factory AuthMethod.fromJson(Map<String, dynamic> json) =>
      _$AuthMethodFromJson(json);

  Map<String, dynamic> toJson() => _$AuthMethodToJson(this);
}

@JsonSerializable()
class AuthenticateResponse {
  AuthenticateResponse();

  factory AuthenticateResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthenticateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthenticateResponseToJson(this);
}

@JsonSerializable()
class NewSessionResponse {
  final String sessionId;
  final SessionModeState modes;
  final SessionModelState? models;

  NewSessionResponse({required this.sessionId, required this.modes, this.models});

  factory NewSessionResponse.fromJson(Map<String, dynamic> json) =>
      _$NewSessionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NewSessionResponseToJson(this);
}

@JsonSerializable()
class SessionModeState {
  final List<SessionMode> available;
  final String current;

  SessionModeState({required this.available, required this.current});

  factory SessionModeState.fromJson(Map<String, dynamic> json) =>
      _$SessionModeStateFromJson(json);

  Map<String, dynamic> toJson() => _$SessionModeStateToJson(this);
}

@JsonSerializable()
class SessionMode {
  final String id;
  final String name;
  final String? description;

  SessionMode({required this.id, required this.name, this.description});

  factory SessionMode.fromJson(Map<String, dynamic> json) =>
      _$SessionModeFromJson(json);

  Map<String, dynamic> toJson() => _$SessionModeToJson(this);
}

@JsonSerializable()
class SessionModelState {
  final List<ModelInfo> available;
  final String current;

  SessionModelState({required this.available, required this.current});

  factory SessionModelState.fromJson(Map<String, dynamic> json) =>
      _$SessionModelStateFromJson(json);

  Map<String, dynamic> toJson() => _$SessionModelStateToJson(this);
}

@JsonSerializable()
class ModelInfo {
  final String id;
  final String name;
  final String? description;

  ModelInfo({required this.id, required this.name, this.description});

  factory ModelInfo.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ModelInfoToJson(this);
}

@JsonSerializable()
class LoadSessionResponse {
  final String sessionId;
  final SessionModeState modes;
  final SessionModelState? models;
  final List<ContentBlock> history;

  LoadSessionResponse({required this.sessionId, required this.modes, this.models, required this.history});

  factory LoadSessionResponse.fromJson(Map<String, dynamic> json) =>
      _$LoadSessionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoadSessionResponseToJson(this);
}

@JsonSerializable()
class SetSessionModeResponse {
  SetSessionModeResponse();

  factory SetSessionModeResponse.fromJson(Map<String, dynamic> json) =>
      _$SetSessionModeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SetSessionModeResponseToJson(this);
}

@JsonSerializable()
class PromptResponse {
  final bool done;

  PromptResponse({required this.done});

  factory PromptResponse.fromJson(Map<String, dynamic> json) =>
      _$PromptResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PromptResponseToJson(this);
}

@JsonSerializable()
class SetSessionModelResponse {
  SetSessionModelResponse();

  factory SetSessionModelResponse.fromJson(Map<String, dynamic> json) =>
      _$SetSessionModelResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SetSessionModelResponseToJson(this);
}

@JsonSerializable()
class WriteTextFileResponse {
  WriteTextFileResponse();

  factory WriteTextFileResponse.fromJson(Map<String, dynamic> json) =>
      _$WriteTextFileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WriteTextFileResponseToJson(this);
}

@JsonSerializable()
class ReadTextFileResponse {
  final String content;

  ReadTextFileResponse({required this.content});

  factory ReadTextFileResponse.fromJson(Map<String, dynamic> json) =>
      _$ReadTextFileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ReadTextFileResponseToJson(this);
}

@JsonSerializable()
class RequestPermissionResponse {
  final String optionId;

  RequestPermissionResponse({required this.optionId});

  factory RequestPermissionResponse.fromJson(Map<String, dynamic> json) =>
      _$RequestPermissionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RequestPermissionResponseToJson(this);
}

@JsonSerializable()
class CreateTerminalResponse {
  final String terminalId;

  CreateTerminalResponse({required this.terminalId});

  factory CreateTerminalResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateTerminalResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTerminalResponseToJson(this);
}

@JsonSerializable()
class TerminalOutputResponse {
  final String? stdout;
  final String? stderr;
  final TerminalExitStatus? exitStatus;

  TerminalOutputResponse({this.stdout, this.stderr, this.exitStatus});

  factory TerminalOutputResponse.fromJson(Map<String, dynamic> json) =>
      _$TerminalOutputResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TerminalOutputResponseToJson(this);
}

@JsonSerializable()
class TerminalExitStatus {
  final int code;

  TerminalExitStatus({required this.code});

  factory TerminalExitStatus.fromJson(Map<String, dynamic> json) =>
      _$TerminalExitStatusFromJson(json);

  Map<String, dynamic> toJson() => _$TerminalExitStatusToJson(this);
}

@JsonSerializable()
class ReleaseTerminalResponse {
  ReleaseTerminalResponse();

  factory ReleaseTerminalResponse.fromJson(Map<String, dynamic> json) =>
      _$ReleaseTerminalResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ReleaseTerminalResponseToJson(this);
}

@JsonSerializable()
class WaitForTerminalExitResponse {
  final int exitCode;

  WaitForTerminalExitResponse({required this.exitCode});

  factory WaitForTerminalExitResponse.fromJson(Map<String, dynamic> json) =>
      _$WaitForTerminalExitResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WaitForTerminalExitResponseToJson(this);
}

@JsonSerializable()
class KillTerminalResponse {
  KillTerminalResponse();

  factory KillTerminalResponse.fromJson(Map<String, dynamic> json) =>
      _$KillTerminalResponseFromJson(json);

  Map<String, dynamic> toJson() => _$KillTerminalResponseToJson(this);
}
