---
name: flutter-refactor-audit
description: Audit existing code for refactoring — architecture and layer violations, duplicated logic and widgets that should be unified, dead code, token/localization/convention breaches, non-optimal or wasteful widget, VM and domain code. Re-verifies every finding against the source, then answers with two lists — what must be fixed and what is worth fixing. Read-only; fixes only on request. Use when asked what to refactor, where the code is bad, unoptimized or duplicated, or to find architecture violations. Unlike `/simplify` and `/code-review` it covers committed code across the tree, not the working diff.
---

# Refactor audit

A standing audit of code that is already committed. `/simplify` and `/code-review` look at
the **working diff**; this looks at the **tree**. The output is a prioritized report of what
to refactor and why — not a rewrite.

The always-on instructions (`architecture`, `layers`, `dart-conventions`, `packages`,
`global`) are the rulebook; they are already in context. This skill is how to apply them
backwards, to code that already exists.

## 1. Pick a scope

`lib/` in a mature app is too large for one honest pass — a single sweep yields shallow,
generic findings. Audit one slice at a time and name the slice in the report:

- a **feature** across layers (`*/authorization/*` in `domain`, `data`, `presentation`);
- a **layer or folder** (`lib/presentation/view/widget/`, `lib/domain/model/`);
- a **cross-cutting theme** (design tokens, localization, error handling, DI).

If the user didn't name a slice, propose one and start there rather than boiling the ocean.

Exclude generated files everywhere: `.g.dart`, `.gr.dart`, `.gen.dart`, `.config.dart`,
`tokens.g.dart`, `app_localizations_*.dart`. A finding inside generated code is not a finding.

## 2. Let the analyzer go first

```bash
fvm flutter analyze
```

Do not hand-report what the analyzer already reports (unused imports, unnecessary null
checks, dead code it can see). The audit is about what static analysis **cannot** see:
structure, duplication, layering, and intent.

## 3. Deterministic sweep

Cheap, no judgment needed. Run these with the Grep tool over the chosen slice.

| Check | Pattern | Where |
| --- | --- | --- |
| `presentation` imports `data` | `/data/` in an import line | `lib/presentation/` |
| `domain` imports Flutter | `package:flutter/` | `lib/domain/` |
| `data` imports `presentation`/`theme` | `/presentation/`, `/theme/` | `lib/data/` |
| `theme` imports another layer | `/domain/`, `/data/`, `/presentation/` | `lib/theme/` |
| Raw network image | `Image\.network` | `lib/` |
| Legacy manual singleton | `static final _instance|factory \w+\.singleton` | `lib/` |
| Manual DI registration | `getIt\.register` | `lib/` outside the service locator |
| Global navigation from a VM | `pushScreen\(|popScreen\(|replaceAll\w*\(` | `lib/presentation/view_model/` |
| `setState` for VM-owned state | `setState\(` | `lib/presentation/` |
| Hardcoded color | `Color\(0x|Colors\.` | `lib/` outside `lib/theme/` |
| Hardcoded size / spacing / radius | `fontSize:\s*\d|EdgeInsets\.\w+\(\s*\d|BorderRadius\.circular\(\s*\d` | `lib/` outside `lib/theme/` |
| Raw asset path | `['"]assets/` | `lib/` outside `lib/theme/asset/` |
| Hardcoded UI string | `Text\(\s*['"]` | `lib/presentation/` |
| Rethrow discipline | `throw e;|catch \(_\) \{\s*\}` | `lib/` |
| Logging bypass | `print\(|debugPrint\(` | `lib/` |
| Deferred-work inventory | `TODO\(|Future\(|FIXME|HACK` | `lib/` |

Every hit is a **candidate, not a finding**. Grep cannot tell a token definition from a
hardcode, a doc comment from code, or a legitimate one-off `pushScreen` in a widget from a
VM violation. Open the file and confirm each one before it reaches the report.

## 4. Judgment pass

Read the files in the slice. This is where the real findings are.

**Architecture** — leaks grep misses: a VM calling a repository directly instead of going
through a model; a model formatting strings for the UI; an entity carrying business logic; a
missing second-level model, so one VM juggles five first-level ones; a screen's state living
in the widget instead of the VM.

**Unification** (usually the highest-value section) — report each as a *cluster*: the sites,
what they share, and the one thing they should become.
- Near-identical widgets differing only by a color, icon, or label → one parameterized widget.
- The same decoration/padding/border re-declared per screen → a shared widget or a theme extension.
- Repeated formatting (dates, durations, prices) where a shared utility already exists.
- Repositories repeating the same request/parse boilerplate.
- Copy-pasted `initState`/`dispose` lifecycle wiring → a mixin.
- Placement: a widget used by exactly one screen sitting in `view/widget/`, or a reused
  widget buried inside one screen's `widget/` folder.

**Presentation quality** — `ValueListenableBuilder` wrapping a whole screen when one `Text`
depends on it; logic or heavy work inside `build()`; a `StatefulWidget` where stateless +
listenable would do; oversized files and `build()` methods with no extracted subwidgets;
a scrollable server-data screen with no pull-to-refresh (see the Presentation layer rule).

**Cost** — code that is correct but wasteful: heavy computation (image/data processing, large
collection mapping) on the UI isolate instead of `compute`/an isolate; a value recomputed on
every `build()` that could be derived once; `ListView(children: [...])` where `.builder`
belongs; a missing `const` on a subtree that rebuilds often; a notifier that publishes a new
collection identity on every tick and rebuilds everything downstream; the same bundled asset
parsed or decoded repeatedly; a linear scan inside a loop where a lookup map already exists.
Report the cost in terms of what the user feels (a janky scroll, a slow screen open), not as
a micro-optimization for its own sake.

**Domain / data** — exceptions crossing a layer boundary instead of `null`/typed results;
parsing without the safe helper; a repository leaking DTOs instead of domain entities; a
`ValueNotifier` or subscription never disposed.

**Dead weight** — unreferenced widgets, VMs, entities, ARB keys, assets, and fakes;
commented-out code with no `Future(` marker explaining why it is parked.

**Conventions** — abbreviated names, missing `///` on declarations, wrong file suffixes,
`pubspec.yaml` ordering / version-pinning / undocumented `dependency_overrides`.

## 5. A documented deviation is not a violation

The rules allow deviations whose reason is written down: a literal carrying a
`// TODO(<github-username>):` that names the missing token, parked code behind a
`// Future(<github-username>):`, a comment stating the constraint or invariant. Those are
**not** findings and never enter either list — collect them in a short "documented deviations"
appendix after the report, so the user can judge whether the reason still holds. If there are
none, say nothing.

An **undocumented** deviation is a finding, but the right fix is sometimes "write down the
reason", not "change the code". Before calling anything a violation, check the project's own
`.claude/project.md` (and any project-specific instruction file) — intentional, approved
deviations from the design or the base rules are recorded there.

## 6. Re-verify before reporting

A first-pass finding is a hypothesis. Go through every one of them again, trying to **refute**
it, before any of it reaches the user:

- **Re-open the file at the cited line.** The symbol, the line number and the surrounding
  context must still say what the finding claims. Line numbers gone stale between reads are
  the most common way an audit reports something that isn't there.
- **Look for the counter-evidence.** Is the "duplicate" diverging on purpose, so merging it
  would couple two things that must move apart? Is the "dead" widget referenced from a route,
  a generated file, a test, or by name in a string? Does the literal already carry a `TODO(`
  naming the missing token? Is the deviation recorded in `.claude/project.md`? Grep the symbol
  across `lib/` **and** `test/` before calling anything unused.
- **Ask what breaks if nobody ever fixes it.** No answer means no finding — a rule cited with
  no consequence is noise, not a defect.
- **Merge duplicates.** One root cause reported once per file is one finding with N sites,
  not N findings.
- **Drop the hedges.** Anything that survives only as "probably" or "might be" either gets
  confirmed or leaves the report.

Say how many findings the pass removed. An audit that never drops anything did not re-check.

## 7. Report — two lists

Answer with **exactly two lists**, each sorted by value per unit of effort, and nothing
between them but their headings. Open with one line naming the audited slice.

**Must do** — the code is wrong, breaks a hard rule from the instructions, or is a defect
waiting to happen. Layer and import violations; a leaked `data` type in `presentation`;
exceptions crossing a boundary; an undisposed notifier or subscription; manual singletons or
manual DI registration; `setState` over VM-owned state; hardcoded UI strings, colors, sizes or
asset paths where localization and tokens exist; hand-edits to generated files; duplication
whose copies have already drifted apart, so a fix landing in one of them is a live bug;
undocumented deviations from the instructions.

**Worth doing** — the code works and breaks no hard rule, but structure, reuse or cost suffer.
Unification clusters; a widget sitting in the wrong folder for its reuse; an over-broad
`ValueListenableBuilder`; an oversized `build()` with no extracted subwidgets; dead code;
missing pull-to-refresh; naming, `///` comments, `pubspec.yaml` ordering; the cost findings
from the judgment pass unless they visibly hurt the user.

Every entry, in both lists, is one line: **what** — `file:line` — **why it matters** —
**suggested fix** — **effort (S/M/L)**. Unification clusters list every site. Anything that
moves or merges public structure is marked as needing the user's decision, not just their
approval to start.

Close with a coverage note: which slice was audited, what was skipped and why. A partial
audit reported as complete is worse than no audit.

## 8. Fixing

Read-only by default. Apply fixes only when the user asks (e.g. `--fix`, or after picking
items from the report). Then:

- one logical change at a time, minimal diff — integrate, don't rewrite;
- `fvm flutter analyze` and `fvm flutter test` after each change;
- one `changelog.md` line per logical change;
- anything that moves or merges public structure (extracting a shared widget, relocating a
  file, changing a model's shape) — confirm with the user before doing it.
