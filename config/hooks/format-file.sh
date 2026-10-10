#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit): best-effort auto-fix the edited file with
# the project's own tooling. Never blocks, never fails the tool call.
set -uo pipefail

payload="$(cat)"
f="$(printf '%s' "$payload" | jq -r '.toolCall.args.TargetFile // .toolCall.args.AbsolutePath // .tool_response.filePath // .tool_input.file_path // empty' 2>/dev/null)"
[ -n "$f" ] && [ -f "$f" ] || { echo '{}'; exit 0; }

dir="$(dirname "$f")"
ext="${f##*.}"

find_up() { # find_up <start-dir> <relative-path> -> prints path if found
  local d="$1"
  while [ "$d" != "/" ]; do
    [ -e "$d/$2" ] && { printf '%s' "$d/$2"; return 0; }
    d="$(dirname "$d")"
  done
  return 1
}

case "$ext" in
  ts|tsx|js|jsx|mjs|cjs)
    # Prefer prettier if the project has it; otherwise use the project's eslint --fix
    # (some frontends have no prettier — eslint is the formatter then).
    p="$(find_up "$dir" node_modules/.bin/prettier || true)"
    e="$(find_up "$dir" node_modules/.bin/eslint || true)"
    if [ -n "$p" ]; then
      "$p" --write --ignore-unknown "$f" >/dev/null 2>&1 || true
    fi
    if [ -n "$e" ]; then
      "$e" --fix --no-error-on-unmatched-pattern "$f" >/dev/null 2>&1 || true
    fi
    ;;
  json|jsonc|css|scss|html|md|mdx|yml|yaml)
    p="$(find_up "$dir" node_modules/.bin/prettier || true)"
    [ -n "$p" ] && "$p" --write --ignore-unknown "$f" >/dev/null 2>&1 || true
    ;;
  kt|kts)
    # Standalone ktlint only — never invoke gradle from a hook.
    if command -v ktlint >/dev/null 2>&1; then
      ktlint -F "$f" >/dev/null 2>&1 || true
    fi
    ;;
  py)
    if command -v ruff >/dev/null 2>&1; then
      ruff format "$f" >/dev/null 2>&1 || true
      ruff check --fix --quiet "$f" >/dev/null 2>&1 || true
    fi
    ;;
esac
echo '{}'
exit 0
