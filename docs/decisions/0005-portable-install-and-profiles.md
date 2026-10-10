# 0005 — Portable install, personal profiles, and a plugin marketplace

## Context

This hub mixed shareable config (`config/AGENTS.md`, `config/CLAUDE.md`) with Lorenzo
Graizzaro's own identity, learning stage, GitHub owner, and absolute `/home/loren/...`
paths, and `install.sh`/`sync.sh` hardcoded `~/.agents/skills` as the hub location. Anyone
cloning the repo got Loren's personal instructions mixed into the generic ones, with no
guidance on how to make the setup their own, and `devops/project-init` defaulted its GitHub
owner to `LorenGrz` unconditionally.

## Decision

- **Split personal from generic.** `config/AGENTS.md` and `config/CLAUDE.md` now carry only
  shareable instructions — no names, no roadmap detail, no personal paths. Everything
  personal (identity, language preference, English-coaching toggle, GitHub owner, learning
  stage, project/tool paths, OS settings repo) moved to `config/profiles/loren.md`, with
  `config/profiles/_template.md` as the commented starting point for anyone else.
- **`install.sh --profile <name>`** resolves which profile to import: the flag, then a
  persisted choice (`~/.config/agent-config/profile`), then `gh api user --jq .login` if it
  matches an existing profile, then the same login with `config/profiles/_template.md`
  copied in for the user to fill, then the template directly if `gh` isn't available.
- **`~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` became generated files**, not symlinks:
  the former `@`-imports `config/AGENTS.md` + the chosen profile + `config/CLAUDE.md`; the
  latter concatenates `config/AGENTS.md` + the profile (Codex has no `@`-import). Both carry
  a header comment marking them as generated and owning only files with that marker get
  silently regenerated — a real pre-existing file is backed up once (`.bak.<timestamp>`),
  matching the existing symlink-repair behavior for `rules/hooks/agents`.
- **`install.sh`/`sync.sh` derive the hub location from the script's own path**
  (`$(dirname "${BASH_SOURCE[0]}")`), not a hardcoded `~/.agents/skills` — the repo now
  works cloned anywhere.
- **`devops/project-init`'s `--owner`** defaults to `gh api user --jq .login`, then
  `git config github.user`, and is required if neither resolves — no more silent
  `LorenGrz` default in `init.sh` or `bootstrap-github.sh`.
- **A root `AGENTS.md`/`CLAUDE.md`** (distinct from `config/`'s) tell an agent that just
  opened this repo how to guide a user through install — dry-run, resolve/create a profile,
  confirm, install, verify — implemented as the `meta/agent-config-setup` skill.
- **A Claude Code plugin marketplace** (`.claude-plugin/marketplace.json` +
  `.claude-plugin/plugin.json`) offers a second, lighter install path: skills (via
  category-directory `skills` entries — `aws/`, `development/`, etc., each already a
  directory of `<name>/SKILL.md` folders, so no flattening needed), the three subagents, and
  a generic hook subset (`hooks/hooks.json`, using `${CLAUDE_PLUGIN_ROOT}`) excluding
  `guard-omarchy.sh` (desktop-specific, left to `install.sh`) and the untracked
  cost-tracking status line. Rules are **not** a Claude Code plugin component (verified
  against the plugin manifest/components reference — the standard-layout table has no
  "rules" entry) — they only come via `install.sh`. The plugin method and `install.sh` are
  documented as alternatives, not meant to be combined on one machine; the plugin is not
  installed on this machine, to avoid duplicating the symlinked `install.sh` setup.

## Consequences

- Anyone can clone this repo, run `./install.sh --dry-run`, create their own profile from
  `_template.md`, and get a working setup with none of Loren's personal content leaking in.
- Loren's own machine keeps working identically — `./install.sh --profile loren` reproduces
  the prior behavior, with the same imported content now split across three files instead
  of two, and `~/.claude/CLAUDE.md`/`~/.codex/AGENTS.md` as generated files instead of
  symlinks (functionally equivalent: same content loads, just assembled from three sources).
- `devops/project-init` works for any GitHub user without a `--owner` override, as long as
  `gh` is authenticated or `git config github.user` is set.
- Future personal preferences go in a profile, not in `config/AGENTS.md`/`config/CLAUDE.md`
  — reviewers should reject a PR that adds a name or personal path to either file.
