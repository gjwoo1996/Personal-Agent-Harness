#!/usr/bin/env bash
set -euo pipefail

git config --global --add safe.directory "$PWD" || true

echo "User: $(whoami)"
echo "Workspace: $PWD"

if command -v node >/dev/null 2>&1; then
  node --version
fi

if command -v gh >/dev/null 2>&1; then
  gh --version
fi

if command -v claude >/dev/null 2>&1; then
  claude --version
fi

if command -v codex >/dev/null 2>&1; then
  codex --version
fi
