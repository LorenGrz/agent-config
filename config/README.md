# config/ — the global layer, installed through `~/.agents`

`install.sh` turns these into the tool-neutral layer `~/.agents/` and links each tool to it
(full map in the root README):

```
~/.agents/AGENTS.md   generated: config/AGENTS.md + config/profiles/<name>.md
~/.agents/rules       -> config/rules
~/.agents/hooks       -> config/hooks
~/.agents/models.env  -> config/models.env
~/.claude/CLAUDE.md   generated: @~/.agents/AGENTS.md + @config/CLAUDE.md
~/.claude/agents      -> config/agents
```

`AGENTS.md` (every tool) and `CLAUDE.md` (Claude Code only: skills note + agent routing)
are **generic** — no names or personal paths.

**`profiles/`** — personal content, one file per person. `_template.md` is the commented
template; copy it to `<name>.md` and fill it in (identity, preferred language, GitHub owner,
learning stage, your own project/tool paths, OS settings repo, ...). Never add personal
content to `AGENTS.md` or `CLAUDE.md` above — add it to your profile instead.

Edit here, commit, push; keep any personal mirror clone you maintain in sync yourself (not
tracked by this repo).

**Also tracked:**

- `agents/` — `scout.md`, `worker.md`, `reasoner.md`, the three model-pinned subagents (see root README).
- `settings.base.json` — sanitized base merged into `~/.claude/settings.json` by `install.sh`
  (permissions, model, hooks, enabledPlugins, extraKnownMarketplaces, theme — your statusLine and other keys are left alone). No secrets,
  no machine-specific `autoMode` block.
- `models.env` — `CHEAP_MODEL` for `oc-ask` (one line to switch DeepSeek / GLM / local).
- `rulesync/` — rule/skill generation for Cursor and Google Antigravity (`--with-rulesync`).

**Not tracked** (machine-local / secret): `~/.claude/settings.json` (the real, merged file),
`settings.local.json`, `.credentials.json`, `sessions/`, `projects/` (auto-memory + transcripts),
logs, caches.

> Cowork sessions on the desktop skip a symlinked `~/.claude/rules/` that points outside
> the working dir. This setup targets the Claude Code CLI, where symlinked rules load fine.

## rules/

Path-scoped — each loads only when Claude touches a matching file.

| File | Loads on | Purpose |
|------|----------|---------|
| `typescript.md` | `**/*.ts(x)` | strict typing, boundary validation |
| `react.md` | `**/*.tsx`, `**/*.jsx` | zero-`useEffect`-for-logic doctrine, hooks own data-loading, presentational/container split, Vitest+RTL |
| `next.md` | Next `app/` files, `next.config.*`, `middleware.ts`/`proxy.ts` | RSC-first data loading, Server Actions, client-boundary and secret rules |
| `nestjs.md` | Nest file suffixes | clean-architecture layering |
| `kotlin.md` | `**/*.kt(s)` | Spring Boot layered architecture (domain / service / controller / mapper), Kotest |
| `python.md` | `**/*.py` | uv/ruff/mypy, pydantic, agent-script reliability |
| `testing.md` | `*.test/spec.*` | behaviour over implementation |
| `security.md` | server + config files | authz binding, tokens, CSRF/CORS, input validation, secrets, error handling |

## hooks/ — wired in `settings.base.json`, referenced as `~/.agents/hooks/<script>`

| Script | Event | Does |
|--------|-------|------|
| `guard-omarchy.sh` | PreToolUse (Edit\|Write\|MultiEdit) | denies edits under `~/.local/share/omarchy/` |
| `scout-readonly.sh` | PreToolUse (Bash) | inside the `scout` subagent only: allowlists read-only commands, denies writes/mutating flags |
| `format-file.sh` | PostToolUse | project formatter on the edited file: prettier → eslint `--fix` (TS), `ktlint -F` (Kotlin), `ruff` (Python) |
| `handoff.sh` | Stop (`snapshot claude` async, `nudge`); Codex `notify` (`snapshot codex`) | keeps `docs/plans/HANDOFF.md` current — see ADR 0007 |
| `stop-git-status.sh` | Stop | shows uncommitted changes when in a git repo |
| `log-instructions.sh` | InstructionsLoaded | logs session/cwd + `file_path`/`memory_type`/`load_reason`/`trigger_file_path` (or raw JSON if the payload has none of those) to `~/.claude/logs/instructions-loaded.log` |
| `rtk.sh` | PreToolUse (Bash) | hands read-only/verification commands (git status/diff/log, ls, find/grep, lint/test/tsc) to [rtk](https://github.com/rtk-ai/rtk) to compress their output; everything else passes through so the normal permission flow applies (rtk answers `allow`). No-op without rtk |

## Per-repo setup

This `config/` tree is global (machine-wide). Per-repo agent config — `AGENTS.md`,
`.claude/settings.json` with superpowers, branch/lint hooks, CI, GitHub Project —
comes from the `devops/project-init` skill, run once per new repo.
