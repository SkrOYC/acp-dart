## 0.2.0

- **Fix:** Resolved critical bug in NDJSON stream handling (`lib/src/stream.dart`) that caused communication failures due to incorrect UTF-8 and line splitting logic.
- **Fix:** Corrected `InitializeRequest` and `InitializeResponse` to properly handle numeric `protocolVersion` and use `clientCapabilities` key, resolving initialization errors with ACP backends.
- **Feature:** Added unstable `Agent.setSessionModel` method for feature parity with the latest ACP TypeScript SDK.

## 0.1.0

- Initial release of the `acp_dart` package.
- Implements the core functionality of the Agent-Client Protocol (ACP).
