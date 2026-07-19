#!/usr/bin/env bash
# Resolves a display name for the current project, used in Telegram notifications.
# Sourced by telegram-notify.sh and telegram-waiting.sh — defines resolve_project_name().

# Prints the project name for the given project directory.
# Order: explicit CLAUDE_PROJECT_NAME → pubspec `name:` → directory name → fallback.
# The env var comes first so a project can override an ugly package/folder name
# ("cross_stitch") with the name it ships under ("Stitchy").
resolve_project_name() {
  local payload_cwd="${1:-}"

  if [ -n "${CLAUDE_PROJECT_NAME:-}" ]; then
    printf '%s' "$CLAUDE_PROJECT_NAME"
    return 0
  fi

  local dir="$payload_cwd"
  [ -z "$dir" ] && dir="${CLAUDE_PROJECT_DIR:-}"
  [ -z "$dir" ] && dir="$PWD"

  if [ -n "$dir" ] && [ -f "$dir/pubspec.yaml" ]; then
    local pubspec_name
    pubspec_name="$(grep -m1 -E '^name:[[:space:]]*' "$dir/pubspec.yaml" 2>/dev/null \
      | sed -E "s/^name:[[:space:]]*//; s/[[:space:]]*(#.*)?$//; s/^[\"']//; s/[\"']$//")"
    if [ -n "$pubspec_name" ]; then
      printf '%s' "$pubspec_name"
      return 0
    fi
  fi

  if [ -n "$dir" ] && [ "$dir" != "/" ]; then
    local base
    base="$(basename "$dir")"
    if [ -n "$base" ]; then
      printf '%s' "$base"
      return 0
    fi
  fi

  printf '%s' 'Unknown project'
}
