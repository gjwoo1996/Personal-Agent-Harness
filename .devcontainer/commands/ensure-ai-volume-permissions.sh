#!/usr/bin/env bash
# Fix ownership on AI CLI named-volume mounts (Docker creates them as root).
set -euo pipefail

ensure_ai_volume_permissions() {
  local dir
  for dir in "${HOME}/.claude" "${HOME}/.ai-state" "${HOME}/.codex"; do
    if [ -e "$dir" ] && [ "$(stat -c '%u' "$dir")" -ne "$(id -u)" ]; then
      echo "Fixing permissions on $dir (named volume owned by root)"
      sudo chown -R "$(id -un):$(id -gn)" "$dir"
    fi
  done
}

ensure_ai_volume_permissions
