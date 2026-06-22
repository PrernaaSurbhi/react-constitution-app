---
name: constitution-review
description: >-
  Use when the user wants to review, audit, or check any React/TypeScript file against the
  project's CONSTITUTION.md rules — covers TypeScript types, hooks, component structure,
  accessibility, performance, naming, styling, and testing. Also activates when the user says
  "review this file", "check against constitution", "does this comply", or "run the review script".
---

# Constitution Review Skill

This skill enforces `CONSTITUTION.md` on any file in this React + TypeScript project.
It works on **any machine** that has Node ≥ 18 and the project dependencies installed (`npm install`).

---

## Prerequisites check (Step 0)

Before doing anything else, verify the environment is ready:

1. Use `execute_command` to run `node --version` — confirm Node ≥ 18.
2. Confirm `node_modules/.bin/eslint` exists with:
   ```
   ls node_modules/.bin/eslint
   ```
   If missing, tell the user to run `npm install` first and stop.

---

## Step 1 — Identify the file to review

- If the user provided a file path, use it.
- If the active file is shown in context, default to that.
- Otherwise use `ask_followup_question` to ask which file to review.

Store the path as `<TARGET_FILE>` (relative to the project root, e.g. `src/components/Button/Button.tsx`).

---

## Step 2 — Read CONSTITUTION.md

Use `read_file` on `CONSTITUTION.md` to load the current rules.
This ensures your review is grounded in the **actual file**, not memory.
Do not skip this step even if you think you remember the rules.

---

## Step 3 — Run the automated review script

Use `execute_command` to run:

```bash
npm run review <TARGET_FILE>
```

- Capture the full terminal output verbatim.
- If the script exits with code 1, there are Critical issues — note that.
- If `npm run review` is unavailable for any reason, fall back to:
  ```bash
  node_modules/.bin/eslint <TARGET_FILE> --format stylish
  ```

Display the raw script output in a collapsible `<details>` block:

```
<details>
<summary>npm run review output</summary>

…paste terminal output here…

</details>
```

---

## Step 4 — Deep in-context review

After the automated run, perform your own analysis of the file using `read_file`.

Check every CONSTITUTION.md section:

| Section | What to look for |
|---------|-----------------|
| §1 TypeScript & Types | `any`, missing `Props` interface, untyped event handlers, `as` assertions |
| §2 Component Structure | >1 exported component, JSX >150 lines, prop drilling >2 levels, inline object/array literals in props |
| §3 React Hooks | Hooks in conditions/loops, missing `useEffect` deps, `useCallback`/`useMemo` without comment |
| §4 Accessibility | `<img>` without `alt`, `<div onClick>` without `role`+`tabIndex`+keyboard handler, inputs without labels |
| §5 Performance | Array-index keys on mutable lists, missing `React.lazy`, anonymous arrow functions in frequently-rendered props |
| §6 Naming | Component not PascalCase, hook not `use`+PascalCase, boolean props missing `is`/`has`/`can` prefix, handlers missing `handle` prefix |
| §7 File & Folder Layout | Component not in its own folder, missing `index.ts` barrel, missing `.module.css` |
| §8 Imports & Exports | Wrong import order, circular imports, mixed default+named exports |
| §9 Styling | Inline `style={{}}` for non-dynamic values, magic numbers in CSS |
| §10 Testing | Missing `.test.tsx` file, testing implementation not behaviour |

---

## Step 5 — Format and deliver the review

Output the review in **exactly** this structure:

```
---
## Review: <ComponentName>

### Summary
<2–3 sentences: what the file does, overall quality, main concern if any>

### 🔴 Critical (must fix before merge)
| # | Line | Issue | CONSTITUTION section | Suggested fix |
|---|------|-------|----------------------|---------------|
| 1 | L42  | …     | §1 — no `any` types  | Replace `any` with `unknown` and narrow |

### 🟡 Important (fix in this PR)
| # | Line | Issue | CONSTITUTION section | Suggested fix |

### 🟢 Nice-to-have (polish / follow-up)
| # | Line | Issue | CONSTITUTION section | Suggested fix |

### Accessibility highlights
- …

### Performance highlights
- …

### Test Coverage
- Test file: `<Name>.test.tsx` — exists / MISSING
- Suggested test cases: …

### What is done well ✅
- …

---
**Next steps:** type `fix critical` · `fix all` · `fix #N` · `add tests`
```

Rules for the table:
- Only include a severity section if there is at least one finding in it.
- Reference the exact line number(s) from the file.
- Map every finding to a CONSTITUTION.md section (§1–§11).
- Never mark a finding Critical unless CONSTITUTION.md marks that rule 🔴.

---

## Step 6 — Offer follow-up actions

After delivering the review, wait for the user to type one of:

- **`fix critical`** — apply only the Critical fixes, minimal surgical edits.
- **`fix all`** — apply Critical + Important fixes in one pass.
- **`fix #N`** — apply the single finding numbered N in the tables above.
- **`add tests`** — scaffold a `.test.tsx` file co-located with the component.

When applying fixes:
- Use `apply_diff` or `search_and_replace` for targeted edits — never full rewrites unless the file is new.
- After every edit, re-run `npm run review <TARGET_FILE>` and confirm the finding is resolved.
- Do not touch code unrelated to the reported issue.

---

## Portability notes

This skill works on **any machine** because:

- `npm run review <file>` resolves paths relative to the project root via `scripts/review.sh`.
- ESLint and Prettier are project-local (`node_modules/.bin/`), not global installs.
- `CONSTITUTION.md` is read fresh from the repo each time — no stale cached rules.
- All commands are standard `bash` / `node` — no OS-specific tooling required beyond Node ≥ 18.

If running on **Windows** (non-WSL), replace `bash scripts/review.sh` with:
```
node scripts/review.js
```
(a cross-platform Node port of the same script — create it if needed with `write_file`).
