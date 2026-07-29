# Changelog

All notable changes to this repository are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). See the README,
section "Versioning", for what MAJOR / MINOR / PATCH mean here.

## [0.0.4]

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
