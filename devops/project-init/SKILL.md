---
name: project-init
description: Use this skill when starting a new project or repo. Scaffolds a repository that works with any AI agent (Codex, Cursor, Claude) and humans - a single AGENTS.md source of truth, CLAUDE.md as a thin pointer, .claude/ with the superpowers plugin and project hooks, a spec-driven workflow, branch flow feat|fix|refactor/<issue>-<slug> to dev with squash merge, a GitHub Project v2 per repo, and real enforcement via ESLint, a git pre-push hook, and CI.
---

# Project Init

Scaffold a new repo once, correctly, instead of re-deciding workflow per project.

## Workflow

1. **Ask**: stack (`react-vite` | `next` | `nestjs` | `node-ts`), project name, visibility (default `public`). Remind Loren: never commit secrets, all his repos are public.

2. **Generate the app, if the target dir is empty**, with the stack's own official generator, then overlay this skill's templates:
   - react-vite: `pnpm create vite@latest <name> --template react-ts`
   - next: `pnpm create next-app@latest <name>`
   - nestjs: `pnpm dlx @nestjs/cli new <name> --package-manager pnpm`
   - node-ts: follow the `typescript-project-starter` skill instead of a generator
   Then run:
   ```
   bash scripts/init.sh --stack <stack> --name <name> --dir <path> --owner LorenGrz [--project-number N] --install
   ```
   Without `--install`, `init.sh` only prints the commands needed (ESLint devDependencies, missing package.json scripts); nothing is installed or written to `package.json` scripts.

3. **Local git setup** (do this, do not delegate it):
   - `git init -b main` if the directory is not already a repo.
   - Confirm `.gitignore` exists and covers: `node_modules/`, `.pnp*`, `.venv/`, `__pycache__/`, `*.py[cod]`, `.env` and `.env.*` (keep `!.env.example`), `*.pem`, `*.key`, `*credentials*.json`, `*secret*.json`, `dist/`, `build/`, `out/`, `.next/`, `.turbo/`, `coverage/`, `*.tsbuildinfo`, `*.log`, `.cache/`, `tmp/`, `.DS_Store`, `Thumbs.db`, `.idea/`, `.vscode/*` (keep `!.vscode/extensions.json`), `.superpowers/`. `init.sh` already wrote this file; only fix it if something is missing.
   - `git config core.hooksPath .githooks`
   - `git add -A && git commit -m "chore: initial project setup"`

4. **External steps, one at a time, each confirmed by Loren before running.** Never hand these to a background agent - they touch GitHub and real resources.
   ```
   bash scripts/bootstrap-github.sh repo     --owner LorenGrz --name <name> --visibility public
   bash scripts/bootstrap-github.sh dev      --owner LorenGrz --name <name>
   bash scripts/bootstrap-github.sh settings --owner LorenGrz --name <name>
   bash scripts/bootstrap-github.sh labels   --owner LorenGrz --name <name>
   bash scripts/bootstrap-github.sh project  --owner LorenGrz --name <name>
   bash scripts/bootstrap-github.sh protect  --owner LorenGrz --name <name>
   ```
   `project` prints the new Project number and the follow-up commit needed to replace `TBD`/`{{PROJECT_NUMBER}}` in the repo (`.github/ISSUE_TEMPLATE/*.yml`, `AGENTS.md`, `.agents/CONTEXT.md`); make that commit yourself, it is not automatic.
   Run with `--dry-run` first any time you want to preview the exact `gh`/`git` commands without touching GitHub.

5. **Verify and report**: repo URL, dev as default branch, Project URL, CI green on the first PR.

## Daily workflow (what the generated AGENTS.md documents)

Everything starts as an issue in the Project. Non-trivial `feat`/`refactor` work goes through superpowers `brainstorming` -> a spec in `docs/superpowers/specs/` -> `writing-plans` -> a plan in `docs/superpowers/plans/`. `fix` work goes through `systematic-debugging` and only gets a spec if behavior changes. Then `scripts/gh-flow.sh start <type> <slug> --issue N`, implement with `subagent-driven-development` + `test-driven-development`, `verification-before-completion`, `scripts/gh-flow.sh pr`, wait for CI, `scripts/gh-flow.sh merge`. Base branch is always `dev`; `main` only moves via `scripts/gh-flow.sh release`. Agents without superpowers installed follow the same steps manually.

The generated `AGENTS.md` is the source of truth for the new repo - read it there, not here, once a project exists. If the code and the doc disagree, fix the doc.

## Standards and enforcement

Every scaffolded repo carries Loren's engineering standards two ways: as conventions any AI reads (`AGENTS.md`'s "Engineering standards" section plus the stack's `AGENTS.stack.md`), and as mechanical enforcement wherever a tool can actually check it:

- **ESLint** (`eslint.config.*`, `typescript-eslint@8.71.1` as of writing): `no-explicit-any`, `no-floating-promises`, `no-misused-promises`, `consistent-type-imports`, `switch-exhaustiveness-check`, `no-unnecessary-condition` (all type-aware via `projectService: true`), plus `eqeqeq` and `no-console` (errors, allowing `console.warn`/`console.error`). react-vite/next also get `eslint-plugin-jsx-a11y@6.10.2` recommended rules and keep the existing zero-useEffect config (`eslint-plugin-react-hooks` + `eslint-plugin-react-you-might-not-need-an-effect`).
  - react-vite and nestjs: `pnpm create vite` and `nest new` both default to `oxlint` with no ESLint config at all now - this skill writes a flat `eslint.config.js`/`.mjs` that supersedes it (same pattern the zero-useEffect override already used for vite). `--install` points `lint` at `eslint` instead of the generator's `oxlint` default.
  - next: `eslint-config-next` already registers the `jsx-a11y` plugin itself (a handful of rules at `warn`). The template merges in `eslint-plugin-jsx-a11y`'s recommended **rules** object only, not its flat-config object (which would try to re-register the same plugin and crash with "Cannot redefine plugin"), and does not need `typescript-eslint` as a direct dependency - `eslint-config-next/typescript` already registers `@typescript-eslint`.
  - node-ts: has no generator, so the template ships the config outright, plus a pinned `typescript@^5` (typescript-eslint 8.x doesn't yet support TypeScript 7, which is now `npm`'s `latest` tag) and `@types/node`.
- **tsconfig strictness**: `init.sh --install` runs `scripts/ensure-tsconfig-strict.js` to turn on `strict`, `noUncheckedIndexedAccess`, `noImplicitOverride`, and `noFallthroughCasesInSwitch` in the project's tsconfig (`tsconfig.app.json` for react-vite, `tsconfig.json` for next/nestjs; node-ts's template ships all four already). All four flags were verified against the stock `pnpm create vite@latest --template react-ts`, `pnpm create next-app@latest`, and `pnpm dlx @nestjs/cli new` scaffolds (October 2026) - none needed to be skipped. The script uses the project's own installed `typescript` to parse the file (comments and all) before deciding what's missing, and only inserts the missing flags as text so existing comments/formatting survive; without `--install` it only prints what it would do.
- **CI** (`.github/workflows/ci.yml`): the `ci` job (kept as-is, branch protection depends on that check name) gains a non-blocking `pnpm audit --audit-level high` step (`continue-on-error: true`) and a `docs-check` step (see below). A new `secret-scan` job runs `gitleaks/gitleaks-action@v3` with `fetch-depth: 0` - free for personal GitHub accounts, no `GITLEAKS_LICENSE` needed. (The task that commissioned this used `@v2`; v2 is EOL as of September 2026 per the project's own README, so this scaffolds `@v3` instead - same inputs/behavior, different Node runtime underneath.)

## Documentation layer

Every scaffolded repo carries enough documentation for a new agent session to work from docs alone: `AGENTS.md`'s "Documentation map" points, in order, to `.agents/CONTEXT.md` (current stack/architecture snapshot), `docs/plans/HANDOFF.md` (current state + how to resume mid-flight work), `docs/architecture.md` (overview/modules/data model/flows/env/deploy skeleton), `docs/decisions/` (ADRs for trade-offs, starting at `0001-record-architecture-decisions.md`, new ones copied from `0000-template.md`), and `docs/superpowers/specs|plans/` (the existing spec-driven workflow). `AGENTS.md`'s "Documentation rules" section says when each gets written and keeps `AGENTS.md` itself capped at ~150 lines. The PR template checklist and a non-blocking `docs-check` step in CI (`scripts/docs-check.sh`, warns via `::warning::` when a PR touches deps/env/docker/workflows/top-level folders without touching docs) nudge toward keeping it current; neither blocks a merge.

## Notes

- `init.sh` never overwrites an existing file unless `--force`; it prints `skip <path> (exists)` instead. Safe to re-run (verified by diffing the tree before/after a second run with no flags changed). Two files are a deliberate exception: `eslint.config.js`/`.mjs` and `AGENTS.md` still get overlaid even if a file already exists there, as long as that file doesn't carry this skill's own marker text yet - `create-next-app --eslint` writes its own `eslint.config.mjs`, and Next 16+ also writes a short `AGENTS.md` (regenerated by `next dev` regardless, per its own comment), both at the exact paths this skill needs to own. Once this skill's version is in place (marker present), normal skip-if-exists behavior resumes.
- `nest new`'s current scaffold ships Vitest, not Jest (`init.sh`'s default `test` script for nestjs follows suit: `vitest run`, only used when the generator's own `package.json` is missing a `test` script, which it currently never is).
- CI's lint step is `pnpm run --if-present lint --max-warnings 0`, with no `--` separator before the flag: the installed pnpm (12.5.1 as of writing) forwards every token after the script name verbatim, including a literal `--`, which breaks `eslint`'s arg parsing if one is added back.
- `bootstrap-github.sh all` only runs with `--dry-run` (refuses otherwise) - the real sequence is always confirmed step by step per item 4.
