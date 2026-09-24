# TypeScript v1.5 interoperability stress report

Date: 2026-09-24

The stress suite ran against ACP Dart commit `c72493d` and the official
TypeScript SDK `v1.5.0` tag at commit
`f1ba3a935df42efb4455be9b62c76b06610aaf50`.

## Result

The tested ACP Dart client, server, JSON-RPC, and transport paths interoperate
with the official TypeScript v1.5.0 APIs. The transport tests passed against the
unchanged Dart implementation. The stress run didn't identify a production
code defect to fix.

## Scenarios

| Direction | Transport | Evidence |
| --- | --- | --- |
| TypeScript client to Dart agent | stdio and NDJSON | Initialize, malformed-line recovery, session updates, tools, permission, request errors, session cancellation, and request cancellation. |
| Dart client to TypeScript `AcpServer` | HTTP and SSE | Malformed HTTP rejection, initialization, connection and session routing headers, affinity cookie reuse, concurrent sessions and prompts, ordered updates, permission outcomes, file reads, request errors, both cancellation forms, closure, and reconnect. |
| TypeScript client to Dart `AcpHttpServer` | HTTP and SSE | The same request and callback matrix, observed custom and routing headers, malformed HTTP rejection, closure, and reconnect. |
| TypeScript client to Dart `AcpHttpServer` | WebSocket | Official client app and stream APIs over a real socket, malformed-frame recovery, concurrent sessions and prompts, callbacks, errors, cancellation, closure, and reconnect. |

Permission callbacks cover allow, reject, and cancelled outcomes. Each HTTP and
WebSocket run creates three simultaneous sessions, prompts them concurrently,
and verifies the order of two updates per session. A fourth prompt runs after a
fresh transport connection.

## Verification

The following commands passed:

```sh
ACP_TYPESCRIPT_SDK_DIR=/path/to/typescript-sdk-v1.5.0 \
  dart test test/typescript_v15_transport_interop_test.dart

ACP_TYPESCRIPT_SDK_DIR=/path/to/typescript-sdk-v1.5.0 \
  dart test

ACP_TYPESCRIPT_SDK_DIR=/path/to/typescript-sdk-v1.5.0 \
  dart test test/typescript_v15_interop_test.dart

dart analyze
dart format --output=none --set-exit-if-changed lib test example bin
```

The transport stress suite passed five consecutive runs. The full opt-in suite
passed 254 tests. The TypeScript harnesses also pass the pinned SDK's Prettier
check.

## WebSocket boundary

Dart client to TypeScript server WebSocket is not part of the gate. The
mandated Bun runtime cannot run the pinned SDK's real Node `ws` suite reliably.
The following command ran in the pinned TypeScript checkout:

```sh
timeout 45s bun test src/ws-stream.test.ts
```

Bun 1.3.13 reported that the `ws.WebSocket` `upgrade` event isn't implemented.
The result was seven passing and 10 failing tests in 40.15 seconds. Real socket
initialization, permission, reconnect, and multiple session tests timed out.
Two other cases failed because Bun's Vitest compatibility didn't provide
`vi.waitFor`. The SDK's in-memory WebSocket server suite passed all 24 tests.

This boundary does not affect the verified TypeScript client to Dart server
WebSocket direction, which uses the official SDK client app and stream APIs
with Bun's native WebSocket client.
