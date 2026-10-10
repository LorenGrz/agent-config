# claude-skills

Personal Claude Code setup for Lorenzo Graizzaro:

- **skills** (this tree, by category) — loaded on demand when a task matches their `description`.
- **[`config/`](./config/)** — `CLAUDE.md`, path-scoped `rules/`, and lifecycle `hooks/`,
  symlinked into `~/.claude/`. See [`config/README.md`](./config/README.md).

`~/.agents/skills` is a clone of this repo; `~/projects/claude-skills` is a second clone (public showcase).

## How skills are discovered

Claude Code only discovers skills at `~/.claude/skills/<skill-name>/SKILL.md` —
**direct children, no category subfolders**. A path like
`~/.claude/skills/development/code-documenter/SKILL.md` is **not** detected.

So the layout is split in two:

| Layer | Path | Structure |
|-------|------|-----------|
| **Source of truth** (this repo, cloned to `~/.agents/skills`) | `~/.agents/skills/<category>/<skill>/SKILL.md` | organised by category |
| **What Claude Code reads** | `~/.claude/skills/<skill>` → symlink into the tree | **flat** |

`~/.agents/skills` is never read by Claude Code directly, only the flat symlink
mirror in `~/.claude/skills`. Directory symlinks are officially supported and a
skill reachable from more than one path is loaded once.

Run [`./sync.sh`](./sync.sh) after adding, moving, or removing a skill to
regenerate the flat symlinks in `~/.claude/skills`.

## Categories

### `development/` — building features

| Skill | Purpose |
|-------|---------|
| [`api-contract-design`](./development/api-contract-design/SKILL.md) | REST API contracts, DTOs, validation, backward-compatible changes |
| [`code-documenter`](./development/code-documenter/SKILL.md) | Reference docs for a function/class/module in the language's native doc format |
| [`database-persistence-patterns`](./development/database-persistence-patterns/SKILL.md) | Repositories, migrations, transactions, domain/storage separation |
| [`debug-assistant`](./development/debug-assistant/SKILL.md) | Error + stack trace → root cause → minimal fix, with a prevention tip |
| [`nest-module-generator`](./development/nest-module-generator/SKILL.md) | NestJS modules/controllers/services with clean-architecture layering |
| [`nextjs-ssr-frontend`](./development/nextjs-ssr-frontend/SKILL.md) | Next.js App Router, server components, route handlers, caching |
| [`react-native-mobile`](./development/react-native-mobile/SKILL.md) | React Native navigation, state, permissions, platform differences |
| [`react-scalable-frontend`](./development/react-scalable-frontend/SKILL.md) | Scalable React architecture — components, state, hooks, folders |
| [`regex-builder-explainer`](./development/regex-builder-explainer/SKILL.md) | Build a regex from natural language or explain one, with match examples |
| [`typescript-code-quality`](./development/typescript-code-quality/SKILL.md) | Strict typing, safe error modelling, validation boundaries |
| [`typescript-project-starter`](./development/typescript-project-starter/SKILL.md) | Scaffold JS/TS projects with pnpm, scripts, tests, lint, format |

### `quality/` — review and tests

| Skill | Purpose |
|-------|---------|
| [`code-review-safety`](./quality/code-review-safety/SKILL.md) | Review changes for correctness, security, test coverage, architecture drift |
| [`execute-test-suite`](./quality/execute-test-suite/SKILL.md) | Detect the build tool, run the right suite, drive a fix-and-retest loop |
| [`react-component-validator`](./quality/react-component-validator/SKILL.md) | Review React components; avoid bad effects; useOnInit lifecycle standard |
| [`unit-test-generator`](./quality/unit-test-generator/SKILL.md) | Generate a unit test file for one unit (happy path, edges, errors) |

### `devops/` — repo, environment, release

| Skill | Purpose |
|-------|---------|
| [`conventional-commit-generator`](./devops/conventional-commit-generator/SKILL.md) | Commit messages in Conventional Commits form from a diff or description |
| [`project-init`](./devops/project-init/SKILL.md) | Scaffolds a new repo for any AI agent: AGENTS.md, `.claude` with superpowers + hooks, spec-driven flow, feat/fix/refactor PRs to dev, GitHub Project backlog, CI |
| [`repository-context-maintainer`](./devops/repository-context-maintainer/SKILL.md) | Keep `.agents/CONTEXT.md` and project docs current |
| [`run-docker-environment`](./devops/run-docker-environment/SKILL.md) | Start local docker-compose dev databases, inspect container health |

### `security/`

| Skill | Purpose |
|-------|---------|
| [`auth-security-basics`](./security/auth-security-basics/SKILL.md) | Auth, authorization, token/session handling, secrets, input validation |
| [`prompt-injection-defense`](./security/prompt-injection-defense/SKILL.md) | OWASP LLM01 defence-in-depth for apps that send untrusted text to an LLM |

### `productivity/` — non-code deliverables

| Skill | Purpose |
|-------|---------|
| [`ats-resume-formatting`](./productivity/ats-resume-formatting/SKILL.md) | Parse-safe CV layout for Workday/Greenhouse/Lever: single column, stacked Title/Company/Dates, plain-text test. Vendored from [msdanyg/ats-resume-skill](https://github.com/msdanyg/ats-resume-skill) (MIT) |
| [`cv-linkedin-optimizer`](./productivity/cv-linkedin-optimizer/SKILL.md) | Tailor CV and LinkedIn to a job posting; ATS keywords; honest gaps |
| [`meeting-notes-organizer`](./productivity/meeting-notes-organizer/SKILL.md) | Raw notes → summary, decisions, action items with owner and deadline |
| [`presentation-prep`](./productivity/presentation-prep/SKILL.md) | Topic/briefing → slide-by-slide structure with visuals, notes, timing |
| [`professional-email-drafter`](./productivity/professional-email-drafter/SKILL.md) | Work emails with situation-appropriate tone, subject line, next step |

### `meta/` — how Loren works

| Skill | Purpose |
|-------|---------|
| [`codex-workflows`](./meta/codex-workflows/SKILL.md) | Reuse Loren's Codex/local-agent workflows and migration patterns |
| [`english-prompt-coach`](./meta/english-prompt-coach/SKILL.md) | Short English feedback on prompts written partly/fully in English |
| [`roadmap-coach`](./meta/roadmap-coach/SKILL.md) | Keep work aligned to the full-stack TS learning roadmap; task sizing |
| [`team-architect-agent`](./meta/team-architect-agent/SKILL.md) | Small-team architect role: boundaries, contracts, tradeoffs, plans |
| [`team-implementer-agent`](./meta/team-implementer-agent/SKILL.md) | Small-team implementer role: scoped production code from a plan |
| [`team-reviewer-agent`](./meta/team-reviewer-agent/SKILL.md) | Small-team reviewer role: bugs, missing tests, security, drift |

## Skills linked from other repos

These are **not** stored here. They live in their own repos and are symlinked
into `~/.agents/skills` (and mirrored flat into `~/.claude/skills`).

| Skill | Source repo | Conceptual category |
|-------|-------------|---------------------|
| `sam-deploy`, `lambda-patterns`, `cost-optimizer`, `serverless-scanner` | [`LorenGrz/aws-skills`](https://github.com/LorenGrz/aws-skills) | devops |
| `iam-least-privilege` | [`LorenGrz/aws-skills`](https://github.com/LorenGrz/aws-skills) | security |
| `apexlang` (Oracle APEX app generation) | [`oracle/skills`](https://github.com/oracle/skills) — `apex/apexlang`, UPL-1.0 | development |
| `omarchy`, `diagnose-crash` | `/usr/share/omarchy/default/agents/skills/` (ships with Omarchy) | system |

`omarchy` and `diagnose-crash` are not vendored here — they update with the OS.
On a machine without Omarchy, install it (or skip those two skills).

## Clones

- `~/.agents/skills` — the working hub. Git clone of this repo; the flat mirror
  in `~/.claude/skills` symlinks into it. Edit here.
- `~/projects/claude-skills` — a second clone, the public showcase. Keep it
  current with `git -C ~/projects/claude-skills pull` after pushing.

## Setup on a new machine

```bash
# 1. Clone the hub
git clone https://github.com/LorenGrz/claude-skills ~/.agents/skills

# 2. Link the external skill repos (see table above), e.g.
git clone https://github.com/LorenGrz/aws-skills ~/projects/aws-skills
git clone https://github.com/oracle/skills ~/projects/oracle-skills
ln -sfn ~/projects/oracle-skills/apex/apexlang ~/.agents/skills/apexlang

# 3. Generate the flat symlink mirror Claude Code reads
cd ~/.agents/skills && ./sync.sh
```

## Adding or changing a skill

1. Create/edit `~/.agents/skills/<category>/<skill>/SKILL.md`.
2. Frontmatter: `name`, a specific `description` starting with "Use this skill
   when…", optional `metadata`, optional `paths:` to auto-activate for matching
   files.
3. Run `./sync.sh` to refresh `~/.claude/skills`.
4. `git commit` and `git push`, then pull in the showcase clone.
