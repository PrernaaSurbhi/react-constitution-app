# ⚖️ Project Constitution

> This file is the **single source of truth** for code quality in this project.  
> Every component, hook, utility, and test must comply with these rules.  
> The ESLint config, Prettier config, and the auto-review script (`scripts/review.sh`) all enforce this document.

---

## Table of Contents
1. [TypeScript & Types](#1-typescript--types)
2. [Component Structure](#2-component-structure)
3. [React Hooks](#3-react-hooks)
4. [Accessibility (a11y)](#4-accessibility-a11y)
5. [Performance](#5-performance)
6. [Naming Conventions](#6-naming-conventions)
7. [File & Folder Layout](#7-file--folder-layout)
8. [Imports & Exports](#8-imports--exports)
9. [Styling](#9-styling)
10. [Testing](#10-testing)
11. [Git & PR Rules](#11-git--pr-rules)
12. [Severity Legend](#12-severity-legend)

---

## 1. TypeScript & Types

| Severity | Rule |
|----------|------|
| 🔴 | Never use `any`. Use `unknown`, narrow with type guards, or define an explicit type. |
| 🔴 | All component props must have an explicit `interface Props` or `type Props` declaration. |
| 🔴 | Event handlers must be typed (`React.ChangeEvent<HTMLInputElement>`, `React.MouseEvent<HTMLButtonElement>`, etc.). |
| 🟡 | Prefer `interface` for object shapes that may be extended; prefer `type` for unions / intersections. |
| 🟡 | Non-trivial functions must declare a return type explicitly. |
| 🟡 | Avoid type assertions (`as Foo`) unless unavoidable; prefer proper narrowing. |
| 🟢 | Export shared types from `src/types/index.ts` so they can be reused. |

---

## 2. Component Structure

| Severity | Rule |
|----------|------|
| 🔴 | One component per file. Do not co-locate two exported components in the same `.tsx` file. |
| 🟡 | JSX must not exceed **150 lines**. Extract sub-components when approaching the limit. |
| 🟡 | A component should do **one thing**. Data fetching, layout, and interactivity must not be tangled together. |
| 🟡 | Avoid prop drilling beyond **2 levels**. Use React Context, composition, or a state library. |
| 🟡 | Do not create object/array literals inline in JSX props — they create a new reference on every render. |
| 🟢 | Page-level components use `default export`. Shared / reusable components use **named export**. |
| 🟢 | Place component-specific helpers/hooks at the bottom of the file, or in a co-located `*.helpers.ts`. |

---

## 3. React Hooks

| Severity | Rule |
|----------|------|
| 🔴 | Never call hooks inside conditions, loops, or nested functions (Rules of Hooks). |
| 🔴 | `useEffect` must include all values from the enclosing scope that are used inside it in its dependency array. |
| 🟡 | Never use `useEffect` to derive state that can be computed inline or via `useMemo`. |
| 🟡 | `useCallback` and `useMemo` must have a documented reason — add a comment `// memoised: <reason>`. |
| 🟡 | Prefer `useReducer` over `useState` when state has more than 3 fields or complex transitions. |
| 🟢 | Extract reusable hook logic into `src/hooks/use<Name>.ts`. All custom hooks must start with `use`. |

---

## 4. Accessibility (a11y)

| Severity | Rule |
|----------|------|
| 🔴 | `<img>` must always have an `alt` attribute. Decorative images use `alt=""` and `role="presentation"`. |
| 🔴 | `<button>` for actions, `<a href>` for navigation. Never `<div onClick>` without `role` + `tabIndex` + keyboard handler. |
| 🔴 | All form inputs must have an associated `<label>` (via `htmlFor`) or an `aria-label` / `aria-labelledby`. |
| 🟡 | Interactive elements must be keyboard-reachable and respond to `Enter`/`Space` when applicable. |
| 🟡 | Do not rely on colour alone to convey meaning — always add a text or icon label. |
| 🟡 | Dynamic content that updates asynchronously should use `aria-live="polite"` (or `assertive` for critical alerts). |
| 🟢 | Use semantic HTML (`<nav>`, `<main>`, `<section>`, `<article>`, `<aside>`, `<header>`, `<footer>`). |

---

## 5. Performance

| Severity | Rule |
|----------|------|
| 🟡 | List items must use **stable, unique** `key` props. Never use array index as a key on mutable lists. |
| 🟡 | Heavy components or pages should be wrapped in `React.lazy()` + `<Suspense>`. |
| 🟡 | Avoid anonymous arrow functions in JSX props for components that render frequently. |
| 🟢 | Use `useTransition` or `useDeferredValue` for non-urgent state updates (e.g. search filtering). |
| 🟢 | Profile before optimising. Add a comment referencing the profiler result when adding `memo`/`useCallback`. |

---

## 6. Naming Conventions

| Symbol | Convention | Example |
|--------|------------|---------|
| Component | PascalCase, matches filename | `UserCard.tsx` → `UserCard` |
| Hook | `use` + PascalCase verb-noun | `useUserProfile`, `useFormState` |
| Boolean prop | `is`, `has`, `can`, `should` prefix | `isLoading`, `hasError`, `canSubmit` |
| Event handler | `handle` + Event | `handleClick`, `handleSubmit` |
| Module constant | UPPER_SNAKE_CASE | `MAX_RETRIES`, `API_BASE_URL` |
| Local variable | camelCase | `userData`, `inputValue` |
| Type / Interface | PascalCase | `UserProfile`, `ButtonProps` |
| Test file | `<Name>.test.tsx` | `UserCard.test.tsx` |
| Style module | `<Name>.module.css` | `UserCard.module.css` |

---

## 7. File & Folder Layout

```
src/
├── components/          # Shared, reusable UI components
│   └── Button/
│       ├── Button.tsx
│       ├── Button.test.tsx
│       ├── Button.module.css
│       └── index.ts     # re-export
├── pages/               # Route-level / page components
├── hooks/               # Custom hooks (use*.ts)
├── context/             # React Context providers
├── types/               # Shared TypeScript types/interfaces
│   └── index.ts
├── utils/               # Pure helper functions
├── services/            # API calls / data-fetching logic
└── App.tsx
```

- Each component lives in its **own folder** named after it.
- `index.ts` in every folder re-exports the public API (avoids deep import paths).
- No barrel files beyond one level deep (import cycles).

---

## 8. Imports & Exports

| Severity | Rule |
|----------|------|
| 🟡 | Import order: (1) React, (2) third-party, (3) internal absolute, (4) relative. Blank line between groups. |
| 🟡 | Never use default + named export in the same file unless the default is the component and named is its type. |
| 🟡 | No circular imports. Use `eslint-plugin-import` to enforce. |
| 🟢 | Prefer absolute imports via `tsconfig.json` paths (`@/components/Button`) over deep relative paths. |

---

## 9. Styling

| Severity | Rule |
|----------|------|
| 🟡 | Use **CSS Modules** (`*.module.css`) or a utility-first library (Tailwind). No inline `style={{}}` except dynamic values. |
| 🟡 | No magic numbers in CSS — use CSS custom properties (`--color-primary`, `--spacing-md`). |
| 🟢 | Responsive design: mobile-first. Use `min-width` media queries. |

---

## 10. Testing

| Severity | Rule |
|----------|------|
| 🔴 | Every public component must have at least a **render smoke test**. |
| 🟡 | Test user behaviour, not implementation details — use `@testing-library/react`. |
| 🟡 | Async operations must be tested with `waitFor` / `findBy*` queries — no arbitrary `setTimeout`. |
| 🟡 | Mock external services at the boundary (API calls, timers, random). |
| 🟢 | Aim for ≥ 80 % branch coverage on business-logic utilities. |
| 🟢 | Co-locate test file next to the component: `Button/Button.test.tsx`. |

---

## 11. Git & PR Rules

| Rule |
|------|
| Branch names: `feat/<ticket>-short-description`, `fix/<ticket>-short-description`, `chore/…` |
| Commit messages follow **Conventional Commits**: `feat: add UserCard component`, `fix: correct aria-label on close button` |
| PRs must pass `npm run lint` and `npm run test` before requesting review. |
| PRs should be ≤ **400 changed lines**. Large changes must be split. |
| Every PR must include a description with: **What changed**, **Why**, **How to test**. |
| The auto-review script (`npm run review <file>`) should show **0 critical issues** before opening a PR. |

---

## 12. Severity Legend

| Icon | Meaning |
|------|---------|
| 🔴 Critical | Bug, accessibility failure, or rules-of-hooks violation. **Must fix before merge.** |
| 🟡 Important | Best-practice violation or perf issue. **Strong recommendation — fix in same PR.** |
| 🟢 Nice-to-have | Polish or future-proofing. **Fix in a follow-up or alongside if trivial.** |

---

*This constitution is enforced automatically by:*
- `eslint.config.js` — static analysis on every save & commit
- `.prettierrc` — formatting on save
- `scripts/review.sh` — deep in-context review via `npm run review <file>`
- `.github/workflows/pr-review.yml` — CI gate on every pull request
