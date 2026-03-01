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

import 'package:collection/collection.dart';

import 'schema.dart';

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
