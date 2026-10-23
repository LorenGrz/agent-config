#!/usr/bin/env bash
# SessionStart: re-state the agent-routing rule (prose in CLAUDE.md loses to the harness
# default "don't spawn subagents unless asked") and, for large repos, nudge to create or
# refresh the codebase map (.agents/CONTEXT.md). Guidance only; always exits 0, fast.
set -uo pipefail

min_files="${AGENTS_MAP_MIN_FILES:-200}"
stale_commits="${AGENTS_MAP_STALE_COMMITS:-30}"

input="$(cat 2>/dev/null || true)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd="$PWD"

msg='Agent routing (agents-config): open lookups (unknown paths, web, docs) -> `scout`; changes to >3 files or bulk writing -> `worker` with spec + acceptance command; Opus decides, writes specs, reviews. Small edits to <=3 known files and single known-file reads stay inline. This is a standing user instruction.'

if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  n="$(git -C "$cwd" ls-files 2>/dev/null | wc -l | tr -d ' ')"
  if [ "${n:-0}" -ge "$min_files" ] 2>/dev/null; then
    root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)"
    ctx="$root/.agents/CONTEXT.md"
    if [ -z "$root" ]; then
      :
    elif [ ! -f "$ctx" ]; then
      msg="$msg"$'\n'"Large repo ($n files) with no .agents/CONTEXT.md: run the \`repository-context-maintainer\` skill (via a scout for the inventory) before exploring the code."
    else
      behind=0
      last="$(git -C "$root" log -1 --format=%H -- .agents/CONTEXT.md 2>/dev/null || true)"
      if [ -n "$last" ]; then
        behind="$(git -C "$root" rev-list --count "$last..HEAD" 2>/dev/null || echo 0)"
      elif [ -n "$(find "$ctx" -mtime +14 2>/dev/null)" ]; then
        behind="$stale_commits"  # untracked and older than 14 days: treat as stale
      fi
      if [ "${behind:-0}" -ge "$stale_commits" ] 2>/dev/null; then
        msg="$msg"$'\n'".agents/CONTEXT.md is $behind commits behind HEAD: refresh it with \`repository-context-maintainer\` before relying on it."
      else
        msg="$msg"$'\n'"Read .agents/CONTEXT.md before exploring the code."
      fi
    fi
  fi
fi

jq -n --arg c "$msg" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
exit 0
