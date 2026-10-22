---
name: agent-config-setup
description: Use this skill when the user wants to install, set up, update, or personalize agent-config (this repo) — "install this repo", "set up my profile", "update my agent config", or any request to run/repair install.sh. Guides the install.sh --profile flow end to end.
---

# agent-config Setup

Guide a user through installing or updating this repo's config on their machine. Never run
a real (non-dry-run) install without the user confirming the plan first — `install.sh`
touches `~/.claude/` and `~/.codex/`.

## Workflow

1. **Dry run.** From the repo root, run `./install.sh --dry-run` (add `--profile <name>` if
   the user already told you their profile). Show the plan: what it would generate, link,
   or back up. Nothing changes yet.

2. **Resolve the profile.**
   - If the user already has `config/profiles/<name>.md`, confirm that's the one to use.
   - If not, ask: their name, preferred language for replies, whether they want a 2-line
     `English note` + `Better` line added when they write partly/fully in English, their
     GitHub owner/username (for `devops/project-init` defaults), and a short line on their
     current stack/learning stage. Create `config/profiles/<name>.md` from
     `config/profiles/_template.md` with their answers filled in. Don't put any of this in
     `config/AGENTS.md` or `config/CLAUDE.md` — those must stay shareable.
   - `install.sh` without `--profile` also auto-detects via `gh api user --jq .login` and
     persists the choice to `~/.config/agent-config/profile`; mention this but still confirm
     with the user rather than relying on it silently.

3. **Real install**, only after the user confirms the dry-run plan:
   ```
   ./install.sh --profile <name>
   ```
   This builds the neutral layer `~/.agents/` (generated `AGENTS.md` + profile, flat
   `skills/`, `rules`, `hooks`, `models.env`), then links each tool to it: Claude Code
   (`~/.claude/{skills,rules,hooks,agents}`, generated `CLAUDE.md`, merged
   `settings.json`), Codex (`~/.codex/AGENTS.md`), OpenCode (`~/.config/opencode/AGENTS.md`)
   and `~/.local/bin/oc-ask`. Real files it doesn't own are backed up once as
   `.bak.<timestamp>`. If the hub is still cloned at `~/.agents/skills` (old layout) it stops
   and prints the `mv` command — relay it to the user, don't move the clone yourself.

4. **Verify:**
   - `cat ~/.agents/AGENTS.md` — generated header, then `config/AGENTS.md` + the profile.
   - `cat ~/.claude/CLAUDE.md` — generated header importing `~/.agents/AGENTS.md` and
     `config/CLAUDE.md`; confirm both paths exist.
   - `readlink ~/.codex/AGENTS.md ~/.config/opencode/AGENTS.md` — both → `~/.agents/AGENTS.md`
     (OpenCode only if installed).
   - `readlink ~/.claude/skills ~/.claude/rules ~/.claude/hooks ~/.claude/agents` — the
     first three → `~/.agents/...`, `agents` → the repo's `config/agents`.
   - `ls ~/.agents/skills | head` — populated; `readlink ~/.agents/skills/<any-name>`
     resolves to `skills/<category>/<name>/` in the repo.
   - Re-running `./install.sh --profile <name>` should report everything already up to
     date (idempotent) — run it once more to prove that.

5. **Optional extras**, each asked about before running, never bundled silently:
   - `--with-rulesync`: also generates Cursor and Google Antigravity (Gemini) global config
     via `config/rulesync/`. Explain: Claude Code, Codex and OpenCode already work without it;
     this is only useful if the user also drives Cursor or Antigravity. Requires `pnpm dlx` (network).
   - `--with-rtk`: installs [`rtk`](https://github.com/rtk-ai/rtk), a separate token-
     reduction tool (its hook is already wired in `config/settings.base.json`). Explain it's unrelated to the config above —
     skip unless the user specifically wants it.

## Notes

- `install.sh` never deletes a real file; it backs up anything it doesn't already own
  before writing over it. If something looks wrong after install, check for a
  `.bak.<timestamp>` sibling next to the file in question.
- If `gh` isn't installed/authenticated and the user gave no `--profile`, `install.sh`
  falls back to `config/profiles/_template.md` directly — point this out so the user
  doesn't end up running with unfilled placeholder content by accident.
