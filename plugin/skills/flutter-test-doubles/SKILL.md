---
name: flutter-test-doubles
description: Create test doubles and wire dependency injection for tests in this getIt + injectable codebase. Prefer fakes from lib/data/fake/ over mocks; register them in getIt and inject via the @visibleForTesting constructor. Use whenever a test needs to replace a repository, model, or service.
---

# Test doubles & DI setup

This stack favors **fakes over mocks**. The data layer already ships fake repository
implementations in `lib/data/fake/` (they implement the domain repository interfaces). Reuse
those; write a purpose-built fake only when none exists. `mockito` is a last resort.

## Injecting a double

Two paths, matching how the code obtains the dependency:

1. **Constructor (preferred).** Models/VMs expose a `@visibleForTesting` constructor taking their
   deps. Build the SUT with fakes directly — no `getIt` for the SUT itself:
   ```dart
   final model = BookingModel(FakeBookingRepository());
   ```
2. **getIt lookup.** For collaborators the code fetches via `getIt<T>()` internally, register the
   fake before building the SUT and reset afterwards:
   ```dart
   setUp(() {
     getIt.reset();
     getIt.registerSingleton<BookingRepository>(FakeBookingRepository());
   });
   tearDown(getIt.reset);
   ```
   `getIt.reset()` genuinely recreates singletons, so state never leaks between tests.

## Writing a fake

Implement the domain interface; return canned entities or `null` (honor the null-on-error
contract — fakes never throw across layers). Expose knobs to steer scenarios:

```dart
final class FakeBookingRepository implements BookingRepository {
  List<BookingEntity> bookingsToReturn = const [];
  bool failNext = false;

  @override
  Future<List<BookingEntity>?> fetchBookings() async =>
      failNext ? null : bookingsToReturn;
}
```

Put reusable fakes under `lib/data/fake/` (so app + tests share them) or, if test-only, under
`test/support/`.

## When a mock is justified

For a leaf collaborator with a wide surface where hand-writing a fake is wasteful, use `mockito`:
add `dev:mockito` (`build_runner` is already a dev dep), annotate `@GenerateNiceMocks([MockSpec<T>()])`,
run `fvm dart run build_runner build --delete-conflicting-outputs`, and stub async returns with
`thenAnswer((_) async => ...)` (never `thenReturn` for `Future`/`Stream`).
