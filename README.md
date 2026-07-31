# ACP Dart Library

[![pub](https://img.shields.io/pub/v/acp_dart)](https://pub.dev/packages/acp_dart)
[![Mintlify Docs](https://img.shields.io/badge/Mintlify-Docs-blue)](https://mintlify.wiki/SkrOYC/acp-dart)

The official Dart implementation of the Agent Client Protocol (ACP) — a standardized communication protocol between code editors and AI-powered coding agents.

Learn more at https://agentclientprotocol.com

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  acp_dart: ^0.5.0
```

Then run:
```bash
dart pub get
```

## Get Started

### Understand the Protocol

Start by reading the [ACP documentation](https://agentclientprotocol.com) to understand the core concepts and protocol specification.

### Try the Examples

The [examples directory](https://github.com/SkrOYC/acp-dart/tree/master/example) contains simple implementations of both Agents and Clients in Dart. These examples can be run from your terminal or from an ACP Client like [Zed](https://zed.dev), making them great starting points for your own integration!

To run the example agent:
```bash
dart run example/agent.dart
```

To run the example client:
```bash
dart run example/client.dart
```

### Explore the API

The library provides:

- **Agent-side**: `AgentSideConnection` for implementing AI agents
- **Client-side**: `ClientSideConnection` for implementing ACP clients
- **Core types**: Comprehensive schema definitions for all ACP messages
- **RPC unions**: Type-safe request, response, and notification unions for exhaustive handling
- **Stream handling**: `ndJsonStream` for NDJSON-based communication
- **Type safety**: Full Dart type annotations and null safety

If you're building an [Agent](https://agentclientprotocol.com/protocol/overview#agent), start with implementing the `Agent` interface and using `AgentSideConnection`.

If you're building a [Client](https://agentclientprotocol.com/protocol/overview#client), start with implementing the `Client` interface and using `ClientSideConnection`.

### Key Features

- **Type Safety**: Full Dart type annotations with null safety
- **RPC Unions**: Sealed union types for exhaustive request/response handling
- **JSON Serialization**: Automatic serialization using `json_serializable`
- **Stream-based Communication**: NDJSON-based communication over stdio
- **Error Handling**: Comprehensive error types and handling mechanisms
- **JSON-RPC Error Mapping**: Parameter-validation failures map to `-32602 Invalid params`, while unexpected failures map to `-32603 Internal error`
- **Protocol Cancellation**: Typed `$/cancel_request` notifications with `-32800` cancelled error semantics
- **Extensible**: Support for extension methods and notifications (method names are passed through as provided; include leading `_` for protocol extension methods)

## Protocol Support Matrix

The implementation tracks ACP stable and unstable surfaces explicitly.

### Stable Supported

- Agent methods: `initialize`, `authenticate`, `logout`, `session/new`, `session/load`, `session/prompt`, `session/cancel`, `session/set_mode`, `session/set_config_option`, `session/list`, `session/close`, `session/delete`
- Client methods: `fs/read_text_file`, `fs/write_text_file`, `session/request_permission`, `session/update`, `elicitation/create`, `elicitation/complete`
- Terminal methods: `terminal/create`, `terminal/output`, `terminal/wait_for_exit`, `terminal/kill`, `terminal/release`
- Protocol cancellation notification: `$/cancel_request`
- Session updates: `user_message_chunk`, `agent_message_chunk`, `agent_thought_chunk`, `tool_call`, `tool_call_update`, `plan`, `available_commands_update`, `current_mode_update`, `config_option_update`

### Unstable Supported

- `session/fork`
- `session/resume`
- Additional update variants implemented for parity tracking: `session_info_update`, `usage_update`

### Deprecated

- `session/set_model`, along with `SessionModelState`, `ModelInfo`, and the `ModelId` typedef. These have no counterpart in the ACP schema — model selection is expressed through `session/set_config_option` with a model config category. They still dispatch, and will be removed in the next major release.

### Known Unsupported

These appear in the published schema but are not implemented here. Several are still at RFD stage and may change shape:

- `providers/list`, `providers/set`, `providers/disable`
- `nes/start`, `nes/suggest`, `nes/accept`, `nes/reject`, `nes/close` (Next Edit Suggestions)
- `document/didOpen`, `document/didChange`, `document/didClose`, `document/didSave`, `document/didFocus`
- `mcp/connect`, `mcp/message`, `mcp/disconnect` (MCP-over-ACP)
- Filesystem methods beyond the ACP stable surface (for example delete/move/mkdir/list operations)

Anything not represented in `agentMethods`, `clientMethods`, and the typed schema unions in this package is unsupported.

See [`parity_verification_checklist.md`](parity_verification_checklist.md) for the release-time parity verification process.

### Error and Stream Behavior

- Incoming request parameter/validation failures are returned as JSON-RPC `Invalid params` (`-32602`).
- Unexpected runtime failures are returned as JSON-RPC `Internal error` (`-32603`) without exposing raw internal exception details.
- `ndJsonStream` skips malformed non-empty lines and continues processing subsequent valid messages. Use the optional `onParseError` callback to handle parse diagnostics (for example, routing logs to `stderr` or a structured logger).

## Usage Examples

### Creating an Agent

```dart
import 'dart:io';

import 'package:acp_dart/acp_dart.dart';

class MyAgent implements Agent {
  final AgentSideConnection _connection;

  MyAgent(this._connection);

  @override
  Future<InitializeResponse> initialize(InitializeRequest params) async {
    return InitializeResponse(
      protocolVersion: 1,
      agentCapabilities: AgentCapabilities(loadSession: false),
      authMethods: const [],
    );
  }

  // Implement other required methods...
}

void main() {
  // Note the argument order: (stdin, stdout).
  final stream = ndJsonStream(stdin, stdout);
  AgentSideConnection((conn) => MyAgent(conn), stream);
}
```

> `implements Agent` requires every interface member to be declared, because
> Dart only inherits default method bodies through `extends`. See
> [`example/agent.dart`](example/agent.dart) for a complete implementation.

### Creating a Client

```dart
import 'package:acp_dart/acp_dart.dart';

class MyClient implements Client {
  @override
  Future<RequestPermissionResponse> requestPermission(
    RequestPermissionRequest params,
  ) async {
    // Handle permission requests
    return RequestPermissionResponse(
      outcome: SelectedOutcome(optionId: params.options.first.optionId),
    );
  }

  @override
  Future<CreateElicitationResponse> createElicitation(
    CreateElicitationRequest params,
  ) async {
    // Collect the requested input from the user, then accept, decline,
    // or cancel. See example/client.dart for a working implementation.
    return ElicitationDeclineResponse();
  }

  @override
  Future<void> sessionUpdate(SessionNotification params) async {
    // Handle session updates
    print('Session update: ${params.update}');
  }

  // Implement other required methods...
}
```

## Resources

- [Package Documentation](https://mintlify.wiki/SkrOYC/acp-dart) — installation, quickstart, API reference, and examples for this package
- [Protocol Documentation](https://agentclientprotocol.com) — the ACP specification itself
- [GitHub Repository](https://github.com/SkrOYC/acp-dart)
- [Examples](https://github.com/SkrOYC/acp-dart/tree/master/example)
- [ACP Reference Implementation](https://github.com/agentclientprotocol/agent-client-protocol) — the schema and Rust SDK this package tracks

## Contributing

Issues and pull requests for this package belong on [SkrOYC/acp-dart](https://github.com/SkrOYC/acp-dart/issues).

For the protocol itself — proposing a new method, changing a message shape — see the [ACP repository](https://github.com/agentclientprotocol/agent-client-protocol) and its [RFD process](https://agentclientprotocol.com/rfds/about).

Before releasing, work through [`parity_verification_checklist.md`](parity_verification_checklist.md).
