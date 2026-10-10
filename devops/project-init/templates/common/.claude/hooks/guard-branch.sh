#!/usr/bin/env bash
# PreToolUse(Bash) hook: block `git commit` and `git push` against dev/main
# directly. Everything else is allowed silently. Branch work must go through
# scripts/gh-flow.sh so issues/PRs/CI stay wired up.
set -uo pipefail

input="$(cat)"
cmd="$(jq -r '.tool_input.command // .toolCall.args.CommandLine // empty' <<<"$input" 2>/dev/null)"
cwd="$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)"
[ -z "$cmd" ] && exit 0
[ -z "$cwd" ] && cwd="$(pwd)"

REASON='Direct commits/pushes to dev or main are blocked. Use scripts/gh-flow.sh start|pr|merge (or release for main) instead.'

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$REASON"
  exit 0
}

current_branch() {
  git -C "$cwd" branch --show-current 2>/dev/null
}

if [[ "$cmd" =~ (^|[[:space:];&|])git[[:space:]]+commit([[:space:]]|$) ]]; then
  branch="$(current_branch)"
  if [ "$branch" = "dev" ] || [ "$branch" = "main" ]; then deny; fi
  exit 0
fi

if [[ "$cmd" =~ (^|[[:space:];&|])git[[:space:]]+push([[:space:]]|$) ]]; then
  rest="${cmd#*push}"
  tokens=()
  for tok in $rest; do
    [[ "$tok" == -* ]] && continue
    tokens+=("$tok")
  done
  refspec="${tokens[1]:-}"
  if [ -n "$refspec" ]; then
    if [[ "$refspec" == *:* ]]; then
      target="${refspec#*:}"
    else
      target="$refspec"
    fi
  else
    target="$(current_branch)"
  fi
  target="${target#refs/heads/}"
  if [ "$target" = "dev" ] || [ "$target" = "main" ]; then deny; fi
  exit 0
fi

exit 0
