#!/usr/bin/env bash
# PAH_MATCHERS: Bash
# Injects git-workflow-standards.md into context before git commit/push/merge/rebase/reset.
set -euo pipefail

[ -n "${CLAUDE_PROJECT_DIR:-}" ] || exit 0

INPUT="$(cat)"
printf '%s' "$INPUT" | grep -qE '"command"[[:space:]]*:[[:space:]]*"[^"]*git (commit|push|merge|rebase|reset)' || exit 0

STANDARDS="${CLAUDE_PROJECT_DIR}/docs/git-workflow/git-workflow-standards.md"
[ -f "$STANDARDS" ] || exit 0

printf '\n[PAH] git-workflow-standards enforced — reading rules before proceeding:\n\n'
cat "$STANDARDS"
