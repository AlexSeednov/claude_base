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

## Enums

### Naming and placement

- Every enum ends with `Enum`: `ProductTypeEnum`, `PaymentStatusEnum`,
  `FieldErrorEnum`. No exception for enums whose name already reads like a type
  or a status (`TokenType`, `StreamingStatusType`) — the suffix is what tells an
  enum apart from an entity or a model at the call site. Where the old name
  carried a redundant noun, drop it instead of stacking:
  `StreamingStatusEnum`, not `StreamingStatusTypeEnum`.
- Enums live in an `enum/` folder **at the level that owns them** —
  `domain/enum/`, `presentation/enum/`, `data/<source>/enum/`. Not in `const/`
  among real constants, not inline in the file of their only user. The single
  exception is a **file-private** enum: it cannot leave its file without
  becoming public, so it stays beside its owner — and still takes the suffix.
- One enum per file, the file named after it (`product_type_enum.dart` →
  `ProductTypeEnum`). A file name that drifted from its enum is a rename waiting
  to happen: the next reader greps the name, not the path.
- `enum/` holds **enums only**. A sealed class hierarchy is not an enum — see
  Layers → Domain → `event/`.

### Extensions

- Presentation-side extensions live in `enum/enum_extension/`, one file per
  enum: `<enum>_enum_ext.dart` → `<Enum>EnumExt`.
- The human-readable label is always **`text`** — never `title`, `name`,
  `label`, `designation` or `caption`. One name across every enum means a call
  site reads the same whichever enum it holds; the synonyms carry no extra
  meaning and only cost a lookup. Everything else is named after what it
  returns: `icon`, `image`, `route`, `count(...)`.
- An enum declared in `domain/` keeps its localized or visual extension in
  `presentation/` — the domain imports neither Flutter nor localization.

### Enums that cross the API boundary

An enum decoded from a backend payload must survive the backend adding a value.
`json_serializable` throws on an unknown one, and that exception takes the
**whole entity** down with it — so decide per field:

- Nullable field plus `unknownEnumValue`, the default answer:

  ```dart
  @JsonKey(name: 'status', unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final PaymentStatusEnum? status;
  ```

  The record still parses and `null` means "the backend knows a value we do
  not". Handle it where the value is rendered — hide the badge, drop the row,
  keep polling — and say so in the field's doc comment.

- A **list** of enum values needs its own `fromJson`: the annotation covers a
  single value, so one unknown element still throws. Decode element by element
  and drop what is unknown:

  ```dart
  @JsonKey(name: 'meetingFormats', fromJson: _formatListFromJson)
  final List<ServiceFormatEnum>? formatList;

  ///
  static List<ServiceFormatEnum>? _formatListFromJson(List<dynamic>? value) =>
      value
          ?.map(
            (e) => $enumDecodeNullable(
              ServiceFormatEnum.jsonMap,
              e,
              unknownValue: JsonKey.nullForUndefinedEnumValue,
            ),
          )
          .nonNulls
          .toList();
  ```

  `$enumDecodeNullable` takes the map explicitly, so such an enum carries its
  own `static const jsonMap` alongside the `@JsonValue` annotations.

- Leaving a field **non-nullable is a deliberate choice**, allowed only where
  the record is useless without the value — a product whose type decides which
  screen opens it, a search hit whose type decides which half of the payload to
  read. There the throw is the feature: the safe-parse helper catches per item,
  so one unknown record is skipped and logged while the rest of the list
  survives. Write that reason in the field's doc comment, or the next pass over
  this rule will "fix" it.

- Enums that only travel **out** — request filters, paging parameters,
  `createToJson` with no factory — need none of this.

### Stored enums

An enum written to local storage is a schema, not just a name (Packages →
*Serialization and Storage*). Renaming the class renames the key the generator
pins the type id to: hand-edit the manifest to keep the old id, or every record
written under the old name is orphaned. Values are stored by index — add new
ones **at the end**, never reorder or delete.

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
- After touching DI, check the graph with `fvm dart run application_base:getit_check`: **HIGH** cycles (every edge eager — a certain stack overflow) must stay at zero. A cycle is broken by turning one of its edges into a lazy `getIt<T>()` getter with a comment naming the cycle it closes — not by manual registration. That leaves a **MEDIUM** cycle: make sure no constructor on it calls a method that takes the lazy edge.

## Navigation

- From a VM, navigate **only through the injectable `NavigationServicePro`**
  (`_navigation.push(...)`, `replaceAll`, `pop`, …), not through the global top-level
  functions in `navigation_service.dart` (`pushScreen`/`popScreen`/…). This lets
  navigation branches be tested with a fake, without a mounted router.
- The global functions are the low-level layer: they are called by the
  `NavigationServiceRouter` implementation, by guards, and by one-off navigation in
  widgets, plus whatever is not in the contract (`unfocus`, `actualContext`,
  `actualRouter`, `pushNamed`, `navigatePath`). Do not use them from a VM.

## Date and Number Formatting

- Format through `intl` (`DateFormat`, `NumberFormat`) **without a locale
  argument**. The language comes from `ApplicationLocale.resolve`
  (`application_base`), wired once as `localeListResolutionCallback` of the
  root `MaterialApp`: it makes the interface's locale the default of `intl`.
- Never pin a locale into a call (`DateFormat('d MMMM', 'ru')`) and never set
  `Intl.systemLocale` "for correct formatting". The pin hides the bug and has to
  be undone for each language added; the system locale *is* the bug —
  formatters then speak the device's language, not the interface's.
- A widget test that checks formatted text wires the same callback into its
  own `MaterialApp` (or sets `Intl.defaultLocale` in `setUp`), otherwise it
  formats in `en_US`.

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
