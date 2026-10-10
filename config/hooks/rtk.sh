#!/usr/bin/env bash
# PreToolUse (Bash): compress noisy command output via rtk (github.com/rtk-ai/rtk).
#
# rtk's hook answers permissionDecision "allow" for every command it rewrites,
# which would skip the normal permission prompt / auto-mode check. So only
# read-only or verification commands are handed to rtk; anything else (push,
# commit, rm, installs, ...) passes through untouched and keeps the regular
# permission flow.
#
# No-op when rtk isn't installed, so this hook is safe in settings.base.json.
# Install: ./install.sh --with-rtk. Measure with: npx ccusage@latest daily.
set -uo pipefail

payload="$(cat)"
RTK="$(command -v rtk 2>/dev/null || true)"
[ -z "$RTK" ] && [ -x "$HOME/.local/bin/rtk" ] && RTK="$HOME/.local/bin/rtk"
[ -n "$RTK" ] || exit 0

cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -n "$cmd" ] || exit 0

# Single commands only: no chaining, pipes, redirects or substitutions.
case "$cmd" in
  *'&&'* | *'||'* | *';'* | *'|'* | *'>'* | *'<'* | *'$('* | *'`'* | *$'\n'*) exit 0 ;;
esac

# Read-only / verification commands worth compressing.
if printf '%s' "$cmd" | grep -qE '^(git (status|diff|log|show|branch)( |$)|ls( |$)|tree( |$)|find |grep |rg |(pnpm|npm|yarn) (test|lint|typecheck|run (test|lint|typecheck|build))( |$)|(pnpm|npx) (vitest|jest|eslint|tsc|playwright)( |$)|tsc( |$)|eslint( |$)|vitest( |$)|pytest( |$)|ruff check( |$)|cargo (test|clippy|check)( |$)|go test( |$)|docker (ps|logs)( |$))'; then
  printf '%s' "$payload" | "$RTK" hook claude
fi
exit 0
