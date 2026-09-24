# ACP Dart

A Dart SDK for the [Agent Client Protocol (ACP)](https://agentclientprotocol.com/). It lets Dart agents and clients exchange JSON-RPC messages over newline-delimited JSON (NDJSON), HTTP with server-sent events (SSE), and WebSocket streams.

This source tree tracks the ACP v1 entry point of the [official TypeScript SDK v1.5.0](https://github.com/agentclientprotocol/typescript-sdk/tree/v1.5.0). The draft ACP v2 entry point is outside this package's scope. Protocol methods marked experimental in v1.5.0 can change in later versions.

## Install and run an example

Add the published package to a Dart project:

```sh
dart pub add acp_dart
```

The published `0.4.0` package predates the v1.5 work in this source tree.
Use a source checkout to evaluate these APIs before the next package release.

To run the examples from a source checkout, install dependencies and start the client:

```sh
dart pub get
dart run example/client.dart
```

The client starts `example/agent.dart` as a subprocess. Enter a number when it requests permission. The example exchanges initialization, session, prompt, update, and permission messages. See the [agent](example/agent.dart) and [client](example/client.dart) source for complete implementations.

## Choose an API

| API | Use it for |
| --- | --- |
| `agent()` and `client()` | Register request and notification handlers, then connect to an `AcpStream`. `connectWith` closes the connection after its callback completes. |
| `AgentSideConnection` and `ClientSideConnection` | Implement the v1 agent or client interfaces with typed method wrappers. These classes remain available for existing integrations. |
| `Connection` | Exchange lower-level JSON-RPC requests and notifications. Use `RequestContext` to observe request-scoped cancellation. |
| `SessionBuilder` and `ActiveSession` | Create a session, send prompts, and consume updates or stop messages from a client app. |

The package entry point is `package:acp_dart/acp_dart.dart`. For example, create a client connection to a child process with `ndJsonStream(process.stdout, process.stdin)`, then pass the stream to `ClientSideConnection` or `client().connectWith(...)`.
Use `acpProtocolVersion` when constructing an `InitializeRequest`.

## Protocol coverage

The following method inventory matches the TypeScript SDK v1.5.0 schema. Stable methods have typed Dart models and connection dispatch. Experimental methods have method constants and payload models; use the app handler API or the v1.5 handler mixins where a typed legacy wrapper is available.

| Direction | Stable methods |
| --- | --- |
| Client to agent | `initialize`, `authenticate`, `logout`, `session/new`, `session/load`, `session/list`, `session/delete`, `session/resume`, `session/close`, `session/set_mode`, `session/set_config_option`, `session/prompt`, `session/cancel` |
| Agent to client | `session/request_permission`, `session/update`, `fs/read_text_file`, `fs/write_text_file`, `terminal/create`, `terminal/output`, `terminal/wait_for_exit`, `terminal/kill`, `terminal/release`, `elicitation/create`, `elicitation/complete` |
| Either direction | `$/cancel_request` |

The v1.5.0 entry point also defines these experimental method families:

- Agent methods: `session/fork`, `providers/*`, `nes/*`, `document/didOpen`, `document/didChange`, `document/didClose`, `document/didSave`, `document/didFocus`, and `mcp/message`.
- Client methods: `mcp/connect`, `mcp/message`, and `mcp/disconnect`.
- Session updates: `plan_update`, `plan_removed`, `compaction_update`, and `compaction_summary_chunk`.

`session/set_model` remains a Dart legacy extension. It is absent from the TypeScript SDK v1.5.0 `AGENT_METHODS` inventory. The Dart API retains `unstableListSessions` and `unstableResumeSession` for compatibility; use `listSessions` and `resumeSession` for the stable v1.5.0 methods.

Unknown session-update payloads retain their raw JSON. The source includes typed models for content, tool calls, configuration options, permissions, elicitation, and the v1.5.0 update variants.

## Transports

`ndJsonStream` connects byte streams, including process stdin and stdout. It sends JSON-RPC parse errors for malformed nonempty lines and accepts a final line without a newline. ACP v1 connections reject JSON-RPC batches.

`createHttpStream` opens an ACP Streamable HTTP client with connection and session SSE streams. `createWebSocketStream` opens a WebSocket client. `AcpHttpServer.bind` hosts HTTP, SSE, and WebSocket ACP connections through `dart:io`. These transport adapters use `dart:io` and run on the Dart VM; they don't provide browser transports.

`AcpCookieStore` lets client transports share affinity cookies across requests. `MemoryAcpCookieStore` stores cookie names and values in memory.
The WebSocket client can send stored cookies, but `dart:io` does not expose
upgrade response headers for storing a new cookie from that handshake.

## Errors and cancellation

Failed JSON-RPC requests complete with `RequestError`, which exposes the protocol code, message, and optional data. A closed connection rejects pending requests. `sendRequestWithCancellation` sends `$/cancel_request` when its cancellation future completes and waits for the peer's reply. Incoming handlers can observe cancellation through `RequestContext`. Session turns can also be cancelled with `session/cancel`.

## Verify the package

Run analysis and the Dart test suite from the repository root:

```sh
dart analyze
dart test
```

If you edit serializable models, regenerate serializers before testing:

```sh
dart run build_runner build --delete-conflicting-outputs
dart test
```

The test suite includes connected byte-stream and process tests, HTTP and WebSocket loopback tests, and JSON fixtures checked against the pinned TypeScript SDK schema. To run the opt-in test against an actual TypeScript v1.5.0 peer, follow the [interop test instructions](tool/README.md).

For release checks, use the [parity verification checklist](parity_verification_checklist.md).

## License

MIT. See [LICENSE](LICENSE).
