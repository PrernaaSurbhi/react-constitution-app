#!/usr/bin/env bash
# =============================================================================
# scripts/review.sh  —  Project Constitution auto-reviewer
#
# Usage:
#   npm run review src/components/Button/Button.tsx
#   ./scripts/review.sh src/components/Button/Button.tsx
#
# What it does:
#   1. Runs ESLint on the file and collects structured violations
#   2. Parses the output into Critical / Important / Nice-to-have buckets
#      mapped back to CONSTITUTION.md sections
#   3. Prints a human-readable review to the terminal
#
# Requirements: node, eslint (project-local), jq (optional – for colour output)
# =============================================================================

set -euo pipefail

FILE="${1:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ESLINT="$ROOT/node_modules/.bin/eslint"
PRETTIER="$ROOT/node_modules/.bin/prettier"
CONSTITUTION="$ROOT/CONSTITUTION.md"

# ─── helpers ──────────────────────────────────────────────────────────────────

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

banner() { echo -e "\n${BOLD}${BLUE}$1${RESET}"; }
ok()     { echo -e "  ${GREEN}✔${RESET}  $1"; }
warn()   { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
err()    { echo -e "  ${RED}✖${RESET}  $1"; }
info()   { echo -e "  ${BLUE}ℹ${RESET}  $1"; }

# ─── validate input ───────────────────────────────────────────────────────────

if [ -z "$FILE" ]; then
  echo -e "${RED}Usage: npm run review <path/to/Component.tsx>${RESET}"
  exit 1
fi

ABS_FILE="$ROOT/$FILE"
if [ ! -f "$ABS_FILE" ]; then
  # Try treating $FILE as absolute
  ABS_FILE="$FILE"
fi
if [ ! -f "$ABS_FILE" ]; then
  echo -e "${RED}File not found: $FILE${RESET}"
  exit 1
fi

FILENAME=$(basename "$ABS_FILE")
COMPONENT_NAME="${FILENAME%.*}"

# ─── header ───────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║  ⚖️  Constitution Review — ${COMPONENT_NAME}${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo -e "  File: ${FILE}"
echo -e "  Constitution: CONSTITUTION.md"
echo ""

CRITICAL_COUNT=0
IMPORTANT_COUNT=0
NICE_COUNT=0
PASSED_COUNT=0

# ─── 1. Prettier check ────────────────────────────────────────────────────────

banner "§ Formatting (Prettier)"
if "$PRETTIER" --check "$ABS_FILE" --loglevel silent 2>/dev/null; then
  ok "File is formatted correctly."
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  warn "File is NOT formatted. Run: npm run format"
  IMPORTANT_COUNT=$((IMPORTANT_COUNT + 1))
fi

# ─── 2. ESLint analysis ───────────────────────────────────────────────────────

banner "§ ESLint (TypeScript + React + a11y + Hooks + Imports)"

ESLINT_OUTPUT=$("$ESLINT" "$ABS_FILE" --format json 2>/dev/null || true)

if [ -z "$ESLINT_OUTPUT" ] || [ "$ESLINT_OUTPUT" = "[]" ]; then
  ok "No ESLint violations found."
  PASSED_COUNT=$((PASSED_COUNT + 1))
else
  # Parse with node since jq may not be available
  node --input-type=module <<EOF
import { readFileSync } from 'fs';
const raw = \`$ESLINT_OUTPUT\`;
let results;
try { results = JSON.parse(raw); } catch { process.exit(0); }

const file = results[0];
if (!file || !file.messages || file.messages.length === 0) {
  console.log("  ✔  No violations.");
  process.exit(0);
}

const severityMap = { 2: '🔴', 1: '🟡' };
const constitutionMap = {
  '@typescript-eslint/no-explicit-any': '§1 — never use any',
  '@typescript-eslint/explicit-function-return-type': '§1 — add return type',
  'react-hooks/rules-of-hooks': '§3 — Rules of Hooks violated',
  'react-hooks/exhaustive-deps': '§3 — exhaustive useEffect deps',
  'jsx-a11y/alt-text': '§4 — img requires alt',
  'jsx-a11y/click-events-have-key-events': '§4 — add keyboard handler',
  'jsx-a11y/interactive-supports-focus': '§4 — add tabIndex',
  'jsx-a11y/label-has-associated-control': '§4 — associate label with input',
  'jsx-a11y/no-static-element-interactions': '§4 — use semantic HTML',
  'react/jsx-key': '§5 — add stable key to list items',
  'react/no-array-index-key': '§5 — avoid index as key',
  'react/no-unstable-nested-components': '§2 — extract inline component',
  'import/no-cycle': '§8 — circular import detected',
  'import/order': '§8 — fix import order',
};

let critical = 0, important = 0;
for (const msg of file.messages) {
  const icon = severityMap[msg.severity] ?? '🟢';
  const sect = constitutionMap[msg.ruleId] ? \` [\${constitutionMap[msg.ruleId]}]\` : '';
  const line = \`L\${msg.line}:\${msg.column}\`;
  const label = msg.severity === 2 ? 'CRITICAL' : 'WARN';
  console.log(\`  \${icon} [\${label}] \${line}  \${msg.ruleId}\${sect}\`);
  console.log(\`         \${msg.message}\`);
  if (msg.severity === 2) critical++;
  else important++;
}
console.log(\`\\n  Summary: \${critical} critical, \${important} warnings\`);
EOF
fi

# ─── 3. Static pattern checks ─────────────────────────────────────────────────

banner "§ Constitution Static Checks"

# Check for 'any' keyword (belt-and-suspenders)
ANY_LINES=$(grep -n ': any' "$ABS_FILE" 2>/dev/null || true)
if [ -n "$ANY_LINES" ]; then
  while IFS= read -r line; do
    err "🔴 [CRITICAL] $line  — Constitution §1: no 'any' types"
    CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
  done <<< "$ANY_LINES"
else
  ok "No 'any' types found.                               §1 ✔"
  PASSED_COUNT=$((PASSED_COUNT + 1))
fi

# Check for inline style objects (not dynamic)
INLINE_STYLE=$(grep -n 'style={{' "$ABS_FILE" 2>/dev/null | grep -v '// ok' || true)
if [ -n "$INLINE_STYLE" ]; then
  while IFS= read -r line; do
    warn "🟡 [IMPORTANT] $line  — Constitution §9: prefer CSS Modules over inline style"
    IMPORTANT_COUNT=$((IMPORTANT_COUNT + 1))
  done <<< "$INLINE_STYLE"
else
  ok "No inline style objects found.                       §9 ✔"
  PASSED_COUNT=$((PASSED_COUNT + 1))
fi

# Check for console.log (not .warn/.error)
CONSOLE_LOG=$(grep -n 'console\.log' "$ABS_FILE" 2>/dev/null || true)
if [ -n "$CONSOLE_LOG" ]; then
  while IFS= read -r line; do
    warn "🟡 [IMPORTANT] $line  — use console.warn/error or a logger"
    IMPORTANT_COUNT=$((IMPORTANT_COUNT + 1))
  done <<< "$CONSOLE_LOG"
else
  ok "No console.log calls found.                          §general ✔"
  PASSED_COUNT=$((PASSED_COUNT + 1))
fi

# Check JSX line count
JSX_LINE_COUNT=$(wc -l < "$ABS_FILE" | tr -d ' ')
if [ "$JSX_LINE_COUNT" -gt 150 ]; then
  warn "🟡 [IMPORTANT] File is $JSX_LINE_COUNT lines — Constitution §2: JSX should not exceed 150 lines. Consider extracting sub-components."
  IMPORTANT_COUNT=$((IMPORTANT_COUNT + 1))
else
  ok "File length: $JSX_LINE_COUNT lines (≤150).              §2 ✔"
  PASSED_COUNT=$((PASSED_COUNT + 1))
fi

# Check for test file
TEST_FILE="${ABS_FILE%.tsx}.test.tsx"
TEST_FILE_ALT="${ABS_FILE%.ts}.test.ts"
if [ ! -f "$TEST_FILE" ] && [ ! -f "$TEST_FILE_ALT" ]; then
  warn "🟡 [IMPORTANT] No test file found. Expected: ${FILENAME%.tsx}.test.tsx  — Constitution §10"
  IMPORTANT_COUNT=$((IMPORTANT_COUNT + 1))
else
  ok "Test file exists.                                     §10 ✔"
  PASSED_COUNT=$((PASSED_COUNT + 1))
fi

# Check naming: component file should be PascalCase
if echo "$FILENAME" | grep -qE '^[a-z]'; then
  warn "🟡 [IMPORTANT] Filename '$FILENAME' should be PascalCase  — Constitution §6"
  IMPORTANT_COUNT=$((IMPORTANT_COUNT + 1))
else
  ok "Filename is PascalCase.                               §6 ✔"
  PASSED_COUNT=$((PASSED_COUNT + 1))
fi

# ─── 4. Summary ───────────────────────────────────────────────────────────────

banner "Review Summary"
echo -e "  ${BOLD}Passed checks  :${RESET} $PASSED_COUNT"
echo -e "  ${BOLD}Critical issues:${RESET} $CRITICAL_COUNT"
echo -e "  ${BOLD}Warnings       :${RESET} $IMPORTANT_COUNT"
echo ""

if [ "$CRITICAL_COUNT" -gt 0 ]; then
  echo -e "  ${RED}${BOLD}❌  FIX CRITICAL ISSUES BEFORE OPENING A PR.${RESET}"
  echo -e "  ${RED}   See CONSTITUTION.md §12 for severity definitions.${RESET}"
  exit 1
elif [ "$IMPORTANT_COUNT" -gt 0 ]; then
  echo -e "  ${YELLOW}${BOLD}⚠️   Warnings found — strongly recommended to fix in this PR.${RESET}"
  echo -e "  ${YELLOW}   See CONSTITUTION.md for details.${RESET}"
  exit 0
else
  echo -e "  ${GREEN}${BOLD}✅  All constitution checks passed. Ready to PR!${RESET}"
  exit 0
fi
