---
name: dart-add-unit-test
description: Write unit tests for pure-Dart domain/core logic (entities, models, services, utilities, extensions). Use when adding or changing business logic. Injects dependencies via the @visibleForTesting constructor and fakes, and resets getIt between tests.
---

# Unit tests (domain / core)

Covers pure-Dart logic in `lib/domain/` and `lib/core/`. UI belongs in the widget-test skill.
See `.claude/instructions/dart-conventions.md` (Singleton, DI, Lifecycle) and `layers.md`.

## Location & runner

- Mirror `lib/` under `test/`; suffix files `_test.dart` (`lib/domain/model/x/x_model.dart` → `test/domain/model/x/x_model_test.dart`).
- This is a single Flutter package: run everything through `fvm flutter test` (not `dart test`).
  - Whole suite: `fvm flutter test`
  - One file: `fvm flutter test test/domain/model/x/x_model_test.dart`
- Import `package:flutter_test/flutter_test.dart` (it re-exports `test`/`expect`/matchers). Only reach for bare `package:test` if a file has zero Flutter deps and you want it in a pure-Dart harness — rare here.

## Dependency injection in tests

Models/VMs are `getIt` singletons whose constructor is `@visibleForTesting` and takes its
dependencies (see the Singleton pattern in the README). In tests:

- **Build the SUT directly** via that constructor with fakes — do **not** pull the SUT from `getIt`.
- For collaborators the code fetches with `getIt<T>()` internally, register fakes first:
  ```dart
  setUp(() {
    getIt.reset();
    getIt.registerSingleton<AccountRepository>(FakeAccountRepository());
  });
  tearDown(getIt.reset);
  ```
- Use existing fakes from `lib/data/fake/` where present; otherwise write a small fake (see the test-doubles skill). Repositories return domain entities or `null` — never throw.

## State (ValueNotifier)

- Assert current state with `.value`.
- For reactions: mutate an input (or call a fake to emit), `await`/pump the microtask, then assert `.value`. Add/remove listeners are not needed for one-shot assertions.

## Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/model/account/account_model.dart';
// import the fake repository from lib/data/fake/ or a local fake

void main() {
  group('AccountModel', () {
    late FakeAccountRepository repository;
    late AccountModel model;

    setUp(() {
      repository = FakeAccountRepository();
      model = AccountModel(repository); // @visibleForTesting constructor
    });

    test('exposes null profile before load', () {
      expect(model.profile.value, isNull);
    });

    test('publishes the profile returned by the repository', () async {
      repository.profileToReturn = const AccountEntity(id: '1');
      await model.load();
      expect(model.profile.value?.id, '1');
    });
  });
}
```

## Loop

Run `fvm flutter test <file>` → read the failure → fix code or assertion → re-run until green.
