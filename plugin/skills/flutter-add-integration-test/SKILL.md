---
name: flutter-add-integration-test
description: Add end-to-end integration tests with the integration_test package that drive real user flows on a device/simulator across flavors. Use when validating whole flows (auth, booking) rather than a single widget.
---

# Integration tests

End-to-end flows against the real app. Not yet set up in this project — bootstrap first.

## One-time setup

- Add dev deps (respect `pubspec.yaml` rules: alphabetical, exact versions, platform comment):
  ```bash
  fvm flutter pub add 'dev:integration_test:{"sdk":"flutter"}'
  ```
  `flutter_test` is already a dev dep.
- Create `integration_test/` at the project root; files `_test.dart`.

## Authoring

- `IntegrationTestWidgetsFlutterBinding.ensureInitialized();` at the top of `main()`.
- Pump the real root widget (the same one the flavor entry points pass to `launchApplication`).
  DI must be initialized — call the app's bootstrap, or register the needed `getIt` services with
  fakes for network isolation (prefer fakes for deterministic runs; see the test-doubles skill).
- Add `Key`s (`ValueKey('...')`) to the widgets a flow targets.
- Interact with `WidgetTester` (`tap`, `enterText`, `pumpAndSettle`), assert with `find` + `findsOneWidget`/`findsNothing`.

## Running (flavored app)

Integration tests need a running device/simulator and the flavor wiring:

```bash
fvm flutter test integration_test --flavor development -t integration_test/app_test.dart
```

For performance traces or web, use `flutter drive` with a `test_driver/integration_test.dart`
host script calling `integrationDriver()`.

## Exploration via MCP

When the app is already running, use the Dart/Flutter MCP tools to inspect the live widget tree
and probe interactions before freezing them into a static test — faster than guessing `Key`s.

## Loop

Run → on `PumpAndSettleTimedOutException` check for infinite animations; on "widget not found"
add `scrollUntilVisible` or a `Key` → re-run until green.
