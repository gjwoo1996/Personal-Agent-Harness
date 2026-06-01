#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET="${1:-.}"
TARGET="$(cd "$TARGET" && pwd -P)"

"$ROOT/bin/pah" install "$TARGET" --components rules
"$ROOT/bin/pah" verify "$TARGET"
