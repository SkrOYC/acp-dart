# ACP Dart Library

The official Dart implementation of the Agent Client Protocol (ACP) — a standardized communication protocol between code editors and AI-powered coding agents.

Learn more at https://agentclientprotocol.com

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  acp_dart: ^0.1.0
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
- **Stream handling**: `ndJsonStream` for NDJSON-based communication
- **Type safety**: Full Dart type annotations and null safety

If you're building an [Agent](https://agentclientprotocol.com/protocol/overview#agent), start with implementing the `Agent` interface and using `AgentSideConnection`.

If you're building a [Client](https://agentclientprotocol.com/protocol/overview#client), start with implementing the `Client` interface and using `ClientSideConnection`.

### Key Features

- **Type Safety**: Full Dart type annotations with null safety
- **JSON Serialization**: Automatic serialization using `json_serializable`
- **Stream-based Communication**: NDJSON-based communication over stdio
- **Complete Protocol Coverage**: All ACP request/response types implemented
- **Error Handling**: Comprehensive error types and handling mechanisms
- **Extensible**: Support for extension methods and notifications

## Usage Examples

### Creating an Agent

```dart
import 'package:acp_dart/acp_dart.dart';

class MyAgent implements Agent {
  final AgentSideConnection _connection;

  MyAgent(this._connection);

  @override
  Future<InitializeResponse> initialize(InitializeRequest params) async {
    return InitializeResponse(
      protocolVersion: '0.1.0',
      capabilities: AgentCapabilities(
        loadSession: false,
        auth: [],
      ),
    );
  }

  // Implement other required methods...
}

void main() {
  final stream = ndJsonStream(stdin, stdout);
  final connection = AgentSideConnection((conn) => MyAgent(conn), stream);
}
```

### Creating a Client

```dart
import 'package:acp_dart/acp_dart.dart';

class MyClient implements Client {
  @override
  Future<RequestPermissionResponse> requestPermission(
    RequestPermissionRequest params,
  ) async {
    // Handle permission requests
    return RequestPermissionResponse(optionId: params.options.first.id);
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

- [Protocol Documentation](https://agentclientprotocol.com)
- [GitHub Repository](https://github.com/SkrOYC/acp-dart)
- [Zed ACP GitHub Repository](https://github.com/zed-industries/agent-client-protocol)
- [Examples](https://github.com/SkrOYC/acp-dart/tree/master/example)

## Contributing

See the official [ACP repository](https://github.com/zed-industries/agent-client-protocol) for contribution guidelines.
