@~/.agents/skills/config/AGENTS.md

# Claude Code specifics

Adapts Claude Code to Loren's workflow. Persistent personal preferences.

## Skills

Invoke a matching skill before acting (`/<name>` or auto-activate); load only what the task needs.

Skills live in `/home/loren/.agents/skills/<category>/<skill>/`, mirrored flat into `/home/loren/.claude/skills` by `sync.sh` — run it after adding/moving a skill. Hub = github.com/LorenGrz/agent-config; edit there, commit, push, then `git -C /home/loren/projects/claude-skills pull` (public showcase clone). AWS skills live in `aws/` inside the hub (folded in via git subtree, not a separate repo). Oracle APEX (`apexlang`) and Omarchy/`diagnose-crash` stay as external symlinks.

Path-scoped rules in `/home/loren/.claude/rules/` load automatically when Claude touches a matching file (`paths:` frontmatter); some skills carry the same frontmatter.

Routing (by skill name):

- PDF work: MarkItDown first — `/home/loren/projects/markitdown/.venv/bin/markitdown`.
- React build/refactor: `react-scalable-frontend`. React review: `react-component-validator`.
- TypeScript quality: `typescript-code-quality`. New repo scaffolding: `project-init`. Tooling upgrade of an existing project: `typescript-project-starter`.
- Roadmap planning: `roadmap-coach`. NestJS modules: `nest-module-generator`. Next.js SSR: `nextjs-ssr-frontend`.
- Persistence: `database-persistence-patterns`. API contracts: `api-contract-design`.
- Tests: `unit-test-generator` to write, `execute-test-suite` to run and fix.
- Debugging: `debug-assistant`. Docs: `code-documenter`. Regex: `regex-builder-explainer`. Commits: `conventional-commit-generator`.
- Security/auth: `auth-security-basics` only when relevant.
- Omarchy/Linux desktop: `omarchy` before editing terminal, Hyprland, Waybar, Mako, Walker, theme, or desktop config.
- AWS (`aws/`): `sam-deploy`, `lambda-patterns`, `iam-least-privilege` (always least privilege), `cost-optimizer`, `serverless-scanner` (migration analysis).
- Oracle APEX: `apexlang` for `.apx` apps and APEXlang workflows.

Rule files are guidance; hard constraints live in each repo's ESLint/CI/hooks (see `project-init`).

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
