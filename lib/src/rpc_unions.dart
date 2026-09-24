/// Type-safe RPC unions for Agent Client Protocol messages.
///
/// This library provides sealed union types that enable exhaustive handling
/// of ACP requests, responses, and notifications. These unions allow you to
/// work with ACP messages in a type-safe manner while supporting both
/// standard protocol methods and custom extensions.
///
/// ## Key Types
///
/// - [AgentNotificationUnion] - Notifications sent by agents to clients
/// - [AgentRequestUnion] - Requests initiated by agents (handled by clients)
/// - [AgentResponseUnion] - Responses produced by agents
/// - [ClientRequestUnion] - Requests initiated by clients (handled by agents)
/// - [ClientResponseUnion] - Responses produced by clients
/// - [ClientNotificationUnion] - Notifications sent by clients to agents
///
/// ## Benefits
///
/// - **Type Safety**: Each message type is strongly typed with full IDE support
/// - **Exhaustive Handling**: Pattern matching ensures all message types are handled
/// - **Forward Compatibility**: Unknown methods are captured as extension types
/// - **Method Discovery**: Automatic routing from JSON-RPC method names to typed objects
///
/// ## Example
///
/// ```dart
/// // Parse an incoming client request
/// final request = ClientRequestUnion.fromMethod(method, params);
///
/// // Handle different request types exhaustively
/// switch (request) {
///   case ClientInitializeRequest(params: final p):
///     // Handle initialization
///     break;
///   case ClientPromptRequest(params: final p):
///     // Handle prompt
///     break;
///   case ClientExtensionMethodRequest(methodName: final m, rawParams: final p):
///     // Handle custom extension
///     break;
/// }
/// ```

library;

import 'package:collection/collection.dart';

import 'schema.dart';
import 'schema_v15_client.dart';
import 'schema_v15_experimental.dart';

/// Base class for notifications sent by the agent.
///
/// Agent notifications are one-way messages from the agent to the client
/// that don't expect a response. The primary notification type is
/// [SessionNotification] for session updates.
///
/// This union type enables pattern matching on notification types:
/// - [SessionAgentNotification] - Standard session update notifications
/// - [AgentExtensionNotification] - Custom extension notifications
abstract class AgentNotificationUnion {
  const AgentNotificationUnion();

  Map<String, dynamic> toJson();

  /// Deserializes a notification from JSON payload.
  ///
  /// Automatically detects the notification type and returns the
  /// appropriate union variant. Unknown notifications are wrapped
  /// in [AgentExtensionNotification].
  static AgentNotificationUnion fromJson(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return SessionAgentNotification(SessionNotification.fromJson(payload));
    }
    return AgentExtensionNotification(payload);
  }
}

class SessionAgentNotification extends AgentNotificationUnion {
  final SessionNotification notification;

  const SessionAgentNotification(this.notification);

  @override
  Map<String, dynamic> toJson() => notification.toJson();
}

class AgentExtensionNotification extends AgentNotificationUnion {
  final dynamic rawPayload;

  const AgentExtensionNotification(this.rawPayload);

  @override
  Map<String, dynamic> toJson() =>
      rawPayload is Map<String, dynamic> ? rawPayload : {'payload': rawPayload};
}

/// Base class for requests initiated by the agent (handled by the client).
///
/// Agent requests are messages sent from the agent to the client that
/// expect a response. These include file system operations, permission
/// requests, and terminal management.
///
/// Supported request types:
/// - [AgentWriteTextFileRequest] - Write content to a file
/// - [AgentReadTextFileRequest] - Read content from a file
/// - [AgentRequestPermissionRequest] - Request user permission
/// - [AgentCreateTerminalRequest] - Create a new terminal
/// - [AgentTerminalOutputRequest] - Get terminal output
/// - [AgentReleaseTerminalRequest] - Release a terminal
/// - [AgentWaitForTerminalExitRequest] - Wait for terminal exit
/// - [AgentKillTerminalRequest] - Kill a terminal command
/// - [AgentExtensionMethodRequest] - Custom extension requests
///
/// ## Example
///
/// ```dart
/// // Create a request to read a file
/// final request = AgentReadTextFileRequest(
///   ReadTextFileRequest(sessionId: 'session-1', path: '/path/to/file.txt'),
/// );
///
/// // Get the method name for JSON-RPC
/// print(request.method); // 'fs/read_text_file'
/// ```
abstract class AgentRequestUnion {
  const AgentRequestUnion();

  /// The JSON-RPC method name for this request type.
  String get method;

  /// Serializes the request parameters to JSON.
  dynamic toJson();

  /// Creates the appropriate request union from a JSON-RPC method and params.
  ///
  /// This factory automatically routes to the correct request type based on
  /// the method name. Unknown methods are wrapped in [AgentExtensionMethodRequest].
  static AgentRequestUnion fromMethod(String method, dynamic params) {
    switch (method) {
      case 'fs/write_text_file':
        return AgentWriteTextFileRequest(
          WriteTextFileRequest.fromJson(params as Map<String, dynamic>),
        );
      case 'fs/read_text_file':
        return AgentReadTextFileRequest(
          ReadTextFileRequest.fromJson(params as Map<String, dynamic>),
        );
      case 'session/request_permission':
        return AgentRequestPermissionRequest(
          RequestPermissionRequest.fromJson(params as Map<String, dynamic>),
        );
      case 'terminal/create':
        return AgentCreateTerminalRequest(
          CreateTerminalRequest.fromJson(params as Map<String, dynamic>),
        );
      case 'terminal/output':
        return AgentTerminalOutputRequest(
          TerminalOutputRequest.fromJson(params as Map<String, dynamic>),
        );
      case 'terminal/release':
        return AgentReleaseTerminalRequest(
          ReleaseTerminalRequest.fromJson(params as Map<String, dynamic>),
        );
      case 'terminal/wait_for_exit':
        return AgentWaitForTerminalExitRequest(
          WaitForTerminalExitRequest.fromJson(params as Map<String, dynamic>),
        );
      case 'terminal/kill':
        return AgentKillTerminalRequest(
          KillTerminalCommandRequest.fromJson(params as Map<String, dynamic>),
        );
      default:
        return AgentExtensionMethodRequest(method, params);
    }
  }
}

class AgentWriteTextFileRequest extends AgentRequestUnion {
  final WriteTextFileRequest params;
  const AgentWriteTextFileRequest(this.params);
  @override
  String get method => clientMethods['fsWriteTextFile']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class AgentReadTextFileRequest extends AgentRequestUnion {
  final ReadTextFileRequest params;
  const AgentReadTextFileRequest(this.params);
  @override
  String get method => clientMethods['fsReadTextFile']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class AgentRequestPermissionRequest extends AgentRequestUnion {
  final RequestPermissionRequest params;
  const AgentRequestPermissionRequest(this.params);
  @override
  String get method => clientMethods['sessionRequestPermission']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class AgentCreateTerminalRequest extends AgentRequestUnion {
  final CreateTerminalRequest params;
  const AgentCreateTerminalRequest(this.params);
  @override
  String get method => clientMethods['terminalCreate']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class AgentTerminalOutputRequest extends AgentRequestUnion {
  final TerminalOutputRequest params;
  const AgentTerminalOutputRequest(this.params);
  @override
  String get method => clientMethods['terminalOutput']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class AgentReleaseTerminalRequest extends AgentRequestUnion {
  final ReleaseTerminalRequest params;
  const AgentReleaseTerminalRequest(this.params);
  @override
  String get method => clientMethods['terminalRelease']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class AgentWaitForTerminalExitRequest extends AgentRequestUnion {
  final WaitForTerminalExitRequest params;
  const AgentWaitForTerminalExitRequest(this.params);
  @override
  String get method => clientMethods['terminalWaitForExit']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class AgentKillTerminalRequest extends AgentRequestUnion {
  final KillTerminalCommandRequest params;
  const AgentKillTerminalRequest(this.params);
  @override
  String get method => clientMethods['terminalKill']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class AgentExtensionMethodRequest extends AgentRequestUnion {
  final String methodName;
  final dynamic rawParams;
  const AgentExtensionMethodRequest(this.methodName, this.rawParams);
  @override
  String get method => methodName;
  @override
  dynamic toJson() => rawParams;
}

/// Base class for responses produced by the agent.
///
/// Agent responses are replies to client requests, including initialization,
/// session management, authentication, and prompt handling.
///
/// Supported response types:
/// - [AgentInitializeResponse] - Response to initialization
/// - [AgentAuthenticateResponse] - Response to authentication
/// - [AgentNewSessionResponse] - Response to session creation
/// - [AgentLoadSessionResponse] - Response to session loading
/// - [AgentSetSessionModeResponse] - Response to mode setting
/// - [AgentPromptResponse] - Response to prompt processing
/// - [AgentSetSessionModelResponse] - Response to model selection (unstable)
/// - [AgentExtensionMethodResponse] - Response to custom extensions
abstract class AgentResponseUnion {
  const AgentResponseUnion();

  /// Serializes the response to JSON.
  dynamic toJson();

  /// Creates the appropriate response union from a method name and result.
  ///
  /// This factory automatically routes to the correct response type based on
  /// the original request method. Unknown methods are wrapped in [AgentExtensionMethodResponse].
  static AgentResponseUnion fromJson(String method, dynamic result) {
    switch (method) {
      case 'initialize':
        return AgentInitializeResponse(
          InitializeResponse.fromJson(result as Map<String, dynamic>),
        );
      case 'authenticate':
        return AgentAuthenticateResponse(
          result == null
              ? AuthenticateResponse()
              : AuthenticateResponse.fromJson(result as Map<String, dynamic>),
        );
      case 'session/new':
        return AgentNewSessionResponse(
          NewSessionResponse.fromJson(result as Map<String, dynamic>),
        );
      case 'session/load':
        return AgentLoadSessionResponse(
          LoadSessionResponse.fromJson(result as Map<String, dynamic>),
        );
      case 'session/list':
        return AgentListSessionsResponse(
          ListSessionsResponse.fromJson(result as Map<String, dynamic>),
        );
      case 'session/fork':
        return AgentForkSessionResponse(
          ForkSessionResponse.fromJson(result as Map<String, dynamic>),
        );
      case 'session/resume':
        return AgentResumeSessionResponse(
          ResumeSessionResponse.fromJson(result as Map<String, dynamic>),
        );
      case 'session/set_mode':
        return AgentSetSessionModeResponse(
          result == null
              ? SetSessionModeResponse()
              : SetSessionModeResponse.fromJson(result as Map<String, dynamic>),
        );
      case 'session/set_config_option':
        return AgentSetSessionConfigOptionResponse(
          SetSessionConfigOptionResponse.fromJson(
            result as Map<String, dynamic>,
          ),
        );
      case 'session/prompt':
        return AgentPromptResponse(
          PromptResponse.fromJson(result as Map<String, dynamic>),
        );
      case 'session/set_model':
        return AgentSetSessionModelResponse(
          result == null
              ? SetSessionModelResponse()
              : SetSessionModelResponse.fromJson(
                  result as Map<String, dynamic>,
                ),
        );
      default:
        return AgentExtensionMethodResponse(method, result);
    }
  }
}

class AgentInitializeResponse extends AgentResponseUnion {
  final InitializeResponse response;
  const AgentInitializeResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class AgentAuthenticateResponse extends AgentResponseUnion {
  final AuthenticateResponse response;
  const AgentAuthenticateResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class AgentNewSessionResponse extends AgentResponseUnion {
  final NewSessionResponse response;
  const AgentNewSessionResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class AgentLoadSessionResponse extends AgentResponseUnion {
  final LoadSessionResponse response;
  const AgentLoadSessionResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class AgentListSessionsResponse extends AgentResponseUnion {
  final ListSessionsResponse response;
  const AgentListSessionsResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class AgentForkSessionResponse extends AgentResponseUnion {
  final ForkSessionResponse response;
  const AgentForkSessionResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class AgentResumeSessionResponse extends AgentResponseUnion {
  final ResumeSessionResponse response;
  const AgentResumeSessionResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class AgentSetSessionModeResponse extends AgentResponseUnion {
  final SetSessionModeResponse response;
  const AgentSetSessionModeResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class AgentSetSessionConfigOptionResponse extends AgentResponseUnion {
  final SetSessionConfigOptionResponse response;
  const AgentSetSessionConfigOptionResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class AgentPromptResponse extends AgentResponseUnion {
  final PromptResponse response;
  const AgentPromptResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class AgentSetSessionModelResponse extends AgentResponseUnion {
  final SetSessionModelResponse response;
  const AgentSetSessionModelResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class AgentExtensionMethodResponse extends AgentResponseUnion {
  final String method;
  final dynamic rawResult;
  const AgentExtensionMethodResponse(this.method, this.rawResult);
  @override
  dynamic toJson() => rawResult;
}

/// Requests initiated by the client (handled by the agent).
///
/// Client requests are messages sent from the client to the agent that
/// expect a response. These include initialization, session management,
/// authentication, and prompt processing.
///
/// Supported request types:
/// - [ClientInitializeRequest] - Initialize the connection
/// - [ClientAuthenticateRequest] - Authenticate with the agent
/// - [ClientNewSessionRequest] - Create a new session
/// - [ClientLoadSessionRequest] - Load an existing session
/// - [ClientSetSessionModeRequest] - Change session mode
/// - [ClientPromptRequest] - Send a prompt to the agent
/// - [ClientSetSessionModelRequest] - Select model (unstable)
/// - [ClientExtensionMethodRequest] - Custom extension requests
///
/// ## Example
///
/// ```dart
/// // Create an initialization request
/// final request = ClientInitializeRequest(
///   InitializeRequest(
///     protocolVersion: 1,
///     clientCapabilities: ClientCapabilities(...),
///   ),
/// );
///
/// // Get the method name
/// print(request.method); // 'initialize'
/// ```
abstract class ClientRequestUnion {
  const ClientRequestUnion();

  /// The JSON-RPC method name for this request type.
  String get method;

  /// Serializes the request parameters to JSON.
  dynamic toJson();

  /// Creates the appropriate request union from a JSON-RPC method and params.
  ///
  /// This factory automatically routes to the correct request type based on
  /// the method name. Unknown methods are wrapped in [ClientExtensionMethodRequest].
  static ClientRequestUnion fromMethod(String method, dynamic params) {
    switch (method) {
      case 'initialize':
        return ClientInitializeRequest(
          InitializeRequest.fromJson(params as Map<String, dynamic>),
        );
      case 'authenticate':
        return ClientAuthenticateRequest(
          AuthenticateRequest.fromJson(params as Map<String, dynamic>),
        );
      case 'session/new':
        return ClientNewSessionRequest(
          NewSessionRequest.fromJson(params as Map<String, dynamic>),
        );
      case 'session/load':
        return ClientLoadSessionRequest(
          LoadSessionRequest.fromJson(params as Map<String, dynamic>),
        );
      case 'session/list':
        return ClientListSessionsRequest(
          ListSessionsRequest.fromJson(params as Map<String, dynamic>),
        );
      case 'session/fork':
        return ClientForkSessionRequest(
          ForkSessionRequest.fromJson(params as Map<String, dynamic>),
        );
      case 'session/resume':
        return ClientResumeSessionRequest(
          ResumeSessionRequest.fromJson(params as Map<String, dynamic>),
        );
      case 'session/set_mode':
        return ClientSetSessionModeRequest(
          SetSessionModeRequest.fromJson(params as Map<String, dynamic>),
        );
      case 'session/set_config_option':
        return ClientSetSessionConfigOptionRequest(
          SetSessionConfigOptionRequest.fromJson(
            params as Map<String, dynamic>,
          ),
        );
      case 'session/prompt':
        return ClientPromptRequest(
          PromptRequest.fromJson(params as Map<String, dynamic>),
        );
      case 'session/set_model':
        return ClientSetSessionModelRequest(
          SetSessionModelRequest.fromJson(params as Map<String, dynamic>),
        );
      default:
        return ClientExtensionMethodRequest(method, params);
    }
  }
}

class ClientInitializeRequest extends ClientRequestUnion {
  final InitializeRequest params;
  const ClientInitializeRequest(this.params);
  @override
  String get method => agentMethods['initialize']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class ClientAuthenticateRequest extends ClientRequestUnion {
  final AuthenticateRequest params;
  const ClientAuthenticateRequest(this.params);
  @override
  String get method => agentMethods['authenticate']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class ClientNewSessionRequest extends ClientRequestUnion {
  final NewSessionRequest params;
  const ClientNewSessionRequest(this.params);
  @override
  String get method => agentMethods['sessionNew']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class ClientLoadSessionRequest extends ClientRequestUnion {
  final LoadSessionRequest params;
  const ClientLoadSessionRequest(this.params);
  @override
  String get method => agentMethods['sessionLoad']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class ClientListSessionsRequest extends ClientRequestUnion {
  final ListSessionsRequest params;
  const ClientListSessionsRequest(this.params);
  @override
  String get method => agentMethods['sessionList']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class ClientForkSessionRequest extends ClientRequestUnion {
  final ForkSessionRequest params;
  const ClientForkSessionRequest(this.params);
  @override
  String get method => agentMethods['sessionFork']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class ClientResumeSessionRequest extends ClientRequestUnion {
  final ResumeSessionRequest params;
  const ClientResumeSessionRequest(this.params);
  @override
  String get method => agentMethods['sessionResume']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class ClientSetSessionModeRequest extends ClientRequestUnion {
  final SetSessionModeRequest params;
  const ClientSetSessionModeRequest(this.params);
  @override
  String get method => agentMethods['sessionSetMode']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class ClientSetSessionConfigOptionRequest extends ClientRequestUnion {
  final SetSessionConfigOptionRequest params;
  const ClientSetSessionConfigOptionRequest(this.params);
  @override
  String get method => agentMethods['sessionSetConfigOption']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class ClientPromptRequest extends ClientRequestUnion {
  final PromptRequest params;
  const ClientPromptRequest(this.params);
  @override
  String get method => agentMethods['sessionPrompt']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class ClientSetSessionModelRequest extends ClientRequestUnion {
  final SetSessionModelRequest params;
  const ClientSetSessionModelRequest(this.params);
  @override
  String get method => agentMethods['modelSelect']!;
  @override
  Map<String, dynamic> toJson() => params.toJson();
}

class ClientExtensionMethodRequest extends ClientRequestUnion {
  final String methodName;
  final dynamic rawParams;
  const ClientExtensionMethodRequest(this.methodName, this.rawParams);
  @override
  String get method => methodName;
  @override
  dynamic toJson() => rawParams;
}

/// Responses returned by the client to the agent.
///
/// Client responses are replies to agent requests, including file system
/// operations, permission decisions, and terminal management results.
///
/// Supported response types:
/// - [ClientWriteTextFileResponse] - Response to file write
/// - [ClientReadTextFileResponse] - Response to file read
/// - [ClientRequestPermissionResponse] - Response to permission request
/// - [ClientCreateTerminalResponse] - Response to terminal creation
/// - [ClientTerminalOutputResponse] - Response to terminal output request
/// - [ClientReleaseTerminalResponse] - Response to terminal release
/// - [ClientWaitForTerminalExitResponse] - Response to exit wait
/// - [ClientKillTerminalResponse] - Response to terminal kill
/// - [ClientExtensionMethodResponse] - Response to custom extensions
abstract class ClientResponseUnion {
  const ClientResponseUnion();

  /// Serializes the response to JSON.
  dynamic toJson();

  /// Creates the appropriate response union from a method name and result.
  ///
  /// This factory automatically routes to the correct response type based on
  /// the original request method. Unknown methods are wrapped in [ClientExtensionMethodResponse].
  static ClientResponseUnion fromMethod(String method, dynamic result) {
    switch (method) {
      case 'fs/write_text_file':
        return ClientWriteTextFileResponse(
          result == null
              ? WriteTextFileResponse()
              : WriteTextFileResponse.fromJson(result as Map<String, dynamic>),
        );
      case 'fs/read_text_file':
        return ClientReadTextFileResponse(
          ReadTextFileResponse.fromJson(result as Map<String, dynamic>),
        );
      case 'session/request_permission':
        return ClientRequestPermissionResponse(
          RequestPermissionResponse.fromJson(result as Map<String, dynamic>),
        );
      case 'terminal/create':
        return ClientCreateTerminalResponse(
          CreateTerminalResponse.fromJson(result as Map<String, dynamic>),
        );
      case 'terminal/output':
        return ClientTerminalOutputResponse(
          TerminalOutputResponse.fromJson(result as Map<String, dynamic>),
        );
      case 'terminal/release':
        return ClientReleaseTerminalResponse(
          result == null
              ? ReleaseTerminalResponse()
              : ReleaseTerminalResponse.fromJson(
                  result as Map<String, dynamic>,
                ),
        );
      case 'terminal/wait_for_exit':
        return ClientWaitForTerminalExitResponse(
          WaitForTerminalExitResponse.fromJson(result as Map<String, dynamic>),
        );
      case 'terminal/kill':
        return ClientKillTerminalResponse(
          result == null
              ? KillTerminalCommandResponse()
              : KillTerminalCommandResponse.fromJson(
                  result as Map<String, dynamic>,
                ),
        );
      default:
        return ClientExtensionMethodResponse(method, result);
    }
  }
}

class ClientWriteTextFileResponse extends ClientResponseUnion {
  final WriteTextFileResponse response;
  const ClientWriteTextFileResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class ClientReadTextFileResponse extends ClientResponseUnion {
  final ReadTextFileResponse response;
  const ClientReadTextFileResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class ClientRequestPermissionResponse extends ClientResponseUnion {
  final RequestPermissionResponse response;
  const ClientRequestPermissionResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class ClientCreateTerminalResponse extends ClientResponseUnion {
  final CreateTerminalResponse response;
  const ClientCreateTerminalResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class ClientTerminalOutputResponse extends ClientResponseUnion {
  final TerminalOutputResponse response;
  const ClientTerminalOutputResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class ClientReleaseTerminalResponse extends ClientResponseUnion {
  final ReleaseTerminalResponse response;
  const ClientReleaseTerminalResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class ClientWaitForTerminalExitResponse extends ClientResponseUnion {
  final WaitForTerminalExitResponse response;
  const ClientWaitForTerminalExitResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class ClientKillTerminalResponse extends ClientResponseUnion {
  final KillTerminalCommandResponse response;
  const ClientKillTerminalResponse(this.response);
  @override
  Map<String, dynamic> toJson() => response.toJson();
}

class ClientExtensionMethodResponse extends ClientResponseUnion {
  final String method;
  final dynamic rawResult;
  const ClientExtensionMethodResponse(this.method, this.rawResult);
  @override
  dynamic toJson() => rawResult;
}

/// Notifications sent by the client to the agent.
///
/// Client notifications are one-way messages from the client to the agent
/// that don't expect a response. The primary notification type is
/// [CancelNotification] for canceling ongoing operations.
///
/// Supported notification types:
/// - [ClientCancelNotification] - Cancel a session operation
/// - [ClientCancelRequestNotification] - Cancel a specific in-flight request
/// - [ClientExtensionNotification] - Custom extension notifications
abstract class ClientNotificationUnion {
  const ClientNotificationUnion();

  /// The JSON-RPC method name for this notification type.
  String get method;

  /// Serializes the notification parameters to JSON.
  dynamic toJson();

  /// Creates the appropriate notification union from a JSON-RPC method and params.
  ///
  /// This factory automatically routes to the correct notification type based on
  /// the method name. Unknown methods are wrapped in [ClientExtensionNotification].
  static ClientNotificationUnion fromMethod(String method, dynamic params) {
    switch (method) {
      case 'session/cancel':
        return ClientCancelNotification(
          CancelNotification.fromJson(params as Map<String, dynamic>),
        );
      case r'$/cancel_request':
        return ClientCancelRequestNotification(
          CancelRequestNotification.fromJson(params as Map<String, dynamic>),
        );
      default:
        return ClientExtensionNotification(method, params);
    }
  }
}

class ClientCancelNotification extends ClientNotificationUnion {
  final CancelNotification notification;
  const ClientCancelNotification(this.notification);
  @override
  String get method => agentMethods['sessionCancel']!;
  @override
  Map<String, dynamic> toJson() => notification.toJson();
}

class ClientCancelRequestNotification extends ClientNotificationUnion {
  final CancelRequestNotification notification;
  const ClientCancelRequestNotification(this.notification);
  @override
  String get method => protocolMethods['cancelRequest']!;
  @override
  Map<String, dynamic> toJson() => notification.toJson();
}

class ClientExtensionNotification extends ClientNotificationUnion {
  final String methodName;
  final dynamic rawParams;
  const ClientExtensionNotification(this.methodName, this.rawParams);
  @override
  String get method => methodName;
  @override
  dynamic toJson() => rawParams;
}

/// Convenience helpers to map methods back to union factories.
extension AgentRequestLookup on Iterable<AgentRequestUnion> {
  AgentRequestUnion? findByMethod(String method) =>
      firstWhereOrNull((element) => element.method == method);
}

const _agentMethods = <String>{
  'initialize',
  'authenticate',
  'providers/list',
  'providers/set',
  'providers/disable',
  'session/new',
  'session/load',
  'session/set_mode',
  'session/set_config_option',
  'session/prompt',
  'session/cancel',
  'mcp/message',
  'session/list',
  'session/delete',
  'session/fork',
  'session/resume',
  'session/close',
  'logout',
  'nes/start',
  'nes/suggest',
  'nes/accept',
  'nes/reject',
  'nes/close',
  'document/didOpen',
  'document/didChange',
  'document/didClose',
  'document/didSave',
  'document/didFocus',
};

const _clientMethods = <String>{
  'session/request_permission',
  'session/update',
  'fs/write_text_file',
  'fs/read_text_file',
  'terminal/create',
  'terminal/output',
  'terminal/release',
  'terminal/wait_for_exit',
  'terminal/kill',
  'mcp/connect',
  'mcp/message',
  'mcp/disconnect',
  'elicitation/create',
  'elicitation/complete',
};

class V15AgentMethods {
  static const Set<String> all = _agentMethods;
}

class V15ClientMethods {
  static const Set<String> all = _clientMethods;
}

class V15RawJsonPayload {
  final Object? value;
  const V15RawJsonPayload(this.value);
}

Object? _decode(String method, Object? value) {
  if (value is! Map) return V15RawJsonPayload(value);
  final json = Map<String, dynamic>.from(value);
  switch (method) {
    case 'initialize':
      return InitializeRequest.fromJson(json);
    case 'authenticate':
      return AuthenticateRequest.fromJson(json);
    case 'session/request_permission':
      return RequestPermissionRequest.fromJson(json);
    case 'fs/write_text_file':
      return WriteTextFileRequest.fromJson(json);
    case 'fs/read_text_file':
      return ReadTextFileRequest.fromJson(json);
    case 'terminal/create':
      return CreateTerminalRequest.fromJson(json);
    case 'terminal/output':
      return TerminalOutputRequest.fromJson(json);
    case 'terminal/release':
      return ReleaseTerminalRequest.fromJson(json);
    case 'terminal/wait_for_exit':
      return WaitForTerminalExitRequest.fromJson(json);
    case 'terminal/kill':
      return KillTerminalCommandRequest.fromJson(json);
    case 'session/update':
      return SessionNotification.fromJson(json);
    case 'elicitation/create':
      return CreateElicitationRequest.fromJson(json);
    case 'mcp/connect':
      return V15ConnectMcpRequest.fromJson(json);
    case 'mcp/disconnect':
      return V15DisconnectMcpRequest.fromJson(json);
    case 'document/didOpen':
      return V15DidOpenDocumentNotification.fromJson(json);
    case 'document/didChange':
      return V15DidChangeDocumentNotification.fromJson(json);
    case 'document/didClose':
      return V15DidCloseDocumentNotification.fromJson(json);
    case 'document/didSave':
      return V15DidSaveDocumentNotification.fromJson(json);
    case 'document/didFocus':
      return V15DidFocusDocumentNotification.fromJson(json);
    case 'nes/accept':
      return V15AcceptNesNotification.fromJson(json);
    case 'nes/reject':
      return V15RejectNesNotification.fromJson(json);
    case 'session/new':
      return NewSessionRequest.fromJson(json);
    case 'session/load':
      return LoadSessionRequest.fromJson(json);
    case 'session/list':
      return ListSessionsRequest.fromJson(json);
    case 'session/delete':
      return DeleteSessionRequest.fromJson(json);
    case 'session/fork':
      return ForkSessionRequest.fromJson(json);
    case 'session/resume':
      return ResumeSessionRequest.fromJson(json);
    case 'session/close':
      return CloseSessionRequest.fromJson(json);
    case 'session/set_mode':
      return SetSessionModeRequest.fromJson(json);
    case 'session/set_config_option':
      return SetSessionConfigOptionRequest.fromJson(json);
    case 'session/prompt':
      return PromptRequest.fromJson(json);
    case 'session/cancel':
      return CancelNotification.fromJson(json);
    case 'providers/list':
      return V15ListProvidersRequest.fromJson(json);
    case 'providers/set':
      return V15SetProviderRequest.fromJson(json);
    case 'providers/disable':
      return V15DisableProviderRequest.fromJson(json);
    case 'mcp/message':
      return V15MessageMcpRequest.fromJson(json);
    case 'elicitation/complete':
      return CompleteElicitationNotification.fromJson(json);
    default:
      return V15RawJsonPayload(json);
  }
}

Object? _encode(Object? value) => switch (value) {
  V15RawJsonPayload(:final value) => value,
  _ => (value as dynamic).toJson(),
};

Map<String, dynamic> _map(Object? value, String name) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('Expected $name object');
}

class _Request {
  final Object? id;
  final String method;
  final Object? params;
  final bool isKnownMethod;
  final bool isExperimental;
  const _Request(
    this.id,
    this.method,
    this.params,
    this.isKnownMethod,
    this.isExperimental,
  );
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'method': method,
    if (params != null) 'params': _encode(params),
  };
}

class V15AgentRequest extends _Request {
  V15AgentRequest._(
    super.id,
    super.method,
    super.params,
    super.isKnownMethod,
    super.isExperimental,
  );
  factory V15AgentRequest.fromJson(Map<String, dynamic> json) {
    final method = json['method'];
    if (method is! String) {
      throw FormatException('Expected method string');
    }
    if (const {
              'session/request_permission',
              'fs/write_text_file',
              'fs/read_text_file',
              'terminal/create',
              'terminal/output',
              'terminal/release',
              'terminal/wait_for_exit',
              'terminal/kill',
              'mcp/connect',
              'mcp/message',
              'mcp/disconnect',
              'elicitation/create',
            }.contains(method) ==
            false &&
        _clientMethods.contains(method)) {
      throw FormatException('Expected request method');
    }
    return V15AgentRequest._(
      json['id'],
      method,
      _decode(method, json['params']),
      _clientMethods.contains(method),
      method == 'mcp/message',
    );
  }
}

class V15ClientRequest extends _Request {
  V15ClientRequest._(
    super.id,
    super.method,
    super.params,
    super.isKnownMethod,
    super.isExperimental,
  );
  factory V15ClientRequest.fromJson(Map<String, dynamic> json) {
    final method = json['method'];
    if (method is! String) {
      throw FormatException('Expected method string');
    }
    if (const {
              'initialize',
              'authenticate',
              'providers/list',
              'providers/set',
              'providers/disable',
              'session/new',
              'session/load',
              'session/set_mode',
              'session/set_config_option',
              'session/prompt',
              'mcp/message',
              'session/list',
              'session/delete',
              'session/fork',
              'session/resume',
              'session/close',
              'logout',
              'nes/start',
              'nes/suggest',
              'nes/close',
            }.contains(method) ==
            false &&
        _agentMethods.contains(method)) {
      throw FormatException('Expected request method');
    }
    return V15ClientRequest._(
      json['id'],
      method,
      _decode(method, json['params']),
      _agentMethods.contains(method),
      const {
        'providers/list',
        'providers/set',
        'providers/disable',
        'mcp/message',
        'nes/start',
        'nes/suggest',
        'nes/close',
        'session/fork',
      }.contains(method),
    );
  }
}

class _Notification {
  final String method;
  final Object? params;
  final bool isKnownMethod;
  const _Notification(this.method, this.params, this.isKnownMethod);
  Map<String, dynamic> toJson() => {
    'method': method,
    if (params != null) 'params': _encode(params),
  };
}

class V15AgentNotification extends _Notification {
  V15AgentNotification._(super.method, super.params, super.isKnownMethod);
  factory V15AgentNotification.fromJson(Map<String, dynamic> json) {
    final method = json['method'];
    if (method is! String) {
      throw FormatException('Expected method string');
    }
    if (json.containsKey('id')) {
      throw FormatException('Expected notification');
    }
    if (!const {
      'session/update',
      'elicitation/complete',
      'mcp/message',
    }.contains(method)) {
      throw FormatException('Expected notification method');
    }
    return V15AgentNotification._(
      method,
      _decode(method, json['params']),
      _clientMethods.contains(method),
    );
  }
}

class V15ClientNotification extends _Notification {
  V15ClientNotification._(super.method, super.params, super.isKnownMethod);
  factory V15ClientNotification.fromJson(Map<String, dynamic> json) {
    final method = json['method'];
    if (method is! String) {
      throw FormatException('Expected method string');
    }
    if (!const {
      'session/cancel',
      'document/didOpen',
      'document/didChange',
      'document/didClose',
      'document/didSave',
      'document/didFocus',
      'nes/accept',
      'nes/reject',
    }.contains(method)) {
      throw FormatException('Expected notification method');
    }
    return V15ClientNotification._(
      method,
      _decode(method, json['params']),
      _agentMethods.contains(method),
    );
  }
}

class _Response {
  final Object? id;
  final Object? result;
  final V15RawJsonPayload? error;
  final Object? _wireResult;
  const _Response(this.id, this.result, this.error, [this._wireResult]);
  Map<String, dynamic> toJson() => {
    'id': id,
    if (error != null)
      'error': error!.value
    else
      'result': _wireResult ?? _encode(result),
  };
}

Object? _responseForMethod(String? method, Object? value) {
  if (value is! Map) return V15RawJsonPayload(value);
  final json = Map<String, dynamic>.from(value);
  if (method == null && json.containsKey('protocolVersion')) {
    return InitializeResponse.fromJson(json);
  }
  switch (method) {
    case 'initialize':
      return InitializeResponse.fromJson(json);
    case 'authenticate':
      return AuthenticateResponse.fromJson(json);
    case 'session/new':
      return NewSessionResponse.fromJson(json);
    case 'session/load':
      return LoadSessionResponse.fromJson(json);
    case 'session/list':
      return ListSessionsResponse.fromJson(json);
    case 'session/delete':
      return DeleteSessionResponse.fromJson(json);
    case 'session/fork':
      return ForkSessionResponse.fromJson(json);
    case 'session/resume':
      return ResumeSessionResponse.fromJson(json);
    case 'session/close':
      return CloseSessionResponse.fromJson(json);
    case 'session/set_mode':
      return SetSessionModeResponse.fromJson(json);
    case 'session/set_config_option':
      return SetSessionConfigOptionResponse.fromJson(json);
    case 'session/prompt':
      return PromptResponse.fromJson(json);
    case 'session/request_permission':
      return RequestPermissionResponse.fromJson(json);
    case 'fs/write_text_file':
      return WriteTextFileResponse.fromJson(json);
    case 'fs/read_text_file':
      return ReadTextFileResponse.fromJson(json);
    case 'terminal/create':
      return CreateTerminalResponse.fromJson(json);
    case 'terminal/output':
      return TerminalOutputResponse.fromJson(json);
    case 'terminal/release':
      return ReleaseTerminalResponse.fromJson(json);
    case 'terminal/wait_for_exit':
      return WaitForTerminalExitResponse.fromJson(json);
    case 'terminal/kill':
      return KillTerminalCommandResponse.fromJson(json);
    case 'elicitation/create':
      return CreateElicitationResponse.fromJson(json);
    case 'mcp/message':
      return V15MessageMcpResponse.fromJson(json);
    case 'mcp/connect':
      return V15ConnectMcpResponse.fromJson(json);
    case 'mcp/disconnect':
      return V15DisconnectMcpResponse.fromJson(json);
    case 'providers/list':
      return V15ListProvidersResponse.fromJson(json);
    case 'providers/set':
    case 'providers/disable':
      return V15ProviderMutationResponse.fromJson(json);
    default:
      return V15RawJsonPayload(json);
  }
}

class V15AgentResponse extends _Response {
  V15AgentResponse._(super.id, super.result, super.error, [super._wireResult]);
  factory V15AgentResponse.fromJson(
    Map<String, dynamic> json, {
    String? method,
  }) {
    if (json.containsKey('error')) {
      return V15AgentResponse._(
        json['id'],
        null,
        V15RawJsonPayload(_map(json['error'], 'error')),
      );
    }
    return V15AgentResponse._(
      json['id'],
      _responseForMethod(method, json['result']),
      null,
      json['result'],
    );
  }
}

class V15ClientResponse extends _Response {
  V15ClientResponse._(super.id, super.result, super.error, [super._wireResult]);
  factory V15ClientResponse.fromJson(
    Map<String, dynamic> json, {
    String? method,
  }) {
    if (json.containsKey('error')) {
      return V15ClientResponse._(
        json['id'],
        null,
        V15RawJsonPayload(_map(json['error'], 'error')),
      );
    }
    return V15ClientResponse._(
      json['id'],
      _responseForMethod(method, json['result']),
      null,
      json['result'],
    );
  }
}
