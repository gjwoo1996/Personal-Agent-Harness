#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PAH="$ROOT/bin/pah"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file() {
  [ -f "$1" ] || fail "expected file: $1"
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  grep -Fq "$pattern" "$file" || fail "expected '$pattern' in $file"
}

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  if grep -Fq "$pattern" "$file"; then
    fail "did not expect '$pattern' in $file"
  fi
}

assert_not_file() {
  [ ! -f "$1" ] || fail "did not expect file: $1"
}

assert_count() {
  local file="$1"
  local pattern="$2"
  local expected="$3"
  local actual
  actual="$(grep -Fc "$pattern" "$file" || true)"
  [ "$actual" = "$expected" ] || fail "expected '$pattern' $expected time(s) in $file, found $actual"
}

assert_command_fails() {
  if "$@"; then
    fail "expected command to fail: $*"
  fi
}

TARGET="$TMP_ROOT/project"
mkdir -p "$TARGET"

"$PAH" install "$TARGET" --dry-run > "$TMP_ROOT/dry-run.log"
assert_contains "$TMP_ROOT/dry-run.log" "[DRY-RUN]"
assert_contains "$TMP_ROOT/dry-run.log" "docs/devcontainer/devcontainer-standards.md"

"$PAH" install "$TARGET"

assert_file "$TARGET/docs/devcontainer/devcontainer-standards.md"
assert_file "$TARGET/docs/devcontainer/devcontainer-standards.ko.md"
assert_file "$TARGET/.cursor/rules/devcontainer-standards.mdc"
assert_file "$TARGET/AGENTS.md"
assert_file "$TARGET/CLAUDE.md"
assert_file "$TARGET/.harness/manifest.json"

assert_contains "$TARGET/AGENTS.md" "<!-- pah:devcontainer:start -->"
assert_contains "$TARGET/CLAUDE.md" "<!-- pah:devcontainer:start -->"
assert_contains "$TARGET/.cursor/rules/devcontainer-standards.mdc" "docs/devcontainer/devcontainer-standards.md"
assert_not_contains "$TARGET/.cursor/rules/devcontainer-standards.mdc" "devcontainer-standards.ko.md"
assert_not_file "$TARGET/.cursor/rules/harness-development.mdc"
assert_contains "$ROOT/config/rule-domains.txt" "devcontainer"
assert_file "$ROOT/templates/stubs/agent-blocks/devcontainer.md"
assert_contains "$TARGET/.harness/manifest.json" '"devcontainer": {'
assert_contains "$TARGET/.harness/manifest.json" '"path": "docs/devcontainer/devcontainer-standards.md"'

"$PAH" verify "$TARGET"
"$PAH" install "$TARGET"
assert_count "$TARGET/AGENTS.md" "<!-- pah:devcontainer:start -->" 1
assert_count "$TARGET/CLAUDE.md" "<!-- pah:devcontainer:start -->" 1
"$PAH" status "$TARGET" | grep -Fq "Personal-Agent-Harness installed" || fail "status did not report installed"

SECOND="$TMP_ROOT/existing"
mkdir -p "$SECOND"
cat > "$SECOND/AGENTS.md" <<'EOM'
# Existing Agent Rules

Keep this project-specific rule.
EOM

"$PAH" install "$SECOND"
assert_contains "$SECOND/AGENTS.md" "Keep this project-specific rule."
assert_contains "$SECOND/AGENTS.md" "<!-- pah:devcontainer:start -->"

"$PAH" verify "$SECOND"

SCAFFOLD="$TMP_ROOT/scaffold"
mkdir -p "$SCAFFOLD"
"$PAH" install "$SCAFFOLD" --components rules,devcontainer,gitignore
assert_file "$SCAFFOLD/.devcontainer/devcontainer.json"
assert_file "$SCAFFOLD/.devcontainer/docker-compose.dev.yml"
assert_file "$SCAFFOLD/.devcontainer/Dockerfile"
assert_file "$SCAFFOLD/.devcontainer/commands/initializeCommand.sh"
assert_file "$SCAFFOLD/.devcontainer/commands/post-create.sh"
assert_file "$SCAFFOLD/.devcontainer/README.md"
assert_contains "$SCAFFOLD/.gitignore" "# pah:managed:start"
"$PAH" verify "$SCAFFOLD"

SETUP_PROJECT="$TMP_ROOT/setup-project"
mkdir -p "$SETUP_PROJECT"
cp -a "$ROOT" "$SETUP_PROJECT/Personal-Agent-Harness"
(
  cd "$SETUP_PROJECT"
  ./Personal-Agent-Harness/setup.sh .
)
assert_file "$SETUP_PROJECT/docs/devcontainer/devcontainer-standards.md"
assert_file "$SETUP_PROJECT/.harness/manifest.json"
"$PAH" verify "$SETUP_PROJECT"

UPDATE_MARKER="pah-update-test-marker-$$"
echo "$UPDATE_MARKER" >> "$SETUP_PROJECT/Personal-Agent-Harness/standards/devcontainer/devcontainer-standards.md"
(
  cd "$SETUP_PROJECT"
  PAH_SKIP_PULL=1 ./Personal-Agent-Harness/update.sh .
)
assert_contains "$SETUP_PROJECT/docs/devcontainer/devcontainer-standards.md" "$UPDATE_MARKER"
"$PAH" verify "$SETUP_PROJECT"

HARNESS_DEV="$TMP_ROOT/harness-dev"
mkdir -p "$HARNESS_DEV"
"$PAH" install "$HARNESS_DEV" --components harness-dev
assert_file "$HARNESS_DEV/.cursor/rules/harness-development.mdc"
assert_contains "$HARNESS_DEV/.cursor/rules/harness-development.mdc" "Personal-Agent-Harness/**"
assert_contains "$HARNESS_DEV/.cursor/rules/harness-development.mdc" "adding-rule-domains.md"
assert_not_file "$HARNESS_DEV/docs/devcontainer/devcontainer-standards.md"
assert_not_file "$HARNESS_DEV/AGENTS.md"

echo "All pah tests passed"
