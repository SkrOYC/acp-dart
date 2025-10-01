# Research Summary: Creating a Dart SDK for the Agent Client Protocol (ACP)

## 1. Overview

This document outlines the research and planning for creating a new Dart SDK for the Agent Client Protocol (ACP). The goal is to provide a robust and easy-to-use library for Dart developers to build ACP-compliant agents and clients. The plan is based on a thorough analysis of the existing TypeScript ACP implementation and research into the best practices and tools available in the Dart ecosystem.

## 2. Project Structure

The project will follow the standard Dart package layout:

```
acp_dart/
├── lib/
│   ├── src/
│   │   ├── acp.dart
│   │   ├── schema.dart
│   │   └── stream.dart
│   └── acp_dart.dart
├── test/
│   ├── acp_test.dart
│   └── schema_test.dart
├── example/
│   ├── agent.dart
│   └── client.dart
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

- **`lib/`**: The main source code of the library.
- **`test/`**: Unit tests for the library.
- **`example/`**: Example agent and client implementations.
- **`pubspec.yaml`**: The package manifest, including dependencies.
- **`analysis_options.yaml`**: Linter configuration.
- **`README.md`**: Project documentation.

## 3. Core Components

The SDK will be composed of the following core components, mirroring the structure of the TypeScript implementation:

### 3.1. Schema

-   **Description:** All ACP messages (requests, responses, notifications) will be defined as Dart classes. This will provide a strongly-typed API for developers.
-   **Implementation:** The `json_serializable` package will be used to automate the conversion of these Dart objects to and from JSON. Each class will be annotated with `@JsonSerializable()`, and the `build_runner` will be used to generate the necessary serialization/deserialization code. This approach will ensure that the Dart implementation is consistent with the ACP specification and easy to maintain.

### 3.2. Connections

-   **Description:** The `AgentSideConnection` and `ClientSideConnection` classes will manage the communication logic for the agent and client, respectively. They will provide a high-level API for sending and receiving ACP messages.
-   **Implementation:** These classes will encapsulate the JSON-RPC communication over a stream. They will use the schema classes to serialize and deserialize messages.

### 3.3. Interfaces

-   **Description:** Abstract `Agent` and `Client` classes will define the methods that developers need to implement for their agents and clients. This will ensure that all agents and clients built with the SDK are compliant with the ACP specification.
-   **Implementation:** These will be abstract classes with methods corresponding to the ACP methods (e.g., `initialize`, `newSession`, `prompt`).

### 3.4. Stream Handling

-   **Description:** A utility for handling newline-delimited JSON (NDJSON) streams will be implemented. This is the standard transport mechanism for ACP.
-   **Implementation:** This will be a Dart `StreamTransformer` that can be used to transform a raw byte stream into a stream of ACP messages.

## 4. Dependencies

The following dependencies will be used:

-   **`json_annotation`**: Annotations for `json_serializable`.
-   **`json_serializable`**: (dev dependency) For generating JSON serialization/deserialization code.
-   **`build_runner`**: (dev dependency) For running code generators.
-   **`test`**: (dev dependency) For writing unit tests.
-   **`lints`**: (dev dependency) For code linting.

## 5. Development Plan

The development will proceed in the following phases:

1.  **Project Setup:** Create the project structure and configure the dependencies.
2.  **Schema Implementation:** Define all the ACP schema classes in Dart and generate the serialization code.
3.  **Core Logic Implementation:** Implement the `Connection`, `AgentSideConnection`, `ClientSideConnection`, and `TerminalHandle` classes.
4.  **Interface Definition:** Define the `Agent` and `Client` abstract classes.
5.  **Stream Handling:** Implement the NDJSON stream transformer.
6.  **Example Implementation:** Create the example agent and client.
7.  **Testing:** Write comprehensive unit tests for all components.
8.  **Documentation:** Write the `README.md` and API documentation.

## 6. Conclusion

This plan provides a clear path forward for creating a high-quality Dart SDK for the Agent Client Protocol. By leveraging the existing TypeScript implementation and the best practices of the Dart ecosystem, we can create a library that is both powerful and easy to use.
