#!/usr/bin/env bash
# InstructionsLoaded: append which instruction files (CLAUDE.md, rules, skills)
# were loaded, for debugging why a rule/skill did or didn't activate.
set -uo pipefail

log_dir="$HOME/.claude/logs"
log="$log_dir/instructions-loaded.log"
payload="$(cat)"
ts="$(date -Is)"

mkdir -p "$log_dir" 2>/dev/null || true

{
  printf '=== %s ===\n' "$ts"
  printf '%s' "$payload" | jq -r '
    . as $p
    | ($p.session_id // "?") as $sid
    | ($p.cwd // $p.workingDirectory // "?") as $cwd
    | ["file_path", "memory_type", "load_reason", "trigger_file_path"] as $keys
    | ($keys | map(select($p[.] != null))) as $present
    | "session: \($sid)",
      "cwd: \($cwd)",
      ( $present[] | "  \(.): \($p[.])" ),
      ( if ($present | length) == 0 then "  raw: \($p | tostring)" else empty end )
  ' 2>/dev/null || printf '%s\n' "$payload"
  printf '\n'
} >> "$log" 2>/dev/null || true
exit 0
