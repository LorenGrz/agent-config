# 0008 — SessionStart hook for routing and codebase-map refresh

## Context

Prose rules in `CLAUDE.md` lose to harness defaults (such as "don't spawn subagents unless
asked") and get diluted in long sessions, so the routing rule from ADR 0006 was often
ignored. Large repos also get explored from scratch each session when `.agents/CONTEXT.md`
is missing or out of date.

## Decision

Add a `SessionStart` hook, `config/hooks/session-start.sh`, that:

- re-injects the agent-routing rule as `additionalContext` at every session start;
- in git repos with at least 200 tracked files (`AGENTS_MAP_MIN_FILES`), nudges to run the
  `repository-context-maintainer` skill when `.agents/CONTEXT.md` is missing, or when it is
  at least 30 commits behind HEAD (`AGENTS_MAP_STALE_COMMITS`); otherwise it says to read it.

This is a cheap substitute for graphify: no dependency or call graph, only the prose map
maintained by the skill. It is wired in `config/settings.base.json` and `hooks/hooks.json`.

## Consequences

- About 60 tokens of context per session.
- Thresholds are tunable through environment variables.
- Still guidance, not enforcement: the model can ignore it.
