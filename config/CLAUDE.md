@~/.agents/skills/config/AGENTS.md

# Claude Code specifics

These instructions adapt Claude Code to Loren's current Codex workflow. Treat them as persistent personal preferences.

## Skills

When a task matches an existing skill, invoke it before acting (`/<name>` or let it auto-activate). Load only the skill needed for the task.

Skills auto-load from `/home/loren/.claude/skills` (flat symlinks). Source of truth is the categorised tree in `/home/loren/.agents/skills/<category>/<skill>/`, which is a git clone of github.com/LorenGrz/claude-skills. Workflow: edit in the hub, commit, `git push`, then `git -C /home/loren/projects/claude-skills pull` (that second clone is the public showcase). After adding/moving a skill run `/home/loren/.agents/skills/sync.sh` to refresh the mirror. AWS skills live in `/home/loren/projects/aws-skills`; Oracle APEX (`apexlang`) in `/home/loren/projects/oracle-skills` (`apex/apexlang`); Omarchy/diagnose-crash ship with Omarchy — all symlinked into the hub and gitignored there.

Path-scoped rules in `/home/loren/.claude/rules/` (`typescript`, `react`, `nestjs`, `testing`, `python`) load automatically when Claude touches matching files. Some skills also carry `paths:` frontmatter and surface on their own for the matching file types.

Routing (by skill name):

- PDF work: use MarkItDown first — `/home/loren/projects/markitdown/.venv/bin/markitdown`.
- React build/refactor: `react-scalable-frontend`. React review: `react-component-validator`.
- TypeScript quality: `typescript-code-quality`. New project/repo scaffolding: `project-init` (agents setup, CI, GitHub Project, branch flow). Tooling upgrade of an existing JS/TS project: `typescript-project-starter`.
- Roadmap planning: `roadmap-coach`. NestJS modules: `nest-module-generator`. Next.js SSR: `nextjs-ssr-frontend`.
- Persistence: `database-persistence-patterns`. API contracts: `api-contract-design`.
- Tests: `unit-test-generator` to write, `execute-test-suite` to run and fix.
- Debugging: `debug-assistant`. Docs: `code-documenter`. Regex: `regex-builder-explainer`. Commits: `conventional-commit-generator`.
- Security/auth: `auth-security-basics` only when relevant.
- Omarchy/Linux desktop: `omarchy` before editing terminal, Hyprland, Waybar, Mako, Walker, theme, or desktop config.
- AWS: `sam-deploy` (SAM), `lambda-patterns` (Lambda code), `iam-least-privilege` (IAM — always least privilege), `cost-optimizer` (cost review), `serverless-scanner` (migration analysis).
- Oracle APEX: `apexlang` for generating/editing APEX apps (`.apx`, page/app metadata, APEXlang workflows).

Rule files are guidance; hard constraints live in each repo's ESLint/CI/hooks (see `project-init`).

## Agent Routing

Three model-pinned agents live in `/home/loren/.claude/agents/`: `scout` (haiku, read-only), `worker` (sonnet, mechanical execution), `reasoner` (opus, decisions).

### Orchestrator mode (default, always — including auto mode)

The main chat (Opus) is the **orchestrator**: it talks with Loren, plans, decides, and reviews. It does not implement multi-step work itself, so the conversation never blocks and Loren can keep planning or talking (including voice mode) while work runs.

- **Implementation of an approved plan** → hand the whole plan to **one background Opus agent** (`reasoner`, `run_in_background: true`). Subagents can't spawn subagents, so if part of the plan is purely mechanical and independent, the orchestrator launches a `worker` for it in parallel instead.
- Its prompt must be self-contained: the plan, file paths, constraints, what it must NOT do, and the acceptance command.
- While it runs, keep answering Loren; don't poll it. When it reports back, verify the claims (run the acceptance command or spot-check) and summarize.
- Independent tasks → separate background agents in one message; same files → `isolation: "worktree"`.
- **Stay inline** (orchestrator does it): quick single-step answers/edits, and anything needing Loren in the loop or touching the outside world — logins, deploys, creating repos/cloud projects, pushing, paid resources, secrets. Background agents can't ask Loren questions, so give them no step that needs approval.

Pick the first row that matches (for sub-delegation and one-off tasks):

| Signal | Agent | Model |
|---|---|---|
| Single step, file and line already known | none — do it inline | — |
| Read-only: locate, inventory, map conventions, "where is X" | `scout` | haiku |
| Mechanical and fully specified, with an objective acceptance check (tests pass, `pnpm lint --max-warnings 0`, typecheck) | `worker` | sonnet |
| Scope crosses modules, architecture or API contract decision, bug with unknown cause, hard to revert | `reasoner` | opus |
| High risk and hard to verify (auth, secrets, data migration) | two `reasoner` in parallel, blind to each other, then compare | opus |

Discriminators, in order: **scope** (file → module → system), **verifiability** (is there a command that says yes/no?), **reversibility**. A task that is verifiable and reversible drops a tier even if it is long.

Rules:

- Chain is `scout` → `reasoner` (plan) → `worker` (execute) → verify. Skip stages that add nothing.
- A subagent gets the acceptance command in its prompt, or it is not ready to be delegated.
- Launch independent agents in a single message so they run in parallel. Use `isolation: "worktree"` when two of them would write the same files.
- Escalate on evidence, not on impatience: `worker` failing its check twice, or `debug-assistant`'s first hypothesis not reproducing, moves the task to `reasoner`.
- Per-skill defaults: `execute-test-suite` → scout tier until red; `unit-test-generator`, `react-component-validator`, `nest-module-generator` → worker; `team-architect-agent`, `api-contract-design`, `auth-security-basics`, `code-review-safety` → reasoner.
