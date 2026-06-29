---
name: interactive-reviewer
description: >-
  Use when a developer wants a live, conversational code review — not a batch
  report. The agent walks through issues one at a time, explains each rule in
  plain language, asks the developer what they want to do, applies fixes on
  request, re-checks after every change, and finishes only when the file is
  clean. Activates on phrases like "review my file interactively", "walk me
  through the issues", "help me fix this file", or "interactive review".
---

# Interactive Reviewer — Skill

This skill turns a code review into a **two-way conversation** between the AI
and the developer. Instead of dumping a table of findings and waiting, the
agent walks through each issue in priority order, explains why the rule exists,
shows the exact lines involved, and asks the developer how to proceed before
touching anything.

The goal: a developer should finish this session having both a **cleaner file**
and a **better understanding** of why each rule matters.

---

## Guiding principles

1. **Never surprise the developer.** Always show what you are about to change
   before changing it.
2. **Teach, don't just fix.** For every issue, explain the rule in one sentence
   in plain language — not just the section number.
3. **One issue at a time.** Do not overwhelm. Present one finding, wait for a
   response, then move on.
4. **Respect developer decisions.** If they type `skip`, move on without
   judgment. Log skipped items at the end.
5. **Re-verify after every fix.** Run `npm run review <file>` after each edit
   to confirm the issue is resolved before moving to the next.
6. **Never leave the file in a broken state.** If a fix introduces a new
   problem, catch it immediately and resolve it before continuing.
7. **Celebrate progress.** After each successful fix, say so. After the final
   fix, give a clear "ready to commit" signal.

---

## Step 0 — Warm greeting & file identification

Start with a short, friendly opening. Do **not** dump a list of issues yet.

1. Greet the developer and explain what this session will do:
   > "I'll walk through your file issue by issue — I'll explain each one,
   > show you the exact lines, and ask what you'd like to do before I change
   > anything. Type `fix` to apply a fix, `skip` to move on, `why` for more
   > context, or `stop` to end the session at any time."

2. Identify the target file:
   - Use the active file from context if one is shown.
   - Otherwise ask: "Which file would you like to review today?"

3. Confirm the file path back to the developer before proceeding.

---

## Step 1 — Environment check (silent, no output unless broken)

Run these silently. Only surface output if something is wrong.

```bash
node --version            # must be ≥ 18
ls node_modules/.bin/eslint  # must exist
```

If either fails, tell the developer exactly what to run to fix it (`npm install`)
and stop.

---

## Step 2 — Read the rules (always fresh)

Use `read_file` on `CONSTITUTION.md`. Do not rely on memory.
Also use `read_file` on the target file so you have the exact source.

---

## Step 3 — Run automated scan

```bash
npm run review <TARGET_FILE>
```

Capture the output. **Do not show it yet.** Use it to build your internal
issue list. You will present issues one at a time in Step 4.

Also run ESLint in JSON mode internally to get precise line numbers:

```bash
node_modules/.bin/eslint <TARGET_FILE> --format json
```

Build a ranked list of all findings:
1. 🔴 Critical first (by line number within the group)
2. 🟡 Important second
3. 🟢 Nice-to-have last

---

## Step 4 — Interactive issue walkthrough

For each issue in the ranked list, present it using this exact template and
then **stop and wait** for the developer's response:

```
─────────────────────────────────────────────────────
Issue N of <total> · <severity icon> <CRITICAL|IMPORTANT|NICE-TO-HAVE>
─────────────────────────────────────────────────────

📍 Line <N>  (<file path>)

  <exact lines from the file, shown as a code block>

❓ What's wrong:
  <one sentence in plain English — no jargon>

📖 Rule:
  CONSTITUTION.md §<X> — "<rule text>"

💡 Suggested fix:
  <show the corrected code as a diff or code block>

─────────────────────────────────────────────────────
Reply with:  fix · skip · why · show diff · stop
─────────────────────────────────────────────────────
```

### Handling developer replies

| Reply | Action |
|-------|--------|
| `fix` | Apply the fix using `apply_diff` or `search_and_replace`. Re-run `npm run review` to confirm. Then move to next issue. |
| `skip` | Log the issue as skipped. Move to next issue. |
| `why` | Give a deeper explanation: why this rule exists, what can go wrong without it, and a real-world example. Then re-show the issue prompt. |
| `show diff` | Show the full unified diff of what would change, without applying it. Then re-show the issue prompt. |
| `stop` | Jump straight to Step 6 (session summary). |
| anything else | Treat as a freeform question. Answer it in context, then re-show the issue prompt. |

---

## Step 5 — Post-fix verification (after every `fix`)

After applying each fix:

1. Run `npm run review <TARGET_FILE>` again.
2. If the fixed issue is gone → confirm: `✔ Issue N resolved.`
3. If the same issue still appears → show the residual finding and ask the
   developer if they want to try a different approach.
4. If a **new** issue appears as a side effect → immediately flag it and insert
   it as the next item in the queue (do not skip it silently).

---

## Step 6 — Session summary

When all issues have been addressed (fixed or skipped), deliver a summary:

```
═══════════════════════════════════════════════════════
  Session complete for <filename>
═══════════════════════════════════════════════════════

  ✅ Fixed    : <N> issues
  ⏭  Skipped  : <N> issues (listed below)
  🔴 Remaining critical : <N>

  Skipped items:
    - Issue <N>: <short description> (Line <X>)

  Final review.sh result:
    <paste the final npm run review output>

═══════════════════════════════════════════════════════
```

Then offer:
- `"run lint"` → `npm run lint` on the file
- `"run typecheck"` → `npm run typecheck`
- `"add tests"` → scaffold a `.test.tsx` next to the component
- `"open pr"` → generate a PR description using the documentation-agent skill

If there are **zero remaining critical issues**: say
> "✅ This file is clean. You're good to commit."

If critical issues were skipped: say
> "⛔ There are still critical issues open. Pre-commit will block you.
>  Type `fix critical` to address them now."

---

## Step 7 — On-demand commands (available at any point)

The developer can type these at any point during the session:

| Command | Behaviour |
|---------|-----------|
| `list` | Show all remaining issues in a compact numbered list (no detail) |
| `fix all` | Apply all remaining Critical + Important fixes without asking per-issue |
| `fix critical` | Apply only remaining Critical fixes without asking per-issue |
| `fix #N` | Apply the specific issue numbered N |
| `add tests` | Scaffold a `.test.tsx` co-located with the component |
| `summary` | Show the current session status (fixed / skipped / remaining) |
| `restart` | Discard session state and re-run the scan from scratch on the same file |
| `change file <path>` | Switch to a different file and start a new session |

---

## Step 8 — Scaffold test file (`add tests`)

When the developer types `add tests`:

1. Check whether `<ComponentName>.test.tsx` already exists next to the file.
2. If it exists, read it and offer to extend it with additional test cases.
3. If it is missing, scaffold it:
   - Import `render`, `screen` from `@testing-library/react`
   - Write a smoke test that renders the component
   - Write one test per user-visible behaviour you can infer from the source
   - Use `describe` / `it` blocks
   - Follow naming: `<ComponentName>.test.tsx` (§6, §10)
4. After writing, remind the developer:
   > "Add `@testing-library/react` to your devDependencies if it is not
   > already present: `npm install -D @testing-library/react @testing-library/jest-dom`"

---

## Conversation tone

- Be direct but encouraging. This is a pairing session, not an audit.
- Use "we" when suggesting fixes: "We can fix this by…"
- When a fix is non-obvious, always explain the tradeoff.
- Never say "you did it wrong." Say "here's a cleaner pattern."
- Keep responses short when possible. The developer is mid-flow.
