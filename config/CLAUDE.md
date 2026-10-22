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

Pick the model by task complexity, not by habit:

- **Opus** (main session / `reasoner`) only reasons and decides — architecture, unknown-cause bugs, plan review, hard-to-reverse calls. Never does worker-type writing.
- **Sonnet** (`worker`) writes all code/docs from an already-decided plan.
- **Haiku** (`scout`) does light read-only lookups only.

When superpowers dispatches subagents (`subagent-driven-development`, `executing-plans`, `dispatching-parallel-agents`, `requesting-code-review`), set `subagent_type`:

| Subagent role | subagent_type |
|---|---|
| Implementer | `worker` |
| Spec/code-quality reviewer (routine) | `worker` |
| Reviewer for security/architecture-critical changes | `reasoner` |
| File search / inventory | `scout` |

Inline (no subagent) when the change touches ≤3 known files — a cold-start subagent costs more than doing it. Prefer `/clear` between unrelated tasks over `/compact`.
