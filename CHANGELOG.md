# Changelog

All notable changes to this repository are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). See the README,
section "Versioning", for what MAJOR / MINOR / PATCH mean here.

## [0.1.1]

### Fixed

- Global, *Editing These Instructions*: the claim that a consuming project picks
  up instruction changes through `/plugin update` was wrong and sent everyone
  down a dead end. The plugin ships only skills and hooks; `instructions/` is
  imported by `CLAUDE.md` and never travels with it. The section now names the
  real path per import option and ends with the part that is easy to miss —
  `CLAUDE.md` imports are read once at session start, so the session must be
  restarted after an update.

### Changed

- Updating (README) and the new *Pulling an Update into a Project* subsection
  (Global): the subtree command is now a single copy-paste line that never opens
  an editor — `GIT_MERGE_AUTOEDIT=no` plus `-m`, because `git subtree` shells out
  to a plain `git merge --no-ff` and would otherwise stop in `$EDITOR` on a merge
  message that is already written. The `vim` escape hatch is spelled out for when
  it happens anyway, and the README now states up front that skills/hooks and
  instructions update by two separate steps.

## [0.1.0]

### Added

- Layers, Presentation: new section *Adaptive Layouts (mobile + desktop)*,
  explicitly scoped to projects that ship both designs — in a single-design
  project the plain `widget/` folder and no platform suffixes stay correct. A
  screen with two layouts splits its widgets into `widget/` (both layouts),
  `widget_mobile/` and `widget_desktop/`; the platform suffix goes **last**
  (`auth_body_desktop.dart` / `AuthBodyDesktop`, never `AuthDesktopBody`) so a
  sorted folder groups a widget with its own variants. The screen file keeps no
  layout of its own — VM lifecycle plus `LayoutSwitcher`, with both bodies as
  widgets rather than `_mobileScaffold()` methods on the `State`, since the
  asymmetry of "desktop extracted, mobile inline" is how the split rots. A
  widget reaches `widget/` only when both layouts actually use it, and a body
  serving both classes (a screen the desktop design does not cover yet) stays
  suffix-free because it is common, not mobile. Closes with the deduplication
  rule: share the leaves, and do not merge two layouts behind a pile of flags
  when the difference *is* the layout.
- Layers, Widget Rules: one widget per file, the file named after it. A private
  sub-widget that grew a layout of its own moves out and becomes public; only
  non-widget internals (`State`, `RenderObject`, `LayoutDelegate`, a storage
  `InheritedWidget`) stay beside their owner.

### Changed

- Dart conventions, Naming: the file/class rules now name the platform suffix
  and the one-widget-per-file naming link, pointing at the new Layers section.

## [0.0.5]

### Added

- New skill `flutter-refactor-audit`: a standing audit of already-committed code
  — layer and architecture violations, duplicated logic and widgets that should
  be unified, dead code, design-token / localization / convention breaches, and
  non-optimal or wasteful widget, VM and domain code. Scopes the pass to one
  slice of the tree, runs a deterministic grep sweep before the judgment pass,
  treats a deviation whose reason is written down as documented rather than
  broken, then re-verifies every finding against the source — trying to refute
  it — before reporting. The answer is two prioritized lists with verified
  `file:line` references: **must do** (a hard rule broken or a defect waiting to
  happen) and **worth doing** (structure, reuse or cost). Read-only unless fixes
  are requested. Complements `/simplify` and `/code-review`, which look at the
  working diff rather than the tree.

## [0.0.4]

### Fixed

- Telegram hooks on Windows: no notification was ever delivered. Windows
  PowerShell 5.1 reads a BOM-less `.ps1` in the system ANSI codepage, where the
  UTF-8 bytes of the em dash introduced in 0.0.3 decode to a typographic quote —
  PowerShell honours it as a string delimiter, so `telegram-notify.ps1` and
  `telegram-waiting.ps1` died with a parser error before sending anything. Both
  scripts are now pure ASCII and build their message glyphs from code points, so
  no future save can reintroduce the fault. macOS and Linux were never affected;
  they run the `.sh` variants. Message text is unchanged.
- `dispatch.js` no longer discards the hook script's stderr. A non-zero exit is
  now reported together with the captured output, and always as exit code 1 —
  never the blocking 2 — so a broken hook is visible instead of quietly doing
  nothing, and still cannot stall a session.

## [0.0.3]

### Added

- Telegram hooks: the project name now appears in every message, resolved from
  the `CLAUDE_PROJECT_NAME` environment variable, then `pubspec.yaml`, then the
  working directory name, falling back to `Unknown project`. New shared
  resolvers `plugin/scripts/project-name.sh` / `.ps1`.

### Changed

- Telegram hooks: messages now open with a status icon and the project name —
  `✅ Claude: Stitchy — <prompt>` on finish, `❓ Claude: Stitchy — Question` on a
  clarifying question, `⚠️ Claude: Stitchy — Approval: <command>` before a risky
  shell command. A finished session with nothing to quote reads
  `✅ Claude: Stitchy done` instead of `Claude session finished`.

## [0.0.2]

### Added

- `dart-conventions`: a distinct `// Future(<github-username>):` marker for
  deferred or temporarily hidden functionality (a parked feature, a
  commented-out screen/route, a control hidden until the backend is ready),
  kept separate from `// TODO` so deferred work is greppable on its own.
- `layers`: a **Pull-to-Refresh** rule under the Presentation layer — every
  screen that shows server-loaded data in a scroll view should reload all of
  its data through a shared `PullToRefreshPro` widget and a single VM
  `refresh()`, by default; lists the screens to skip (maps, static/stub
  screens, forms).
- `global`: an **Editing These Instructions** rule — changes to the instruction
  files must be made in this package, not in a project's vendored `.claude/base`
  copy, so they can be versioned, tagged, and rolled out via `/plugin update`.

## [0.0.1]

Initial extraction of the shared Claude Code configuration into a standalone
repository, so it can be maintained in one place and reused across projects.

### Added

- `flutter-base` plugin distributed through the `claude-base` marketplace:
  - Test skills: `dart-add-unit-test`, `dart-checks-assertions`,
    `dart-collect-coverage`, `flutter-add-widget-test`,
    `flutter-add-integration-test`, `flutter-test-doubles`.
  - Cross-platform Telegram notification hooks (`Stop`, `PreToolUse`) with a
    Node dispatcher that runs the bash or PowerShell implementation per OS.
- Always-on instruction files under `instructions/` (`global`, `architecture`,
  `dart-conventions`, `packages`, `layers`), consumed by a project's `CLAUDE.md`
  through `@import`.
