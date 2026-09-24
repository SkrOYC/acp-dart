/// A Dart implementation of the Agent Client Protocol (ACP).
///
/// This library provides a complete implementation of the ACP specification,
/// enabling communication between AI agents and client applications.
///
/// ## Key Components
///
/// - [ClientSideConnection] and [AgentSideConnection] for managing ACP connections
/// - [Client] and [Agent] abstract interfaces for implementing protocol participants
/// - [TerminalHandle] for controlling terminal operations
/// - [ndJsonStream] for NDJSON-based communication
/// - Comprehensive schema definitions for all ACP messages
///
/// ## Example Usage
///
/// See the examples directory for complete implementations of agents and clients.
///
/// ## Protocol Documentation
///
/// For detailed protocol information, see: https://agentclientprotocol.com/

library;

export 'src/acp.dart'
    show
        Agent,
        AgentSideConnection,
        Client,
        ClientSideConnection,
        Connection,
        ProtocolCancellationHandler,
        RequestContext,
        RequestError,
        TerminalHandle;

export 'src/schema.dart';
export 'src/schema_v15_client.dart';
export 'src/schema_v15_experimental.dart';
export 'src/rpc_unions.dart';
export 'src/app.dart';
export 'src/cookie_store.dart';
export 'src/http_stream.dart' show HttpStreamOptions, createHttpStream;
export 'src/websocket_stream.dart'
    show WebSocketStreamOptions, createWebSocketStream;
export 'src/http_server.dart' show AcpHttpServer;

export 'src/stream.dart' show AcpStream, ndJsonStream;
