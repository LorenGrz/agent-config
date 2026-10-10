import js from '@eslint/js'
import globals from 'globals'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import reactYouMightNotNeedAnEffect from 'eslint-plugin-react-you-might-not-need-an-effect'
import tseslint from 'typescript-eslint'

// Zero-useEffect doctrine: react-hooks/set-state-in-effect and the
// react-you-might-not-need-an-effect rules are forced to 'error' below so
// setState-in-effect and derived-state-in-effect patterns fail `pnpm lint`
// instead of only warning. See AGENTS.md for the doctrine.
export default tseslint.config(
  { ignores: ['dist'] },
  {
    extends: [
      js.configs.recommended,
      tseslint.configs.recommended,
      reactHooks.configs.flat['recommended-latest'],
      reactYouMightNotNeedAnEffect.configs.recommended,
    ],
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      ecmaVersion: 2020,
      globals: globals.browser,
    },
    plugins: {
      'react-refresh': reactRefresh,
    },
    rules: {
      ...reactRefresh.configs.vite.rules,
      'react-hooks/set-state-in-effect': 'error',
      'react-you-might-not-need-an-effect/no-derived-state': 'error',
      'react-you-might-not-need-an-effect/no-chain-state-updates': 'error',
      'react-you-might-not-need-an-effect/no-event-handler': 'error',
      'react-you-might-not-need-an-effect/no-adjust-state-on-prop-change': 'error',
      'react-you-might-not-need-an-effect/no-reset-all-state-on-prop-change': 'error',
      'react-you-might-not-need-an-effect/no-pass-live-state-to-parent': 'error',
      'react-you-might-not-need-an-effect/no-pass-data-to-parent': 'error',
      'react-you-might-not-need-an-effect/no-external-store-subscription': 'error',
      'react-you-might-not-need-an-effect/no-initialize-state': 'error',
    },
  },
)
