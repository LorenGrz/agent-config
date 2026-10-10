#!/usr/bin/env bash
# Install / repair the Claude + Codex integration for this hub.
#
# - Symlinks ~/.claude/{CLAUDE.md,rules,hooks,agents} and ~/.codex/AGENTS.md
#   into this repo.
# - Runs sync.sh to (re)build the flat ~/.claude/skills mirror.
# - Merges config/settings.base.json into ~/.claude/settings.json (jq):
#     * hooks / statusLine / enabledPlugins / extraKnownMarketplaces / model /
#       theme: base wins (full overwrite).
#     * permissions.allow / permissions.ask: union of existing + base, deduped.
#     * every other existing top-level key (machine/project-specific blocks
#       such as per-machine auto-approval config) is preserved as-is.
#   settings.json is backed up before any write.
#
# Idempotent and safe: never deletes a real file or directory. If a symlink
# target already exists as a real file/dir, it is moved aside to
# <path>.bak.<timestamp> first.
#
# Usage:
#   ./install.sh [--dry-run] [--with-rtk] [--with-rulesync]
#
#   --dry-run       print planned actions only, change nothing
#   --with-rtk      also install rtk (https://github.com/rtk-ai/rtk) and run
#                   `rtk init -g`
#   --with-rulesync also (re)generate rulesync output for codexcli, geminicli
#                   and cursor via config/rulesync/

set -euo pipefail

HUB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CODEX_DIR="${CODEX_DIR:-$HOME/.codex}"

DRY_RUN=0
WITH_RTK=0
WITH_RULESYNC=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --with-rtk) WITH_RTK=1 ;;
    --with-rulesync) WITH_RULESYNC=1 ;;
    -h|--help)
      sed -n '2,25p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown flag: $arg" >&2
      exit 1
      ;;
  esac
done

ts() { date +%Y%m%d%H%M%S; }

# link <target> <link_path> — create or repair a symlink, never deleting a
# real file/dir (backs it up instead).
link() {
  local target="$1" link_path="$2"

  if [ -L "$link_path" ]; then
    if [ "$(readlink "$link_path")" = "$target" ]; then
      echo "ok:      $link_path -> $target"
      return
    fi
    echo "repair:  $link_path (was -> $(readlink "$link_path"))"
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "  [dry-run] rm '$link_path' && ln -s '$target' '$link_path'"
    else
      rm -f "$link_path"
      ln -s "$target" "$link_path"
    fi
  elif [ -e "$link_path" ]; then
    local backup="${link_path}.bak.$(ts)"
    echo "backup:  $link_path -> $backup (real file/dir, not deleted)"
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "  [dry-run] mv '$link_path' '$backup' && ln -s '$target' '$link_path'"
    else
      mkdir -p "$(dirname "$link_path")"
      mv "$link_path" "$backup"
      ln -s "$target" "$link_path"
    fi
  else
    echo "create:  $link_path -> $target"
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "  [dry-run] ln -s '$target' '$link_path'"
    else
      mkdir -p "$(dirname "$link_path")"
      ln -s "$target" "$link_path"
    fi
  fi
}

echo "== symlinks =="
if [ "$DRY_RUN" -eq 1 ]; then
  echo "  [dry-run] mkdir -p '$CLAUDE_DIR' '$CODEX_DIR'"
else
  mkdir -p "$CLAUDE_DIR" "$CODEX_DIR"
fi
link "$HUB/config/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
link "$HUB/config/rules"     "$CLAUDE_DIR/rules"
link "$HUB/config/hooks"     "$CLAUDE_DIR/hooks"
link "$HUB/config/agents"    "$CLAUDE_DIR/agents"
link "$HUB/config/AGENTS.md" "$CODEX_DIR/AGENTS.md"

echo
echo "== skills mirror (sync.sh) =="
if [ "$DRY_RUN" -eq 1 ]; then
  echo "  [dry-run] '$HUB/sync.sh'"
else
  "$HUB/sync.sh"
fi

echo
echo "== settings.json merge =="
SETTINGS="$CLAUDE_DIR/settings.json"
BASE="$HUB/config/settings.base.json"

if [ ! -f "$SETTINGS" ]; then
  echo "create:  $SETTINGS"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] cp '$BASE' '$SETTINGS'"
  else
    mkdir -p "$CLAUDE_DIR"
    cp "$BASE" "$SETTINGS"
  fi
else
  MERGED="$(jq -s '
    .[0] as $cur | .[1] as $base
    | $cur
    | .model = $base.model
    | .hooks = $base.hooks
    | .statusLine = $base.statusLine
    | .enabledPlugins = $base.enabledPlugins
    | .extraKnownMarketplaces = $base.extraKnownMarketplaces
    | .theme = $base.theme
    | .permissions.allow = ((($cur.permissions.allow // []) + ($base.permissions.allow // [])) | unique)
    | .permissions.ask   = ((($cur.permissions.ask   // []) + ($base.permissions.ask   // [])) | unique)
  ' "$SETTINGS" "$BASE")"

  if [ "$(jq -S . "$SETTINGS")" = "$(jq -S . <<<"$MERGED")" ]; then
    echo "ok:      $SETTINGS already up to date"
  else
    BACKUP="$SETTINGS.bak.$(ts)"
    echo "backup:  $SETTINGS -> $BACKUP"
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "  [dry-run] write merged settings to '$SETTINGS' (after backup)"
    else
      cp "$SETTINGS" "$BACKUP"
      jq . <<<"$MERGED" >"$SETTINGS"
    fi
  fi
fi

if [ "$WITH_RULESYNC" -eq 1 ]; then
  echo
  echo "== rulesync (codexcli, antigravity-cli [Gemini], cursor) =="
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] '$HUB/config/rulesync/build.sh'"
    echo "  [dry-run] pnpm dlx rulesync generate   # reads config/rulesync/rulesync.jsonc"
  else
    "$HUB/config/rulesync/build.sh"
    (cd "$HUB/config/rulesync" && pnpm dlx rulesync generate)
  fi
fi

if [ "$WITH_RTK" -eq 1 ]; then
  echo
  echo "== rtk =="
  RTK_CMD='curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh'
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] $RTK_CMD"
    echo "  [dry-run] rtk init -g"
  else
    echo "running: $RTK_CMD"
    sh -c "$RTK_CMD"
    rtk init -g
  fi
fi

echo
echo "hint: run 'npx ccusage@latest' to see your Claude Code token usage/cost."
