# Project Packages

## Internal Infrastructure Packages

These packages are the shared foundation for all projects on this stack.

- **application_base** — shared infrastructure: `getIt`, request/response types (`RequestGet`, `RequestPost`, `RequestDelete`, `ResponseEntity`), `SafeService`, flavor types, `launchApplication()`.

Used in the project (if connected):
- **firebase_base** — Firebase wrapper: init, Crashlytics, Analytics. Connect only when Firebase is present in the project.

## Key Architecture Packages

- **get_it** + **injectable** — DI. Annotations: `@lazySingleton`, `@singleton`, `@factoryMethod`, `@disposeMethod`.
- **auto_route** — routing. `@RoutePage()`. Generates `.gr.dart`.
- **rxdart** — reactive streams. `PublishSubject` in domain subjects.

## Serialization and Storage

- **json_annotation** / **json_serializable** — JSON serialization.
- **hive_ce** / **hive_ce_flutter** — local key-value storage.

## UI / Images

- **cached_network_image** — caching of network images. **Never use `Image.network`
  directly** — load every network image through the single `CachedNetworkImagePro`
  widget (`lib/presentation/view/widget/base/cached_network_image_pro.dart`).
  - The widget takes a nullable `url` (shows a placeholder on `null`/empty string and on
    load error), plus optional `defaultImage` (a custom placeholder instead of the default
    grey token backdrop), `cacheKey`, `fit`, `width`, `height`, `alignment`.
  - Whether to send auth headers is a per-project decision (see `project.md`). If needed,
    add headers here, in this one place.

## pubspec.yaml Rules

- Alphabetical order within `dependencies` / `dev_dependencies`.
- Comment with supported platforms above each dependency.
- Exact versions (`1.2.3`, not `^1.2.3`).
- Dev dependencies — for build only, never import in `lib/`.
- `dependency_overrides` must be documented with an explanation of the conflict.
