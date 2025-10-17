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
