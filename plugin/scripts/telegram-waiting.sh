#!/usr/bin/env bash
# Sends a Telegram notification when Claude needs user input or is about to run a
# dangerous command (PreToolUse hook). macOS/Unix port of telegram-waiting.ps1.
# Fires for: AskUserQuestion, Bash (dangerous patterns only). Requires: curl, jq.
# Required env vars: TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID.

set -u

# Fallback definition: if the helper is missing the hook must still notify.
resolve_project_name() { printf '%s' 'Unknown project'; }
# shellcheck source=./project-name.sh
. "$(dirname "$0")/project-name.sh" 2>/dev/null || true

input_json="$(cat)"

token="${TELEGRAM_BOT_TOKEN:-}"
chat_id="${TELEGRAM_CHAT_ID:-}"

if [ -z "$token" ] || [ -z "$chat_id" ]; then
  printf '%s' '{"continue":true}'
  exit 0
fi

tool_name="$(printf '%s' "$input_json" | jq -r '.tool_name // empty' 2>/dev/null)"
project="$(resolve_project_name "$(printf '%s' "$input_json" | jq -r '.cwd // empty' 2>/dev/null)")"
text=""

case "$tool_name" in
  AskUserQuestion)
    # Claude is asking a clarifying question.
    text="❓ Claude: $project — Question"
    ;;
  Bash)
    cmd="$(printf '%s' "$input_json" | jq -r '.tool_input.command // empty' 2>/dev/null)"
    # Only notify for commands matching dangerous patterns.
    dangerous='^[[:space:]]*(rm|rmdir|del|kill|curl|wget|eval|chmod|chown|Remove-Item)\b|^[[:space:]]*git[[:space:]]+(push|reset|rebase|cherry-pick|merge|clean)\b|--force|--no-verify'
    if printf '%s' "$cmd" | grep -Eq "$dangerous"; then
      short="$cmd"
      if [ "${#short}" -gt 60 ]; then
        short="${short:0:60}..."
      fi
      text="⚠️ Claude: $project — Approval: $short"
    fi
    ;;
esac

# Not our case — silently pass through.
if [ -z "$text" ]; then
  printf '%s' '{"continue":true}'
  exit 0
fi

body="$(jq -nc --arg chat "$chat_id" --arg text "$text" '{chat_id: $chat, text: $text}')"

curl -s -m 10 -X POST "https://api.telegram.org/bot$token/sendMessage" \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d "$body" >/dev/null 2>&1 || true

printf '%s' '{"continue":true}'
exit 0
