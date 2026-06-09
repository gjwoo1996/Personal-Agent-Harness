#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET="$(cd "${1:-.}" && pwd -P)"

if [ "${PAH_SKIP_PULL:-0}" != "1" ] && [ -d "$ROOT/.git" ]; then
  git -C "$ROOT" pull --ff-only
fi

"$ROOT/bin/pah" install "$TARGET" --components rules,hooks
"$ROOT/bin/pah" verify "$TARGET"
