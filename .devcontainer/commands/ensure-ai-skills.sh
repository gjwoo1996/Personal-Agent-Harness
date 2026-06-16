#!/usr/bin/env bash
# Idempotent AI skill setup for Claude Code and Codex CLI inside the harness devcontainer.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_FILE="$(cd "$SCRIPT_DIR/.." && pwd)/versions.env"

if [ ! -f "$VERSIONS_FILE" ]; then
  echo "ERROR: missing $VERSIONS_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$VERSIONS_FILE"

SUPERPOWERS_PATH="${HOME}/.codex/superpowers"
SUPERPOWERS_SKILLS_LINK="${HOME}/.agents/skills/superpowers"
GSTACK_PATH="${HOME}/.codex/gstack"

warn() {
  echo "WARN: $*" >&2
}

ensure_ai_volume_permissions() {
  "$SCRIPT_DIR/ensure-ai-volume-permissions.sh"
}

ensure_bun() {
  if command -v bun >/dev/null 2>&1 && bun --version | grep -Fxq "$BUN_VERSION"; then
    echo "Bun: already installed (${BUN_VERSION})"
    return 0
  fi

  echo "Bun: installing ${BUN_VERSION}"
  if curl -fsSL https://bun.sh/install | bash -s "bun-v${BUN_VERSION}"; then
    export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
    export PATH="${BUN_INSTALL}/bin:${PATH}"
    command -v bun >/dev/null 2>&1
  else
    warn "Bun install failed; skipping gstack setup"
    return 1
  fi
}

ensure_repo() {
  local url="$1"
  local path="$2"
  local ref="$3"

  if [ ! -d "$path/.git" ]; then
    echo "Repo: cloning $url to $path"
    rm -rf "$path"
    git clone "$url" "$path"
  else
    echo "Repo: fetching $path"
    git -C "$path" fetch --tags --prune origin
  fi

  if [ -n "$ref" ]; then
    git -C "$path" fetch --tags origin "$ref" || true
    git -C "$path" checkout --detach "$ref"
  else
    git -C "$path" remote set-head origin -a >/dev/null 2>&1 || true
    local default_ref
    default_ref="$(git -C "$path" symbolic-ref --quiet --short refs/remotes/origin/HEAD || true)"
    if [ -n "$default_ref" ]; then
      git -C "$path" checkout --detach "$default_ref"
    fi
  fi
}

claude_superpowers_installed() {
  command -v claude >/dev/null 2>&1 \
    && claude plugin list 2>/dev/null | grep -q 'superpowers'
}

ensure_claude_superpowers() {
  if ! command -v claude >/dev/null 2>&1; then
    warn "Claude CLI unavailable; skipping Claude superpowers"
    return 0
  fi

  if claude_superpowers_installed; then
    echo "Claude superpowers: already installed"
    return 0
  fi

  echo "Claude superpowers: installing..."
  if claude plugin marketplace add "$SUPERPOWERS_MARKETPLACE" --scope user \
      && claude plugin install superpowers@superpowers-marketplace --scope user; then
    echo "Claude superpowers: installed"
  else
    warn "Claude superpowers install failed; continuing"
  fi
}

codex_superpowers_plugin_installed() {
  command -v codex >/dev/null 2>&1 \
    && codex plugin list 2>/dev/null | grep -E 'superpowers@openai-curated[[:space:]]+installed' -q
}

codex_superpowers_skills_installed() {
  [ -d "${SUPERPOWERS_PATH}/skills/using-superpowers" ] \
    && { [ -L "${SUPERPOWERS_SKILLS_LINK}" ] || [ -d "${SUPERPOWERS_SKILLS_LINK}" ]; }
}

ensure_codex_superpowers_skills() {
  mkdir -p "${HOME}/.agents/skills"
  ensure_repo "$SUPERPOWERS_REPO" "$SUPERPOWERS_PATH" "$SUPERPOWERS_REF"

  if [ ! -e "${SUPERPOWERS_SKILLS_LINK}" ]; then
    ln -s "${SUPERPOWERS_PATH}/skills" "${SUPERPOWERS_SKILLS_LINK}"
  fi
}

ensure_codex_superpowers_plugin() {
  if ! command -v codex >/dev/null 2>&1; then
    warn "Codex CLI unavailable; skipping Codex superpowers plugin"
    return 1
  fi
  if ! codex plugin marketplace list 2>/dev/null | grep -q 'openai-curated'; then
    return 1
  fi
  if ! codex plugin list 2>/dev/null | grep -q 'superpowers@openai-curated'; then
    return 1
  fi
  codex plugin add superpowers@openai-curated
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
      warn "Codex [features] exists but multi_agent is not true; set multi_agent = true manually in $config"
      return 0
    fi
    printf '\nmulti_agent = true\n' >> "$config"
  else
    printf '\n[features]\nmulti_agent = true\n' >> "$config"
  fi
  echo "Codex multi_agent: enabled in $config"
}

ensure_codex_superpowers() {
  if ! command -v codex >/dev/null 2>&1; then
    warn "Codex CLI unavailable; installing skills symlink only"
  fi

  if codex_superpowers_plugin_installed; then
    echo "Codex superpowers: already installed (plugin)"
    ensure_codex_multi_agent
    return 0
  fi

  if codex_superpowers_skills_installed; then
    echo "Codex superpowers: already installed (skills symlink)"
  else
    echo "Codex superpowers: installing skills..."
    ensure_codex_superpowers_skills
  fi

  ensure_codex_superpowers_plugin 2>/dev/null \
    && echo "Codex superpowers: plugin enabled" \
    || warn "Codex superpowers plugin skipped"
  ensure_codex_multi_agent
}

ensure_gstack() {
  if ! ensure_bun; then
    return 0
  fi

  export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
  export PATH="${BUN_INSTALL}/bin:${PATH}"

  echo "gstack: ensuring repository"
  ensure_repo "$GSTACK_REPO" "$GSTACK_PATH" "$GSTACK_REF"

  (
    cd "$GSTACK_PATH"
    bun install
    bun run setup --host claude || warn "gstack setup for Claude failed"
    bun run setup --host codex || warn "gstack setup for Codex failed"
  )
}

verify_browse_chromium() {
  if ! command -v chromium >/dev/null 2>&1; then
    warn "Chromium unavailable; browse health check skipped"
    return 0
  fi

  chromium --headless --disable-gpu --no-sandbox --dump-dom about:blank >/dev/null 2>&1 \
    && echo "browse health: Chromium launches" \
    || warn "browse health check failed"
}

ensure_ai_volume_permissions
ensure_claude_superpowers
ensure_codex_superpowers
ensure_gstack
verify_browse_chromium
