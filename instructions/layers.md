# Layer Rules

## Core Layer (`lib/core/`)

The foundation, available to all layers. **Does not import any other layer.**

- `service/` — Service Locator (`service_locator.dart` + `service_locator.config.dart`), logging, SDK initialization.
- `pigeon/` — generated platform channel bindings. **Never edit manually.**
- `const/` — global constants (enums, static values shared across all layers).
- `utility/`, `mixin/` — shared helpers and mixins.

The logger interface and its base implementation live here. The concrete remote implementation (e.g., Crashlytics) lives in `data/`, bound via Service Locator. Custom exceptions used by multiple layers also go here.

---

## Domain Layer (`lib/domain/`)

Pure Dart. No Flutter imports. Only `core`. Dart packages (`json_annotation`, `hive_ce`, `rxdart`) are allowed.

### `entity/`
Simple data classes. No business logic.
- `@JsonSerializable()` with `createFactory`/`createToJson` only when needed.
- `@JsonKey(name: 'api_field_name')` for field mapping.
- Include `part 'entity.g.dart'`, `factory Entity.fromJson(...)`.
- Static `parse()` for safe parsing:
  ```dart
  static FeatureEntity? parse(ResponseEntity data) =>
      SafeService.parse<FeatureEntity>(data, FeatureEntity.fromJson);
  ```
- Group by feature: `authorization/`, `account/`, etc.

### `repository/`
Abstract interfaces (`abstract interface class`) — data contracts.
- Methods return domain entities or `null` (not exceptions).
- Implementations live in `data/`, annotated with `@LazySingleton(as: Interface)`.

### `model/`
Business logic singletons.
- **First level**: work with a specific domain area via repositories.
- **Second level**: orchestrate multiple first-level models.
- Expose state via `ValueNotifier<T>`. Implement `init()` / `prepare()`.
- Group by features, mirroring `entity/`.

### `subject/`
Reactive event buses (`rxdart` `PublishSubject`) for communication between models.
- `@lazySingleton` + `@disposeMethod` for closing streams.

### `service/`
Pure Dart services that don't fit a specific model.

### `enum/`, `extension/`, `mixin/`, `utility/`, `const/`, `localization/`
Enums, extensions, mixins, helpers, constants, and ARB files respectively.

---

## Data Layer (`lib/data/`)

Implements repository interfaces from `domain/`. Imports only `domain` and `core`.

### Structure
- `remote/repository/` — concrete repository implementations, `_remote` suffix (e.g., `AccountRepositoryRemote`).
- `remote/service/` — HTTP client, request/response handling.
- `remote/entity/` — DTOs for the remote API when they differ from domain entities.
- `remote/const/` — API paths and endpoint constants.
- `local/` — repository implementations (`_local` suffix), storage setup, adapters, migrations.
- `fake/` — fake repository implementations for development and testing.

### Request Pattern
```
Typed Request → RequestService → ResponseEntity → Entity.parse() → null on error
```

**Null on error**: return `null`/`false` instead of exceptions. Log errors inside the data layer.  
**Forbidden** to import `presentation` or `theme`. Register via `@LazySingleton(as: RepositoryInterface)`.

---

## Presentation Layer (`lib/presentation/`)

Imports `domain`, `core`, `theme`. **Never import `data`.**

### Structure
- `view/application.dart` — root widget (`MaterialApp.router`).
- `view/screen/` — screens grouped by feature. Each with `@RoutePage()` and a `widget/` subfolder.
- `view/subscreen/` — modal content (bottom sheets, dialogs).
- `view/widget/` — reusable widgets.
- `view_model/` — presentation logic singletons. Mirror the structure of `view/screen/`.
- `navigation/` — router config (`auto_route`), guards, observers.
- `service/` — presentation services: network monitoring, loading overlay, clipboard.
- `utility/` — `BuildContext` extensions: `context.loc`, `context.featureTheme`.

### Screen Lifecycle
```dart
final _vm = getIt<FeatureVM>();

@override
void initState() {
  super.initState();
  _vm.init();
  WidgetsBinding.instance.addPostFrameCallback(_vm.prepare);
}

@override
void dispose() {
  _vm.dispose();
  super.dispose();
}
```

### Widget Rules
- Prefer `StatelessWidget` + `ValueListenableBuilder` over `StatefulWidget` + `setState`.
- Use `const` constructors. Keep widgets small — extract subtrees into separate widgets.
- Use the `spacing` parameter **only when all gaps between children are equal**. When gaps differ, keep a flat `Row`/`Column` with `SizedBox` separators — do not nest widgets just to use `spacing`.
- A widget used by **only one screen** lives in that screen's `widget/` subfolder (`view/screen/<feature>/<screen>/widget/`). Put a widget in `view/widget/` **only** when it is reused across screens.
- Scope `ValueListenableBuilder<T>` as **narrowly as possible** to minimize rebuilds.
- No business/presentation logic in widgets — logic belongs in the VM.
- No heavy operations in `build()`.

---

## Theme Layer (`lib/theme/`)

Imports only `core` (or nothing).

- `color/` — color interfaces by widget/group. Concrete implementations in `extends/`.
- `font/` — font family definitions. Always **local fonts** from `assets/font/`.
- `size/` — size values grouped by purpose.
- `style/` — custom styles: decorations, shadows, borders, animations, text styles, button styles.
- `extends/` — `ThemeExtension<T>` subclasses with `_pro` suffix. Access via `context.featureTheme`.
- `asset/` — generated asset references (`flutter_gen_runner`). **Never use raw paths.**

### ThemeExtension Pattern
```dart
final class FeatureThemePro extends ThemeExtension<FeatureThemePro> {
  const FeatureThemePro({required this.background, required this.border});
  final Color background;
  final Color border;

  @override
  FeatureThemePro copyWith({Color? background, Color? border}) => ...;
  @override
  FeatureThemePro lerp(FeatureThemePro? other, double t) => ...;
}
```

The `_pro` suffix = a custom extension or override of a framework concept. Must be consistent across the entire project.

---

## Assets (`assets/`)

```
assets/
├── font/
├── image/          # Split by type (icon/gif) and domain (user/map/project)
├── logo/
│   ├── dark_theme/
│   └── light_theme/
├── application_icon/
│   ├── dark_theme/
│   └── light_theme/
└── video/
```

- **Never access assets by raw path.** Only via generated constants from `lib/theme/asset/`.
- Use local fonts — do not rely on online Google Fonts loading.
- After adding assets — regenerate (see Architecture → *Build and Codegen*).
