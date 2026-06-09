#!/usr/bin/env bash
# Idempotent superpowers setup for Claude Code and Codex CLI inside the harness devcontainer.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/ensure-ai-volume-permissions.sh"

SUPERPOWERS_REPO="${HOME}/.codex/superpowers"
SUPERPOWERS_SKILLS_LINK="${HOME}/.agents/skills/superpowers"

claude_superpowers_installed() {
  command -v claude >/dev/null 2>&1 \
    && claude plugin list 2>/dev/null | grep -q 'superpowers'
}

install_claude_superpowers() {
  command -v claude >/dev/null 2>&1 || return 0

  if claude_superpowers_installed; then
    echo "Claude superpowers: already installed"
    return 0
  fi

  echo "Claude superpowers: installing..."
  claude plugin marketplace add obra/superpowers-marketplace --scope user
  claude plugin install superpowers@superpowers-marketplace --scope user
  echo "Claude superpowers: installed"
}

codex_superpowers_plugin_installed() {
  command -v codex >/dev/null 2>&1 \
    && codex plugin list 2>/dev/null | grep -E 'superpowers@openai-curated[[:space:]]+installed' -q
}

codex_superpowers_skills_installed() {
  [ -d "${SUPERPOWERS_REPO}/skills/using-superpowers" ] \
    && { [ -L "${SUPERPOWERS_SKILLS_LINK}" ] || [ -d "${SUPERPOWERS_SKILLS_LINK}" ]; }
}

install_codex_superpowers_skills() {
  mkdir -p "${HOME}/.agents/skills"

  if [ ! -d "${SUPERPOWERS_REPO}/skills" ]; then
    echo "Codex superpowers: cloning skills repo to ${SUPERPOWERS_REPO}"
    git clone --depth 1 https://github.com/obra/superpowers.git "${SUPERPOWERS_REPO}"
  fi

  if [ ! -e "${SUPERPOWERS_SKILLS_LINK}" ]; then
    ln -s "${SUPERPOWERS_REPO}/skills" "${SUPERPOWERS_SKILLS_LINK}"
  fi
}

install_codex_superpowers_plugin() {
  # Marketplace may be empty on first post-create; plugin install is optional.
  if ! codex plugin marketplace list 2>/dev/null | grep -q 'openai-curated'; then
    return 1
  fi
  if ! codex plugin list 2>/dev/null | grep -q 'superpowers@openai-curated'; then
    return 1
  fi
  codex plugin add superpowers@openai-curated
}

install_codex_superpowers() {
  command -v codex >/dev/null 2>&1 || return 0

  if codex_superpowers_plugin_installed; then
    echo "Codex superpowers: already installed (plugin)"
    ensure_codex_multi_agent
    return 0
  fi

  if codex_superpowers_skills_installed; then
    echo "Codex superpowers: already installed (skills symlink)"
    install_codex_superpowers_plugin 2>/dev/null && echo "Codex superpowers: plugin enabled" || true
    ensure_codex_multi_agent
    return 0
  fi

  echo "Codex superpowers: installing..."
  install_codex_superpowers_skills

  if install_codex_superpowers_plugin 2>/dev/null; then
    echo "Codex superpowers: installed (plugin + skills)"
  else
    echo "Codex superpowers: installed (skills symlink; plugin skipped — marketplace not ready)"
  fi

  ensure_codex_multi_agent
}

ensure_codex_multi_agent() {
  local config="${HOME}/.codex/config.toml"
  mkdir -p "$(dirname "$config")"

  if [ -f "$config" ] && grep -qE '^\s*multi_agent\s*=\s*true' "$config"; then
    echo "Codex multi_agent: already enabled"
    return 0
  fi

  if [ -f "$config" ] && grep -q '^\[features\]' "$config"; then
    if grep -qE '^\s*multi_agent\s*=' "$config"; then
      echo "WARN: Codex [features] exists but multi_agent is not true; set multi_agent = true manually in $config"
      return 0
    fi
    printf '\nmulti_agent = true\n' >> "$config"
  else
    printf '\n[features]\nmulti_agent = true\n' >> "$config"
  fi
  echo "Codex multi_agent: enabled in $config"
}

install_claude_superpowers
install_codex_superpowers
