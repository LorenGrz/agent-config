# 0007 — Automatic `HANDOFF.md`

## Context

When Claude's quota runs out mid-task, another agent (OpenCode, Codex, a fresh session)
must resume from `docs/plans/HANDOFF.md`. Asking the model to update it "before stopping"
fails exactly when it matters: an out-of-quota model can't write anything.

## Decision

One script, `config/hooks/handoff.sh`, two modes:

- `snapshot` — deterministic, no model, no tokens. Rewrites only the marked auto block
  (branch, HEAD, last commits, uncommitted files, newest plan) and only when it changed, so
  git stays quiet. Runs on Claude's `Stop` (async); Codex can call it through `notify`.
  Appends the block if a `HANDOFF.md` doesn't have it yet, so templates need no change.
- `nudge` — Claude `Stop` hook that blocks the stop once, asking for a ≤15-line rewrite of
  "Current state / Pending work", only if the code changed since the last nudge and at
  least `HANDOFF_NUDGE_MINUTES` (20) passed. Never fires when `stop_hook_active` is set.
  State in `.git/agent-handoff/`.

Both no-op outside git repos and in repos without `docs/plans/HANDOFF.md` (created by
`project-init` / `adopt.sh`).

## Consequences

- The mechanical state is always current, even with zero quota left.
- The narrative costs at most one short extra turn per 20 minutes of real changes.
- OpenCode doesn't run the snapshot itself (no hook wired yet); Claude's and Codex's
  snapshots cover the common case of switching *away* from Claude.
