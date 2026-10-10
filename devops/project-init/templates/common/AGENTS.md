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

## Engineering standards

Mechanical rules live in `eslint.config.*`, `tsconfig*.json`, and `.github/workflows/ci.yml` - this section is what no linter catches.

- **TypeScript**: strict mode, no `any` (`unknown` + narrow at untrusted boundaries); discriminated unions for state/result variants; keep DTOs separate from domain types. Deeper: `typescript-code-quality`.
- **Validation**: validate every external input (HTTP, env, storage, third-party) at the boundary before it reaches business logic; never trust a shared type as runtime validation.
- **Errors**: typed result objects or domain-specific error classes; preserve cause when wrapping; never leak stack traces or internals through a public API.
- **API contracts**: request/response DTOs at the boundary, consistent machine-readable error shapes, backward-compatible changes. Deeper: `api-contract-design`.
- **Persistence**: repositories persist/retrieve only, no business decisions; migrations for schema changes; transaction boundaries in the application layer, never spanning an external call. Deeper: `database-persistence-patterns`.
- **Security & secrets**: every repo here is public - never commit `.env`, keys, or credentials; read secrets from env vars; authorize from the authenticated principal server-side, never a client-supplied id. Deeper: `auth-security-basics`.
- **LLM-facing code** (only if this app sends untrusted text to an LLM): separate instructions from data, validate model output against a schema, least-privilege tools, human approval for high-risk actions. Deeper: `prompt-injection-defense`.
- **Testing**: behavior over implementation, name by `should <expected> when <condition>`, mock at the boundary, cover happy path + edge cases + errors. Deeper: `unit-test-generator` to write, `execute-test-suite` to run and fix.
- **Commits**: Conventional Commits (`type(scope): subject`), one logical change per commit. Deeper: `conventional-commit-generator`.
- **Docs**: update this file and `.agents/CONTEXT.md` in the same session anything here changes (stack, scripts, architecture, known issues).

{{STACK_CONVENTIONS}}

## Definition of done

- [ ] `pnpm lint` passes with `--max-warnings 0`
- [ ] `pnpm typecheck` passes
- [ ] `pnpm test` passes, and new behavior shipped with a test
- [ ] `pnpm build` passes
- [ ] `AGENTS.md` / `.agents/CONTEXT.md` updated if stack, scripts, or architecture changed
- [ ] No secrets, keys, or credentials in the diff

## Known issues

<!-- Keep this list current; delete the placeholder once there is real content. -->

## Project backlog

https://github.com/users/{{OWNER}}/projects/{{PROJECT_NUMBER}}
