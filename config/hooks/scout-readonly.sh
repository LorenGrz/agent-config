#!/usr/bin/env bash
# PreToolUse(Bash) hook for the read-only `scout` subagent.
# Allowlist: every segment of the command (split on | && || ;) must start with
# a known read-only program, and read-only-looking programs are checked for
# their write flags. Anything else is denied with exit 2 (stderr goes back to
# the agent). A denylist is not enough: the scout once ran
# `aws ec2 terminate-instances` while "read-only" was only prompt text.
set -uo pipefail

input=$(cat)
# Also registered globally in settings.json (agent frontmatter hooks only load
# at session start): act only inside the scout subagent there.
agent_type=$(jq -r '.agent_type // empty' <<<"$input")
if [ "${SCOUT_GUARD_ALWAYS:-0}" != 1 ] && [ "$agent_type" != scout ]; then exit 0; fi
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
[ -z "$cmd" ] && exit 0

# Quote-aware helpers: `|`, `;`, `&&` and `>` inside '...' or "..." are data
# (e.g. rg "a|b"), not shell operators.
mask_quotes() { # prints $1 with quoted characters replaced by '_'
  local s=$1 out="" q="" c i
  for ((i = 0; i < ${#s}; i++)); do
    c=${s:i:1}
    if [ -n "$q" ]; then [ "$c" = "$q" ] && q="" && out+=$c || out+=_
    elif [ "$c" = "'" ] || [ "$c" = '"' ]; then q=$c; out+=$c
    else out+=$c; fi
  done
  printf '%s' "$out"
}
split_segments() { # prints one segment per line, split on unquoted | || && ;
  local s=$1 m seg="" c i
  m=$(mask_quotes "$s")
  for ((i = 0; i < ${#s}; i++)); do
    c=${m:i:1}
    if [ "$c" = "|" ] || [ "$c" = ";" ] || { [ "$c" = "&" ] && [ "${m:i+1:1}" = "&" ]; }; then
      printf '%s\n' "$seg"; seg=""
      [ "${m:i+1:1}" = "|" ] || [ "${m:i+1:1}" = "&" ] && ((i++))
    else seg+=${s:i:1}; fi
  done
  printf '%s\n' "$seg"
}

deny() {
  echo "scout is read-only: blocked \`$1\` ($2). Report the command instead of running it." >&2
  exit 2
}

# Output redirection to anything but /dev/null or another fd writes files.
while IFS= read -r target; do
  target="${target#>}"; target="${target#>}"; target="${target#"${target%%[![:space:]]*}"}"
  [[ "$target" == /dev/null || "$target" =~ ^\&[0-9]$ ]] || deny "$cmd" "output redirection to $target"
done < <(mask_quotes "$cmd" | grep -Eo '>>?[[:space:]]*[^[:space:]]+')
# Command substitution / subshells can hide arbitrary programs.
printf '%s' "$cmd" | grep -Eq '\$\(|`' && deny "$cmd" "command substitution is not allowed"

aws_read_verb='^(describe|list|get|head|lookup|search|batch-get|scan|query|filter|simulate|ls)'

while IFS= read -r seg; do
  seg="${seg#"${seg%%[![:space:]]*}"}"
  [ -z "$seg" ] && continue
  # Drop leading VAR=value assignments.
  while [[ "$seg" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*)$ ]]; do seg="${BASH_REMATCH[1]}"; done
  read -r prog rest <<<"$seg"
  prog="${prog##*/}"
  case "$prog" in
    rg|grep|egrep|ls|cat|head|tail|wc|sort|uniq|cut|tr|file|stat|pwd|echo|printf|jq|awk|date|basename|dirname|realpath|readlink|test|true|false|which|du|tree|diff|column|nl|md5sum|sha256sum|base64|markitdown|pdftotext) ;;
    sed) [[ " $rest " =~ [[:space:]]-i ]] && deny "$seg" "sed -i edits files" ;;
    find) [[ "$rest" =~ -(delete|exec|execdir|ok|fprint) ]] && deny "$seg" "find with side effects" ;;
    git)
      sub=$(awk '{for(i=1;i<=NF;i++) if ($i !~ /^-/ && prev != "-C") {print $i; exit} else prev=$i}' <<<"$rest")
      [[ "$sub" =~ ^(log|show|diff|status|blame|ls-files|ls-tree|rev-parse|rev-list|branch|grep|describe|shortlog|cat-file|remote)$ ]] \
        || deny "$seg" "git $sub is not read-only"
      [[ "$sub" == branch && "$rest" =~ [[:space:]]-(d|D|m|M|c|C)([[:space:]]|$) ]] && deny "$seg" "git branch modification"
      [[ "$sub" == remote && ! "$rest" =~ remote([[:space:]]+-v)?[[:space:]]*$ ]] && deny "$seg" "git remote modification" ;;
    curl)
      [[ "$rest" =~ (^|[[:space:]])(-X|--request)[[:space:]]*(POST|PUT|PATCH|DELETE) ]] && deny "$seg" "curl write method"
      [[ "$rest" =~ (^|[[:space:]])(-d|--data[a-z-]*|-F|--form|-T|--upload-file)([[:space:]]|=|$) ]] && deny "$seg" "curl sends a body"
      [[ "$rest" =~ (^|[[:space:]])(-o|--output)[[:space:]]+([^[:space:]]+) && "${BASH_REMATCH[3]}" != /dev/null ]] && deny "$seg" "curl writes a file"
      [[ "$rest" =~ (^|[[:space:]])(-O|--remote-name) ]] && deny "$seg" "curl writes a file" ;;
    cd|type|id|uname|whoami|hostname) ;; # cd only changes this shell's cwd
    command) [[ "$rest" =~ ^-[vV]([[:space:]]|$) ]] || deny "$seg" "only 'command -v/-V' is allowed (command <prog> bypasses the allowlist)" ;;
    env) [ -z "$rest" ] || deny "$seg" "env with arguments runs a program" ;;
    pipx) [[ "$rest" =~ ^list([[:space:]]|$) ]] || deny "$seg" "only 'pipx list' is allowed" ;;
    uv) [[ "$rest" =~ ^(tool[[:space:]]+list|pip[[:space:]]+(list|show))([[:space:]]|$) ]] || deny "$seg" "uv is limited to tool list / pip list / pip show" ;;
    pip|pip3) [[ "$rest" =~ ^(list|show|freeze)([[:space:]]|$) ]] || deny "$seg" "pip is limited to list|show|freeze" ;;
    npm|pnpm) [[ "$rest" =~ ^(ls|list|view|why|outdated)([[:space:]]|$) ]] || deny "$seg" "$prog is limited to ls|list|view|why|outdated" ;;
    node|python3|python) [[ "$rest" =~ ^(--version|-V)[[:space:]]*$ ]] || deny "$seg" "$prog is limited to --version" ;;
    gh)
      read -r -a words <<<"$rest"
      case "${words[0]:-} ${words[1]:-}" in
        "repo view"|"pr view"|"pr list"|"pr diff"|"pr checks"|"pr status"|"issue view"|"issue list"|"run view"|"run list"|"release view"|"release list") ;;
        "api "*)
          [[ "${words[1]}" == graphql ]] && deny "$seg" "gh api graphql can mutate"
          [[ "$rest" =~ (^|[[:space:]])(-f|-F|--field|--raw-field|--input) ]] && deny "$seg" "gh api sends a body"
          if [[ "$rest" =~ (^|[[:space:]])(-X|--method)[[:space:]=]*([^[:space:]]+) ]]; then
            [[ "${BASH_REMATCH[3]^^}" == GET ]] || deny "$seg" "gh api non-GET method"
          fi ;;
        *) deny "$seg" "gh ${words[0]:-} ${words[1]:-} is not on the read-only list" ;;
      esac ;;
    aws)
      read -r -a words <<<"$rest"
      svc="" verb=""
      for w in "${words[@]}"; do
        [[ "$w" == -* ]] && continue
        if [ -z "$svc" ]; then svc="$w"; elif [ -z "$verb" ]; then verb="$w"; break; fi
      done
      if [ "$svc" = s3 ]; then [[ "$verb" == ls ]] || deny "$seg" "aws s3 $verb mutates or downloads"
      else [[ "$verb" =~ $aws_read_verb ]] || deny "$seg" "aws $svc $verb is not a read verb"; fi ;;
    *) deny "$seg" "'$prog' is not on the read-only allowlist" ;;
  esac
done < <(split_segments "$cmd")

exit 0
