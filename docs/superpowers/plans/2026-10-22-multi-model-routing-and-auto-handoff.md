# Plan — Multi-model routing (Claude + OpenCode + optional Codex) and automatic handoff

Date: 2026-10-22
Status: draft, awaiting approval
Related ADRs (to write): 0006 multi-vendor routing, 0007 automatic handoff

## Goal

Keep Claude Code (subscription) as the lead for heavy and intermediate work, push cheap
work to open models (DeepSeek, GLM, Kimi, ...) through OpenCode, optionally use Codex for
deep implementation, and make the switch between them lossless: when Claude's quota runs
out, OpenCode (or Codex) picks up from `docs/plans/HANDOFF.md`, which is kept current
automatically — never by asking the model at the last minute.

## Non-goals

- No Claude subscription OAuth inside OpenCode, OmniRoute or any other third-party harness
  (Anthropic consumer terms, Feb/Apr 2026). Claude Code always runs on its own login, which
  also keeps `/voice` working.
- No OmniRoute in the default path. It stays an optional, documented gateway for
  API-key / local providers only.
- No automatic creation of `HANDOFF.md` in repos that don't have one (only `project-init` /
  `adopt.sh` create it).

## Target routing

| Tier | Model | Reached via | Does |
|---|---|---|---|
| cheap | DeepSeek / GLM / Kimi (OpenCode Go) or Ollama | `oc-ask` wrapper → `opencode run` | read-only lookups, summaries, inventories — replaces most `scout` (Haiku) use |
| cheap fallback | Haiku (`scout`) | Claude subagent | only when OpenCode is missing, down, or out of quota |
| worker | Sonnet (`worker`) | Claude subagent | implements decided plans (unchanged) |
| deep worker (optional) | GPT Codex | `codex mcp-server` in Claude Code | large, well-specified implementation tasks — only if `codex` is installed and logged in |
| reasoner | Opus (main / `reasoner`) | Claude | decisions, unknown-cause bugs, plan review (unchanged) |
| quota-out | OpenCode TUI (Go models) or Codex CLI | opened by hand / Agent Deck | continues from `HANDOFF.md` |

## Phase 0 — Verify assumptions (on Loren's machine, before writing code)

Each item becomes a line in ADR 0006 "verified on <date>" — same discipline as ADR 0002's
rulesync target check.

1. Claude Code hooks: `Stop` input has `stop_hook_active`; `{"decision":"block","reason":…}`
   continues the turn; `PreCompact` and `SessionEnd` exist and accept `async`; whether a
   usage-limit stop fires `Stop` or a separate failure event (`StopFailure`?).
2. OpenCode: plugin event for "turn finished" (`session.idle`?), plugin dir
   (`~/.config/opencode/plugins/`), global `AGENTS.md` path, whether it reads
   `~/.claude/skills`, permission keys for a read-only agent (`edit`/`bash`: `deny`).
3. OpenCode Go model IDs: `opencode models | grep -i -E 'deepseek|glm|kimi'`.
4. rulesync: exact target name for OpenCode (`opencode`?) via the config schema.
5. Codex (optional): `codex mcp-server` uses the `codex login` ChatGPT auth; `notify`
   (or a hooks equivalent) in `~/.codex/config.toml` fires after each turn.
6. CodeGraph: install command and MCP registration for Claude Code, Codex and OpenCode.
7. Voice: the settings key for dictation language (so it can live in the profile).

Verification: a short note per item; anything that fails changes the matching phase below.

## Phase 1 — Automatic handoff (all agents)

Two layers, so it works even with zero quota left:

**1a. Deterministic snapshot — no model, no tokens.**
`config/hooks/handoff-snapshot.sh [agent-name]`:
- No-op unless cwd is a git repo containing `docs/plans/HANDOFF.md`.
- Rewrites only the block between `<!-- handoff:auto:start -->` and
  `<!-- handoff:auto:end -->` (appends the block if missing; never touches the narrative):
  timestamp, agent that last ran (claude / opencode / codex), branch, HEAD, last 5 commits,
  `git status --short`, `git diff --stat`, newest file in `docs/superpowers/plans/`.
- Atomic write (temp file + `mv`), `flock` so parallel agents don't clobber each other.
- Wired to: Claude `Stop` (async), `PreCompact`, `SessionEnd`; OpenCode plugin on turn end;
  Codex `notify`.

**1b. Narrative nudge — Claude only, throttled.**
`config/hooks/handoff-nudge.sh` on `Stop`:
- Exit 0 if `stop_hook_active` is true (no loops) or there's no `HANDOFF.md`.
- Hash `HEAD + git status --porcelain`; exit 0 if unchanged since the last nudge or if the
  last nudge was < `HANDOFF_NUDGE_MINUTES` (default 20) ago. State in
  `.git/agent-handoff/` (never committed).
- Otherwise block once with: "Rewrite Current state / Active plan / Pending work in
  docs/plans/HANDOFF.md (≤15 lines total, replace, don't append). Don't touch the auto block."
- Cost bound: at most one short extra turn per 20 min of real changes.

**1c. Read side.** `config/AGENTS.md` Working Style: "If `docs/plans/HANDOFF.md` exists,
read it before anything else when resuming work." (Project template already says it.)

**1d. Templates.** Add the auto-block markers to
`devops/project-init/templates/common/docs/plans/HANDOFF.md` and to `adopt.sh`'s generated
content.

Files: `config/hooks/handoff-snapshot.sh`, `config/hooks/handoff-nudge.sh`,
`config/settings.base.json`, `hooks/hooks.json` (plugin subset: both scripts),
`config/opencode/plugins/handoff.js`, `config/codex/config.fragment.toml`,
`config/AGENTS.md`, project-init template + `adopt.sh`.

Verification:
- `bats`-style shell test in a temp git repo: snapshot writes the block, is idempotent,
  leaves narrative byte-identical, no-ops without `HANDOFF.md`.
- Nudge: fixture JSON with `stop_hook_active: true` → exit 0; changed tree → block JSON;
  second call inside 20 min → exit 0.
- Manual: edit a file in Claude Code, end the turn, check the auto block; same in OpenCode.

## Phase 2 — OpenCode as the cheap tier

- `install.sh --with-opencode` (idempotent, backs up like the rest):
  - generates `~/.config/opencode/opencode.json` from `config/opencode/opencode.base.json`:
    OpenCode Go provider, optional Ollama provider (`localhost:11434/v1`), MCP servers
    (CodeGraph if enabled), the handoff plugin, and a read-only `cheap-scout` agent
    (edits and mutating bash denied);
  - links the global `AGENTS.md` (+ profile) for OpenCode;
  - links skills if OpenCode reads them natively, otherwise relies on rulesync (Phase 5).
- `config/bin/oc-ask` (symlinked to `~/.local/bin/oc-ask`):
  `oc-ask [--model M] "question"` → `opencode run --attach $OC_URL --agent cheap-scout -m
  ${M:-$AGENT_CHEAP_MODEL} --format json` → prints only the final answer, with a timeout.
  Starts `opencode serve` on demand if nothing is listening. Exit code 3 = "unavailable or
  out of quota" so Claude falls back to `scout`.
- `config/CLAUDE.md` Agent Routing: lookups/inventories → `oc-ask` first; `scout` only on
  exit 3. Keep the file ≤60 lines (ADR 0004).
- `settings.base.json` permissions.allow: `Bash(oc-ask *)`.
- Profile: `AGENT_CHEAP_MODEL` default (picked from Phase 0 step 3).

Verification: `oc-ask "list the files that define hooks"` returns an answer with
`--model` set to a Go model; with OpenCode stopped it exits 3; inside Claude Code a lookup
request goes through `oc-ask` (check the transcript); `ccusage` shows fewer Haiku calls.

## Phase 3 — Codex (optional, only if installed)

- `install.sh` detects `codex` on PATH and a valid login; if present:
  - `claude mcp add -s user codex -- codex mcp-server` (skip if already registered);
  - merges `config/codex/config.fragment.toml` into `~/.codex/config.toml` (handoff
    `notify`, CodeGraph MCP) — backup first, never overwrite unrelated keys.
  - If absent: prints one line ("Codex not found — skipping deep-worker tier").
- `config/CLAUDE.md` routing: "deep worker" row — use the `codex` MCP tool only for
  well-specified tasks with an acceptance command, in a dedicated worktree, sandbox
  `workspace-write`. Approval policy is an open decision (below).
- `~/.codex/AGENTS.md` stays as today (generated by install.sh).

Verification: `claude mcp list` shows `codex`; a toy task ("add a unit test for X") run
through the MCP tool lands in its worktree and passes the given command.

## Phase 4 — Shared structural context: CodeGraph

- `install.sh --with-codegraph`: installs CodeGraph and registers it as an MCP server for
  Claude Code (user scope), OpenCode (`opencode.json`) and Codex (fragment) — one index,
  three agents.
- `config/AGENTS.md`: "For structural questions (who calls X, impact of changing Y) use the
  code-graph tool before reading files."
- Per-repo opt-out documented (huge monorepos / tiny repos).

Verification: same question asked with and without the MCP in a real repo; compare tokens
with `ccusage`; record numbers in ADR 0006.

## Phase 5 — rulesync: reach OpenCode

- Add the verified OpenCode target to `config/rulesync/rulesync.jsonc` and widen the proof
  skill set in `build.sh` if OpenCode needs it.
- Update ADR 0002's table with the OpenCode row.

Verification: `install.sh --with-rulesync` with `HOME` pointed at a temp dir, as in ADR 0002.

## Phase 6 — Central session panel (documented, not auto-installed)

- README "Daily workflow": Agent Deck as the panel for Claude Code + OpenCode (+ Codex)
  sessions with worktrees; CCManager as the no-tmux alternative. `install.sh` only prints
  the install hint (no `curl | bash` on the user's behalf).
- "Out of Claude quota" runbook: open OpenCode in the same worktree from Agent Deck →
  it reads `AGENTS.md` + `HANDOFF.md` → continue.

## Phase 7 — Voice

- Profile: dictation language Spanish (key from Phase 0 step 7) and a note that `/voice`
  needs the claude.ai login — never route Claude Code through `ANTHROPIC_BASE_URL`.

## Phase 8 — Docs

- ADR 0006 (multi-vendor routing + verified facts), ADR 0007 (automatic handoff).
- README: routing table, hooks table, install flags, cost section (Claude Pro + OpenCode Go
  baseline; ChatGPT Plus as the next step; Max only when `ccusage` shows constant limits).
- `config/README.md` hooks table; plugin `hooks.json`.

## Order and delivery

One branch per phase (`feat/auto-handoff`, `feat/opencode-tier`, `feat/codex-tier`,
`feat/codegraph`, `docs/…`), each with its own PR and verification output. Phase 1 first:
it's useful on its own and everything else depends on handoff working.

## Open decisions (Loren)

1. Cheap tier: read-only only for now (recommended), or also mechanical edits in an
   isolated worktree?
2. Nudge interval: 20 min OK?
3. Codex MCP approval policy: `never` inside a dedicated worktree (fast, recommended) or
   `on-request` (safer, blocks without a human)?
4. Ollama/local models: include in the base config or keep as a documented option?
5. Push access: this session only has read access to the repo — either grant push so the
   branches/PRs are opened from here, or receive patches to apply locally.
