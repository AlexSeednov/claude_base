# Project Packages

## Internal Infrastructure Packages

These packages are the shared foundation for all projects on this stack.

- **application_base** — shared infrastructure: `getIt`, request/response types (`RequestGet`, `RequestPost`, `RequestDelete`, `ResponseEntity`), `SafeService`, flavor types, `launchApplication()`.

Used in the project (if connected):
- **firebase_base** — Firebase wrapper: init, Crashlytics, Analytics. Connect only when Firebase is present in the project.
- **metrica_base** — the Yandex counterpart of `firebase_base`: the `AnalyticsService` / `CrashReportingService` contracts with AppMetrica on mobile and the Yandex Metrica counter on the web, `AnalyticsNavigatorObserver` for screen views, `ErrorGroupUtility` for one error grouping on every platform. Connect only when the project reports to Yandex. What stays in the project:
  - **the keys** — AppMetrica API key and Metrica counter number, constants per flavor, handed over as a `MetricaConfig` to `MetricaBase.prepare()` right after DI init (on the web together with the cookie-consent gate, `MetricaConfig.webConsent`);
  - **the events registry** — a `sealed` family on top of the package's `AnalyticsEventBase` (`name`, `parameters`, and `keyActionCounter` for the key actions of the platform). Screen views and the service error event are package types, not registry members. A new event is a new class in the registry — the package never sees a fixed list;
  - **DI environments** — the package module is wired as an external module and its services are registered per environment: `getIt.init(environment: PlatformEnvironment.current)`.

  User identity goes to both services as a `String?`. The package's `docs/` hold the dashboards guide and the cookie-consent notes; a project describes only its own events and widgets on top of them.

These packages change **in their own repositories**, never through a patched local copy: change the package, add its `CHANGELOG.md` entry, bump the version, and let the user push and tag; the project then takes the new tag in `pubspec.yaml`. Until the tag exists a temporary `dependency_overrides` path entry is allowed — with a `TODO(<github-username>)` comment naming the tag that removes it.

## Key Architecture Packages

- **get_it** + **injectable** — DI. Annotations: `@lazySingleton`, `@singleton`, `@factoryMethod`, `@disposeMethod`.
- **auto_route** — routing. `@RoutePage()`. Generates `.gr.dart`.
- **rxdart** — reactive streams. `PublishSubject` in domain subjects.

## Serialization and Storage

- **json_annotation** / **json_serializable** — JSON serialization.
- **hive_ce** / **hive_ce_flutter** — local key-value storage. Stored data must survive every release:
  - where adapters are generated (`hive_ce_generator`), new `AdapterSpec` entries go **at the end only** of `@GenerateAdapters`, and `hive_adapters.g.yaml` — it pins the type and field ids — stays checked in and is never deleted or rebuilt from scratch;
  - box names and storage keys are frozen: renaming one silently orphans the data written under the old name;
  - a stored field is never renamed, repurposed or changed in type — add a new nullable field with a safe fallback and keep reading the old one; a record that fails to load is skipped and logged, never wiped.

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
