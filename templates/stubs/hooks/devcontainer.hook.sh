#!/usr/bin/env bash
# PAH_MATCHERS: Edit,Write
# Injects devcontainer-standards.md into context before .devcontainer/ file modifications.
set -euo pipefail

[ -n "${CLAUDE_PROJECT_DIR:-}" ] || exit 0

INPUT="$(cat)"
printf '%s' "$INPUT" | grep -qE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*\.devcontainer/' || exit 0

STANDARDS="${CLAUDE_PROJECT_DIR}/docs/devcontainer/devcontainer-standards.md"
[ -f "$STANDARDS" ] || exit 0

printf '\n[PAH] devcontainer-standards enforced — reading rules before proceeding:\n\n'
cat "$STANDARDS"
