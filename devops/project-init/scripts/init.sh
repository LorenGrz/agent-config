#!/usr/bin/env bash
# init.sh - overlay project-init's templates onto a project directory.
#
# Usage: init.sh --stack <react-vite|next|nestjs|node-ts> --name <name>
#                 [--dir <path>] [--owner LorenGrz] [--project-number N]
#                 [--force] [--install]
#
# Idempotent: never overwrites an existing file unless --force. Prints
# "skip <path> (exists)" for anything it leaves alone.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: init.sh --stack <react-vite|next|nestjs|node-ts> --name <name>
               [--dir <path>] [--owner LorenGrz] [--project-number N]
               [--force] [--install]

  --stack            react-vite | next | nestjs | node-ts (required)
  --name             project name, used as {{PROJECT}} (required)
  --dir              target directory (default: cwd)
  --owner            GitHub owner, used as {{OWNER}} (default: LorenGrz)
  --project-number   GitHub Project number, used as {{PROJECT_NUMBER}} (default: TBD)
  --force            overwrite files that already exist
  --install          actually install ESLint devDependencies and write
                     missing package.json scripts, instead of just printing
                     the commands needed
EOF
}

STACK=""
NAME=""
DIR="$(pwd)"
OWNER="LorenGrz"
PROJECT_NUMBER="TBD"
FORCE=0
INSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --stack) STACK="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --dir) DIR="$2"; shift 2 ;;
    --owner) OWNER="$2"; shift 2 ;;
    --project-number) PROJECT_NUMBER="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --install) INSTALL=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

case "$STACK" in
  react-vite|next|nestjs|node-ts) ;;
  *) echo "Error: --stack must be one of react-vite|next|nestjs|node-ts" >&2; exit 1 ;;
esac
[ -n "$NAME" ] || { echo "Error: --name is required" >&2; exit 1; }

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMMON_DIR="$SKILL_DIR/templates/common"
STACK_DIR="$SKILL_DIR/templates/$STACK"
DATE="$(date +%Y-%m-%d)"

mkdir -p "$DIR"

substitute() {
  sed -e "s/{{PROJECT}}/$NAME/g" \
      -e "s/{{OWNER}}/$OWNER/g" \
      -e "s/{{PROJECT_NUMBER}}/$PROJECT_NUMBER/g" \
      -e "s/{{STACK}}/$STACK/g" \
      -e "s/{{DATE}}/$DATE/g"
}

# Copy every file under $1 (templates/common or templates/<stack>) into $DIR,
# substituting placeholders. Skips AGENTS.md and AGENTS.stack.md - those are
# assembled separately by generate_agents_md.
copy_template_tree() {
  local src_root="$1"
  [ -d "$src_root" ] || return 0
  local file rel dest
  while IFS= read -r -d '' file; do
    rel="${file#"$src_root"/}"
    [ "$rel" = "AGENTS.md" ] && continue
    [ "$rel" = "AGENTS.stack.md" ] && continue
    dest="$DIR/$rel"
    if [ -e "$dest" ] && [ "$FORCE" != 1 ]; then
      echo "skip $rel (exists)"
      continue
    fi
    mkdir -p "$(dirname "$dest")"
    substitute < "$file" > "$dest"
    [ -x "$file" ] && chmod +x "$dest"
    echo "wrote $rel"
  done < <(find "$src_root" -type f -print0)
}

# Build AGENTS.md from templates/common/AGENTS.md, inserting
# templates/<stack>/AGENTS.stack.md at the {{STACK_CONVENTIONS}} marker line.
generate_agents_md() {
  local dest="$DIR/AGENTS.md"
  if [ -e "$dest" ] && [ "$FORCE" != 1 ]; then
    echo "skip AGENTS.md (exists)"
    return
  fi
  local stack_conv="$STACK_DIR/AGENTS.stack.md"
  {
    while IFS= read -r line || [ -n "$line" ]; do
      if [ "$line" = "{{STACK_CONVENTIONS}}" ]; then
        [ -f "$stack_conv" ] && cat "$stack_conv"
      else
        printf '%s\n' "$line"
      fi
    done < "$COMMON_DIR/AGENTS.md"
  } | substitute > "$dest"
  echo "wrote AGENTS.md"
}

# Print (or, with --install, run) the pnpm add -D command for the ESLint
# plugins the stack's eslint config needs. nestjs/node-ts get no override.
print_or_install_eslint_deps() {
  local -a deps=()
  case "$STACK" in
    react-vite)
      deps=(eslint @eslint/js globals typescript-eslint eslint-plugin-react-hooks eslint-plugin-react-refresh eslint-plugin-react-you-might-not-need-an-effect)
      ;;
    next)
      deps=(eslint-plugin-react-hooks eslint-plugin-react-you-might-not-need-an-effect)
      ;;
    *)
      return 0
      ;;
  esac
  local cmd="pnpm add -D ${deps[*]}"
  if [ "$INSTALL" = 1 ]; then
    echo "Installing ESLint dependencies: $cmd"
    (cd "$DIR" && pnpm add -D "${deps[@]}")
  else
    echo "Run this to install the ESLint dependencies the generated eslint config needs:"
    echo "  $cmd"
  fi
}

# Canonical dev/test/lint/typecheck/format/format:check commands per stack.
declare -A SCRIPTS
case "$STACK" in
  react-vite)
    SCRIPTS=( [dev]="vite" [test]="vitest" [lint]="eslint ." [typecheck]="tsc -b --noEmit" [format]="prettier --write ." ["format:check"]="prettier --check ." )
    ;;
  next)
    SCRIPTS=( [dev]="next dev" [test]="vitest" [lint]="eslint ." [typecheck]="tsc --noEmit" [format]="prettier --write ." ["format:check"]="prettier --check ." )
    ;;
  nestjs)
    SCRIPTS=( [dev]="nest start --watch" [test]="jest" [lint]='eslint "{src,apps,libs,test}/**/*.ts" --fix' [typecheck]="tsc --noEmit" [format]='prettier --write "src/**/*.ts"' ["format:check"]='prettier --check "src/**/*.ts"' )
    ;;
  node-ts)
    SCRIPTS=( [dev]="tsx src/index.ts" [test]="vitest" [lint]="eslint ." [typecheck]="tsc --noEmit" [format]="prettier --write ." ["format:check"]="prettier --check ." )
    ;;
esac

# Report which of the six canonical scripts are missing from package.json.
# For react-vite/next, a "lint" script that doesn't invoke eslint (e.g. the
# vite scaffold's default `oxlint`) counts as needing an update, since the
# generated eslint.config.js/.mjs only takes effect through eslint.
report_scripts() {
  local pkg="$DIR/package.json"
  [ -f "$pkg" ] || { echo "no package.json found at $pkg, skipping script check"; return; }

  local -a needs=()
  local name current
  for name in "${!SCRIPTS[@]}"; do
    current="$(jq -r --arg n "$name" '.scripts[$n] // empty' "$pkg")"
    if [ -z "$current" ]; then
      needs+=("$name")
    elif [ "$name" = "lint" ] && { [ "$STACK" = "react-vite" ] || [ "$STACK" = "next" ]; } && [[ "$current" != *eslint* ]]; then
      needs+=("$name")
    fi
  done

  if [ ${#needs[@]} -eq 0 ]; then
    echo "package.json scripts: dev/test/lint/typecheck/format/format:check all present"
    return
  fi

  if [ "$INSTALL" = 1 ]; then
    # jq rather than `pnpm pkg set`: pnpm's property-path parser rejects the
    # colon in "format:check" (ERR_PNPM_PKG_INVALID_PROPERTY_PATH).
    local tmp
    for name in "${needs[@]}"; do
      tmp="$(mktemp)"
      jq --arg n "$name" --arg v "${SCRIPTS[$name]}" '.scripts[$n] = $v' "$pkg" > "$tmp"
      mv "$tmp" "$pkg"
      echo "set scripts.$name = ${SCRIPTS[$name]}"
    done
  else
    echo "package.json is missing (or needs eslint for) these scripts:"
    for name in "${needs[@]}"; do
      # npm pkg set, not pnpm pkg set: pnpm's property-path parser rejects
      # the colon in "format:check".
      echo "  npm pkg set \"scripts.$name=${SCRIPTS[$name]}\""
    done
  fi
}

# CI's pnpm/action-setup reads the pnpm version from "packageManager"; without
# it the action fails. Pin to the local pnpm when the field is missing.
ensure_package_manager() {
  local pkg="$DIR/package.json"
  [ -f "$pkg" ] || return 0
  [ -n "$(jq -r '.packageManager // empty' "$pkg")" ] && return 0
  local ver
  ver="$(pnpm --version 2>/dev/null)" || { echo "pnpm not found: add \"packageManager\": \"pnpm@<version>\" to package.json for CI"; return 0; }
  local tmp
  tmp="$(mktemp)"
  jq --arg v "pnpm@$ver" '.packageManager = $v' "$pkg" > "$tmp" && mv "$tmp" "$pkg"
  echo "set packageManager = pnpm@$ver"
}

copy_template_tree "$COMMON_DIR"
generate_agents_md
copy_template_tree "$STACK_DIR"
print_or_install_eslint_deps
report_scripts
ensure_package_manager
