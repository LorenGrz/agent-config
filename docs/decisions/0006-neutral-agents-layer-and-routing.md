# 0006 — Tool-neutral `~/.agents` layer and OpenCode-first routing

## Context

Everything lived under Claude Code's own paths (`~/.claude/skills`, `rules`, `hooks`),
with Codex and others reached through generated copies or rulesync. Two problems:

1. **Lock-in.** If Claude Code breaks or is replaced, the setup has to be migrated. Codex
   and OpenCode now read `~/.agents/skills/<name>/SKILL.md` natively (the Agent Skills
   open standard), so there is a neutral place to put things.
2. **Cost.** Routing only spanned Anthropic models (Opus/Sonnet/Haiku). Lookups and
   mechanical, already-decided work don't need Claude usage at all.

The hub itself was cloned at `~/.agents/skills`, which collides with that native path
(category folders, not flat `<name>/SKILL.md`).

## Decision

- **Three layers.** The repo (source, cloned anywhere) → `~/.agents/` (generated/linked by
  `install.sh`: `AGENTS.md` = generic + profile, flat `skills/`, `rules`, `hooks`,
  `models.env`) → per-tool adapters that are only symlinks into `~/.agents` (Claude's
  generated `CLAUDE.md` and merged `settings.json` are the exceptions). No tool-specific
  file is a source. Removing a tool = deleting its links.
- Skills move to `skills/<category>/<name>/`. `sync.sh` folds into `install.sh`.
  `install.sh` refuses to run while the hub is still at `~/.agents/skills` and prints the
  `mv` command instead of moving a git checkout itself.
- Removed as duplicates: the Claude plugin marketplace install method, `codex-workflows`,
  `team-architect/implementer/reviewer-agent`, the skill routing list in `config/CLAUDE.md`.
- **Routing:** cheap tiers go to OpenCode through `bin/oc-ask` (`scout` = OpenCode `plan`
  agent, read-only; `work` = `build` agent for one decided plan step with an acceptance
  command). The model is one line, `CHEAP_MODEL` in `config/models.env`. Exit 3 = fall back
  to Claude's `scout` (Haiku) / `worker` (Sonnet). Opus keeps the decisions.
- **Codex (optional):** if installed, registered as an MCP server in Claude Code for large,
  well-specified work in its own worktree (`workspace-write`, approval `never`).
- Claude Code always runs on its own login — never through a gateway or third-party
  harness (Anthropic consumer terms; also keeps `/voice` working).

## Not verified here (check on the real machine)

- OpenCode reads `~/.config/opencode/AGENTS.md` as global instructions.
- `opencode run --agent plan` stays read-only and doesn't hang on a permission prompt in
  non-interactive mode (the 300 s timeout in `oc-ask` bounds it either way).
- `claude mcp get codex` exits non-zero when the server isn't registered.
- Exact OpenCode Go model IDs for `CHEAP_MODEL` (`opencode models`).

## Consequences

- A new tool needs one adapter (a few `link` lines in `install.sh`) or a rulesync target.
- Claude usage drops for lookups and mechanical steps; quality of those steps depends on
  the cheap model, so Claude always runs the acceptance command itself.
- Cut on purpose (revisit when needed): code-graph MCP, per-tool generated agent files,
  a shared MCP list, `opencode serve` warm sessions.
