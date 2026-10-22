# Claude Code specifics

Claude Code-only additions on top of `AGENTS.md` (imported separately by the file that
pulls this one in — do not re-import it here).

## Skills and rules

Skills auto-activate from their `description`; invoke one explicitly with `/<name>`. They live
in the hub's `skills/<category>/<name>/` and reach every tool through `~/.agents/skills`
(`install.sh` keeps it in sync — re-run it after adding or moving a skill).

Path-scoped rules (`~/.claude/rules` → `~/.agents/rules`) load when a touched file matches
their `paths:` frontmatter. Rules are guidance; hard constraints live in each repo's
ESLint/CI/hooks (see `project-init`).

## Agent Routing

Spend Claude usage only where it matters. Cheap tiers go to OpenCode first via `oc-ask`
(model set in `~/.agents/models.env`); Claude's own agents are the fallback.

| Step | First | Fallback (when `oc-ask` exits 3) |
|---|---|---|
| Lookup / inventory / "where is X" | `oc-ask scout "..."` (read-only) | `scout` subagent (Haiku) |
| Implement an already-decided plan step | `oc-ask work "<step> — acceptance: <cmd>"`, then run `<cmd>` yourself | `worker` subagent (Sonnet) if `<cmd>` fails twice or exit 3 |
| Large, well-specified implementation (many files, clear acceptance) — only if the `codex` MCP tool exists | `codex` tool: own git worktree, `sandbox: workspace-write`, `approval-policy: never`, acceptance command in the prompt | `worker` (Sonnet) |
| Decide: architecture, unknown-cause bugs, plan review, hard-to-reverse calls | main session (Opus) / `reasoner` | — |

- `oc-ask work` gets one plan step at a time, with the files to touch and the acceptance
  command. Never hand it open-ended decisions; always verify its result yourself.
- Inline (no `oc-ask`, no subagent) when the change touches ≤3 known files.
- superpowers `subagent_type`: implementer / routine reviewer → `worker`; security- or
  architecture-critical reviewer → `reasoner`; file search → `scout` (try `oc-ask scout` first).
- Prefer `/clear` between unrelated tasks over `/compact`.
