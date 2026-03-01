## Unreleased

- **Error Mapping Parity:** Connection request error handling now maps parameter/validation exceptions to JSON-RPC `-32602` (`Invalid params`) and unexpected exceptions to `-32603` (`Internal error`), preserving structured error payloads when available.
- **Internal Error Sanitization:** Unexpected internal exceptions no longer echo raw exception text in protocol error `data`.
- **NDJSON Tolerant Parsing:** `ndJsonStream` now skips malformed non-empty JSON lines and continues streaming subsequent valid messages instead of terminating the stream, with an optional `onParseError` callback for consumer-controlled diagnostics.
- **Regression Tests:** Added coverage for invalid-params mapping, internal-error fallback, and malformed-line tolerant stream behavior.
- **Extension Semantics:** `extMethod` and `extNotification` now preserve caller-provided method names instead of auto-prefixing `_`; callers must provide the leading underscore for protocol extension methods.
- **Extension Dispatch:** Incoming extension request/notification handlers now pass full method names through to callbacks and avoid spurious method-not-found handling after successful extension notification dispatch.
- **Tests:** Added regression coverage for extension method pass-through, handled extension notifications, and unknown non-extension method-not-found behavior.

## 0.3.0

- **Protocol Parity:** Rebuilt every data model to match the official ACP `schema.json`, including sessions, permissions, plans, content payloads, terminal updates, MCP server descriptors, and `_meta` envelopes; regenerated `schema.g.dart` to keep serialization in lock-step.
- **Filesystem Coverage:** Restored delete/move/mkdir/list operations, ensured each request carries the appropriate `sessionId`, path fields, and limits, and aligned WaitForTerminalExit and related responses with nullable exit metadata.
- **Typed RPC Unions:** Introduced sealed Agent/Client request, response, and notification unions with exhaustive handling and constant tables; added comprehensive round-trip tests plus HTTP and SSE example flows that exercise the new types end-to-end.
- **Converters & Utilities:** Harmonized converters for session updates, MCP servers, permission requests, and tool-call content, removing non-spec variants while preserving forward-compatible `Unknown*` fallbacks.
- **Stability Fixes:** Corrected numerous spec mismatches (capability flags, optionality, naming, prompt payloads) and tightened serialization behaviors to prevent regressions.
- **Docs & Testing:** Updated research notes, tracked schema alignment in `schema_alignment_checklist.md`, refreshed examples, and broadened test coverage to guard the new behavior.

## 0.2.0

- **Fix:** Resolved critical bug in NDJSON stream handling (`lib/src/stream.dart`) that caused communication failures due to incorrect UTF-8 and line splitting logic.
- **Fix:** Corrected `InitializeRequest` and `InitializeResponse` to properly handle numeric `protocolVersion` and use `clientCapabilities` key, resolving initialization errors with ACP backends.
- **Feature:** Added unstable `Agent.setSessionModel` method for feature parity with the latest ACP TypeScript SDK.

## 0.1.0

- Initial release of the `acp_dart` package.
- Implements the core functionality of the Agent-Client Protocol (ACP).
