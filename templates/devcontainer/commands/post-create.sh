#!/usr/bin/env bash
set -euo pipefail

git config --global --add safe.directory "$PWD" || true

mkdir -p /home/vscode/.ai-state/claude
if [ -e /home/vscode/.claude.json ] && [ ! -L /home/vscode/.claude.json ]; then
  cp /home/vscode/.claude.json /home/vscode/.ai-state/claude/.claude.json
fi
touch /home/vscode/.ai-state/claude/.claude.json
ln -sfn /home/vscode/.ai-state/claude/.claude.json /home/vscode/.claude.json

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
