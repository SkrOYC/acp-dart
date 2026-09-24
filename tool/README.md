# TypeScript v1.5 interop tests

The opt-in tests run Dart against an official TypeScript SDK v1.5.0 checkout.
They cover these peer and transport combinations:

| Client | Server | Transport |
| --- | --- | --- |
| TypeScript | Dart example agent | stdio and NDJSON |
| Dart | TypeScript `AcpServer` | HTTP and SSE |
| TypeScript | Dart `AcpHttpServer` | HTTP and SSE |
| TypeScript | Dart `AcpHttpServer` | WebSocket |

The transport stress suite covers malformed input, initialization, routing
headers, affinity cookies, concurrent sessions, and concurrent prompts. It also
covers ordered updates and allow, reject, and cancelled permission outcomes.
The suite also covers file reads, request errors, both cancellation forms,
connection closure, and reconnects.

The stdio test also covers the legacy Dart example and cooperative request
cancellation.

Clone the pinned SDK tag and install its dependencies with Bun:

```sh
git clone --branch v1.5.0 https://github.com/agentclientprotocol/typescript-sdk.git /path/to/typescript-sdk-v1.5.0
cd /path/to/typescript-sdk-v1.5.0
bun install
```

Run all interop tests from the `acp_dart` repository:

```sh
ACP_TYPESCRIPT_SDK_DIR=/path/to/typescript-sdk-v1.5.0 \
  dart test \
    test/typescript_v15_interop_test.dart \
    test/typescript_v15_transport_interop_test.dart
```

Set `ACP_TYPESCRIPT_SDK_DIR` to any local clone whose `HEAD` is exactly tagged
`v1.5.0`. The tests use local loopback connections and do not contact an
external service.

The reverse WebSocket direction is excluded from the gate. Bun 1.3.13 doesn't
implement the `ws.WebSocket` `upgrade` event used by the pinned SDK's Node
WebSocket stack. In the pinned checkout, `bun test src/ws-stream.test.ts`
reports this limitation. Its real socket initialization, permission, reconnect,
and concurrent session cases time out. HTTP is tested in both directions. The
WebSocket gate uses the official TypeScript client API over an actual socket to
the Dart server.

For the complete matrix and results, see the
[TypeScript v1.5 interoperability stress report](typescript_v15_stress_report.md).
