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

## Notes

- `init.sh` never overwrites an existing file unless `--force`; it prints `skip <path> (exists)` instead. Safe to re-run.
- `pnpm create vite`'s current template ships `oxlint`, not ESLint. This skill still writes an ESLint flat config (`typescript-eslint` + `eslint-plugin-react-hooks` + `eslint-plugin-react-refresh` + `eslint-plugin-react-you-might-not-need-an-effect`) because the zero-useEffect doctrine needs those specific rules; `--install` points the `lint` script at `eslint .` instead of the generated `oxlint` default.
- `bootstrap-github.sh all` only runs with `--dry-run` (refuses otherwise) - the real sequence is always confirmed step by step per item 4.
