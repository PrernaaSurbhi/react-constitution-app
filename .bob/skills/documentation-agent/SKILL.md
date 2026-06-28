---
name: documentation-agent
description: Use when the user wants PR summaries, update notes, release-style change summaries, or documentation generated from the current git diff and project conventions.
---

# Documentation Agent

Use this skill when the user wants a pull request summary, update notes, release-style notes, or a concise explanation of what changed in the repository.

## Step 1 — Inspect the current changes

1. Use [`execute_command`](../../../package.json) to run `git status --short` from the repository root.
2. Use [`execute_command`](../../../package.json) to run `git diff --stat` to understand the size and scope of the current working tree changes.
3. If there are no working tree changes, use [`execute_command`](../../../package.json) to run `git diff --stat HEAD~1..HEAD` so the summary can be generated from the latest commit.
4. If the user mentions a specific base branch, also run `git diff --stat <base>...HEAD` and `git diff <base>...HEAD`.

## Step 2 — Ground the summary in project conventions

1. Read [`CONSTITUTION.md`](../../../CONSTITUTION.md) before writing the summary so terminology matches the project's standards.
2. Read [`README.md`](../../../README.md) when the summary needs product or setup context.
3. If the user asks for a PR description, prefer [`describe_pull_request()`](../../../.github/workflows/pr-review.yml:34) when a base branch and head branch are known.
4. Never invent files, commands, tests, or motivations that are not present in the diff or repository.

## Step 3 — Review the changed files

1. Use `git diff --name-only` or `git diff --name-status` to collect the changed file list.
2. Read the relevant changed files before describing them. Never summarize code you have not opened.
3. Focus on user-visible behavior changes, validation changes, test changes, workflow changes, and documentation changes.
4. Keep the summary proportional to the change size. Do not over-explain small diffs.

## Step 4 — Produce the requested output

### For PR summaries

Structure the output as:
- **What changed**
- **Why**
- **How to test**

### For update notes or release-style notes

Structure the output as:
- **Summary**
- **Key changes**
- **Impact**

### Writing rules

- Be concise, factual, and grounded in the actual diff.
- Call out notable checks when they are visible in the repo workflow, such as [`npm run lint`](../../../package.json:9), [`npm run typecheck`](../../../package.json:13), [`npm run build`](../../../package.json:8), and [`npm run review <file>`](../../../package.json:14).
- Mention workflow or CI changes when files under [`.github/workflows`](../../../.github/workflows) changed.
- Mention constitution or prompt changes when [`CONSTITUTION.md`](../../../CONSTITUTION.md) or files under [`.bob`](../../../.bob) changed.
- If tests or validation were not run, say so instead of implying they passed.

## Step 5 — Offer next actions

After providing the summary, offer one or more relevant next actions such as:
- refine into a shorter PR title
- expand into a full PR description
- convert into release notes
- tailor the summary for technical or non-technical readers
