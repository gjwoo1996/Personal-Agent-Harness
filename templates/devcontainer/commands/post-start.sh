#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/ensure-ai-volume-permissions.sh"

echo "Dev container started for ${PWD##*/}"
