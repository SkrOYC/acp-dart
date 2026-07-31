## 0.5.0

Brings the package in line with the stable ACP v1 method inventory. The
missing methods were identified by diffing `agentMethods`/`clientMethods`
against the published schema's method constants.

### Added

- **Elicitation:** Full support for `elicitation/create` and the
  `elicitation/complete` notification, both agent-to-client. Covers form and
  URL modes, session and request scopes, `ElicitationSchema` with all five
  property schema variants (string, number, integer, boolean, array), titled
  and plain multi-select item constraints, `EnumOption`, `StringFormat`, and
  the accept/decline/cancel response actions. Unrecognised modes, property
  types, and actions round-trip through `Unknown*` variants rather than being
  dropped.
- **Elicitation Capabilities:** `ClientCapabilities.elicitation` so clients can
  advertise which elicitation modes they render.
- **Session Lifecycle:** `session/close` and `session/delete`, with typed
  models, dispatch, unions, and `Agent` interface members.
- **Authentication:** `logout`, completing the authentication surface.
- **Notification Routing:** `AgentNotificationUnion.fromMethod`, which
  dispatches on the JSON-RPC method name. The existing `fromJson` takes only a
  payload and always decodes it as a `SessionNotification`, so it cannot tell
  `session/update` from `elicitation/complete`. `fromJson` is unchanged.

### Changed

- **Support Matrix:** `session/list` is documented as stable rather than
  unstable. The README now enumerates the specific schema methods this package
  does not implement (`providers/*`, `nes/*`, `document/did*`, `mcp/*`)
  instead of describing them in the abstract.

### Deprecated

- **`session/set_model`:** Not present in the ACP schema. Model selection is
  expressed through `session/set_config_option` with a model config category.
  The method, `SetSessionModelRequest`/`Response`, `SessionModelState`,
  `ModelInfo`, and the `ModelId` typedef are all marked `@Deprecated`. Dispatch
  is retained so existing integrations keep working.

### Fixed

- **Example Agent:** `example/agent.dart` declared `implements Agent` but
  omitted `unstableListSessions`, `unstableForkSession`, and
  `unstableResumeSession`, so it had not compiled since those methods were
  introduced — despite the README instructing users to run it. Dart only
  inherits default method bodies through `extends`, never `implements`.
- **README Snippets:** Both usage examples were non-compiling. The agent
  snippet used `protocolVersion: '0.1.0'` (the field is an `int`) along with
  `capabilities:` and `auth:`, neither of which exists. The client snippet
  constructed `RequestPermissionResponse` with a non-existent `optionId:`
  parameter and read `option.id` instead of `option.optionId`.

### Compatibility Notes

- **Breaking for `implements`:** Adding members to the `Agent` and `Client`
  interfaces breaks implementors that use `implements`, which requires every
  member to be declared. The new members carry `=> null` defaults, so classes
  using `extends` are unaffected. Implementors using `implements` must add
  `closeSession`, `deleteSession`, and `logout` (agents) or `createElicitation`
  and `completeElicitation` (clients). Returning `null` from any of them keeps
  the previous behaviour: `-32601 Method not found`.
- **Deprecation:** The `session/set_model` surface will be removed in the next
  major release.

## 0.4.0

### Added

- **Stable Method Support:** Added end-to-end support for `session/set_config_option` with typed request/response models and connection dispatch wiring.
- **Unstable Session Surface:** Added unstable support for `session/list`, `session/fork`, and `session/resume`, including typed schema models, capability models, and client/agent interface wiring.
- **Protocol Cancellation:** Added protocol-level `$/cancel_request` support with typed notifications and connection helpers to cancel pending outbound requests.
- **Schema/Model Coverage:** Expanded schema parity with session config option selector families, session capability objects, additional session update variants, and usage/cost payload models.
- **Typed Unions Expansion:** Extended request/response/notification union coverage to include newly supported session and protocol methods.
- **Maintainer Parity Process:** Added `parity_verification_checklist.md` for release-time parity verification.

### Changed

- **Extension Method Semantics:** `extMethod` and `extNotification` now preserve method names exactly as provided; callers must include protocol extension prefixes (for example, leading `_`) explicitly.
- **Request Error Mapping:** Validation-like failures now map to JSON-RPC `-32602` (`Invalid params`) and unexpected runtime failures map to sanitized `-32603` (`Internal error`) payloads.
- **NDJSON Stream Robustness:** `ndJsonStream` now skips malformed non-empty lines and continues processing valid messages, with optional `onParseError` diagnostics.
- **Documentation Accuracy:** README now uses an explicit stable/unstable/unsupported support matrix instead of broad completeness claims.
- **Release Notes Accuracy:** Corrected prior filesystem wording to avoid implying unsupported non-stable filesystem method families.

### Developer Experience

- **Reproducible Environment:** Added `devenv` configuration (`devenv.nix`, `devenv.yaml`, `devenv.lock`) for consistent local setup and CI-like workflows.
- **Regression Test Coverage:** Expanded ACP dispatch, schema round-trip, union mapping, extension, cancellation, and stream error-path test coverage.

### Compatibility Notes

- **Potentially Breaking:** Extension method name auto-prefixing behavior was removed; integrations relying on implicit `_` rewriting must update call sites.
- **Behavioral Change:** Malformed NDJSON lines no longer fail the stream by default; they are dropped unless handled through `onParseError`.
- **Behavioral Change:** Some failures previously surfaced as generic internal errors now return `Invalid params` when they are parameter/validation related.

## 0.3.0

- **Protocol Parity:** Rebuilt every data model to match the official ACP `schema.json`, including sessions, permissions, plans, content payloads, terminal updates, MCP server descriptors, and `_meta` envelopes; regenerated `schema.g.dart` to keep serialization in lock-step.
- **Client Operations Coverage:** Implemented ACP client request/response models for read/write text-file and terminal workflows, ensuring each request carries the appropriate `sessionId`, path fields, and limits, and aligned WaitForTerminalExit and related responses with nullable exit metadata.
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
