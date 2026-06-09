#!/usr/bin/env bash
set -euo pipefail

git config --global --add safe.directory "$PWD" || true

echo "User: $(whoami)"
echo "Workspace: $PWD"

node --version
npm --version
jq --version

if command -v claude >/dev/null 2>&1; then
  claude --version
fi

if command -v codex >/dev/null 2>&1; then
  codex --version
fi

echo ""
echo "Harness devcontainer ready."
echo "  Tests:  bash tests/test_pah.sh"
echo "  npm:    npm pack   (run npm login before npm publish)"
