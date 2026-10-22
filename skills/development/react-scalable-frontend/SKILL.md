---
name: react-scalable-frontend
description: Use this skill when building or refactoring scalable React TypeScript frontends with clean component boundaries, predictable state, accessible UI, maintainable hooks, and production-ready folder conventions.
paths:
  - "**/*.tsx"
  - "**/*.jsx"
metadata:
  version: "0.1.0"
  owner: "typescript-fullstack"
  stack:
    - typescript
    - react
  focus:
    - frontend architecture
    - component design
    - state management
    - accessibility
  triggers:
    - scalable React
    - frontend architecture
    - component boundary
    - custom hook
---

# React Scalable Frontend

## Objective

Build React frontends that remain easy to change as features grow: components render UI, hooks encapsulate behavior, and data flow stays explicit.

## Architecture Rules

- Keep presentational components focused on rendering and user interaction.
- Move async workflows, subscriptions, forms, and browser integrations into custom hooks or feature services.
- Prefer feature-oriented folders when the repository does not already define a convention.
- Keep shared UI components generic; keep domain-specific behavior inside feature modules.
- Avoid global state for data that is local to one screen or form.
- Use server-state libraries or existing query clients for remote data rather than duplicating cache logic manually.

## Component Rules

- Model loading, empty, error, and success states explicitly.
- Use stable keys from domain data, not array indexes, when rendering dynamic lists.
- Use accessible controls with labels, keyboard interaction, focus states, and semantic HTML.
- Avoid prop drilling through many layers; introduce composition, context, or local feature hooks when it reduces complexity.

## Hook Rules

- Follow the existing `react-component-validator` guidance for `useEffect`.
- Extract custom hooks for lifecycle behavior, data orchestration, reusable browser APIs, and complex state transitions.
- Return small, typed APIs from hooks.
- Keep hook names aligned with intent, such as `useUserProfile`, `useCheckoutForm`, or `useKeyboardShortcuts`.

## Validation

- Run typecheck, lint, and tests when available.
- Check responsive layout and keyboard navigation for user-facing changes.
- Review bundle-impact risks when adding new dependencies.
