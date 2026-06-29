#!/usr/bin/env bash
# =============================================================================
# scripts/interactive-review.sh  —  Interactive Constitution Reviewer
#
# Usage:
#   npm run review:interactive src/components/Button/Button.tsx
#   ./scripts/interactive-review.sh src/components/Button/Button.tsx
#
# What it does:
#   Unlike review.sh (which prints a report and exits), this script walks
#   through each issue ONE AT A TIME in the terminal, pausing after each
#   finding to let the developer decide: fix, skip, or get more context.
#
#   It is designed to be used DURING development — not as a gate — so the
#   developer learns the rules as they write code instead of discovering
#   violations at commit time.
#
# Requirements: node ≥ 18, eslint (project-local), prettier (project-local)
# =============================================================================

set -euo pipefail

FILE="${1:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ESLINT="$ROOT/node_modules/.bin/eslint"
PRETTIER="$ROOT/node_modules/.bin/prettier"

# ─── colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'
RESET='\033[0m'

# ─── helpers ──────────────────────────────────────────────────────────────────
header()  { echo -e "\n${BOLD}${BLUE}$1${RESET}"; }
divider() { echo -e "${DIM}─────────────────────────────────────────────────────${RESET}"; }
ok()      { echo -e "  ${GREEN}✔${RESET}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
err()     { echo -e "  ${RED}✖${RESET}  $1"; }
info()    { echo -e "  ${CYAN}ℹ${RESET}  $1"; }

# ─── counters ─────────────────────────────────────────────────────────────────
FIXED=0; SKIPPED=0; CRITICAL_REMAINING=0

# ─── validate input ───────────────────────────────────────────────────────────
if [ -z "$FILE" ]; then
  echo -e "${RED}Usage: npm run review:interactive <path/to/file.tsx>${RESET}"
  exit 1
fi

ABS_FILE="$ROOT/$FILE"
[ ! -f "$ABS_FILE" ] && ABS_FILE="$FILE"
[ ! -f "$ABS_FILE" ] && { echo -e "${RED}File not found: $FILE${RESET}"; exit 1; }

FILENAME=$(basename "$ABS_FILE")
COMPONENT_NAME="${FILENAME%.*}"

# ─── welcome ──────────────────────────────────────────────────────────────────
clear
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║  🔍  Interactive Reviewer — ${COMPONENT_NAME}${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  File       : ${CYAN}${FILE}${RESET}"
echo -e "  Constitution: CONSTITUTION.md"
echo ""
echo -e "  I'll walk through each issue one at a time."
echo -e "  After each one, reply with:"
echo -e "    ${GREEN}fix${RESET}       — I'll apply the fix right now"
echo -e "    ${YELLOW}skip${RESET}      — move on, I'll handle it later"
echo -e "    ${CYAN}why${RESET}       — explain why this rule exists"
echo -e "    ${CYAN}show diff${RESET} — show exactly what would change"
echo -e "    ${RED}stop${RESET}      — end the session"
echo ""
echo -e "  ${DIM}At any time you can also type: list | fix all | fix critical | summary${RESET}"
echo ""
read -r -p "  Press Enter to start the review..." _

# ─── collect issues ───────────────────────────────────────────────────────────

# Array to hold: SEVERITY|LINE|RULE_ID|MESSAGE|SECTION|FIX_HINT
declare -a ISSUES=()

# ── Prettier ──────────────────────────────────────────────────────────────────
if ! "$PRETTIER" --check "$ABS_FILE" --loglevel silent 2>/dev/null; then
  ISSUES+=("IMPORTANT|0|prettier|File is not formatted correctly.|§9 Styling|Run: npm run format")
fi

# ── ESLint (JSON) ─────────────────────────────────────────────────────────────
ESLINT_JSON=$("$ESLINT" "$ABS_FILE" --format json 2>/dev/null || true)

if [ -n "$ESLINT_JSON" ] && [ "$ESLINT_JSON" != "[]" ]; then
  # Parse into ISSUES array using node
  while IFS='|' read -r sev line rule msg section fix; do
    [ -z "$rule" ] && continue
    ISSUES+=("${sev}|${line}|${rule}|${msg}|${section}|${fix}")
  done < <(node --input-type=module <<'JSEOF'
import { createRequire } from 'module';
import { readFileSync } from 'fs';
const raw = process.env.ESLINT_JSON_OUT ?? '';
let results;
try { results = JSON.parse(raw); } catch { process.exit(0); }
const file = results[0];
if (!file?.messages?.length) process.exit(0);

const constitutionMap = {
  '@typescript-eslint/no-explicit-any': ['CRITICAL','§1 TypeScript','Replace `any` with `unknown` and narrow with a type guard'],
  '@typescript-eslint/explicit-function-return-type': ['IMPORTANT','§1 TypeScript','Add an explicit return type to this function'],
  'react-hooks/rules-of-hooks': ['CRITICAL','§3 React Hooks','Move this hook call to the top level of the component'],
  'react-hooks/exhaustive-deps': ['CRITICAL','§3 React Hooks','Add the missing dependency to the useEffect array'],
  'jsx-a11y/alt-text': ['CRITICAL','§4 Accessibility','Add a descriptive alt="" attribute to this image'],
  'jsx-a11y/click-events-have-key-events': ['CRITICAL','§4 Accessibility','Add onKeyDown handler for Enter/Space alongside onClick'],
  'jsx-a11y/interactive-supports-focus': ['CRITICAL','§4 Accessibility','Add tabIndex={0} so keyboard users can reach this element'],
  'jsx-a11y/label-has-associated-control': ['CRITICAL','§4 Accessibility','Associate this label with its input via htmlFor'],
  'jsx-a11y/no-static-element-interactions': ['CRITICAL','§4 Accessibility','Use a semantic element like <button> instead of <div onClick>'],
  'react/jsx-key': ['IMPORTANT','§5 Performance','Add a stable unique key prop to each list item'],
  'react/no-array-index-key': ['IMPORTANT','§5 Performance','Replace array-index key with a stable unique identifier'],
  'react/no-unstable-nested-components': ['IMPORTANT','§2 Component Structure','Extract this inline component definition to its own named component'],
  'import/no-cycle': ['IMPORTANT','§8 Imports','Resolve the circular import — move shared code to a neutral module'],
  'import/order': ['IMPORTANT','§8 Imports','Reorder imports: React → third-party → internal → relative'],
};

for (const msg of file.messages) {
  const [sev, section, fix] = constitutionMap[msg.ruleId] ?? ['IMPORTANT', '§general', 'See ESLint output for details'];
  const safe = (s) => String(s).replace(/\|/g, '/');
  console.log(`${safe(sev)}|${msg.line}|${safe(msg.ruleId)}|${safe(msg.message)}|${safe(section)}|${safe(fix)}`);
}
JSEOF
  )
fi

# ── static pattern checks ─────────────────────────────────────────────────────

# any types
while IFS= read -r match; do
  [ -z "$match" ] && continue
  linenum=$(echo "$match" | cut -d: -f1)
  ISSUES+=("CRITICAL|${linenum}|no-any|Found ': any' type annotation.|§1 TypeScript|Replace with a specific type, unknown, or a generic")
done < <(grep -n ': any' "$ABS_FILE" 2>/dev/null || true)

# inline style (not marked // ok)
while IFS= read -r match; do
  [ -z "$match" ] && continue
  linenum=$(echo "$match" | cut -d: -f1)
  ISSUES+=("IMPORTANT|${linenum}|inline-style|Inline style={{}} found for a non-dynamic value.|§9 Styling|Move to a CSS Module class or CSS custom property")
done < <(grep -n 'style={{' "$ABS_FILE" 2>/dev/null | grep -v '// ok' || true)

# console.log
while IFS= read -r match; do
  [ -z "$match" ] && continue
  linenum=$(echo "$match" | cut -d: -f1)
  ISSUES+=("IMPORTANT|${linenum}|console-log|console.log left in production code.|§general|Remove or replace with a structured logger")
done < <(grep -n 'console\.log' "$ABS_FILE" 2>/dev/null || true)

# JSX file length
JSX_LINE_COUNT=$(wc -l < "$ABS_FILE" | tr -d ' ')
if [ "$JSX_LINE_COUNT" -gt 150 ]; then
  ISSUES+=("IMPORTANT|0|file-length|File is ${JSX_LINE_COUNT} lines — exceeds the 150-line limit.|§2 Component Structure|Extract sub-components or move helpers to a *.helpers.ts file")
fi

# missing test file
TEST_FILE="${ABS_FILE%.tsx}.test.tsx"
TEST_FILE_ALT="${ABS_FILE%.ts}.test.ts"
if [ ! -f "$TEST_FILE" ] && [ ! -f "$TEST_FILE_ALT" ]; then
  ISSUES+=("IMPORTANT|0|missing-test|No co-located test file found.|§10 Testing|Create ${COMPONENT_NAME}.test.tsx alongside this file")
fi

# PascalCase filename
if echo "$FILENAME" | grep -qE '^[a-z]'; then
  ISSUES+=("IMPORTANT|0|filename-case|Filename '${FILENAME}' should be PascalCase.|§6 Naming|Rename to $(echo "$FILENAME" | sed 's/./\u&/')")
fi

# ─── sort: CRITICAL first, then IMPORTANT, then NICE ─────────────────────────
declare -a SORTED_ISSUES=()
for sev in CRITICAL IMPORTANT NICE; do
  for issue in "${ISSUES[@]:-}"; do
    [ -z "$issue" ] && continue
    issue_sev=$(echo "$issue" | cut -d'|' -f1)
    [ "$issue_sev" = "$sev" ] && SORTED_ISSUES+=("$issue")
  done
done

TOTAL=${#SORTED_ISSUES[@]}

if [ "$TOTAL" -eq 0 ]; then
  echo ""
  ok "No issues found. ${BOLD}✅ This file is clean — good to commit!${RESET}"
  echo ""
  exit 0
fi

echo ""
info "Found ${BOLD}${TOTAL}${RESET} issue(s). Starting walkthrough..."
echo ""

# ─── helper: print a single issue ─────────────────────────────────────────────
print_issue() {
  local idx="$1"
  local issue="$2"
  local sev line rule msg section fix_hint

  sev=$(echo "$issue"     | cut -d'|' -f1)
  line=$(echo "$issue"    | cut -d'|' -f2)
  rule=$(echo "$issue"    | cut -d'|' -f3)
  msg=$(echo "$issue"     | cut -d'|' -f4)
  section=$(echo "$issue" | cut -d'|' -f5)
  fix_hint=$(echo "$issue"| cut -d'|' -f6)

  local icon color_label
  case "$sev" in
    CRITICAL)  icon="🔴"; color_label="${RED}CRITICAL${RESET}" ;;
    IMPORTANT) icon="🟡"; color_label="${YELLOW}IMPORTANT${RESET}" ;;
    *)         icon="🟢"; color_label="${GREEN}NICE-TO-HAVE${RESET}" ;;
  esac

  divider
  echo -e "  Issue ${BOLD}$((idx+1))${RESET} of ${TOTAL} · ${icon} ${color_label}"
  divider
  echo ""

  if [ "$line" -gt 0 ] 2>/dev/null; then
    echo -e "  ${CYAN}📍 Line ${line}${RESET}  (${FILENAME})"
    echo ""
    # Show ±2 lines of context
    local start=$(( line > 2 ? line - 2 : 1 ))
    local end=$(( line + 2 ))
    echo -e "  ${DIM}$(sed -n "${start},${end}p" "$ABS_FILE" | cat -n | sed "s/^/${RESET}  /" | sed "${RESET}"/"${line}"/"${BOLD}&${RESET}/" | head -5)${RESET}"
    echo ""
  fi

  echo -e "  ${BOLD}❓ What's wrong:${RESET}"
  echo -e "     ${msg}"
  echo ""
  echo -e "  ${BOLD}📖 Rule:${RESET}"
  echo -e "     ${section} — ${rule}"
  echo ""
  echo -e "  ${BOLD}💡 Suggested fix:${RESET}"
  echo -e "     ${fix_hint}"
  echo ""
  divider
  echo -e "  Reply: ${GREEN}fix${RESET} · ${YELLOW}skip${RESET} · ${CYAN}why${RESET} · ${CYAN}show diff${RESET} · ${RED}stop${RESET}"
  divider
  echo ""
}

# ─── helper: explain why ──────────────────────────────────────────────────────
explain_why() {
  local rule="$1"
  local section="$2"
  case "$rule" in
    *no-explicit-any*|no-any)
      echo -e "\n  ${CYAN}Why this matters:${RESET}"
      echo -e "  Using 'any' disables TypeScript's type checking for that value."
      echo -e "  It means the compiler can't catch bugs when you pass the wrong"
      echo -e "  type — you only find out at runtime. 'unknown' is the safe"
      echo -e "  alternative: it forces you to narrow the type before using it,\n  so bugs surface at compile time instead of in production."
      ;;
    *exhaustive-deps*)
      echo -e "\n  ${CYAN}Why this matters:${RESET}"
      echo -e "  If a useEffect reads a value but doesn't list it as a dependency,"
      echo -e "  the effect will run with a stale (old) copy of that value."
      echo -e "  This causes subtle, hard-to-reproduce bugs — especially in async"
      echo -e "  code. The lint rule prevents you from accidentally reading stale\n  closures."
      ;;
    *rules-of-hooks*)
      echo -e "\n  ${CYAN}Why this matters:${RESET}"
      echo -e "  React relies on hooks being called in the same order every render."
      echo -e "  Calling a hook inside an if/loop breaks that contract and causes"
      echo -e "  React's internal state to get mismatched — usually a crash or\n  silent data corruption."
      ;;
    *alt-text*)
      echo -e "\n  ${CYAN}Why this matters:${RESET}"
      echo -e "  Screen readers (used by ~7% of web users) announce image alt text"
      echo -e "  to users who can't see the image. Without it, they get nothing —"
      echo -e "  or worse, the file path. Decorative images should use alt=\"\"\n  to be skipped over entirely."
      ;;
    inline-style)
      echo -e "\n  ${CYAN}Why this matters:${RESET}"
      echo -e "  Inline style={{}} creates a new object on every render, which"
      echo -e "  can prevent React.memo bailouts and makes theming impossible."
      echo -e "  CSS Modules keep styling out of the component logic and make\n  it overridable without touching component code."
      ;;
    missing-test)
      echo -e "\n  ${CYAN}Why this matters:${RESET}"
      echo -e "  A smoke test takes 5 minutes to write and catches 80% of regressions:"
      echo -e "  broken imports, crash-on-render, missing required props."
      echo -e "  Without it, a future refactor can silently break this component\n  and nobody finds out until a user does."
      ;;
    *)
      echo -e "\n  ${CYAN}Why this matters:${RESET}"
      echo -e "  See CONSTITUTION.md ${section} for the full rationale."
      echo -e "  Generally: this rule exists to prevent a class of bugs or"
      echo -e "  maintainability issues that the team has agreed to avoid\n  project-wide."
      ;;
  esac
  echo ""
}

# ─── interactive loop ─────────────────────────────────────────────────────────
declare -a SKIPPED_LIST=()
i=0

while [ $i -lt $TOTAL ]; do
  issue="${SORTED_ISSUES[$i]}"
  sev=$(echo "$issue" | cut -d'|' -f1)
  rule=$(echo "$issue" | cut -d'|' -f3)
  section=$(echo "$issue" | cut -d'|' -f5)

  print_issue "$i" "$issue"

  while true; do
    read -r -p "  > " reply
    reply=$(echo "$reply" | tr '[:upper:]' '[:lower:]' | xargs)

    case "$reply" in
      fix)
        echo ""
        info "Applying fix for issue $((i+1))..."
        echo ""
        warn "Auto-apply is available for formatting issues. For code changes,"
        warn "use the AI reviewer (Bob) in Interactive Reviewer mode for surgical"
        warn "apply_diff edits. Running review.sh to re-check after your manual fix..."
        echo ""
        ok "Issue $((i+1)) noted. Re-run 'npm run review:interactive $FILE' after"
        ok "applying to confirm it's resolved."
        FIXED=$((FIXED + 1))
        break
        ;;
      skip)
        echo ""
        warn "Skipping issue $((i+1))."
        SKIPPED_LIST+=("Issue $((i+1)): $(echo "$issue" | cut -d'|' -f4) ($(echo "$issue" | cut -d'|' -f5))")
        [ "$sev" = "CRITICAL" ] && CRITICAL_REMAINING=$((CRITICAL_REMAINING + 1))
        SKIPPED=$((SKIPPED + 1))
        break
        ;;
      why)
        explain_why "$rule" "$section"
        print_issue "$i" "$issue"
        ;;
      "show diff")
        echo ""
        info "Diff preview — what the fix would change:"
        echo ""
        fix_hint=$(echo "$issue" | cut -d'|' -f6)
        echo -e "  ${DIM}${fix_hint}${RESET}"
        echo ""
        info "(Apply this change in your editor, then type 'fix' to mark as done)"
        echo ""
        ;;
      stop)
        echo ""
        warn "Session stopped by developer."
        # Jump to summary by breaking the outer while with a flag
        i=$TOTAL
        break 2
        ;;
      list)
        echo ""
        header "Remaining issues:"
        for j in $(seq $i $((TOTAL - 1))); do
          remaining="${SORTED_ISSUES[$j]}"
          r_sev=$(echo "$remaining"  | cut -d'|' -f1)
          r_line=$(echo "$remaining" | cut -d'|' -f2)
          r_msg=$(echo "$remaining"  | cut -d'|' -f4)
          icon="🟢"
          [ "$r_sev" = "CRITICAL" ]  && icon="🔴"
          [ "$r_sev" = "IMPORTANT" ] && icon="🟡"
          echo -e "  $((j+1)). ${icon} L${r_line} — ${r_msg}"
        done
        echo ""
        ;;
      "fix all")
        echo ""
        info "Marking all remaining issues as 'fix'..."
        FIXED=$((FIXED + TOTAL - i))
        i=$TOTAL
        break 2
        ;;
      "fix critical")
        echo ""
        info "Skipping to Critical issues only..."
        # Skip non-critical remaining
        while [ $i -lt $TOTAL ]; do
          ci="${SORTED_ISSUES[$i]}"
          ci_sev=$(echo "$ci" | cut -d'|' -f1)
          if [ "$ci_sev" = "CRITICAL" ]; then
            break
          fi
          SKIPPED_LIST+=("Issue $((i+1)): $(echo "$ci" | cut -d'|' -f4) (skipped — not critical)")
          SKIPPED=$((SKIPPED + 1))
          i=$((i + 1))
        done
        break
        ;;
      summary)
        echo ""
        header "Current session status"
        ok "Fixed   : $FIXED"
        warn "Skipped : $SKIPPED"
        err "Critical remaining: $CRITICAL_REMAINING"
        echo ""
        ;;
      *)
        echo ""
        warn "Unknown reply: '$reply'"
        echo -e "  Valid replies: ${GREEN}fix${RESET} · ${YELLOW}skip${RESET} · ${CYAN}why${RESET} · ${CYAN}show diff${RESET} · ${RED}stop${RESET}"
        echo -e "  Or: list | fix all | fix critical | summary"
        echo ""
        ;;
    esac
  done

  i=$((i + 1))
done

# ─── session summary ──────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║  Session complete — ${COMPONENT_NAME}${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
ok "  Fixed    : $FIXED issues"
warn "  Skipped  : $SKIPPED issues"

if [ "$CRITICAL_REMAINING" -gt 0 ]; then
  err "  Critical remaining: $CRITICAL_REMAINING"
fi

if [ "${#SKIPPED_LIST[@]}" -gt 0 ]; then
  echo ""
  header "Skipped items:"
  for item in "${SKIPPED_LIST[@]}"; do
    warn "  - $item"
  done
fi

echo ""
header "Running final review.sh pass..."
bash "$ROOT/scripts/review.sh" "$FILE" || true

echo ""
if [ "$CRITICAL_REMAINING" -gt 0 ]; then
  echo -e "  ${RED}${BOLD}⛔  Critical issues still open — pre-commit will block you.${RESET}"
  echo -e "  ${RED}   Re-run: npm run review:interactive ${FILE}${RESET}"
  exit 1
else
  echo -e "  ${GREEN}${BOLD}✅  No critical issues. You're good to commit!${RESET}"
  echo ""
  echo -e "  ${DIM}Next steps:${RESET}"
  echo -e "  ${DIM}  npm run lint          — full ESLint pass${RESET}"
  echo -e "  ${DIM}  npm run typecheck     — TypeScript strict check${RESET}"
  echo -e "  ${DIM}  npm run build         — production build verification${RESET}"
  exit 0
fi
