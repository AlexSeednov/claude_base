---
name: dart-checks-assertions
description: Assertion style for tests — prefer package:checks (check(x).equals(y)) over raw expect/matcher for readable, chainable failures. Use when writing new test assertions or converting expect(...) calls.
---

# Assertions with package:checks

Optional but preferred style: `package:checks` gives a fluent, chainable API and clearer failure
messages than `package:matcher`. Adopt it when first writing tests; add the dep on demand:

```bash
fvm flutter pub add dev:checks
```

Import `package:checks/checks.dart` in the test file (keep `flutter_test` for `testWidgets`,
`tester`, etc.).

## expect → check

| matcher                                    | checks                                                    |
| ------------------------------------------ | -------------------------------------------------------- |
| `expect(x, equals(y))` / `expect(x, y)`    | `check(x).equals(y)`                                      |
| `expect(x, isA<T>())`                      | `check(x).isA<T>()`                                       |
| `expect(list.length, 1)`                   | `check(list).length.equals(1)`                           |
| `expect(s, startsWith('a'))`               | `check(s).startsWith('a')`                               |
| `expect(x.prop, y)`                        | `check(x).has((e) => e.prop, 'prop').equals(y)`          |

Chain multiple checks on one subject with cascades:

```dart
check(user)
  ..has((u) => u.id, 'id').equals('1')
  ..has((u) => u.name, 'name').equals('Alex');
```

## Async

```dart
await check(future).completes((it) => it.equals(expected));
await check(future).throws<StateError>();
await check(streamQueue).emitsThrough((it) => it.equals('Ready'));
```

Note: `check` is for value/logic assertions. Widget-tree assertions still use `expect(finder,
findsOneWidget)` from `flutter_test`.
