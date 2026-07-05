---
name: dart-collect-coverage
description: Collect test coverage for this Flutter app and produce an LCOV report, excluding generated code. Use when asked to measure coverage, find untested code, or gate a change on coverage.
---

# Test coverage

Flutter has coverage built in — no extra package needed for the app.

## Collect

```bash
fvm flutter test --coverage
```

Writes `coverage/lcov.info`. View it:

- HTML (needs `lcov`): `genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html`
- Or the IDE's coverage gutter from `coverage/lcov.info`.

## Exclude generated & untestable code

Generated files (`.g.dart`, `.gr.dart`, `.gen.dart`, `.config.dart`, `tokens.g.dart`,
`app_localizations_*.dart`) must not count toward coverage — they're already excluded from
analysis and shouldn't be tested. They only appear in `lcov.info` if a test imports/executes
them; keep them out of test imports. For code that legitimately can't be covered, use inline
directives:

- Single line: `// coverage:ignore-line`
- Block: `// coverage:ignore-start` … `// coverage:ignore-end`
- Whole file: `// coverage:ignore-file`

If you need to strip generated paths from an existing report, filter with `lcov --remove
coverage/lcov.info '*/*.g.dart' '*/*.gr.dart' ... -o coverage/lcov.info`.

## Loop

Run coverage → open the report → find red (untested) lines in real logic (ignore generated) →
add tests (see the unit/widget skills) → re-run.
