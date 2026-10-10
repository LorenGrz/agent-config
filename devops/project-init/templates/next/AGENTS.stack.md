## Next.js conventions

Zero-useEffect doctrine, adapted for the App Router and enforced by `eslint.config.mjs` (`react-hooks/set-state-in-effect`, `react-you-might-not-need-an-effect/*`):

- Data fetching happens in Server Components, not in a client-side `useEffect`.
- Mutations go through Server Actions, not client-side fetch-then-setState.
- `'use client'` only at the leaves of the tree (the interactive component itself), not on whole route segments.
- `useEffect` is only for syncing with something outside React in a Client Component (subscriptions, browser APIs) - never to set state from props or other state.
- Derived values are computed in render, not copied into state inside an effect.
- Tests: Vitest + React Testing Library for client components; colocated as `*.test.tsx`.
