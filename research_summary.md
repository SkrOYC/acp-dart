# ACP Dart SDK Gap Analysis (vs. Official Specification)

**Date:** 2025-10-17  
**Target SDK:** acp-dart  
**Target Spec:** /mnt/pendrive/agent-client-protocol/

## Executive Summary

The SDK now mirrors the official Agent Client Protocol (ACP) schema, including all handshakes, session lifecycle payloads, permission flows, plan reporting, content blocks, terminal RPCs, and unstable model selection endpoints. Legacy filesystem RPCs (`delete`, `move`, `list`, `make`) were removed to match the current spec, and bespoke extensions (e.g., `SessionStopSessionUpdate`) are gone.

## Highlights

- End-to-end JSON models match `schema/schema.json`, including `_meta` propagation, discriminator values, and enum string constants.
- MCP server configuration supports the HTTP/SSE/stdio variants defined in the spec.
- Typed union wrappers (`AgentRequestUnion`, etc.) provide method-aware routing helpers instead of raw string tables.
- Tool-call content uses `type` discriminators with a tightened converter that round-trips official payloads.
- Example agent/client flows and tests exercise spec-compliant request/response sequences (initialize, new session, prompt, permission, terminal, etc.).
- Added schema round-trip tests to guard against future drift.

## Outstanding Work

- `AgentNotification`, `AgentRequest`, `AgentResponse`, `ClientNotification`, `ClientRequest`, and `ClientResponse` remain abstract placeholders. If the SDK needs strongly typed unions for these enums, follow-up implementation is still required.
