#!/usr/bin/env bash
# Status line: ccusage + el delta de costo del último prompt.
# ccusage sólo muestra acumulados; el delta se calcula guardando el total
# anterior por sesión en /tmp y restando.
set -uo pipefail

# ccusage: del PATH, o el bin global de pnpm (la statusline puede correr sin el PATH del shell).
ccusage=$(command -v ccusage || echo "${PNPM_HOME:-$HOME/.local/share/pnpm}/ccusage")
[[ -x "$ccusage" ]] || ccusage="$HOME/.local/share/pnpm/bin/ccusage"
[[ -x "$ccusage" ]] || exit 0

entrada=$(cat)
linea=$(printf '%s' "$entrada" | "$ccusage" statusline 2>/dev/null) || exit 0

sesion=$(printf '%s' "$entrada" | jq -r '.session_id // "sin-sesion"')
total=$(printf '%s' "$linea" | grep -oP '\$\K-?[0-9]+\.[0-9]+(?= session)' | head -1)

if [[ -n "$total" ]]; then
  estado="/tmp/claude-costo-${USER}-${sesion}"
  anterior=$(cat "$estado" 2>/dev/null || echo 0)
  printf '%s' "$total" > "$estado"
  delta=$(awk -v a="$total" -v b="$anterior" 'BEGIN { d = a - b; printf "%.2f", (d > 0 ? d : 0) }')
  linea="${linea} | ↑ \$${delta} este prompt"
fi

printf '%s\n' "$linea"
