# 0001 — One repo for agent config and skills

## Context

Agent config (`CLAUDE.md`, `AGENTS.md`, `rules/`, `hooks/`, subagents) and skills lived in
the same tree already, but AWS skills (`cost-optimizer`, `iam-least-privilege`,
`lambda-patterns`, `sam-deploy`, `serverless-scanner`) were a separate repo
(`LorenGrz/aws-skills`), symlinked in and gitignored. A second, near-duplicate repo
(`LorenGrz/serverless-scanner-skill`) held one of those skills again. Three repos to
keep in sync for one person's setup added overhead with no real isolation benefit —
none of them has independent versioning, contributors, or a release cycle of its own.

## Decision

Fold `aws-skills` into this repo at `aws/` with `git subtree add --prefix=aws`, preserving
its commit history. Drop the external symlinks and the matching `.gitignore` entries.
`serverless-scanner-skill`'s `SKILL.md` and all four `references/*.md` files were
byte-identical to `aws/serverless-scanner` after the merge, so no second copy was kept —
`aws/serverless-scanner` (from the subtree) is the only copy, and no
`aws/serverless-scanner-migration` was needed.

This repo (then `LorenGrz/claude-skills`) was renamed to `LorenGrz/agent-config` on GitHub
to reflect the broader scope: it is not just skills, it is the whole agent config +
skills hub for every AI tool Loren uses.

## Consequences

- One `git clone` + `install.sh` sets up skills, rules, hooks, subagents, and settings.
- `sync.sh`'s existing glob (`<category>/<skill>/SKILL.md`, two levels deep) already covers
  `aws/<skill>/SKILL.md` — no new discovery logic was needed, only repointing the
  `~/.claude/skills` mirror entries that used to target `/home/loren/projects/aws-skills/*`.
- `/home/loren/projects/aws-skills` and `/home/loren/projects/serverless-scanner-skill` keep
  existing on disk as of this change (not archived/renamed — out of scope for an agent to do
  without Loren's direct action) but are no longer the source of truth; update them to point
  here or retire them in a follow-up.
- Oracle APEX (`apexlang`) and Omarchy (`omarchy`, `diagnose-crash`) stay as external
  symlinks: they genuinely belong to other projects/the OS and update independently.
