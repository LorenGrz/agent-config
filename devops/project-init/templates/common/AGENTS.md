# AGENTS.md

Single source of truth for humans and AI agents (Codex, Cursor, Claude, others) working on **{{PROJECT}}**. If this file and the code disagree, the code wins - fix this file.

## Purpose

<!-- One or two sentences: what this project does and for whom. -->

## Stack

- Type: {{STACK}}
- Package manager: pnpm

## Commands

| Command | Purpose |
|---|---|
| `pnpm dev` | Run the app locally |
| `pnpm test` | Run the test suite |
| `pnpm lint` | Lint (`--max-warnings 0` in CI) |
| `pnpm typecheck` | Type-check without emitting |
| `pnpm format` | Auto-format |
| `pnpm format:check` | Check formatting without writing |

## How we work (spec-driven, with superpowers)

1. Everything starts as an issue in the Project: `scripts/gh-flow.sh issue <feat|fix|refactor|chore> "<title>"`.
2. Non-trivial `feat`/`refactor` work: superpowers `brainstorming` -> write a spec in `docs/superpowers/specs/` -> superpowers `writing-plans` -> write a plan in `docs/superpowers/plans/`.
3. `fix` work: superpowers `systematic-debugging`; only write a spec if the fix changes behavior.
4. `scripts/gh-flow.sh start <feat|fix|refactor> <slug> --issue N` (or create a worktree with superpowers `using-git-worktrees` for parallel work).
5. Execute with superpowers `subagent-driven-development` + `test-driven-development`.
6. Superpowers `verification-before-completion` -> `scripts/gh-flow.sh pr` -> wait for CI to go green -> `scripts/gh-flow.sh merge`. The issue closes and the Project moves it to Done automatically.
7. Agents without superpowers installed: follow the same seven steps manually.

### Branch and PR rules

- Base branch is `dev`. Never commit or push directly to `dev` or `main`.
- One branch per issue: `feat|fix|refactor/<issue>-<slug>`.
- PR titles are Conventional Commits (`feat: ...`, `fix: ...`, `refactor: ...`, `chore: ...`) - the squash merge uses the PR title as the commit message.
- `main` only changes via `scripts/gh-flow.sh release` (a `dev` -> `main` PR, merged with a merge commit).

{{STACK_CONVENTIONS}}

## Known issues

<!-- Keep this list current; delete the placeholder once there is real content. -->

## Project backlog

https://github.com/users/{{OWNER}}/projects/{{PROJECT_NUMBER}}
