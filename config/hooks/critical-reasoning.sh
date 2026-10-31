#!/usr/bin/env bash
# UserPromptSubmit + PreToolUse(Edit|Write|MultiEdit): when the work looks costly to get
# wrong (architecture, unknown-cause bugs, security, migrations, prod/IAM), remind the main
# session to route it through the `reasoner` subagent (Opus) instead of deciding inline on
# Sonnet. Guidance only (additionalContext); never blocks, always exits 0, silent in subagents.
set -uo pipefail

input="$(cat 2>/dev/null || true)"
agent_type="$(jq -r '.agent_type // empty' <<<"$input" 2>/dev/null || true)"
[ -z "$agent_type" ] || exit 0  # already inside worker/scout/reasoner

event="$(jq -r '.hook_event_name // empty' <<<"$input" 2>/dev/null || true)"
reason=""

case "$event" in
  UserPromptSubmit)
    prompt="$(jq -r '.prompt // empty' <<<"$input" 2>/dev/null | tr '[:upper:]' '[:lower:]')"
    re='arquitectur|architecture|dise(ñ|n)o de (api|base|schema|sistema)|api contract|contrato de api|migraci(ó|o)n|migration|seguridad|security|autenticaci|authenticat|authoriz|autorizaci|\biam\b|permisos|root cause|causa ra(í|i)z|no s(é|e) por qu(é|e)|race condition|deadlock|memory leak|producci(ó|o)n|\bprod\b|borrar (datos|la base)|drop table|rotar (credenciales|secretos)|breaking change|trade-?off'
    if grep -Eq "$re" <<<"$prompt"; then
      reason="el pedido toca una decisión crítica (arquitectura, seguridad, migración, causa desconocida o prod)"
    fi
    ;;
  PreToolUse)
    f="$(jq -r '.tool_input.file_path // .tool_input.path // empty' <<<"$input" 2>/dev/null)"
    case "$f" in
      */migrations/*|*.sql|*/template.y*ml|*/samconfig.toml|*/auth/*|*auth*.ts|*guard*.ts|*/iam/*|*policy*.json|*.env|*.env.*|*/.github/workflows/*|*/prisma/schema.prisma)
        reason="se edita un archivo sensible ($f): migración, auth, IAM, infra o CI"
        ;;
    esac
    ;;
esac

[ -n "$reason" ] || exit 0

msg="Razonamiento crítico (agents-config): $reason. Antes de decidir o editar, delegá el análisis al subagente \`reasoner\` (Opus) con el contexto y la pregunta concreta; después implementá con \`worker\` o inline según el tamaño. No resuelvas la decisión de fondo en Sonnet. Si ya hay un plan aprobado de reasoner/Opus para esto, ignorá este aviso."
jq -n --arg c "$msg" --arg e "${event:-UserPromptSubmit}" \
  '{hookSpecificOutput:{hookEventName:$e,additionalContext:$c}}'
exit 0
