# Plan: consolidar todo en `agents-config` (un solo repo)

## Context

Lo que pediste: no tener config duplicada en repos distintos, y que quien quiera usar tu setup entre fácil.

Lo que encontré (solo lectura):
- **`claude-skills` ya no existe como repo.** `~/projects/claude-skills` es un *segundo clon local* del mismo remoto `LorenGrz/agents-config`, mismo commit (`d6e320d`), sin cambios ni stash. En GitHub solo existe `agents-config`; `aws-skills` y `serverless-scanner-skill` ya están archivados y plegados dentro (ADR 0001).
- **`~/.agents/skills` ES `agents-config`.** Ya tiene `install.sh`, perfiles (`config/profiles/<nombre>.md`), plugin marketplace (`.claude-plugin/`), README con instalación en 2 métodos y la skill `agents-config-setup`. La onboarding para terceros ya está resuelta; no hay que migrar nada.
- **El problema real:** los cambios de hoy (`opusplan` + hook `critical-reasoning.sh`) viven solo en `~/.claude/settings.json`. `install.sh` sobrescribe `model` y `hooks` desde `config/settings.base.json` (que dice `"model": "opus"` y no tiene el hook nuevo), así que **la próxima corrida de `install.sh` los revierte**. Además el hook está sin commitear.

## Cambios

Todo en `~/.agents/skills` (rama `feat/opusplan-critical-reasoning`, Conventional Commits, merge `--no-ff` como el historial del repo):

1. `config/settings.base.json` — `"model": "opusplan"`; agregar `UserPromptSubmit` → `critical-reasoning.sh` y un segundo bloque `PreToolUse` `Edit|Write|MultiEdit` → `critical-reasoning.sh` (mismo contenido que ya puse en `~/.claude/settings.json`).
2. `config/hooks/critical-reasoning.sh` — ya escrito y probado (5 payloads); solo se commitea.
3. `hooks/hooks.json` (plugin) — registrar el hook nuevo con `${CLAUDE_PLUGIN_ROOT}/config/hooks/critical-reasoning.sh` en `UserPromptSubmit` y `PreToolUse`, para que el Método 2 (marketplace) también lo tenga. Nota: el plugin no puede fijar el modelo, eso queda solo en `install.sh`.
4. `config/hooks/session-start.sh` — el mensaje dice "Opus decides"; cambiar a "plan mode (Opus) y `reasoner` deciden; la sesión principal (Sonnet) ejecuta y delega".
5. `config/CLAUDE.md` (sección Agent Routing) — mismo ajuste: la sesión principal es Sonnet vía `opusplan`; Opus entra en plan mode y como `reasoner`.
6. `docs/decisions/0009-opusplan-and-critical-reasoning-hook.md` — ADR nuevo: por qué `opusplan` (planes en Opus, ejecución en Sonnet), por qué un hook de aviso y no de bloqueo (un hook no puede cambiar de modelo), trade-off y alcance. Marcar 0003/0006 como parcialmente superados (la "sesión principal Opus" pasa a Sonnet) con la nota al tope, como ya hace 0003 con 0006.
7. Docs: `README.md` (tabla de hooks ~L149-159 y lista del plugin L158) y `config/README.md` (L65-82) con el hook nuevo; `.agents/CONTEXT.md` si menciona modelo/hooks.
8. `config/profiles/loren.md` — quitar la línea de "Showcase/mirror clones … `~/projects/claude-skills`" (ya no hay clon espejo).

## Limpieza local (después del push)

- Borrar `~/projects/claude-skills`. Antes verifico `git status` limpio, sin stash y `HEAD == origin/master` (ya lo está hoy). Es un clon sin trabajo propio.
- Actualizar memoria: `github-repos.md` (la línea "`claude-skills` — backed up") y `skills-inventory.md` (L58, clon espejo). Mover la nota de que `agents-config` es el único repo.

## Para quien clone tu setup

Sin cambios de flujo: `git clone … ~/.agents/skills && ./install.sh --dry-run && ./install.sh --profile <nombre>`. Con este plan se llevan el hook nuevo y `opusplan` por defecto. Documentar en el README que `opusplan` es el default y cómo cambiarlo (una línea en `settings.base.json` o su propio `settings.json`).

## Fuera de alcance (te lo marco, no lo toco)

- `Bash(git *)` en `settings.local.json` y los datos de BookLibre en `autoMode`: son locales (no están en el repo) y no se publican, pero conviene acotarlos aparte.

## Verificación

1. `./install.sh --dry-run` → debe reportar que `settings.json` ya coincide (sin diff en `model` ni `hooks`), o mostrar solo diferencias esperadas.
2. `jq` sobre `config/settings.base.json` y `hooks/hooks.json` → JSON válido; `grep critical-reasoning` aparece en ambos.
3. Repetir los 5 payloads de prueba del hook contra `config/hooks/critical-reasoning.sh` desde el repo.
4. `claude plugin validate` (o equivalente) sobre `.claude-plugin/` si está disponible; si no, lo digo.
5. `git status --short` limpio tras el merge; `git push origin master`; `git ls-remote origin master` coincide con `HEAD`.
6. Sesión nueva: `/model` muestra `opusplan`; un prompt con "arquitectura" dispara el aviso del hook.

## Detalle de ejecución

~8 archivos chicos y bien especificados: los edito yo en línea (JSON, markdown y un par de líneas de shell), sin `worker`. El push y el borrado del clon los hago al final, y el borrado solo tras confirmar que el clon está limpio.
