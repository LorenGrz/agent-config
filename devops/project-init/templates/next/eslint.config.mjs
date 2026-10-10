import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";
import reactHooks from "eslint-plugin-react-hooks";
import reactYouMightNotNeedAnEffect from "eslint-plugin-react-you-might-not-need-an-effect";

// Zero-useEffect doctrine on top of create-next-app's own config: forced to
// 'error' below so setState-in-effect and derived-state-in-effect patterns
// fail `pnpm lint` instead of only warning. See AGENTS.md for the doctrine.
const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  reactHooks.configs.flat["recommended-latest"],
  reactYouMightNotNeedAnEffect.configs.recommended,
  {
    rules: {
      "react-hooks/set-state-in-effect": "error",
      "react-you-might-not-need-an-effect/no-derived-state": "error",
      "react-you-might-not-need-an-effect/no-chain-state-updates": "error",
      "react-you-might-not-need-an-effect/no-event-handler": "error",
      "react-you-might-not-need-an-effect/no-adjust-state-on-prop-change": "error",
      "react-you-might-not-need-an-effect/no-reset-all-state-on-prop-change": "error",
      "react-you-might-not-need-an-effect/no-pass-live-state-to-parent": "error",
      "react-you-might-not-need-an-effect/no-pass-data-to-parent": "error",
      "react-you-might-not-need-an-effect/no-external-store-subscription": "error",
      "react-you-might-not-need-an-effect/no-initialize-state": "error",
    },
  },
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
  ]),
]);

export default eslintConfig;
