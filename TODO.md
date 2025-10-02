# TODO: ACP Dart SDK Implementation

This document breaks down the tasks required to build the Dart SDK for the Agent Client Protocol (ACP). Each task includes a reference to the corresponding file in the [official ACP TypeScript implementation](https://github.com/zed-industries/agent-client-protocol/tree/main/typescript) for guidance.

## Phase 1: Project Setup & Schema Definition

- [X] **Task 1.1: Initialize Dart Project**
    - **Description:** Create a new Dart project named `acp_dart` and establish the standard directory structure (`lib`, `test`, `example`).
    - **Reference:** N/A (Standard Dart practice)

- [X] **Task 1.2: Configure Dependencies**
    - **Description:** Add necessary dependencies to `pubspec.yaml`. This includes `json_annotation` for the main dependencies, and `json_serializable`, `build_runner`, `test`, and `lints` for the dev dependencies.
    - **Reference:** N/A (Dart ecosystem tooling)

- [X] **Task 1.3: Configure Linter**
    - **Description:** Create an `analysis_options.yaml` file and configure it with a recommended set of lints, such as `package:lints/recommended.yaml`.
    - **Reference:** N/A (Dart ecosystem tooling)

- [X] **Task 1.4: Define Core Schema Types**
    - **Description:** In `lib/src/schema.dart`, define the basic enumerations and simple types from the ACP specification.
    - **Reference:** [`typescript/schema.ts`](https://github.com/zed-industries/agent-client-protocol/blob/main/typescript/schema.ts) (e.g., `Role`, `ToolKind`, `ToolCallStatus`).

- [X] **Task 1.5: Implement Request Schemas**
    - **Description:** Implement all ACP request classes in `lib/src/schema.dart` with `@JsonSerializable` annotations.
    - **Reference:** [`typescript/schema.ts`](https://github.com/zed-industries/agent-client-protocol/blob/main/typescript/schema.ts) (e.g., `InitializeRequest`, `NewSessionRequest`, `PromptRequest`).

- [X] **Task 1.6: Implement Response Schemas**
    - **Description:** Implement all ACP response classes in `lib/src/schema.dart` with `@JsonSerializable` annotations.
    - **Reference:** [`typescript/schema.ts`](https://github.com/zed-industries/agent-client-protocol/blob/main/typescript/schema.ts) (e.g., `InitializeResponse`, `NewSessionResponse`, `PromptResponse`).

- [X] **Task 1.7: Implement Notification Schemas**
    - **Description:** Implement all ACP notification classes in `lib/src/schema.dart` with `@JsonSerializable` annotations.
    - **Reference:** [`typescript/schema.ts`](https://github.com/zed-industries/agent-client-protocol/blob/main/typescript/schema.ts) (e.g., `SessionNotification`, `CancelNotification`).

- [X] **Task 1.8: Generate Serialization Code**
    - **Description:** Run `dart run build_runner build --delete-conflicting-outputs` to generate the `*.g.dart` files for all schema classes.
    - **Reference:** N/A (Dart ecosystem tooling)

- [X] **Task 1.9: Write Schema Unit Tests**
    - **Description:** In `test/schema_test.dart`, write unit tests to verify the JSON serialization and deserialization of all schema classes.
    - **Reference:** [`typescript/acp.test.ts`](https://github.com/zed-industries/agent-client-protocol/blob/main/typescript/acp.test.ts)

## Phase 2: Core Implementation

- [X] **Task 2.1: Implement NDJSON Stream Transformer**
    - **Description:** In `lib/src/stream.dart`, implement the `ndJsonStream` transformer to handle newline-delimited JSON streams.
    - **Reference:** [`typescript/stream.ts`](https://github.com/zed-industries/agent-client-protocol/blob/main/typescript/stream.ts)

- [X] **Task 2.2: Implement `RequestError` Class**
    - **Description:** In `lib/src/acp.dart`, implement the `RequestError` class for handling JSON-RPC errors.
    - **Reference:** [`typescript/acp.ts`](https://github.com/zed-industries/agent-client-protocol/blob/main/typescript/acp.ts) (see `RequestError` class).

- [X] **Task 2.3: Implement Base `Connection` Class**
    - **Description:** In `lib/src/acp.dart`, implement the base `Connection` class to manage the JSON-RPC communication.
    - **Reference:** [`typescript/acp.ts`](https://github.com/zed-industries/agent-client-protocol/blob/main/typescript/acp.ts) (see `Connection` class).

- [X] **Task 2.4: Define `Agent` and `Client` Interfaces**
  - **Description:** In `lib/src/acp.dart`, define the `Agent` and `Client` abstract classes (interfaces).
  - **Reference:** [`typescript/acp.ts`](https://github.com/zed-industries/agent-client-protocol/blob/main/typescript/acp.ts) (see `Agent` and `Client` interfaces).

- [X] **Task 2.5: Implement `AgentSideConnection`**
  - **Description:** In `lib/src/acp.dart`, implement the `AgentSideConnection` class.
  - **Reference:** [`typescript/acp.ts`](https://github.com/zed-industries/agent-client-protocol/blob/main/typescript/acp.ts) (see `AgentSideConnection` class).

- [X] **Task 2.6: Implement `ClientSideConnection`**
  - **Description:** In `lib/src/acp.dart`, implement the `ClientSideConnection` class.
  - **Reference:** [`typescript/acp.ts`](https://github.com/zed-industries/agent-client-protocol/blob/main/typescript/acp.ts) (see `ClientSideConnection` class).

- [X] **Task 2.7: Implement `TerminalHandle`**
    - **Description:** In `lib/src/acp.dart`, implement the `TerminalHandle` class.
    - **Reference:** [`typescript/acp.ts`](https://github.com/zed-industries/agent-client-protocol/blob/main/typescript/acp.ts) (see `TerminalHandle` class).

- [X] **Task 2.8: Write Core Logic Unit Tests**
    - **Description:** In `test/acp_test.dart`, write unit tests for the `Connection`, `AgentSideConnection`, `ClientSideConnection`, and `TerminalHandle` classes.
    - **Reference:** [`typescript/acp.test.ts`](https://github.com/zed-industries/agent-client-protocol/blob/main/typescript/acp.test.ts)

## Phase 3: Examples & Documentation

- [X] **Task 3.1: Create Example Agent**
    - **Description:** In `example/agent.dart`, implement a minimal agent using the SDK.
    - **Reference:** [`typescript/examples/agent.ts`](https://github.com/zed-industries/agent-client-protocol/blob/main/typescript/examples/agent.ts)

- [x] **Task 3.2: Create Example Client**
    - **Description:** In `example/client.dart`, implement a minimal client that spawns and communicates with the example agent.
    - **Reference:** [`typescript/examples/client.ts`](https://github.com/zed-industries/agent-client-protocol/blob/main/typescript/examples/client.ts)

- [ ] **Task 3.3: Write `README.md`**
    - **Description:** Write the main `README.md` for the project, including an overview, installation instructions, and usage examples.
    - **Reference:** [`typescript/README.md`](https://github.com/zed-industries/agent-client-protocol/blob/main/typescript/README.md)

- [ ] **Task 3.4: Generate API Documentation**
    - **Description:** Use `dart doc` to generate API documentation for the library.
    - **Reference:** N/A (Dart ecosystem tooling)
