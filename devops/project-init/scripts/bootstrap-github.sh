#!/usr/bin/env bash
# bootstrap-github.sh - the external (GitHub) half of project setup. Run
# from the project directory, one step at a time, each confirmed by Loren
# before it runs for real. Use --dry-run to preview the exact commands.
#
# Usage: bootstrap-github.sh [--dry-run] <repo|dev|settings|labels|project|protect|all>
#                             [--owner LorenGrz] [--name <repo>] [--visibility public]
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bootstrap-github.sh [--dry-run] <step> [--owner LorenGrz] [--name <repo>] [--visibility public]

Steps (idempotent where gh supports a read check):
  repo      gh repo create, pushes the initial commit
  dev       create/push the dev branch, make it the default branch
  settings  squash + merge-commit enabled, rebase disabled, delete-branch-on-merge
  labels    feat/fix/refactor/chore/triage labels
  project   create the GitHub Project v2, link it, add Priority/Size fields,
            replace TBD/{{PROJECT_NUMBER}} locally (does not commit)
  protect   branch protection on dev and main (status check: ci, no required reviews)
  all       runs every step above in order - only allowed with --dry-run;
            for real runs, confirm and run each step individually

--dry-run prints every command with a leading "+" instead of running it.
EOF
}

DRY_RUN=0
OWNER="LorenGrz"
NAME=""
VISIBILITY="public"
STEP=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --owner) OWNER="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --visibility) VISIBILITY="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    repo|dev|settings|labels|project|protect|all) STEP="$1"; shift ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

[ -n "$STEP" ] || { usage; exit 1; }
NAME="${NAME:-$(basename "$PWD")}"
export DRY_RUN

run() { # run "<shell command as one string>"
  if [ "$DRY_RUN" = "1" ]; then
    printf '+ %s\n' "$1"
  else
    eval "$1"
  fi
}

step_repo() {
  if [ "$DRY_RUN" != "1" ] && gh repo view "$OWNER/$NAME" >/dev/null 2>&1; then
    echo "repo $OWNER/$NAME already exists, skipping create"
    return
  fi
  run "SKIP_BRANCH_GUARD=1 gh repo create \"$OWNER/$NAME\" --$VISIBILITY --source . --remote origin --push"
}

step_dev() {
  run "git switch -c dev 2>/dev/null || git switch dev"
  run "SKIP_BRANCH_GUARD=1 git push -u origin dev"
  run "gh repo edit \"$OWNER/$NAME\" --default-branch dev"
}

step_settings() {
  run "gh repo edit \"$OWNER/$NAME\" --enable-squash-merge --enable-merge-commit --enable-rebase-merge=false --delete-branch-on-merge"
}

step_labels() {
  local name
  declare -A colors=( [feat]=1d76db [fix]=d73a4a [refactor]=5319e7 [chore]=cfd3d7 [triage]=fbca04 )
  for name in feat fix refactor chore triage; do
    run "gh label create \"$name\" --color \"${colors[$name]}\" --description \"$name work\" --force --repo \"$OWNER/$NAME\""
  done
}

step_project() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '+ %s\n' "gh project create --owner \"$OWNER\" --title \"$NAME\" --format json"
    printf '+ %s\n' "gh project link <NUMBER> --owner \"$OWNER\" --repo \"$OWNER/$NAME\""
    printf '+ %s\n' "gh project field-create <NUMBER> --owner \"$OWNER\" --name Priority --data-type SINGLE_SELECT --single-select-options \"P0,P1,P2\""
    printf '+ %s\n' "gh project field-create <NUMBER> --owner \"$OWNER\" --name Size --data-type SINGLE_SELECT --single-select-options \"XS,S,M,L,XL\""
    printf '+ %s\n' "(then replace TBD/{{PROJECT_NUMBER}} in .github/ISSUE_TEMPLATE/*.yml, AGENTS.md, .agents/CONTEXT.md with <NUMBER>, and print the commit command - does not commit)"
    return
  fi

  local number
  number="$(gh project create --owner "$OWNER" --title "$NAME" --format json | jq -r '.number')"
  gh project link "$number" --owner "$OWNER" --repo "$OWNER/$NAME"
  gh project field-create "$number" --owner "$OWNER" --name Priority --data-type SINGLE_SELECT --single-select-options "P0,P1,P2"
  gh project field-create "$number" --owner "$OWNER" --name Size --data-type SINGLE_SELECT --single-select-options "XS,S,M,L,XL"

  local f
  for f in .github/ISSUE_TEMPLATE/*.yml AGENTS.md .agents/CONTEXT.md; do
    [ -f "$f" ] || continue
    sed -i -e "s/TBD/$number/g" -e "s/{{PROJECT_NUMBER}}/$number/g" "$f"
  done

  echo "Project #$number created: https://github.com/users/$OWNER/projects/$number"
  echo "This only edited files on disk. Commit the number substitution yourself:"
  echo "  git add .github/ISSUE_TEMPLATE AGENTS.md .agents/CONTEXT.md && git commit -m \"chore: set project number to $number\""
}

protect_branch() {
  local branch="$1"
  local body
  body="$(cat <<'JSON'
{
  "required_status_checks": {"strict": true, "contexts": ["ci"]},
  "enforce_admins": false,
  "required_pull_request_reviews": {"required_approving_review_count": 0},
  "restrictions": null
}
JSON
)"
  if [ "$DRY_RUN" = "1" ]; then
    printf '+ gh api -X PUT repos/%s/%s/branches/%s/protection --input - <<JSON\n%s\nJSON\n' "$OWNER" "$NAME" "$branch" "$body"
  else
    gh api -X PUT "repos/$OWNER/$NAME/branches/$branch/protection" --input - <<<"$body"
  fi
}

step_protect() {
  protect_branch dev
  protect_branch main
}

run_step() {
  case "$1" in
    repo) step_repo ;;
    dev) step_dev ;;
    settings) step_settings ;;
    labels) step_labels ;;
    project) step_project ;;
    protect) step_protect ;;
    *) echo "Unknown step: $1" >&2; exit 1 ;;
  esac
}

if [ "$STEP" = "all" ]; then
  if [ "$DRY_RUN" != "1" ]; then
    echo "bootstrap-github.sh all only runs with --dry-run. Run each step individually and have Loren confirm before each one." >&2
    exit 1
  fi
  for s in repo dev settings labels project protect; do
    echo "## $s"
    run_step "$s"
  done
else
  run_step "$STEP"
fi
