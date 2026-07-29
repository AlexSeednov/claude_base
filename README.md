# claude_base

Shared **Claude Code** configuration for Flutter/Dart clean-architecture
projects. Kept in one place and reused across projects, so a change is made once
here instead of being copy-pasted into every repository.

The repository plays two roles at the same time:

- a **plugin marketplace** (`claude-base`) that distributes the **`flutter-base`
  plugin** — test skills and Telegram notification hooks;
- a store of **always-on instruction files** (`instructions/`) that a project's
  `CLAUDE.md` pulls in with `@import`.

These are two different delivery channels because they carry two different kinds
of thing. A plugin distributes executable tooling (skills, hooks, commands) and
updates cleanly through `/plugin update`. Instruction files are always-on context
and must be `@import`ed into `CLAUDE.md` — a Claude Code plugin does **not** load
a `CLAUDE.md`, and skills load on demand rather than always. So the same
repository serves both, through the two mechanisms described below.

## What is not here

Project-specific configuration stays in each project and is intentionally **not**
part of this base:

- the project's own `CLAUDE.md`, and any project instruction file it imports
  (design links, API endpoints, project-only rules);
- `.claude/settings.local.json` (machine-local, holds secrets such as the
  Telegram token — see [Telegram hooks](#telegram-hooks));
- project-specific `settings.json` entries (enabled MCP servers, project-only
  permission or exclude paths).

## Repository layout

```text
claude_base/
├── .claude-plugin/
│   └── marketplace.json          # marketplace catalog: lists the flutter-base plugin
├── plugin/                       # the flutter-base plugin (marketplace "source": "./plugin")
│   ├── .claude-plugin/
│   │   └── plugin.json           # plugin manifest (name, version, metadata)
│   ├── hooks/
│   │   └── hooks.json            # Stop + PreToolUse hooks, paths via ${CLAUDE_PLUGIN_ROOT}
│   ├── scripts/                  # hook implementations
│   │   ├── dispatch.js           # cross-platform launcher (picks .sh on Unix, .ps1 on Windows)
│   │   ├── telegram-notify.sh    # Stop notification (Unix)
│   │   ├── telegram-notify.ps1   # Stop notification (Windows)
│   │   ├── telegram-waiting.sh   # PreToolUse notification (Unix)
│   │   ├── telegram-waiting.ps1  # PreToolUse notification (Windows)
│   │   ├── project-name.sh       # project-name resolver shared by both hooks (Unix)
│   │   └── project-name.ps1      # project-name resolver shared by both hooks (Windows)
│   └── skills/                   # auto-discovered when the plugin is installed
│       ├── dart-add-unit-test/
│       ├── dart-checks-assertions/
│       ├── dart-collect-coverage/
│       ├── flutter-add-widget-test/
│       ├── flutter-add-integration-test/
│       ├── flutter-refactor-audit/
│       └── flutter-test-doubles/
├── instructions/                 # always-on context, consumed via @import (NOT part of the plugin)
│   ├── global.md
│   ├── architecture.md
│   ├── dart-conventions.md
│   ├── packages.md
│   └── layers.md
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## Quick start

Two independent steps per project. Do them once; updates are covered under
[Updating](#updating).

1. **Install the plugin** (skills + hooks) — once per machine, then enable per
   project. See [Plugin](#plugin).
2. **Wire the instructions** into the project's `CLAUDE.md` — see
   [Instructions](#instructions).

## Plugin

The `flutter-base` plugin is distributed through the `claude-base` marketplace,
which is just this git repository.

### Install manually

On each machine, once:

```text
/plugin marketplace add https://github.com/AlexSeednov/claude_base.git
/plugin install flutter-base@claude-base
```

`/plugin marketplace add` registers the catalog; `/plugin install` fetches the
plugin into the local plugin cache. Marketplace registration is per user (stored
in `~/.claude/plugins/known_marketplaces.json`), so it covers every project on
that machine.

The repository is public, so no authentication is needed. A private repository
would work the same way, cloned with your existing git credentials.

### Enable automatically for a project (recommended, team-ready)

Commit this to the project's `.claude/settings.json` so anyone who trusts the
project folder is prompted to add the marketplace and gets the plugin enabled
automatically:

```json
{
  "extraKnownMarketplaces": {
    "claude-base": {
      "source": {
        "source": "github",
        "repo": "AlexSeednov/claude_base"
      }
    }
  },
  "enabledPlugins": {
    "flutter-base@claude-base": true
  }
}
```

`enabledPlugins` keys the plugin by its `name@marketplace` identifier. Do not
rename the plugin or marketplace afterwards — that key is how every install
references it.

## Instructions

The five files in `instructions/` are always-on context. A project's `CLAUDE.md`
pulls them in with `@import`. Pick one of the two delivery options below; both
end with `CLAUDE.md` importing the same file set.

The first time Claude Code sees an external import in a project it shows a
one-time approval dialog listing the files.

### Option A — import from a local clone (single source, simplest across machines)

Clone this repository once per machine to a stable, home-relative path (next to
your other packages), then import from it. Recommended when you mostly work solo
across several computers: one `git pull` updates the instructions for every
project at once.

```bash
git clone https://github.com/AlexSeednov/claude_base.git ~/Projects/Packages/claude_base
```

In each project's `CLAUDE.md`:

```text
@~/Projects/Packages/claude_base/instructions/global.md
@~/Projects/Packages/claude_base/instructions/architecture.md
@~/Projects/Packages/claude_base/instructions/dart-conventions.md
@~/Projects/Packages/claude_base/instructions/packages.md
@~/Projects/Packages/claude_base/instructions/layers.md

@.claude/project.md
```

Keep the clone path identical across your machines (and for teammates) so the
`~/`-relative imports resolve everywhere. The project repository alone is not
self-contained under this option — a fresh checkout needs the clone present.

### Option B — vendor via git subtree (self-contained, best for teams / CI)

Embed a copy of this repository inside the project under `.claude/base/`, so a
plain `git clone` of the project already contains the instructions (works for
teammates and CI with no extra setup). The trade-off is that updates need a
subtree pull plus a commit in each project, which also pins the instructions to a
known version.

```bash
# once, to add:
git subtree add --prefix .claude/base \
  https://github.com/AlexSeednov/claude_base.git main --squash
```

In each project's `CLAUDE.md`:

```text
@.claude/base/instructions/global.md
@.claude/base/instructions/architecture.md
@.claude/base/instructions/dart-conventions.md
@.claude/base/instructions/packages.md
@.claude/base/instructions/layers.md

@.claude/project.md
```

> A skill in the plugin references instruction files by the project-relative path
> `.claude/instructions/...`. If you rely on those references, either keep an
> `instructions` copy at that path or adjust the reference — Option A/B above use
> `~/...` and `.claude/base/...` respectively.

## Telegram hooks

The plugin ships two hooks that send a Telegram message:

- **`Stop`** — when a session finishes (`telegram-notify`). The message includes
  the first user prompt as a session name.
- **`PreToolUse`** with matcher `AskUserQuestion` — when Claude asks a clarifying
  question and is waiting on you (`telegram-waiting`).

`dispatch.js` is the entry point in both: it runs the `.sh` implementation on
Unix and the `.ps1` on Windows, so one command string in `hooks.json` works on
every platform.

### Message format

Every message opens with a status icon and the project name, so a phone showing
several sessions at once stays readable:

```
✅ Claude: Stitchy — Convert the palette loader to a repository
✅ Claude: Stitchy done          # session with no prompt to quote
❓ Claude: Stitchy — Question
⚠️ Claude: Stitchy — Approval: git push --force
```

Editing this format carries one constraint: the `.ps1` scripts must stay **pure
ASCII** and build their glyphs from code points (`[char]0x2705`), as they do
now. Windows PowerShell 5.1 reads a BOM-less script in the system ANSI codepage,
where a pasted literal glyph can decode into a character that terminates the
surrounding string and kills the hook with a parser error — this is exactly what
broke every Windows notification in 0.0.3. The `.sh` variants take literals
as-is.

### Project name

`project-name.sh` / `.ps1` resolve the name, first match wins:

1. the `CLAUDE_PROJECT_NAME` environment variable;
2. `name:` from `pubspec.yaml` in the session's working directory;
3. the name of that directory;
4. `Unknown project`.

Steps 2–3 need no setup at all. Set the variable when the package/folder name is
not what you want to read on your phone (`cross_stitch` → `Stitchy`) — in the
`env` block of the project's `.claude/settings.local.json`:

```json
{
  "env": {
    "CLAUDE_PROJECT_NAME": "Stitchy"
  }
}
```

### Credentials

The scripts read two environment variables and contain **no secrets**:

- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_CHAT_ID`

If either is missing, every hook silently passes through and never blocks the
session. Set them once per machine in the `env` block of your user settings
(`~/.claude/settings.json`) or, if you prefer to keep them out of a shared file,
in a project's gitignored `.claude/settings.local.json`:

```json
{
  "env": {
    "TELEGRAM_BOT_TOKEN": "…",
    "TELEGRAM_CHAT_ID": "…"
  }
}
```

Never commit the token. Keep it in a gitignored or user-level settings file.

### Optional: also notify before dangerous shell commands

`telegram-waiting` also knows how to notify before a risky `Bash` command
(`rm`, `git push --force`, `--no-verify`, …), but the shipped matcher only covers
`AskUserQuestion`. To enable the Bash path, add `|Bash` to the `PreToolUse`
matcher in `plugin/hooks/hooks.json`:

```json
{ "matcher": "AskUserQuestion|Bash", "hooks": [ /* … */ ] }
```

## Skills

All skills auto-load once the plugin is installed and appear as
`flutter-base:<name>`.

| Skill                          | Purpose                                                                            |
| ------------------------------ | ---------------------------------------------------------------------------------- |
| `dart-add-unit-test`           | Unit tests for pure-Dart domain/core logic; DI via the `@visibleForTesting` ctor.  |
| `dart-checks-assertions`       | Prefer `package:checks` (`check(x).equals(y)`) over raw `expect`/matchers.          |
| `dart-collect-coverage`        | Collect LCOV coverage, excluding generated code.                                    |
| `flutter-add-widget-test`      | Component/widget tests with `WidgetTester` and `ValueListenableBuilder`-driven UI.  |
| `flutter-add-integration-test` | End-to-end flows with `integration_test` across flavors.                            |
| `flutter-refactor-audit`       | Audit committed code: layer violations, duplication, dead code, convention breaches. Re-verifies findings, answers with a must-do and a worth-doing list. |
| `flutter-test-doubles`         | Test doubles and getIt/injectable wiring; prefer fakes over mocks.                  |

## Singletons and dependency injection

This is the canonical reference that `instructions/dart-conventions.md` points to.

Singleton lifetime is owned by **getIt** (`@lazySingleton` / `@singleton`), never
a manual `static final _instance`. Dependencies come through the **constructor**
(constructor injection), not `getIt<T>()` calls in the body. The constructor is
marked `@visibleForTesting`: outside tests the analyzer forbids creating a second
instance, while a test builds an isolated instance with fakes. `getIt.reset()`
genuinely recreates the object between tests, so no state leaks.

```dart
/// First-level model: owns one domain area through its repository.
@lazySingleton
final class AccountModel {
  /// Constructor injection. @visibleForTesting so the analyzer blocks a second
  /// instance in app code, while a test can build an isolated one with fakes.
  @visibleForTesting
  AccountModel(this._repository);

  /// Contract from the domain layer; the concrete impl is bound in the data
  /// layer via @LazySingleton(as: AccountRepository) and injected by codegen.
  final AccountRepository _repository;

  /// UI-facing state; views listen via ValueListenableBuilder.
  final ValueNotifier<AccountEntity?> account = ValueNotifier(null);

  /// Async setup after the first frame (addPostFrameCallback).
  Future<void> prepare(Duration timeStamp) async {
    account.value = await _repository.fetchAccount();
  }
}
```

- `@lazySingleton` is lazy, `@singleton` is eager. Registration is generated into
  `service_locator.config.dart` — never register manually.
- Do **not** use the legacy `_instance` + `factory .singleton()` pattern: dual
  control over the lifecycle (static + getIt) leaks state between tests.
- Services from `application_base` and `firebase_base` are injectable (external
  injectable modules wired into `@InjectableInit`) — take them via the
  constructor or via `getIt<T>()`. A dependency registered **outside** codegen
  (manual registration) cannot be constructor-injected — take it via `getIt<T>()`
  in the method body.

In a test, reset getIt, register fakes, then build the model through its
`@visibleForTesting` constructor:

```dart
setUp(() {
  getIt.reset();
  final repository = FakeAccountRepository();
  getIt.registerSingleton<AccountRepository>(repository);
  model = AccountModel(repository);
});
```

## Versioning

Use **semantic versioning with git tags**, the same convention as the other
packages on this stack (`application_base`, `firebase_base`). This is the
recommended answer to "tags, version branches, or changelog?": **tags plus a
changelog on a single `main` branch — not version-named branches.**

Three things move together on each release:

1. **`version` in `plugin/.claude-plugin/plugin.json`** — Claude Code resolves the
   plugin version from this field and uses it for update detection: `/plugin
   update` only pulls when the string changes. Bump it on every release. (Set the
   version in `plugin.json` only, never also in the marketplace entry — the
   manifest value silently wins and a stale one would mask it.)
2. **A git tag `vMAJOR.MINOR.PATCH`** — an immutable release marker, matching the
   other packages. It lets a project pin the marketplace or a subtree to an exact
   ref when needed.
3. **A `CHANGELOG.md` entry** — the human-readable history.

What the numbers mean for this repository:

| Bump      | When                                                                                                   |
| --------- | ------------------------------------------------------------------------------------------------------ |
| **MAJOR** | Breaking change: a convention/architecture rule that forces edits in projects, or removing/renaming a skill or hook (which breaks `enabledPlugins` keys and references). |
| **MINOR** | Additive: a new skill, a new instruction section, a new hook.                                           |
| **PATCH** | Wording fixes and script bug fixes with no behavioral change for consumers.                             |

The instruction files are versioned by the same tags, since they live in the same
repository. Option A (local clone) tracks whatever branch/tag the clone is on;
Option B (subtree) pins each project to the commit it vendored.

**Alternative — rolling / commit-SHA versioning.** During heavy churn you can omit
the `version` field entirely; Claude Code then treats every commit as a new
version and `/plugin update` always pulls `main`. It is the lowest-ceremony
setup, but gives no named releases or pinning. Prefer tagged semver once the base
stabilizes, so releases are traceable like your other packages.

Avoid version-named branches. Release channels in Claude Code are built from
distinct resolved versions (tags/SHAs), not branch names, and add complexity that
a solo/small-team base does not need.

## Updating

Per machine, after a new release is pushed:

```text
/plugin marketplace update claude-base
/plugin update flutter-base@claude-base
```

Instructions:

- **Option A (local clone):** `git pull` in `~/Projects/Packages/claude_base` —
  every project that imports from it follows immediately.
- **Option B (subtree):** in each project,
  `git subtree pull --prefix .claude/base https://github.com/AlexSeednov/claude_base.git main --squash`,
  then commit.

## Adding to the base

- **A new skill:** create `plugin/skills/<name>/SKILL.md` with `name` and
  `description` frontmatter. It auto-loads on the next session after the plugin
  updates.
- **A new instruction rule:** edit a file in `instructions/`, or add a new file
  and reference it from consuming `CLAUDE.md` files.
- **A new hook:** add the implementation under `plugin/scripts/` and wire it in
  `plugin/hooks/hooks.json` using `${CLAUDE_PLUGIN_ROOT}` for the path.

Then bump the version, add a `CHANGELOG.md` entry, commit, tag, and push. Run
`claude plugin validate ./plugin` to check the manifest, skill/hook frontmatter,
and `hooks.json` before publishing.

Keep everything in this repository in **English**, and free of any single
project's names or details — those belong in the consuming project, not the base.
