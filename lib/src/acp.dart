/// Error response for JSON-RPC 2.0

library;

import 'dart:async';

import 'package:acp_dart/src/schema.dart';
import 'package:acp_dart/src/stream.dart';

class ErrorResponse {
  final int code;
  final String message;
  final dynamic data;

  ErrorResponse({required this.code, required this.message, this.data});

  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    if (data != null) 'data': data,
  };

  factory ErrorResponse.fromJson(Map<String, dynamic> json) => ErrorResponse(
    code: json['code'] as int,
    message: json['message'] as String,
    data: json['data'],
  );
}

/// Type alias for request handler function
typedef RequestHandler =
    Future<dynamic> Function(String method, dynamic params);

/// Type alias for notification handler function
typedef NotificationHandler =
    Future<void> Function(String method, dynamic params);

/// Pending response promise container
class _PendingResponse {
  final void Function(dynamic) resolve;
  final void Function(dynamic) reject;

  _PendingResponse(this.resolve, this.reject);
}

/// Request error for ACP/JSON-RPC communication
class RequestError implements Exception {
  final int code;
  final String message;
  final dynamic data;

  RequestError(this.code, this.message, [this.data]);

  /// Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.
  static RequestError parseError([dynamic data]) {
    return RequestError(-32700, 'Parse error', data);
  }

  /// The JSON sent is not a valid Request object.
  static RequestError invalidRequest([dynamic data]) {
    return RequestError(-32600, 'Invalid request', data);
  }

  /// The method does not exist / is not available.
  static RequestError methodNotFound(String method) {
    return RequestError(-32601, 'Method not found', {'method': method});
  }

  /// Invalid method parameter(s).
  static RequestError invalidParams([dynamic data]) {
    return RequestError(-32602, 'Invalid params', data);
  }

  /// Internal JSON-RPC error.
  static RequestError internalError([dynamic data]) {
    return RequestError(-32603, 'Internal error', data);
  }

  /// Authentication required.
  static RequestError authRequired([dynamic data]) {
    return RequestError(-32000, 'Authentication required', data);
  }

  /// Resource, such as a file, was not found
  static RequestError resourceNotFound([String? uri]) {
    return RequestError(
      -32002,
      'Resource not found',
      uri != null ? {'uri': uri} : null,
    );
  }

  /// Converts this error to a JSON-RPC Result type (error variant)
  Map<String, dynamic> toResult() {
    return {'error': toErrorResponse().toJson()};
  }

  /// Converts this error to an ErrorResponse
  ErrorResponse toErrorResponse() {
    return ErrorResponse(code: code, message: message, data: data);
  }
}

/// Base connection class for managing JSON-RPC communication over ACP streams
class Connection {
  final Map<dynamic, _PendingResponse> _pendingResponses = {};
  int _nextRequestId = 0;
  final RequestHandler _requestHandler;
  final NotificationHandler _notificationHandler;
  final AcpStream _stream;
  Future<void> _writeQueue = Future.value();

  Connection(this._requestHandler, this._notificationHandler, this._stream) {
    _receive();
  }

  /// Sends a request and returns a future that completes with the response
  Future<T> sendRequest<T>(String method, [dynamic params]) {
    final id = _nextRequestId++;
    final completer = Completer<T>();
    _pendingResponses[id] = _PendingResponse(
      (value) => completer.complete(value as T),
      (error) => completer.completeError(error),
    );
    _sendMessage({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    });
    return completer.future;
  }

  /// Sends a notification (no response expected)
  Future<void> sendNotification(String method, [dynamic params]) {
    return _sendMessage({
      'jsonrpc': '2.0',
      'method': method,
      if (params != null) 'params': params,
    });
  }

  /// Starts receiving messages from the stream
  void _receive() {
    _stream.readable.listen(
      _processMessage,
      onError: (error) {
        print('Error receiving message: $error');
      },
      onDone: () {
        // Stream closed
      },
    );
  }

  /// Processes an incoming message
  void _processMessage(Map<String, dynamic> message) {
    try {
      if (message.containsKey('method') && message.containsKey('id')) {
        // It's a request
        _handleRequest(message);
      } else if (message.containsKey('method')) {
        // It's a notification
        _handleNotification(message);
      } else if (message.containsKey('id')) {
        // It's a response
        _handleResponse(message);
      } else {
        print('Invalid message: $message');
      }
    } catch (error) {
      print('Error processing message $message: $error');
      // Send error response if it was a request
      if (message.containsKey('id')) {
        _sendMessage({
          'jsonrpc': '2.0',
          'id': message['id'],
          'error': {'code': -32700, 'message': 'Parse error'},
        });
      }
    }
  }

  /// Handles incoming request
  void _handleRequest(Map<String, dynamic> message) async {
    final method = message['method'] as String;
    final params = message['params'];
    final id = message['id'];

    try {
      final result = await _requestHandler(method, params);
      _sendMessage({'jsonrpc': '2.0', 'id': id, 'result': result});
    } catch (error) {
      late Map<String, dynamic> errorResponse;
      if (error is RequestError) {
        errorResponse = error.toErrorResponse().toJson();
      } else {
        errorResponse = RequestError.internalError(
          error.toString(),
        ).toErrorResponse().toJson();
      }
      _sendMessage({'jsonrpc': '2.0', 'id': id, 'error': errorResponse});
    }
  }

  /// Handles incoming notification
  void _handleNotification(Map<String, dynamic> message) async {
    final method = message['method'] as String;
    final params = message['params'];

    try {
      await _notificationHandler(method, params);
    } catch (error) {
      print('Error handling notification $method: $error');
    }
  }

  /// Handles incoming response
  void _handleResponse(Map<String, dynamic> message) {
    final id = message['id'];
    final pending = _pendingResponses.remove(id);

    if (pending != null) {
      if (message.containsKey('result')) {
        pending.resolve(message['result']);
      } else if (message.containsKey('error')) {
        pending.reject(message['error']);
      }
    } else {
      print('Received response for unknown request id: $id');
    }
  }

  /// Sends a message through the stream with queuing
  Future<void> _sendMessage(Map<String, dynamic> message) {
    _writeQueue = _writeQueue.then((_) async {
      try {
        _stream.writable.add(message);
      } catch (error) {
        print('Error sending message: $error');
      }
    });
    return _writeQueue;
  }
}

/// Abstract base class defining the Client interface for ACP connections.
///
/// Clients implement this interface to handle requests from agents, including
/// file system operations, permission requests, terminal management, and
/// session updates.
abstract class Client {
  /// Requests permission from the user for a tool call operation.
  ///
  /// Called by the agent when it needs user authorization before executing
  /// a potentially sensitive operation. The client should present the options
  /// to the user and return their decision.
  ///
  /// If the client cancels the prompt turn via `session/cancel`, it MUST
  /// respond to this request with `RequestPermissionOutcome::Cancelled`.
  Future<RequestPermissionResponse> requestPermission(
    RequestPermissionRequest params,
  );

  /// Handles session update notifications from the agent.
  ///
  /// This is a notification endpoint (no response expected) that receives
  /// real-time updates about session progress, including message chunks,
  /// tool calls, and execution plans.
  ///
  /// Note: Clients SHOULD continue accepting tool call updates even after
  /// sending a `session/cancel` notification, as the agent may send final
  /// updates before responding with the cancelled stop reason.
  Future<void> sessionUpdate(SessionNotification params);

  /// Writes content to a text file in the client's file system.
  ///
  /// Only available if the client advertises the `fs.writeTextFile` capability.
  /// Allows the agent to create or modify files within the client's environment.
  Future<WriteTextFileResponse>? writeTextFile(WriteTextFileRequest params);

  /// Reads content from a text file in the client's file system.
  ///
  /// Only available if the client advertises the `fs.readTextFile` capability.
  /// Allows the agent to access file contents within the client's environment.
  Future<ReadTextFileResponse>? readTextFile(ReadTextFileRequest params);

  /// Deletes a file in the client's file system.
  ///
  /// Only available if the client advertises the `fs.deleteFile` capability.
  Future<DeleteFileResponse>? deleteFile(DeleteFileRequest params);

  /// Lists the contents of a directory in the client's file system.
  ///
  /// Only available if the client advertises the `fs.listDirectory` capability.
  Future<ListDirectoryResponse>? listDirectory(ListDirectoryRequest params);

  /// Creates a new directory in the client's file system.
  ///
  /// Only available if the client advertises the `fs.makeDirectory` capability.
  Future<MakeDirectoryResponse>? makeDirectory(MakeDirectoryRequest params);

  /// Moves or renames a file or directory in the client's file system.
  ///
  /// Only available if the client advertises the `fs.moveFile` capability.
  Future<MoveFileResponse>? moveFile(MoveFileRequest params);

  /// Creates a new terminal to execute a command.
  ///
  /// Only available if the `terminal` capability is set to `true`.
  ///
  /// The Agent must call `releaseTerminal` when done with the terminal
  /// to free resources.
  Future<CreateTerminalResponse>? createTerminal(CreateTerminalRequest params);

  /// Gets the current output and exit status of a terminal.
  ///
  /// Returns immediately without waiting for the command to complete.
  /// If the command has already exited, the exit status is included.
  Future<TerminalOutputResponse>? terminalOutput(TerminalOutputRequest params);

  /// Releases a terminal and frees all associated resources.
  ///
  /// The command is killed if it hasn't exited yet. After release,
  /// the terminal ID becomes invalid for all other terminal methods.
  ///
  /// Tool calls that already contain the terminal ID continue to
  /// display its output.
  Future<ReleaseTerminalResponse?>? releaseTerminal(
    ReleaseTerminalRequest params,
  );

  /// Waits for a terminal command to exit and returns its exit status.
  ///
  /// This method returns once the command completes, providing the
  /// exit code and/or signal that terminated the process.
  Future<WaitForTerminalExitResponse>? waitForTerminalExit(
    WaitForTerminalExitRequest params,
  );

  /// Kills a terminal command without releasing the terminal.
  ///
  /// While `releaseTerminal` also kills the command, this method keeps
  /// the terminal ID valid so it can be used with other methods.
  ///
  /// Useful for implementing command timeouts that terminate the command
  /// and then retrieve the final output.
  ///
  /// Note: Call `releaseTerminal` when the terminal is no longer needed.
  Future<KillTerminalResponse?>? killTerminal(
    KillTerminalCommandRequest params,
  );

  /// Extension method
  ///
  /// Allows the Agent to send an arbitrary request that is not part of the ACP spec.
  ///
  /// To help avoid conflicts, it's a good practice to prefix extension
  /// methods with a unique identifier such as domain name.
  Future<Map<String, dynamic>>? extMethod(
    String method,
    Map<String, dynamic> params,
  );

  /// Extension notification
  ///
  /// Allows the Agent to send an arbitrary notification that is not part of the ACP spec.
  Future<void>? extNotification(String method, Map<String, dynamic> params);
}

/// An agent-side connection to a client.
///
/// This class provides the agent's view of an ACP connection, allowing
/// agents to communicate with clients. It implements the Client interface
/// to provide methods for requesting permissions, accessing the file system,
/// and sending session updates.
class AgentSideConnection implements Client {
  late final Connection _connection;

  /// Creates a new agent-side connection to a client.
  ///
  /// This establishes the communication channel from the agent's perspective
  /// following the ACP specification.
  ///
  /// [toAgent] - A function that creates an Agent handler to process incoming client requests
  /// [stream] - The bidirectional message stream for communication. Typically created using
  ///            ndJsonStream for stdio-based connections.
  AgentSideConnection(
    Agent Function(AgentSideConnection) toAgent,
    AcpStream stream,
  ) {
    final agent = toAgent(this);

    Future<dynamic> requestHandler(String method, dynamic params) async {
      switch (method) {
        case 'initialize':
          final validatedParams = InitializeRequest.fromJson(
            params as Map<String, dynamic>,
          );
          return agent.initialize(validatedParams);
        case 'session/new':
          final validatedParams = NewSessionRequest.fromJson(
            params as Map<String, dynamic>,
          );
          return agent.newSession(validatedParams);
        case 'session/load':
          final validatedParams = LoadSessionRequest.fromJson(
            params as Map<String, dynamic>,
          );
          final result = await agent.loadSession(validatedParams);
          if (result == null) {
            throw RequestError.methodNotFound(method);
          }
          return result;
        case 'session/set_mode':
          final validatedParams = SetSessionModeRequest.fromJson(
            params as Map<String, dynamic>,
          );
          final result = await agent.setSessionMode(validatedParams);
          return result ?? {};
        case 'session/set_model':
          final validatedParams = SetSessionModelRequest.fromJson(
            params as Map<String, dynamic>,
          );
          final result = await agent.setSessionModel(validatedParams);
          return result ?? {};
        case 'authenticate':
          final validatedParams = AuthenticateRequest.fromJson(
            params as Map<String, dynamic>,
          );
          final result = await agent.authenticate(validatedParams);
          return result ?? {};
        case 'session/prompt':
          final validatedParams = PromptRequest.fromJson(
            params as Map<String, dynamic>,
          );
          return agent.prompt(validatedParams);
        default:
          if (method.startsWith('_')) {
            final result = await agent.extMethod(
              method.substring(1),
              params as Map<String, dynamic>,
            );
            if (result == null) {
              throw RequestError.methodNotFound(method);
            }
            return result;
          }
          throw RequestError.methodNotFound(method);
      }
    }

    Future<void> notificationHandler(String method, dynamic params) async {
      switch (method) {
        case 'session/cancel':
          final validatedParams = CancelNotification.fromJson(
            params as Map<String, dynamic>,
          );
          return agent.cancel(validatedParams);
        default:
          if (method.startsWith('_')) {
            await agent.extNotification(
              method.substring(1),
              params as Map<String, dynamic>,
            );
          }
          throw RequestError.methodNotFound(method);
      }
    }

    _connection = Connection(requestHandler, notificationHandler, stream);
  }

  @override
  Future<void> sessionUpdate(SessionNotification params) async {
    return _connection.sendNotification(
      clientMethods['sessionUpdate']!,
      params.toJson(),
    );
  }

  @override
  Future<RequestPermissionResponse> requestPermission(
    RequestPermissionRequest params,
  ) async {
    final result = await _connection.sendRequest(
      clientMethods['sessionRequestPermission']!,
      params.toJson(),
    );
    return RequestPermissionResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<ReadTextFileResponse> readTextFile(ReadTextFileRequest params) async {
    final result = await _connection.sendRequest(
      clientMethods['fsReadTextFile']!,
      params.toJson(),
    );
    return ReadTextFileResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<WriteTextFileResponse> writeTextFile(
    WriteTextFileRequest params,
  ) async {
    final result = await _connection.sendRequest(
      clientMethods['fsWriteTextFile']!,
      params.toJson(),
    );
    return WriteTextFileResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<DeleteFileResponse>? deleteFile(DeleteFileRequest params) async {
    final result = await _connection.sendRequest(
      clientMethods['fsDeleteFile']!,
      params.toJson(),
    );
    return DeleteFileResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<ListDirectoryResponse>? listDirectory(
    ListDirectoryRequest params,
  ) async {
    final result = await _connection.sendRequest(
      clientMethods['fsListDirectory']!,
      params.toJson(),
    );
    return ListDirectoryResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<MakeDirectoryResponse>? makeDirectory(
    MakeDirectoryRequest params,
  ) async {
    final result = await _connection.sendRequest(
      clientMethods['fsMakeDirectory']!,
      params.toJson(),
    );
    return MakeDirectoryResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<MoveFileResponse>? moveFile(MoveFileRequest params) async {
    final result = await _connection.sendRequest(
      clientMethods['fsMoveFile']!,
      params.toJson(),
    );
    return MoveFileResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<CreateTerminalResponse>? createTerminal(
    CreateTerminalRequest params,
  ) async {
    final result = await _connection.sendRequest(
      clientMethods['terminalCreate']!,
      params.toJson(),
    );
    return CreateTerminalResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<TerminalOutputResponse>? terminalOutput(
    TerminalOutputRequest params,
  ) async {
    final result = await _connection.sendRequest(
      clientMethods['terminalOutput']!,
      params.toJson(),
    );
    return TerminalOutputResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<ReleaseTerminalResponse?>? releaseTerminal(
    ReleaseTerminalRequest params,
  ) async {
    final result = await _connection.sendRequest(
      clientMethods['terminalRelease']!,
      params.toJson(),
    );
    return ReleaseTerminalResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<WaitForTerminalExitResponse>? waitForTerminalExit(
    WaitForTerminalExitRequest params,
  ) async {
    final result = await _connection.sendRequest(
      clientMethods['terminalWaitForExit']!,
      params.toJson(),
    );
    return WaitForTerminalExitResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<KillTerminalResponse?>? killTerminal(
    KillTerminalCommandRequest params,
  ) async {
    final result = await _connection.sendRequest(
      clientMethods['terminalKill']!,
      params.toJson(),
    );
    return KillTerminalResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>>? extMethod(
    String method,
    Map<String, dynamic> params,
  ) async {
    final result = await _connection.sendRequest('_$method', params);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void>? extNotification(
    String method,
    Map<String, dynamic> params,
  ) async {
    return _connection.sendNotification('_$method', params);
  }
}

/// A client-side connection to an agent.
///
/// This class provides the client's view of an ACP connection, allowing
/// clients (such as code editors) to communicate with agents. It implements
/// the Agent interface to provide methods for initializing sessions, sending
/// prompts, and managing the agent lifecycle.
class ClientSideConnection implements Agent {
  late final Connection _connection;

  /// Creates a new client-side connection to an agent.
  ///
  /// This establishes the communication channel between a client and agent
  /// following the ACP specification.
  ///
  /// [toClient] - A function that creates a Client handler to process incoming agent requests
  /// [stream] - The bidirectional message stream for communication. Typically created using
  ///            ndJsonStream for stdio-based connections.
  ClientSideConnection(
    Client Function(ClientSideConnection) toAgent,
    AcpStream stream,
  ) {
    final client = toAgent(this);

    Future<dynamic> requestHandler(String method, dynamic params) async {
      switch (method) {
        case 'fs/write_text_file':
          final validatedParams = WriteTextFileRequest.fromJson(
            params as Map<String, dynamic>,
          );
          return client.writeTextFile(validatedParams);
        case 'fs/read_text_file':
          final validatedParams = ReadTextFileRequest.fromJson(
            params as Map<String, dynamic>,
          );
          return client.readTextFile(validatedParams);
        case 'fs/delete_file':
          final validatedParams = DeleteFileRequest.fromJson(
            params as Map<String, dynamic>,
          );
          return client.deleteFile(validatedParams);
        case 'fs/list_directory':
          final validatedParams = ListDirectoryRequest.fromJson(
            params as Map<String, dynamic>,
          );
          return client.listDirectory(validatedParams);
        case 'fs/make_directory':
          final validatedParams = MakeDirectoryRequest.fromJson(
            params as Map<String, dynamic>,
          );
          return client.makeDirectory(validatedParams);
        case 'fs/move_file':
          final validatedParams = MoveFileRequest.fromJson(
            params as Map<String, dynamic>,
          );
          return client.moveFile(validatedParams);
        case 'session/request_permission':
          final validatedParams = RequestPermissionRequest.fromJson(
            params as Map<String, dynamic>,
          );
          return client.requestPermission(validatedParams);
        case 'terminal/create':
          final validatedParams = CreateTerminalRequest.fromJson(
            params as Map<String, dynamic>,
          );
          final result = await client.createTerminal(validatedParams);
          if (result == null) {
            throw RequestError.methodNotFound(method);
          }
          return result;
        case 'terminal/output':
          final validatedParams = TerminalOutputRequest.fromJson(
            params as Map<String, dynamic>,
          );
          final result = await client.terminalOutput(validatedParams);
          if (result == null) {
            throw RequestError.methodNotFound(method);
          }
          return result;
        case 'terminal/release':
          final validatedParams = ReleaseTerminalRequest.fromJson(
            params as Map<String, dynamic>,
          );
          final result = await client.releaseTerminal(validatedParams);
          return result ?? {};
        case 'terminal/wait_for_exit':
          final validatedParams = WaitForTerminalExitRequest.fromJson(
            params as Map<String, dynamic>,
          );
          final result = await client.waitForTerminalExit(validatedParams);
          if (result == null) {
            throw RequestError.methodNotFound(method);
          }
          return result;
        case 'terminal/kill':
          final validatedParams = KillTerminalCommandRequest.fromJson(
            params as Map<String, dynamic>,
          );
          final result = await client.killTerminal(validatedParams);
          return result ?? {};
        default:
          if (method.startsWith('_')) {
            final result = await client.extMethod(
              method.substring(1),
              params as Map<String, dynamic>,
            );
            if (result == null) {
              throw RequestError.methodNotFound(method);
            }
            return result;
          }
          throw RequestError.methodNotFound(method);
      }
    }

    Future<void> notificationHandler(String method, dynamic params) async {
      switch (method) {
        case 'session/update':
          final validatedParams = SessionNotification.fromJson(
            params as Map<String, dynamic>,
          );
          return client.sessionUpdate(validatedParams);
        default:
          if (method.startsWith('_')) {
            await client.extNotification(
              method.substring(1),
              params as Map<String, dynamic>,
            );
          }
          throw RequestError.methodNotFound(method);
      }
    }

    _connection = Connection(requestHandler, notificationHandler, stream);
  }

  @override
  Future<InitializeResponse> initialize(InitializeRequest params) async {
    final result = await _connection.sendRequest(
      agentMethods['initialize']!,
      params.toJson(),
    );
    return InitializeResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<NewSessionResponse> newSession(NewSessionRequest params) async {
    final result = await _connection.sendRequest(
      agentMethods['sessionNew']!,
      params.toJson(),
    );
    return NewSessionResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<LoadSessionResponse>? loadSession(LoadSessionRequest params) async {
    final result = await _connection.sendRequest(
      agentMethods['sessionLoad']!,
      params.toJson(),
    );
    return LoadSessionResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<SetSessionModeResponse?>? setSessionMode(
    SetSessionModeRequest params,
  ) async {
    final result = await _connection.sendRequest(
      agentMethods['sessionSetMode']!,
      params.toJson(),
    );
    return SetSessionModeResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<SetSessionModelResponse?>? setSessionModel(
    SetSessionModelRequest params,
  ) async {
    final result = await _connection.sendRequest(
      agentMethods['modelSelect']!,
      params.toJson(),
    );
    return SetSessionModelResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<AuthenticateResponse?>? authenticate(
    AuthenticateRequest params,
  ) async {
    final result = await _connection.sendRequest(
      agentMethods['authenticate']!,
      params.toJson(),
    );
    return AuthenticateResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<PromptResponse> prompt(PromptRequest params) async {
    final result = await _connection.sendRequest(
      agentMethods['sessionPrompt']!,
      params.toJson(),
    );
    return PromptResponse.fromJson(result as Map<String, dynamic>);
  }

  @override
  Future<void> cancel(CancelNotification params) async {
    return _connection.sendNotification(
      agentMethods['sessionCancel']!,
      params.toJson(),
    );
  }

  @override
  Future<Map<String, dynamic>>? extMethod(
    String method,
    Map<String, dynamic> params,
  ) async {
    final result = await _connection.sendRequest('_$method', params);
    return result as Map<String, dynamic>;
  }

  @override
  Future<void>? extNotification(
    String method,
    Map<String, dynamic> params,
  ) async {
    return _connection.sendNotification('_$method', params);
  }
}

/// Abstract base class defining the Agent interface for ACP connections.
///
/// Agents implement this interface to handle requests from clients, including
/// initialization, session management, authentication, and prompt processing.
abstract class Agent {
  /// Establishes the connection with a client and negotiates protocol capabilities.
  ///
  /// This method is called once at the beginning of the connection to:
  /// - Negotiate the protocol version to use
  /// - Exchange capability information between client and agent
  /// - Determine available authentication methods
  ///
  /// The agent should respond with its supported protocol version and capabilities.
  Future<InitializeResponse> initialize(InitializeRequest params);

  /// Creates a new conversation session with the agent.
  ///
  /// Sessions represent independent conversation contexts with their own history and state.
  ///
  /// The agent should:
  /// - Create a new session context
  /// - Connect to any specified MCP servers
  /// - Return a unique session ID for future requests
  ///
  /// May return an `auth_required` error if the agent requires authentication.
  Future<NewSessionResponse> newSession(NewSessionRequest params);

  /// Loads an existing session to resume a previous conversation.
  ///
  /// This method is only available if the agent advertises the `loadSession` capability.
  ///
  /// The agent should:
  /// - Restore the session context and conversation history
  /// - Connect to the specified MCP servers
  /// - Stream the entire conversation history back to the client via notifications
  Future<LoadSessionResponse>? loadSession(LoadSessionRequest params);

  /// Sets the operational mode for a session.
  ///
  /// Allows switching between different agent modes (e.g., "ask", "architect", "code")
  /// that affect system prompts, tool availability, and permission behaviors.
  ///
  /// The mode must be one of the modes advertised in `availableModes` during session
  /// creation or loading. Agents may also change modes autonomously and notify the
  /// client via `current_mode_update` notifications.
  ///
  /// This method can be called at any time during a session, whether the Agent is
  /// idle or actively generating a turn.
  Future<SetSessionModeResponse?>? setSessionMode(SetSessionModeRequest params);

  /// Selects the model for a given session.
  ///
  /// **UNSTABLE:** This capability is not part of the spec yet, and may be removed or changed at any point.
  Future<SetSessionModelResponse?>? setSessionModel(SetSessionModelRequest params);

  /// Authenticates the client using the specified authentication method.
  ///
  /// Called when the agent requires authentication before allowing session creation.
  /// The client provides the authentication method ID that was advertised during initialization.
  ///
  /// After successful authentication, the client can proceed to create sessions with
  /// `newSession` without receiving an `auth_required` error.
  Future<AuthenticateResponse?>? authenticate(AuthenticateRequest params);

  /// Processes a user prompt within a session.
  ///
  /// This method handles the whole lifecycle of a prompt:
  /// - Receives user messages with optional context (files, images, etc.)
  /// - Processes the prompt using language models
  /// - Reports language model content and tool calls to the Clients
  /// - Requests permission to run tools
  /// - Executes any requested tool calls
  /// - Returns when the turn is complete with a stop reason
  Future<PromptResponse> prompt(PromptRequest params);

  /// Cancels ongoing operations for a session.
  ///
  /// This is a notification sent by the client to cancel an ongoing prompt turn.
  ///
  /// Upon receiving this notification, the Agent SHOULD:
  /// - Stop all language model requests as soon as possible
  /// - Abort all tool call invocations in progress
  /// - Send any pending `session/update` notifications
  /// - Respond to the original `session/prompt` request with `StopReason::Cancelled`
  Future<void> cancel(CancelNotification params);

  /// Extension method
  ///
  /// Allows the Client to send an arbitrary request that is not part of the ACP spec.
  ///
  /// To help avoid conflicts, it's a good practice to prefix extension
  /// methods with a unique identifier such as domain name.
  Future<Map<String, dynamic>>? extMethod(
    String method,
    Map<String, dynamic> params,
  );

  /// Extension notification
  ///
  /// Allows the Client to send an arbitrary notification that is not part of the ACP spec.
  Future<void>? extNotification(String method, Map<String, dynamic> params);
}

/// Interface for objects that can be asynchronously disposed.
abstract class AsyncDisposable {
  Future<void> dispose();
}

/// A handle for managing terminal operations within a session.
///
/// This class provides methods to interact with a terminal created by an agent,
/// including getting output, waiting for completion, killing processes, and
/// releasing resources.
///
/// Terminal handles are typically created by agents and provided to clients
/// for terminal management operations.
class TerminalHandle implements AsyncDisposable {
  /// The unique identifier for this terminal instance.
  final String id;

  /// Private session identifier for routing requests.
  final String _sessionId;

  /// The connection used to send terminal-related requests.
  final Connection _connection;

  /// Creates a new terminal handle.
  ///
  /// [id] - The unique terminal identifier
  /// [sessionId] - The session this terminal belongs to
  /// [connection] - The connection for sending requests
  TerminalHandle(this.id, this._sessionId, this._connection);

  /// Gets the current terminal output without waiting for the command to exit.
  ///
  /// Returns the current stdout, stderr, and exit status if the command
  /// has already completed.
  Future<TerminalOutputResponse> currentOutput() async {
    return await _connection.sendRequest(clientMethods['terminalOutput']!, {
      'sessionId': _sessionId,
      'terminalId': id,
    });
  }

  /// Waits for the terminal command to complete and returns its exit status.
  ///
  /// This method blocks until the command finishes execution, then returns
  /// the exit code that indicates the command's success or failure.
  Future<WaitForTerminalExitResponse> waitForExit() async {
    return await _connection.sendRequest(
      clientMethods['terminalWaitForExit']!,
      {'sessionId': _sessionId, 'terminalId': id},
    );
  }

  /// Kills the terminal command without releasing the terminal.
  ///
  /// The terminal remains valid after killing, allowing you to:
  /// - Get the final output with `currentOutput()`
  /// - Check the exit status
  /// - Release the terminal when done
  ///
  /// Useful for implementing timeouts or cancellation.
  Future<KillTerminalResponse> kill() async {
    return await _connection.sendRequest(clientMethods['terminalKill']!, {
      'sessionId': _sessionId,
      'terminalId': id,
    });
  }

  /// Releases the terminal and frees all associated resources.
  ///
  /// If the command is still running, it will be killed.
  /// After release, the terminal ID becomes invalid and cannot be used
  /// with other terminal methods.
  ///
  /// Tool calls that already reference this terminal will continue to
  /// display its output.
  ///
  /// **Important:** Always call this method when done with the terminal.
  Future<ReleaseTerminalResponse> release() async {
    return await _connection.sendRequest(clientMethods['terminalRelease']!, {
      'sessionId': _sessionId,
      'terminalId': id,
    });
  }

  /// Disposes of the terminal handle and releases resources.
  ///
  /// This is the Dart equivalent of TypeScript's [Symbol.asyncDispose].
  /// It ensures proper cleanup by calling release().
  @override
  Future<void> dispose() async {
    await release();
  }
}
