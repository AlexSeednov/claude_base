---
name: flutter-add-widget-test
description: Write component-level widget tests with WidgetTester — verify rendering, ValueListenableBuilder-driven UI, and user interactions (tap, scroll, text entry). Use when validating a screen or widget shows correct data and reacts to events.
---

# Widget tests

For `lib/presentation/` widgets and screens. See `.claude/instructions/layers.md` (Presentation)
and `project.md` (theme access). Business logic is tested in the unit-test skill, not here.

## Location & runner

- `test/presentation/...`, files `_test.dart`. Run: `fvm flutter test test/presentation/...`.
- Use `testWidgets('...', (tester) async { ... })` from `flutter_test`.

## Pump with real app scaffolding

Screens read theme tokens (`context.appTheme`), localization (`context.loc`), and Material
inherited widgets — pumping the widget bare will throw. Wrap it:

```dart
Future<void> pumpScreen(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        theme: getIt<ThemePro>().light, // registers AppThemePro in extensions
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
```

Adjust to the actual `ThemePro`/`AppLocalizations` API. Keep this helper in the test file (or a
shared `test/support/` helper) rather than re-inlining it.

## Provide the VM via getIt with fakes

Screens resolve their VM through `getIt<FeatureVM>()`. Register a fake (or a real VM built on
fake models) before pumping:

```dart
setUp(() {
  getIt.reset();
  getIt.registerSingleton<HomeVM>(FakeHomeVM());
});
tearDown(getIt.reset);
```

Drive UI by pushing values into the fake VM's `ValueNotifier`s, then `pump()`.

## Interactions

- Static render: `pumpScreen(...)` then `expect(find..., matcher)`.
- State change: `await tester.tap(finder)` → `await tester.pump()`.
- Animations/async: `await tester.pumpAndSettle()`.
- Text: `await tester.enterText(finder, '...')`. Off-screen list item: `scrollUntilVisible`.
- Prefer `find.byType`/`find.text`; add a `Key` in the widget when a target is otherwise ambiguous.

## Loop

`fvm flutter test <file>` → inspect failing `Finder`/matcher → fix widget or assertion → re-run.
