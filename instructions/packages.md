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
  - It takes a nullable `url` and falls back to a placeholder on `null`, on an empty
    string and on a load error; `cacheKey` identifies the cached entry.
  - Auth headers, where a project sends them at all, are composed **here and nowhere
    else** — that single place is the point of the widget.
  - Everything past that is per-project: the rest of the constructor surface, any named
    constructors, what the default placeholder is, and whether auth headers are used.
    Read it off the widget, and keep what's worth writing down in `project.md` — not
    here, where it would only describe one project.

## pubspec.yaml Rules

- Alphabetical order within `dependencies` / `dev_dependencies`.
- Comment with supported platforms above each dependency.
- Exact versions (`1.2.3`, not `^1.2.3`).
- Dev dependencies — for build only, never import in `lib/`.
- `dependency_overrides` must be documented with an explanation of the conflict.
