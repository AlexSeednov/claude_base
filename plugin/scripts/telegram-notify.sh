#!/usr/bin/env bash
# Sends a Telegram notification when Claude finishes a session (Stop hook).
# macOS/Unix port of telegram-notify.ps1. Requires: curl, jq.
# Required env vars: TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID.

set -u

# Fallback definition: if the helper is missing the hook must still notify.
resolve_project_name() { printf '%s' 'Unknown project'; }
# shellcheck source=./project-name.sh
. "$(dirname "$0")/project-name.sh" 2>/dev/null || true

input_json="$(cat)"

token="${TELEGRAM_BOT_TOKEN:-}"
chat_id="${TELEGRAM_CHAT_ID:-}"

# No credentials — silently pass through so the session is never blocked.
if [ -z "$token" ] || [ -z "$chat_id" ]; then
  printf '%s' '{"continue":true}'
  exit 0
fi

# Extract the transcript path from the hook payload.
transcript_path="$(printf '%s' "$input_json" | jq -r '.transcript_path // empty' 2>/dev/null)"

# Derive a session name from the first non-empty user message (JSONL transcript).
# Handles both transcript shapes: content as a plain string (older Claude Code)
# and content as an array of blocks where the prompt lives in a `text` block
# (VSCode extension / newer Claude Code). Tool-result user turns have no text
# block and are skipped.
session_name=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  session_name="$(jq -rs '
    [ .[]
      | select(.type == "user")
      | ( if (.message.content | type) == "string"
          then .message.content
          else ([.message.content[]? | select(.type == "text") | .text] | first)
          end )
      | select(. != null and ((gsub("\\s"; "")) | length) > 0)
    ] | (first // empty)
  ' "$transcript_path" 2>/dev/null)"
fi

project="$(resolve_project_name "$(printf '%s' "$input_json" | jq -r '.cwd // empty' 2>/dev/null)")"

if [ -n "$session_name" ]; then
  # Keep only the first line and cap the length, mirroring the Windows script.
  first_line="$(printf '%s' "$session_name" | head -n1)"
  first_line="${first_line#"${first_line%%[![:space:]]*}"}"
  first_line="${first_line%"${first_line##*[![:space:]]}"}"
  if [ "${#first_line}" -gt 100 ]; then
    first_line="${first_line:0:100}..."
  fi
  text="✅ Claude: $project — $first_line"
else
  text="✅ Claude: $project done"
fi

# Build the body via jq so Cyrillic and special characters stay valid JSON.
body="$(jq -nc --arg chat "$chat_id" --arg text "$text" '{chat_id: $chat, text: $text}')"

curl -s -m 10 -X POST "https://api.telegram.org/bot$token/sendMessage" \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d "$body" >/dev/null 2>&1 || true

printf '%s' '{"continue":true}'
exit 0
