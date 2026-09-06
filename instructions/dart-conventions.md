# Dart & Flutter: Code Conventions

## Naming

- **Files**: `snake_case.dart`. Role suffix: `_vm`, `_model`, `_entity`, `_service`, `_pro`. In a project with both a mobile and a desktop design, a platform-specific widget also carries `_mobile` / `_desktop` — always **last**, after the role suffix (see Layers → *Adaptive Layouts*).
- **Classes**: `PascalCase`. Prefer `final class`. Contracts — `abstract interface class`, base classes — `abstract base class`. A widget class is named after its file (`product_card_small.dart` → `ProductCardSmall`), and each file holds one widget.
- **Identifiers**: `lowerCamelCase`. Acronyms longer than 2 letters — treat as words: `HttpClient`, not `HTTPClient`.
- **Generated files**: `.g.dart`, `.gr.dart`, `.gen.dart`, `.config.dart` — declared via `part`, **never edit manually**.
- **No abbreviations**: `userRepository`, not `userRepo`; `backgroundColor`, not `bgColor`.

## Imports

1. Order: `dart:` → `package:` → relative → exports. Separate groups with a blank line, sort alphabetically within groups.
2. Follow the repository's existing import style; do not mix `package:` and relative paths.
3. `// MARK:` sections — only when the file contains the corresponding content. Preferred order: Singleton, Const, References, Notifiers, Data, Base functions, Functions.

## Singleton Pattern

> The canonical pattern (with a code example) lives in the `claude_base` README,
> section "Singletons and dependency injection". Below is the working summary; the
> README wins on any conflict.

Singleton lifetime is owned by **getIt** (`@lazySingleton`/`@singleton`), not a manual
`static final _instance`. Dependencies come through the **constructor** (constructor
injection), not `getIt<T>()` in the body. Mark the constructor `@visibleForTesting`:
outside tests the analyzer forbids creating a second instance, while a test builds an
isolated instance with fakes (`getIt.reset()` genuinely recreates the object between
tests). `@lazySingleton` — lazy, `@singleton` — eager; registration is codegen'd into
`service_locator.config.dart`. Do **not** use the legacy `_instance` + `factory
.singleton()`: dual control over the lifecycle (static + getIt) leaks state between tests.

> Services from `application_base`, `firebase_base` and `metrica_base` are injectable (external
> injectable modules wired into `@InjectableInit`) — take them via the constructor or via `getIt<T>()`.
> If a dependency is registered **outside** codegen (manual registration), injectable cannot
> inject it through the constructor — take it via `getIt<T>()` in the method body.

## Lifecycle

- `init()` — synchronous setup, called in `initState`.
- `prepare(Duration timeStamp)` — async initialization after first frame, via `addPostFrameCallback`.
- `dispose()` — resource cleanup.

## State Management

- Models expose state via `ValueNotifier<T>`. VMs subscribe to models and expose UI-ready notifiers.
- Views consume via `ValueListenableBuilder<T>`. Never use `setState()` for state managed by a VM.

## Dependency Injection

- Import getIt only from `package:application_base/core/service/service_locator.dart`.
- Obtain dependencies via `getIt<T>()`, not through widget constructors.
- All registration — via `injectable` annotations + codegen. No manual registration.
- Interface → implementation binding: `@LazySingleton(as: RepositoryInterface)` on the concrete class.
- After touching DI, check the graph with `fvm dart run application_base:getit_check`: **HIGH** cycles must stay at zero. A cycle is broken by turning one of its edges into a lazy `getIt<T>()` getter with a comment naming the cycle it closes — not by manual registration.

## Navigation

- From a VM, navigate **only through the injectable `NavigationServicePro`**
  (`_navigation.push(...)`, `replaceAll`, `pop`, …), not through the global top-level
  functions in `navigation_service.dart` (`pushScreen`/`popScreen`/…). This lets
  navigation branches be tested with a fake, without a mounted router.
- The global functions are the low-level layer: they are called by the
  `NavigationServiceRouter` implementation, by guards, and by one-off navigation in
  widgets, plus whatever is not in the contract (`unfocus`, `actualContext`,
  `actualRouter`, `pushNamed`, `navigatePath`). Do not use them from a VM.

## Error Handling

- Data layer catches external errors, returns `null` or a typed result — never propagates exceptions between layers.
- Use `rethrow`, not `throw e`. Log via core logging service.

## Code Style

- Prefer early returns over `else`. Use guard clauses.
- Prefer `async/await` over raw futures.
- Avoid positional boolean parameters — use named parameters.
- Prefer `final` for fields and variables that are not reassigned.
- Mark every temporary stub or unfinished bit of logic with a Flutter-style to-do: `// TODO(<github-username>): what to replace and under what condition`. No silent placeholders — a stub without a `TODO` is not allowed.
- Mark deferred or temporarily hidden functionality with a distinct marker: `// Future(<github-username>): why it's deferred and what brings it back`. Use it for code that is finished (or intentional) but deliberately held back — a parked feature, a commented-out screen or route, a control hidden until the backend is ready. This is **not** a `TODO`: `TODO` marks unfinished/stub logic that must be completed; `Future` marks working-or-intentional code that is postponed on purpose. Keeping the two markers separate makes all deferred functionality greppable (`Future(`) independently of unfinished work.
