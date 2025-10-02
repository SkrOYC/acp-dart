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

library acp_dart;

export 'src/acp.dart'
    show
        Agent,
        AgentSideConnection,
        Client,
        ClientSideConnection,
        Connection,
        RequestError,
        TerminalHandle;

export 'src/schema.dart';

export 'src/stream.dart' show AcpStream, ndJsonStream;
