#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .devcontainer/.env from .env.example. Fill in validated AI CLI versions before rebuilding."
fi
