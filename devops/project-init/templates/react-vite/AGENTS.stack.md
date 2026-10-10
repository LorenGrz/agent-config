## React + Vite conventions

Zero-useEffect doctrine, enforced by `eslint.config.js` (`react-hooks/set-state-in-effect`, `react-you-might-not-need-an-effect/*`):

- Derived values are computed in render (`const full = first + ' ' + last`), never copied into state inside an effect.
- Responses to user actions live in event handlers, not effects.
- Data loading lives in a custom hook per screen/resource (or TanStack Query) - not an ad-hoc `useEffect` + `useState` pair in the component.
- `useEffect` is only for syncing with something outside React (subscriptions, browser APIs like `document.title` or a WebSocket) - never to set state from props or other state.
- One responsibility per component; split when a component both fetches and renders unrelated things.
- Tests: Vitest + React Testing Library, colocated as `*.test.tsx`.
