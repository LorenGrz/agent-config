# config/ — portable Claude Code configuration

Tracked here, symlinked into `~/.claude/` / `~/.codex/` so each agent loads it —
`install.sh` at the repo root creates/repairs all of these:

```
~/.claude/CLAUDE.md  -> ~/.agents/skills/config/CLAUDE.md
~/.claude/rules      -> ~/.agents/skills/config/rules
~/.claude/hooks      -> ~/.agents/skills/config/hooks
~/.claude/agents     -> ~/.agents/skills/config/agents
~/.codex/AGENTS.md   -> ~/.agents/skills/config/AGENTS.md
```

`AGENTS.md` holds the agent-agnostic instructions (read by Codex and other agents); `CLAUDE.md` is
`@~/.agents/skills/config/AGENTS.md` plus Claude Code-only sections (skills, agent routing).

Edit here, commit, push, then `git -C ~/projects/claude-skills pull` for the showcase clone.

**Also tracked:**

- `agents/` — `scout.md`, `worker.md`, `reasoner.md`, the three model-pinned subagents (see root README).
- `settings.base.json` — sanitized base merged into `~/.claude/settings.json` by `install.sh`
  (permissions, model, hooks, statusLine, enabledPlugins, extraKnownMarketplaces, theme). No secrets,
  no machine-specific `autoMode` block.
- `rulesync/` — multi-AI rule/skill generation for Codex CLI, Cursor, and Google Antigravity
  (Gemini). See the root README.

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

## hooks/ — wire into `~/.claude/settings.json`

```json
{
  "hooks": {
    "PreToolUse":  [
      { "matcher": "Edit|Write|MultiEdit", "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/guard-omarchy.sh" }] },
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/scout-readonly.sh" }] }
    ],
    "PostToolUse": [{ "matcher": "Edit|Write|MultiEdit", "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/format-file.sh", "statusMessage": "formatting" }] }],
    "Stop":        [{ "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/stop-git-status.sh" }] }],
    "InstructionsLoaded": [{ "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/log-instructions.sh", "async": true }] }]
  }
}
```

| Script | Event | Does |
|--------|-------|------|
| `guard-omarchy.sh` | PreToolUse (Edit\|Write\|MultiEdit) | denies edits under `~/.local/share/omarchy/` |
| `scout-readonly.sh` | PreToolUse (Bash) | inside the `scout` subagent only: allowlists read-only commands, denies writes/mutating flags |
| `format-file.sh` | PostToolUse | project formatter on the edited file: prettier → eslint `--fix` (TS), `ktlint -F` (Kotlin), `ruff` (Python) |
| `stop-git-status.sh` | Stop | shows uncommitted changes when in a git repo |
| `log-instructions.sh` | InstructionsLoaded | logs session/cwd + `file_path`/`memory_type`/`load_reason`/`trigger_file_path` (or raw JSON if the payload has none of those) to `~/.claude/logs/instructions-loaded.log` |

## Per-repo setup

This `config/` tree is global (machine-wide). Per-repo agent config — `AGENTS.md`,
`.claude/settings.json` with superpowers, branch/lint hooks, CI, GitHub Project —
comes from the `devops/project-init` skill, run once per new repo.
