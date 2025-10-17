# Schema Alignment Checklist

- [x] Initialization payloads: `InitializeRequest`, `InitializeResponse`, `ClientCapabilities`, `AgentCapabilities`, `AuthMethod`, `AuthenticateRequest`, `AuthenticateResponse`
- [x] Session lifecycle: `NewSessionRequest/Response`, `LoadSessionRequest/Response`, `SessionMode`, `SessionModeState`, `SessionModelState`, `ModelInfo`, `SetSessionMode*`, `SetSessionModel*`
- [x] Identifiers: add dedicated wrappers/typedefs for `ProtocolVersion`, `SessionId`, `SessionModeId`, `ModelId`, `AuthMethodId`, `ToolCallId`, `PermissionOptionId`
- [x] Content blocks & resources: implement `TextContent`, `ImageContent`, `AudioContent`, `ResourceLink`, `EmbeddedResource`, `EmbeddedResourceResource`, converters, `_meta`
- [x] Plan & commands: add `Plan`, `PlanEntry`, enums (`PlanEntryPriority`, `PlanEntryStatus`), `AvailableCommand`, `AvailableCommandInput`
- [x] Tool calls & permissions: align `ToolCall`, `ToolCallContent`, `ToolCallUpdate`, `ToolCallLocation`, `PermissionOption`, `RequestPermissionOutcome`, converters
- [x] File system & terminal methods: ensure only spec-supported RPCs, align fields and `_meta`; drop deprecated `Delete/Move/List` APIs
- [x] Notifications & updates: align `SessionNotification`, `SessionUpdate` variants, include `_meta`
- [ ] Client/agent RPC envelopes: implement `AgentNotification`, `AgentRequest`, `AgentResponse`, `ClientNotification`, `ClientRequest`, `ClientResponse`
- [x] Schema primitives: ensure `_meta` is present where defined, remove non-spec fields, add defaults, ensure enums use `@JsonValue`
- [x] Update converters (`ContentBlockConverter`, `ToolCallContentConverter`, etc.) to use spec discriminators and handle nullability properly
- [x] Regenerate `schema.g.dart` via `build_runner`
- [x] Add schema parity tests validating example payloads against `schema.json`
