# TypeScript v1.5 interop test

This test launches the Dart example agent and connects the official TypeScript
SDK v1.5.0 client to it over stdio and NDJSON. It covers malformed input,
initialize, session creation and updates, prompt completion, permission,
method-not-found errors, `session/cancel`, and request-scoped cancellation
notification delivery. The legacy Dart example may finish a request after that
notification because request cancellation is cooperative.

Clone the pinned SDK tag and install its dependencies with Bun:

```sh
git clone --branch v1.5.0 https://github.com/agentclientprotocol/typescript-sdk.git /path/to/typescript-sdk-v1.5.0
cd /path/to/typescript-sdk-v1.5.0
bun install
```

Run the Dart integration test from the `acp_dart` repository:

```sh
ACP_TYPESCRIPT_SDK_DIR=/path/to/typescript-sdk-v1.5.0 \
  dart test test/typescript_v15_interop_test.dart
```

Set `ACP_TYPESCRIPT_SDK_DIR` to any local clone whose `HEAD` is exactly tagged
`v1.5.0`. The test does not access the network.
