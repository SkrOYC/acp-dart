# ACP Dart SDK Gap Analysis (vs. Official Specification)

**Date:** 2025-10-17
**Target SDK:** acp-dart
**Target Spec:** /mnt/pendrive/agent-client-protocol/

## Executive Summary

The `acp-dart` SDK is highly compliant with the official Agent Client Protocol (ACP) specification. All major components, including core handshake, session management, file system operations, terminal control, tool calls, and content blocks, are correctly implemented based on the latest available schema definitions. The SDK even includes implementations for features marked as **UNSTABLE** in the spec (e.g., model selection), demonstrating forward-looking development.

The only notable inconsistency found is the presence of a non-standard session update type, which should be removed to achieve 100% adherence to the protocol specification.

## Detailed Findings

### 1. Areas of High Compliance (No Gaps Found)

| Feature Area | Implemented Components | Compliance Status |
| :--- | :--- | :--- |
| **Core Enums** | `Role`, `ToolKind`, `ToolCallStatus`, `StopReason` | Fully compliant. Correct use of `@JsonValue` for serialization. |
| **Initialization** | `InitializeRequest`, `ClientCapabilities`, `AgentCapabilities` | Fully compliant. |
| **Session Management** | `AuthenticateRequest`, `NewSessionRequest`, `LoadSessionRequest`, `SetSessionModeRequest`, `PromptRequest`, `CancelNotification` | Fully compliant. |
| **File System (fs)** | `WriteTextFileRequest`, `ReadTextFileRequest`, `DeleteFileRequest`, `MakeDirectoryRequest`, `MoveFileRequest`, and corresponding responses. | Fully compliant. |
| **Terminal** | `CreateTerminalRequest`, `TerminalOutputRequest`, `WaitForTerminalExitRequest`, `KillTerminalCommandRequest`, and corresponding responses. | Fully compliant. |
| **Content Blocks** | `TextContentBlock`, `ImageContentBlock`, `AudioContentBlock`, `ResourceLinkContentBlock`, `ResourceContentBlock`. | Fully compliant. The spec confirms `AudioContent` is a valid block type. |
| **Tool Calls** | `ToolCall`, `ToolCallUpdate`, `ToolCallLocation`, `ToolCallContent` (including `content`, `diff`, `terminal` types). | Fully compliant. |
| **Unstable Features** | `SetSessionModelRequest`, `SessionModelState` (Model Selection). | Implemented, matching the unstable definitions in the spec. |

### 2. Identified Inconsistency (Gap)

| Component | Description | Spec Adherence | Recommendation |
| :--- | :--- | :--- | :--- |
| **`SessionStopSessionUpdate`** | A class extending `SessionUpdate` that contains a `reason` field. | **Non-Compliant.** This update type is not defined in the official `SessionUpdate` `oneOf` schema in the specification. The protocol signals the end of a prompt turn via the `PromptResponse` (which contains the `StopReason`), not a streaming update. | **Remove** `SessionStopSessionUpdate` and any related logic from `lib/src/schema.dart` and `lib/src/session_update_converter.dart`. |

## Action Plan for 100% Compliance

To ensure 100% adherence to the official protocol, the following code modification is required:

1.  **Remove `SessionStopSessionUpdate`** from `lib/src/schema.dart`.
2.  **Remove the corresponding converter logic** from `lib/src/session_update_converter.dart`.

This will eliminate the non-standard update type and align the SDK strictly with the defined protocol messages.
