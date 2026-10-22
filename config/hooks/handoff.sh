#!/usr/bin/env bash
# Keep docs/plans/HANDOFF.md current without anyone asking, so another agent (OpenCode,
# Codex, a fresh Claude session) can pick the work up — even after Claude's quota ran out.
#
#   handoff.sh snapshot [agent]   No model, no tokens. Rewrites only the block between the
#                                 handoff:auto markers: date, agent, branch, last commits,
#                                 uncommitted files, newest plan. Wired to Claude's Stop hook;
#                                 Codex can call it via `notify` (see README).
#   handoff.sh nudge              Claude Stop hook. Asks Claude to rewrite the human part
#                                 (Current state / Pending work) — only when the code changed
#                                 since the last nudge AND >= HANDOFF_NUDGE_MINUTES (20) passed,
#                                 never twice in a row.
#
# No-op outside a git repo or when the repo has no docs/plans/HANDOFF.md (project-init and
# adopt.sh create it). State lives in .git/agent-handoff/, never committed.
set -uo pipefail

mode="${1:-}"
agent="${2:-claude}"

payload=""
[ -t 0 ] || payload="$(timeout 2 cat 2>/dev/null || true)"
json_get() { [ -n "$payload" ] && command -v jq >/dev/null 2>&1 && jq -r "$1 // empty" <<<"$payload" 2>/dev/null; }

cwd="$(json_get .cwd)"
[ -n "$cwd" ] && cd "$cwd" 2>/dev/null
root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0
HANDOFF="docs/plans/HANDOFF.md"
[ -f "$HANDOFF" ] || exit 0

START='<!-- handoff:auto:start — written by handoff.sh after each agent turn; do not edit -->'
END='<!-- handoff:auto:end -->'

# Code state, ignoring HANDOFF.md itself so writing it never counts as "a change".
code_state() {
  git rev-parse HEAD 2>/dev/null
  git status --porcelain -- . ":(exclude)$HANDOFF" 2>/dev/null
  git diff HEAD -- . ":(exclude)$HANDOFF" 2>/dev/null
}

snapshot() {
  local branch head plan commits status block body tmp
  branch="$(git branch --show-current 2>/dev/null)"; branch="${branch:-detached}"
  head="$(git rev-parse --short HEAD 2>/dev/null || echo none)"
  plan="$(ls -t docs/superpowers/plans/*.md 2>/dev/null | head -1)"
  commits="$(git log -5 --format='  - %h %s' 2>/dev/null)"
  status="$(git status --short -- . ":(exclude)$HANDOFF" 2>/dev/null | head -30)"

  local plan_md="none"; [ -n "$plan" ] && plan_md="\`$plan\`"
  body="- Branch: \`$branch\` @ \`$head\`
- Active plan (newest file): $plan_md
- Last commits:
${commits:-  - none}
- Uncommitted changes: $( [ -n "$status" ] && printf '\n\n```\n%s\n```' "$status" || echo none)"

  # Rewrite only when something besides the timestamp changed (keeps git quiet).
  local current
  current="$(awk -v s="$START" -v e="$END" '$0==s{f=1;next} $0==e{f=0} f' "$HANDOFF" | grep -v -e '^- Updated: ' -e '^## Auto snapshot$')"
  [ "$current" = "$body" ] && return 0

  block="$START
## Auto snapshot
- Updated: $(date '+%Y-%m-%d %H:%M %z') by $agent
$body
$END"

  tmp="$(mktemp "${HANDOFF}.XXXX")" || return 0
  if grep -qxF "$START" "$HANDOFF"; then
    awk -v s="$START" -v e="$END" -v b="$block" '
      $0==s {print b; skip=1; next}
      $0==e {skip=0; next}
      !skip' "$HANDOFF" >"$tmp"
  else
    { cat "$HANDOFF"; printf '\n%s\n' "$block"; } >"$tmp"
  fi
  mv "$tmp" "$HANDOFF"
}

nudge() {
  [ "$(json_get .stop_hook_active)" = "true" ] && return 0
  local dir hash now last_hash last_time minutes
  dir="$(git rev-parse --absolute-git-dir)/agent-handoff"
  mkdir -p "$dir"
  hash="$(code_state | cksum | cut -d' ' -f1)"
  now="$(date +%s)"
  minutes="${HANDOFF_NUDGE_MINUTES:-20}"

  if [ ! -f "$dir/last" ]; then            # first run in this repo: just start the clock
    printf '%s %s\n' "$hash" "$now" >"$dir/last"; return 0
  fi
  read -r last_hash last_time <"$dir/last"
  [ "$hash" = "$last_hash" ] && return 0
  [ $((now - ${last_time:-0})) -lt $((minutes * 60)) ] && return 0

  printf '%s %s\n' "$hash" "$now" >"$dir/last"
  jq -n --arg f "$HANDOFF" '{
    decision: "block",
    reason: ("Before stopping, update " + $f + ": rewrite \"Current state\" and \"Pending work\" (and \"Active plan\" if it changed) so another agent can resume. Max 15 lines total, replace instead of appending, keep the auto-snapshot block untouched. Then stop.")
  }'
}

case "$mode" in
  snapshot) snapshot ;;
  nudge) nudge ;;
  *) echo "usage: handoff.sh snapshot [agent] | nudge" >&2; exit 2 ;;
esac
exit 0
