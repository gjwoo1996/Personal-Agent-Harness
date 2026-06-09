#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/ensure-ai-volume-permissions.sh"

git config --global --add safe.directory "$PWD" || true

echo "User: $(whoami)"
echo "Workspace: $PWD"

node --version
npm --version
jq --version

if command -v gh >/dev/null 2>&1; then
  gh --version
fi

if command -v claude >/dev/null 2>&1; then
  claude --version
fi

if command -v codex >/dev/null 2>&1; then
  codex --version
fi

"$SCRIPT_DIR/install-superpowers.sh"

echo ""
echo "Superpowers:"
if command -v claude >/dev/null 2>&1; then
  claude plugin list 2>/dev/null | grep superpowers || echo "  WARN: Claude superpowers not installed"
fi
if command -v codex >/dev/null 2>&1; then
  if codex plugin list 2>/dev/null | grep -q 'superpowers@openai-curated.*installed'; then
    codex plugin list 2>/dev/null | grep superpowers
  elif [ -e "${HOME}/.agents/skills/superpowers" ]; then
    echo "  Codex superpowers: skills symlink at ~/.agents/skills/superpowers"
  else
    echo "  WARN: Codex superpowers not installed"
  fi
fi

echo ""
echo "Harness devcontainer ready."
echo "  Tests:  bash tests/test_pah.sh"
echo "  npm:    npm pack   (run npm login before npm publish)"
