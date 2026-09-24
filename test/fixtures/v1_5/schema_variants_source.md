# Schema variant fixtures

Oracle: `agentclientprotocol/typescript-sdk` tag `v1.5.0`,
`schema/schema.json` definitions `ContentBlock`, `ToolCallContent`,
`RequestPermissionOutcome`, `AuthMethod`, `SessionConfigOption`, and
`SessionUpdate`. Deserializer behavior follows `src/schema-deserialize.test.ts`
and `src/acp.test.ts` cases for unknown properties and union validation.
