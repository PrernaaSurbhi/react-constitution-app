// eslint.config.js — enforces the Project Constitution (CONSTITUTION.md)
// Uses ESLint v10 flat-config compatible plugins only.
import js from '@eslint/js';
import globals from 'globals';
import reactHooks from 'eslint-plugin-react-hooks';
import reactRefresh from 'eslint-plugin-react-refresh';
import tseslint from 'typescript-eslint';
import { defineConfig, globalIgnores } from 'eslint/config';
import pluginA11y from 'eslint-plugin-jsx-a11y';
import pluginImportX from 'eslint-plugin-import-x';
import pluginPrettier from 'eslint-plugin-prettier';

export default defineConfig([
  globalIgnores(['dist', 'node_modules', 'coverage']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      js.configs.recommended,
      tseslint.configs.recommended,
      reactHooks.configs.flat.recommended,
      reactRefresh.configs.vite,
    ],
    plugins: {
      'jsx-a11y': pluginA11y,
      'import-x': pluginImportX,
      prettier: pluginPrettier,
    },
    languageOptions: {
      globals: globals.browser,
      parserOptions: {
        ecmaFeatures: { jsx: true },
      },
    },
    rules: {
      // ─── Prettier formatting ──────────────────────────────────────────
      'prettier/prettier': 'warn',

      // ─── TypeScript (CONSTITUTION §1) ────────────────────────────────
      '@typescript-eslint/no-explicit-any': 'error',          // 🔴 no any
      '@typescript-eslint/no-unsafe-assignment': 'off',       // handled by no-explicit-any
      '@typescript-eslint/explicit-function-return-type': [   // 🟡 return types
        'warn',
        { allowExpressions: true, allowTypedFunctionExpressions: true },
      ],
      '@typescript-eslint/consistent-type-definitions': ['warn', 'interface'], // 🟡
      '@typescript-eslint/no-non-null-assertion': 'warn',     // 🟡 avoid !

      // ─── React Hooks (CONSTITUTION §3) ───────────────────────────────
      'react-hooks/rules-of-hooks': 'error',                  // 🔴
      'react-hooks/exhaustive-deps': 'error',                 // 🔴

      // ─── Accessibility (CONSTITUTION §4) ─────────────────────────────
      'jsx-a11y/alt-text': 'error',                           // 🔴
      'jsx-a11y/anchor-is-valid': 'error',                    // 🔴
      'jsx-a11y/aria-props': 'error',                         // 🔴
      'jsx-a11y/aria-role': 'error',                          // 🔴
      'jsx-a11y/click-events-have-key-events': 'error',       // 🔴
      'jsx-a11y/interactive-supports-focus': 'error',         // 🔴
      'jsx-a11y/label-has-associated-control': 'error',       // 🔴
      'jsx-a11y/no-noninteractive-element-interactions': 'warn', // 🟡
      'jsx-a11y/no-static-element-interactions': 'error',     // 🔴

      // ─── Imports (CONSTITUTION §8) ────────────────────────────────────
      'import-x/no-duplicates': 'error',                     // 🟡
      'import-x/no-cycle': 'error',                          // 🟡 no circular imports
      'import-x/order': [
        'warn',
        {
          groups: ['builtin', 'external', 'internal', ['parent', 'sibling', 'index']],
          'newlines-between': 'always',
          alphabetize: { order: 'asc' },
        },
      ],

      // ─── General code quality ─────────────────────────────────────────
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      'no-debugger': 'error',
      'prefer-const': 'error',
      'no-var': 'error',
      eqeqeq: ['error', 'always'],
    },
  },
]);
