# ACP parity verification checklist

Use this checklist before a package release. The comparison target is the ACP v1 entry point of [TypeScript SDK v1.5.0](https://github.com/agentclientprotocol/typescript-sdk/tree/v1.5.0). Keep draft ACP v2 separate.

## Method inventory

- Run `dart test test/upstream_v15_methods_test.dart test/rpc_unions_v15_test.dart`.
- Compare `agentMethods`, `clientMethods`, and `protocolMethods` with `src/schema/index.ts` in the pinned SDK tag.
- Verify each stable method has a dispatch path, a typed request or notification payload, a response model where applicable, and a connected-stream test.
- Mark experimental methods in public documentation. Keep `session/set_model` identified as a Dart legacy extension.

## Schema and wire behavior

- Run `dart test test/upstream_v1_5_fixture_integration_test.dart test/upstream_v1_5_schema_variants_integration_test.dart test/session_update_v15_integration_test.dart`.
- Check content, tool-call, permission, authentication, configuration, elicitation, and session-update variants against the pinned schema and Zod validators.
- Test required-field failures, optional fields, `_meta`, unknown extension fields, and JSON-RPC error codes.
- Regenerate `lib/src/schema.g.dart` after changing serializable models.

## Connected flows

- Run the process, app, HTTP, WebSocket, and server integration tests in `test/`.
- Exercise initialize, session creation, prompts, updates, permission callbacks, cancellation, stream closure, and request errors through connected peers.
- Check that optional handlers return `-32601 Method not found` when absent.
- Verify HTTP connection and session headers, SSE routing, WebSocket error recovery, and cookie handling.

## TypeScript interoperability

- Clone the official SDK at tag `v1.5.0` and install its dependencies with Bun.
- Follow [the interop test setup](tool/README.md) to run the actual TypeScript client against the Dart example agent.
- Record the pinned tag, test commands, and results in the release notes or pull request.

## Documentation and release checks

- Check the README support matrix, examples, installation command, and transport limits against the shipped code.
- Mark experimental APIs and local extensions explicitly in the changelog.
- Run the complete validation commands:

```sh
dart run build_runner build --delete-conflicting-outputs
dart analyze
dart test
```
