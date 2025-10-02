# ACP-Dart Library Research Summary

## Overview
The `acp-dart` library is a Dart implementation of the Agent Client Protocol (ACP), which enables communication between AI agents and client applications. The library provides a complete implementation of the ACP specification.

## Key Components
- `ClientSideConnection` and `AgentSideConnection` for managing ACP connections
- `Client` and `Agent` abstract interfaces for implementing protocol participants
- `TerminalHandle` for controlling terminal operations
- `ndJsonStream` for NDJSON-based communication
- Comprehensive schema definitions for all ACP messages

## Architecture
The library follows a client-agent model where:
- Agents implement the `Agent` interface with methods for initialization, session management, authentication, and handling prompts
- Clients implement the `Client` interface with methods for file system operations, terminal management, and permission requests
- Both sides communicate through NDJSON streams

## Schema Design
The schema includes:
- Request/Response types for various ACP operations (initialize, authenticate, newSession, loadSession, etc.)
- Content blocks for different data types (text, image, audio, resource links)
- Session update mechanisms for streaming responses
- Tool call definitions with permission handling

## Features
- Support for different content types through specialized content blocks
- Session management with mode switching capabilities
- Tool calls with permission requests for sensitive operations
- Terminal management for executing commands
- Extensibility through extension methods and notifications

## Implementation Details
- Uses `json_annotation` and custom converters for JSON serialization
- Implements proper error handling with `RequestError` and `ErrorResponse`
- Includes comprehensive type definitions for all protocol messages
- Provides example implementation demonstrating usage

## Example Usage
The example demonstrates a complete agent implementation that:
- Handles new session creation
- Processes prompts with simulated model interactions
- Manages tool calls with permission requests
- Streams updates to the client

## Dependencies
- `path`: For path manipulation
- `json_annotation`: For JSON serialization annotations
- `build_runner` and `json_serializable`: For code generation
- `test`: For unit testing
- `lints`: For code quality
