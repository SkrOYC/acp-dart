# ACP Parity Verification Checklist

Use this checklist before each release to keep parity claims aligned with shipped behavior.

## 1) Method Inventory Verification

- Compare `agentMethods`, `clientMethods`, and `protocolMethods` in `lib/src/schema.dart` against current ACP stable and unstable method inventories.
- Confirm each method is represented in:
  - Connection dispatch logic (`lib/src/acp.dart`)
  - Typed unions (`lib/src/rpc_unions.dart`)
  - Tests (`test/acp_test.dart`, `test/rpc_unions_test.dart`)

## 2) Capability-Gated Surface Verification

- For optional methods, verify behavior when handler/capability is absent:
  - Expected JSON-RPC error is `-32601 Method not found` where appropriate.
- Verify extension method/notification pass-through semantics are unchanged.
- Verify `$/cancel_request` behavior on both connection sides.

## 3) Schema Variant Verification

- Verify session update discriminators handled by `SessionUpdateConverter` match expected parity targets.
- Add/refresh round-trip tests for any newly added request/response/update/content variants.
- Confirm unknown variant fallback behavior remains intact.

## 4) Documentation Sync

- Update `README.md` protocol matrix:
  - Stable supported
  - Unstable supported
  - Known unsupported/partial
- Ensure examples and installation version snippets are correct for the release.

## 5) Changelog Sync

- Ensure release notes include only verified implemented behavior.
- Mark unstable features explicitly as unstable.
- Remove or clarify any claims that exceed current implementation.

## 6) Validation Commands

- Run full tests:
  - `dart test`
- If schema/models changed, regenerate code and rerun tests:
  - `dart run build_runner build --delete-conflicting-outputs`
  - `dart test`
