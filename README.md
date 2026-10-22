# agent-config

Lorenzo Graizzaro's **agent config + skills hub**, built to be portable and tool-neutral:
one repo configures every coding AI (Claude Code, Codex CLI, OpenCode — plus Cursor and
Antigravity via rulesync) through a single neutral layer, `~/.agents/`. If one tool breaks
or a new one shows up, nothing else changes. Personal content lives only in
`config/profiles/<your-name>.md`.

## Install

```bash
git clone https://github.com/LorenGrz/agent-config ~/projects/agent-config
~/projects/agent-config/install.sh --dry-run          # preview, changes nothing
~/projects/agent-config/install.sh --profile <your-name>
```

Clone it anywhere **except** `~/.agents/skills` (that path is now the flat skills folder
Codex and OpenCode read natively — `install.sh` refuses to run from there and prints the
`mv` command if you have the old layout). Re-run `install.sh` any time: it's idempotent,
never deletes a real file (backs it up as `.bak.<timestamp>`), and also refreshes skills.

Inside a Claude Code / Codex / OpenCode session opened in the clone, you can just ask the
agent to "install this repo" — see `AGENTS.md` and the `agent-config-setup` skill.

Optional: `--with-rulesync` (Cursor / Antigravity), `--with-rtk` (output compression).

## How it works

```
repo (source, edited by hand)
  skills/<category>/<name>/   config/{AGENTS.md, CLAUDE.md, profiles, rules, hooks, agents, models.env}   bin/oc-ask
        │  install.sh
        ▼
~/.agents/   (tool-neutral runtime)
  AGENTS.md (generic + profile)   skills/<name>   rules   hooks   models.env
        │  symlinks only
        ▼
Claude Code  ~/.claude/{skills,rules,hooks} → ~/.agents · agents → config/agents
             CLAUDE.md (@~/.agents/AGENTS.md + config/CLAUDE.md) · settings.json (merged)
Codex        ~/.codex/AGENTS.md → ~/.agents/AGENTS.md · skills: native · codex MCP in Claude
OpenCode     ~/.config/opencode/AGENTS.md → ~/.agents/AGENTS.md · skills: native
oc-ask       ~/.local/bin/oc-ask → bin/oc-ask
```

| Loads | When |
|---|---|
| `AGENTS.md` (+ `CLAUDE.md` in Claude) | every session |
| Skills | description only, full `SKILL.md` when the task matches |
| Rules | when a touched file matches `paths:` |
| Hooks | run by the harness at lifecycle events, not read by the model |
| Subagents `scout` / `worker` / `reasoner` | when dispatched (Claude Code) |

Hooks (`config/hooks/`, wired in `config/settings.base.json`):

| Event | Script | Does |
|---|---|---|
| PreToolUse (Edit/Write) | `guard-omarchy.sh` | denies edits under `~/.local/share/omarchy/` |
| PreToolUse (Bash) | `scout-readonly.sh` | inside `scout` only: read-only allowlist |
| PreToolUse (Bash) | `rtk.sh` | compresses read-only command output via rtk (no-op without it) |
| PostToolUse (Edit/Write) | `format-file.sh` | project formatter/linter on the edited file |
| Stop | `stop-git-status.sh` | shows uncommitted changes |
| Stop | `handoff.sh snapshot` | refreshes the auto block of `docs/plans/HANDOFF.md` — no model, no tokens |
| Stop | `handoff.sh nudge` | asks Claude to update the HANDOFF narrative (code changed + ≥20 min) |
| InstructionsLoaded | `log-instructions.sh` | logs what loaded |

## Model routing (save Claude usage)

| Step | First | Fallback |
|---|---|---|
| Lookups / inventories | `oc-ask scout "..."` → OpenCode, read-only | `scout` (Haiku) |
| One decided plan step + acceptance command | `oc-ask work "..."` → OpenCode | `worker` (Sonnet) |
| Large well-specified implementation (optional) | `codex` MCP tool, own worktree | `worker` (Sonnet) |
| Decisions, unknown-cause bugs, plan review | Opus (main session / `reasoner`) | — |

Change the cheap model with one line in `config/models.env` (`CHEAP_MODEL=provider/model`,
see `opencode models`) — DeepSeek, GLM, an Ollama model, whatever. `oc-ask` exits 3 when
OpenCode is missing, fails or runs out, and Claude falls back to its own agents. Details:
`config/CLAUDE.md`, ADR [0006](docs/decisions/0006-neutral-agents-layer-and-routing.md).

### Out of Claude quota

1. Open `opencode` (or `codex`) in the same repo/worktree.
2. It reads `AGENTS.md` and `docs/plans/HANDOFF.md` — the auto block is already current
   (ADR [0007](docs/decisions/0007-automatic-handoff.md)).
3. Continue from "Pending work".

For Codex snapshots too, add to `~/.codex/config.toml`
(`install.sh` prints the exact line):
`notify = ["bash", "~/.agents/hooks/handoff.sh", "snapshot", "codex"]`.

A session panel for running Claude Code and OpenCode side by side (worktrees, fork,
status): [Agent Deck](https://github.com/asheshgoplani/agent-deck), installed by hand.

### Costs

Baseline: Claude Pro + OpenCode Go. Next step if mid-tier work runs short: ChatGPT Plus for
the Codex tier. Claude Max only when `npx ccusage@latest` shows you hitting limits
constantly. Never use a Claude subscription inside OpenCode or a gateway (against
Anthropic's terms).

## Per-project layer — `project-init`

The global layer only guides models. `skills/devops/project-init` scaffolds a repo so
standards hold for any AI and humans: project `AGENTS.md`, `.claude/settings.json` with
superpowers + branch/lint hooks, strict ESLint/tsconfig, pre-push + CI (lint, typecheck,
test, gitleaks), `scripts/gh-flow.sh`, GitHub Project, and the docs layer
(`.agents/CONTEXT.md`, `docs/architecture.md`, ADRs, `docs/superpowers/{specs,plans}/`,
`docs/plans/HANDOFF.md`). Use it for any repo that will outlive a session.

## Skills

| Category | Skills |
|---|---|
| `aws` | `sam-deploy`, `lambda-patterns`, `iam-least-privilege`, `cost-optimizer`, `serverless-scanner` |
| `development` | `api-contract-design`, `code-documenter`, `database-persistence-patterns`, `debug-assistant`, `frontend-design`, `nest-module-generator`, `nextjs-ssr-frontend`, `react-native-mobile`, `react-scalable-frontend`, `regex-builder-explainer`, `typescript-code-quality`, `typescript-project-starter` |
| `quality` | `code-review-safety`, `execute-test-suite`, `react-component-validator`, `unit-test-generator` |
| `devops` | `conventional-commit-generator`, `project-init`, `repository-context-maintainer`, `run-docker-environment` |
| `security` | `auth-security-basics`, `prompt-injection-defense` |
| `productivity` | `ats-resume-formatting`, `cv-linkedin-optimizer`, `meeting-notes-organizer`, `presentation-prep`, `professional-email-drafter` |
| `meta` | `agent-config-setup`, `english-prompt-coach`, `roadmap-coach` |
| external (symlinked in the hub root, gitignored) | `apexlang`, `omarchy`, `diagnose-crash` |

Add a skill: create `skills/<category>/<name>/SKILL.md` (`name` = folder, `description` =
when to use it, portable frontmatter), run `./install.sh`, commit.

## Troubleshooting

| Symptom | Check |
|---|---|
| A skill doesn't activate | `ls ~/.agents/skills`; does its `description` match the task? |
| A tool doesn't see config | `readlink` its link (table above) — should resolve into `~/.agents` |
| `oc-ask` always falls back | run it by hand; check `CHEAP_MODEL` against `opencode models` |
| Hook not firing | `/hooks` in Claude Code; `~/.claude/logs/instructions-loaded.log` |
| `settings.json` looks wrong | the timestamped `.bak` next to it |

## Credits

[obra/superpowers](https://github.com/obra/superpowers) ·
[trailofbits/claude-code-config](https://github.com/trailofbits/claude-code-config) ·
[rtk-ai/rtk](https://github.com/rtk-ai/rtk) ·
[dyoshikawa/rulesync](https://github.com/dyoshikawa/rulesync) ·
[sst/opencode](https://github.com/sst/opencode)
