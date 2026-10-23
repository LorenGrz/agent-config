# 0006 — The main session always delegates

## Context

ADR 0003 allowed skipping subagents when a change touched ≤3 known files. Combined with the
harness default of not spawning agents unless the user asks, the main session (Opus) ended up
doing lookups and writing inline. Example, 2026-10-23: 6 search calls ran inline on Opus to
research a plugin, spending Opus tokens on work `scout` handles fine.

## Decision

The main session (Opus) is only the orchestrator: it reads the minimum context needed,
decides, writes the spec, reviews the result, and reports.

- Lookups that are not a single read of a known path → `scout`, with one concrete question.
- Any file change (code, docs, config, tests, ADRs) → `worker`, with the decided spec, exact
  files, and an acceptance command.
- Costly-to-get-wrong decisions → `reasoner` or the main session, never `worker`/`scout`.
- Inline only for: answering from loaded context, one read of a known file to decide,
  git/gh to verify/commit/merge work a `worker` did, and memory files.
- Independent subtasks are dispatched in parallel in one message.
- This is a standing user instruction and overrides the harness default.

Supersedes the "≤3 known files inline" paragraph of 0003.

## Consequences

- Fewer Opus output tokens.
- Each subagent pays a cold-start cost; accepted because Opus tokens are the expensive part.
- Small edits get slightly slower.
- The main session has to write clear specs.
