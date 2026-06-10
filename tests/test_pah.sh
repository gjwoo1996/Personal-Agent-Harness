#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PAH="$ROOT/bin/pah"
HARNESS_VERSION="$(tr -d '\r\n' < "$ROOT/VERSION")"
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

assert_not_dir() {
  [ ! -d "$1" ] || fail "did not expect directory: $1"
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

assert_mode() {
  local file="$1"
  local expected="$2"
  local actual
  actual="$(stat -c '%a' "$file")"
  [ "$actual" = "$expected" ] || fail "expected mode $expected for $file, found $actual"
}

assert_dir_count() {
  local dir="$1"
  local expected="$2"
  local actual
  actual="$(find "$dir" -mindepth 1 -maxdepth 1 -type d | wc -l)"
  [ "$actual" = "$expected" ] || fail "expected $expected directories in $dir, found $actual"
}

TARGET="$TMP_ROOT/project"
mkdir -p "$TARGET"

"$PAH" install "$TARGET" --dry-run > "$TMP_ROOT/dry-run.log"
assert_contains "$TMP_ROOT/dry-run.log" "[DRY-RUN]"
assert_contains "$TMP_ROOT/dry-run.log" "docs/devcontainer/devcontainer-standards.md"
assert_contains "$TMP_ROOT/dry-run.log" "docs/git-workflow/git-workflow-standards.md"

"$PAH" install "$TARGET"

assert_file "$TARGET/docs/devcontainer/devcontainer-standards.md"
assert_file "$TARGET/docs/devcontainer/devcontainer-standards.ko.md"
assert_file "$TARGET/.cursor/rules/devcontainer-standards.mdc"
assert_file "$TARGET/docs/git-workflow/git-workflow-standards.md"
assert_file "$TARGET/docs/git-workflow/git-workflow-standards.ko.md"
assert_file "$TARGET/.cursor/rules/git-workflow-standards.mdc"
assert_file "$TARGET/AGENTS.md"
assert_file "$TARGET/CLAUDE.md"
assert_file "$TARGET/.harness/manifest.json"

assert_contains "$TARGET/AGENTS.md" "<!-- pah:devcontainer:start -->"
assert_contains "$TARGET/CLAUDE.md" "<!-- pah:devcontainer:start -->"
assert_contains "$TARGET/AGENTS.md" "<!-- pah:git-workflow:start -->"
assert_contains "$TARGET/CLAUDE.md" "<!-- pah:git-workflow:start -->"
assert_contains "$TARGET/.cursor/rules/devcontainer-standards.mdc" "docs/devcontainer/devcontainer-standards.md"
assert_contains "$TARGET/.cursor/rules/git-workflow-standards.mdc" "docs/git-workflow/git-workflow-standards.md"
assert_not_contains "$TARGET/.cursor/rules/devcontainer-standards.mdc" "devcontainer-standards.ko.md"
assert_not_contains "$TARGET/.cursor/rules/git-workflow-standards.mdc" "git-workflow-standards.ko.md"
assert_not_file "$TARGET/.cursor/rules/harness-development.mdc"
assert_contains "$ROOT/config/rule-domains.txt" "devcontainer"
assert_file "$ROOT/templates/stubs/agent-blocks/devcontainer.md"
assert_contains "$TARGET/.harness/manifest.json" '"devcontainer": {'
assert_contains "$TARGET/.harness/manifest.json" '"path": "docs/devcontainer/devcontainer-standards.md"'
assert_contains "$TARGET/.harness/manifest.json" '"git-workflow": {'
assert_contains "$TARGET/.harness/manifest.json" '"path": "docs/git-workflow/git-workflow-standards.md"'
assert_mode "$TARGET/.harness/manifest.json" 644

"$PAH" verify "$TARGET"
"$PAH" install "$TARGET"
assert_count "$TARGET/AGENTS.md" "<!-- pah:devcontainer:start -->" 1
assert_count "$TARGET/CLAUDE.md" "<!-- pah:devcontainer:start -->" 1
assert_count "$TARGET/AGENTS.md" "<!-- pah:git-workflow:start -->" 1
assert_count "$TARGET/CLAUDE.md" "<!-- pah:git-workflow:start -->" 1
"$PAH" status "$TARGET" > "$TMP_ROOT/early-status.log"
assert_contains "$TMP_ROOT/early-status.log" "Personal-Agent-Harness installed"

SECOND="$TMP_ROOT/existing"
mkdir -p "$SECOND"
cat > "$SECOND/AGENTS.md" <<'EOM'
# Existing Agent Rules

Keep this project-specific rule.
EOM

"$PAH" install "$SECOND"
assert_contains "$SECOND/AGENTS.md" "Keep this project-specific rule."
assert_contains "$SECOND/AGENTS.md" "<!-- pah:devcontainer:start -->"
assert_contains "$SECOND/AGENTS.md" "<!-- pah:git-workflow:start -->"
SECOND_AGENTS_BACKUP="$(find "$SECOND/.harness/backups" -path '*/AGENTS.md' -type f | head -n 1)"
[ -n "$SECOND_AGENTS_BACKUP" ] || fail "expected original AGENTS.md backup"
assert_contains "$SECOND_AGENTS_BACKUP" "Keep this project-specific rule."
assert_not_contains "$SECOND_AGENTS_BACKUP" "<!-- pah:devcontainer:start -->"
assert_not_contains "$SECOND_AGENTS_BACKUP" "<!-- pah:git-workflow:start -->"

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
assert_contains "$SCAFFOLD/.devcontainer/docker-compose.dev.yml" 'claude-config:/home/vscode/.claude'
assert_contains "$SCAFFOLD/.devcontainer/docker-compose.dev.yml" 'claude-json:/home/vscode/.ai-state/claude'
assert_contains "$SCAFFOLD/.devcontainer/docker-compose.dev.yml" 'codex-config:/home/vscode/.codex'
assert_contains "$SCAFFOLD/.devcontainer/docker-compose.dev.yml" 'name: ${aiStateVolumePrefix}-claude-config'
assert_contains "$SCAFFOLD/.devcontainer/docker-compose.dev.yml" 'name: ${aiStateVolumePrefix}-claude-json'
assert_contains "$SCAFFOLD/.devcontainer/docker-compose.dev.yml" 'name: ${aiStateVolumePrefix}-codex-config'
assert_not_contains "$SCAFFOLD/.devcontainer/docker-compose.dev.yml" '${devcontainerId}'
assert_contains "$SCAFFOLD/.devcontainer/commands/initializeCommand.sh" 'aiStateVolumePrefix='
assert_contains "$SCAFFOLD/.devcontainer/commands/post-create.sh" 'ln -sfn /home/vscode/.ai-state/claude/.claude.json /home/vscode/.claude.json'
assert_contains "$SCAFFOLD/.devcontainer/README.md" 'AI State Storage'
assert_contains "$SCAFFOLD/.devcontainer/README.md" 'Docker named volumes'
assert_contains "$SCAFFOLD/.devcontainer/README.md" '/home/vscode/.claude'
assert_contains "$SCAFFOLD/.devcontainer/README.md" '/home/vscode/.claude.json'
assert_contains "$SCAFFOLD/.devcontainer/README.md" '/home/vscode/.codex'
assert_contains "$SCAFFOLD/.devcontainer/README.md" 'docker volume rm'
assert_contains "$SCAFFOLD/.devcontainer/.env.example" 'CLAUDE_CODE_VERSION=2.1.170'
assert_contains "$SCAFFOLD/.devcontainer/.env.example" 'CODEX_CLI_VERSION=0.139.0'
assert_contains "$SCAFFOLD/.gitignore" "# pah:managed:start"
assert_contains "$SCAFFOLD/.gitignore" "Personal-Agent-Harness/"
"$PAH" verify "$SCAFFOLD"

SETUP_PROJECT="$TMP_ROOT/setup-project"
mkdir -p "$SETUP_PROJECT"
cp -a "$ROOT" "$SETUP_PROJECT/Personal-Agent-Harness"
(
  cd "$SETUP_PROJECT"
  ./Personal-Agent-Harness/setup.sh .
)
assert_file "$SETUP_PROJECT/docs/devcontainer/devcontainer-standards.md"
assert_file "$SETUP_PROJECT/docs/git-workflow/git-workflow-standards.md"
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

GIT_WORKFLOW_UPDATE_MARKER="pah-git-workflow-update-test-marker-$$"
echo "$GIT_WORKFLOW_UPDATE_MARKER" >> "$SETUP_PROJECT/Personal-Agent-Harness/standards/git-workflow/git-workflow-standards.md"
(
  cd "$SETUP_PROJECT"
  PAH_SKIP_PULL=1 ./Personal-Agent-Harness/update.sh .
)
assert_contains "$SETUP_PROJECT/docs/git-workflow/git-workflow-standards.md" "$GIT_WORKFLOW_UPDATE_MARKER"
"$PAH" verify "$SETUP_PROJECT"

EXTERNAL_PROJECT="$TMP_ROOT/external-project"
mkdir -p "$EXTERNAL_PROJECT"
"$ROOT/bootstrap.sh" "$EXTERNAL_PROJECT"
assert_file "$EXTERNAL_PROJECT/docs/devcontainer/devcontainer-standards.md"
assert_file "$EXTERNAL_PROJECT/.harness/manifest.json"
assert_not_dir "$EXTERNAL_PROJECT/Personal-Agent-Harness"
"$PAH" verify "$EXTERNAL_PROJECT"

NESTED_PROJECT="$TMP_ROOT/nested-project"
mkdir -p "$NESTED_PROJECT"
cp -a "$ROOT" "$NESTED_PROJECT/Personal-Agent-Harness"
"$ROOT/bootstrap.sh" "$NESTED_PROJECT" --clean-nested
assert_not_dir "$NESTED_PROJECT/Personal-Agent-Harness"
assert_file "$NESTED_PROJECT/.harness/manifest.json"
"$PAH" verify "$NESTED_PROJECT"

EXTERNAL_HARNESS="$TMP_ROOT/external-harness-root"
cp -a "$ROOT" "$EXTERNAL_HARNESS"
EXTERNAL_UPDATE_MARKER="pah-external-update-marker-$$"
echo "$EXTERNAL_UPDATE_MARKER" >> "$EXTERNAL_HARNESS/standards/devcontainer/devcontainer-standards.md"
PAH_SKIP_PULL=1 "$EXTERNAL_HARNESS/update.sh" "$EXTERNAL_PROJECT"
assert_contains "$EXTERNAL_PROJECT/docs/devcontainer/devcontainer-standards.md" "$EXTERNAL_UPDATE_MARKER"
"$PAH" verify "$EXTERNAL_PROJECT"

INIT_PROJECT="$TMP_ROOT/init-project"
mkdir -p "$INIT_PROJECT"
"$PAH" init "$INIT_PROJECT"
assert_file "$INIT_PROJECT/docs/devcontainer/devcontainer-standards.md"
assert_not_dir "$INIT_PROJECT/Personal-Agent-Harness"
"$PAH" verify "$INIT_PROJECT"

UPDATE_PROJECT="$TMP_ROOT/update-project"
mkdir -p "$UPDATE_PROJECT"
"$PAH" init "$UPDATE_PROJECT"
UPDATE_HARNESS="$TMP_ROOT/update-harness-root"
cp -a "$ROOT" "$UPDATE_HARNESS"
UPDATE_MARKER="pah-init-update-marker-$$"
echo "$UPDATE_MARKER" >> "$UPDATE_HARNESS/standards/devcontainer/devcontainer-standards.md"
PAH_DISTRIBUTION=npm "$UPDATE_HARNESS/bin/pah" update "$UPDATE_PROJECT"
assert_contains "$UPDATE_PROJECT/docs/devcontainer/devcontainer-standards.md" "$UPDATE_MARKER"
"$PAH" verify "$UPDATE_PROJECT"

NPM_ROOT="$TMP_ROOT/npm-package"
mkdir -p "$NPM_ROOT"
cp -a "$ROOT/bin" "$ROOT/config" "$ROOT/standards" "$ROOT/templates" "$NPM_ROOT/"
cp -a "$ROOT/bootstrap.sh" "$ROOT/setup.sh" "$ROOT/update.sh" "$ROOT/VERSION" "$NPM_ROOT/"
assert_file "$NPM_ROOT/bin/pah"
assert_file "$NPM_ROOT/bin/pah-entry"
assert_file "$NPM_ROOT/setup.sh"
assert_file "$NPM_ROOT/update.sh"
assert_file "$NPM_ROOT/bootstrap.sh"
assert_file "$NPM_ROOT/standards/devcontainer/devcontainer-standards.md"
assert_not_dir "$NPM_ROOT/dev-docs"
NPM_TARGET="$TMP_ROOT/npm-target"
mkdir -p "$NPM_TARGET"
PAH_DISTRIBUTION=npm "$NPM_ROOT/bin/pah-entry" init "$NPM_TARGET"
assert_file "$NPM_TARGET/.harness/manifest.json"
assert_not_dir "$NPM_TARGET/Personal-Agent-Harness"

NPM_BIN_ROOT="$TMP_ROOT/npm-bin"
mkdir -p "$NPM_BIN_ROOT/node_modules/personal-agent-harness" "$NPM_BIN_ROOT/node_modules/.bin"
cp -a "$NPM_ROOT/." "$NPM_BIN_ROOT/node_modules/personal-agent-harness/"
ln -s ../personal-agent-harness/bin/pah-entry "$NPM_BIN_ROOT/node_modules/.bin/pah"
NPM_BIN_TARGET="$TMP_ROOT/npm-bin-target"
mkdir -p "$NPM_BIN_TARGET"
"$NPM_BIN_ROOT/node_modules/.bin/pah" init "$NPM_BIN_TARGET"
assert_file "$NPM_BIN_TARGET/.harness/manifest.json"
assert_not_dir "$NPM_BIN_TARGET/Personal-Agent-Harness"

HARNESS_DEV="$TMP_ROOT/harness-dev"
mkdir -p "$HARNESS_DEV"
"$PAH" install "$HARNESS_DEV" --components harness-dev
assert_file "$HARNESS_DEV/.cursor/rules/harness-development.mdc"
assert_contains "$HARNESS_DEV/.cursor/rules/harness-development.mdc" "Personal-Agent-Harness/**"
assert_contains "$HARNESS_DEV/.cursor/rules/harness-development.mdc" "dev-docs/internal/development.md"
assert_contains "$HARNESS_DEV/.cursor/rules/harness-development.mdc" "adding-rule-domains.md"
assert_not_contains "$HARNESS_DEV/.cursor/rules/harness-development.mdc" "Personal-Agent-Harness/docs/internal"
assert_not_file "$HARNESS_DEV/docs/devcontainer/devcontainer-standards.md"
assert_not_file "$HARNESS_DEV/AGENTS.md"

BROKEN_BLOCK="$TMP_ROOT/broken-block"
mkdir -p "$BROKEN_BLOCK"
cat > "$BROKEN_BLOCK/AGENTS.md" <<'EOM'
# Existing Agent Rules

<!-- pah:devcontainer:start -->
Damaged managed block without an end marker.

PROJECT_RULE_MUST_SURVIVE
EOM
cp "$BROKEN_BLOCK/AGENTS.md" "$TMP_ROOT/broken-block-agents.before"
assert_command_fails "$PAH" install "$BROKEN_BLOCK"
cmp -s "$TMP_ROOT/broken-block-agents.before" "$BROKEN_BLOCK/AGENTS.md" || fail "damaged AGENTS.md changed during failed install"
assert_not_file "$BROKEN_BLOCK/docs/devcontainer/devcontainer-standards.md"
assert_not_dir "$BROKEN_BLOCK/.harness"

BROKEN_ROOT="$TMP_ROOT/broken-registry"
cp -a "$ROOT" "$BROKEN_ROOT"
printf '\nmissing-domain\n' >> "$BROKEN_ROOT/config/rule-domains.txt"
BROKEN_TARGET="$TMP_ROOT/broken-target"
mkdir -p "$BROKEN_TARGET"
assert_command_fails "$BROKEN_ROOT/bin/pah" install "$BROKEN_TARGET"
assert_not_file "$BROKEN_TARGET/docs/devcontainer/devcontainer-standards.md"
assert_not_file "$BROKEN_TARGET/.harness/manifest.json"
assert_not_dir "$BROKEN_TARGET/.harness"

DUPLICATE_ROOT="$TMP_ROOT/duplicate-registry"
cp -a "$ROOT" "$DUPLICATE_ROOT"
printf '\ndevcontainer\n' >> "$DUPLICATE_ROOT/config/rule-domains.txt"
mkdir -p "$TMP_ROOT/duplicate-target"
assert_command_fails "$DUPLICATE_ROOT/bin/pah" install "$TMP_ROOT/duplicate-target"

INVALID_ROOT="$TMP_ROOT/invalid-registry"
cp -a "$ROOT" "$INVALID_ROOT"
printf '\nInvalid Domain\n' >> "$INVALID_ROOT/config/rule-domains.txt"
mkdir -p "$TMP_ROOT/invalid-target"
assert_command_fails "$INVALID_ROOT/bin/pah" install "$TMP_ROOT/invalid-target"

EMPTY_ROOT="$TMP_ROOT/empty-registry"
cp -a "$ROOT" "$EMPTY_ROOT"
printf '# No active rule domains.\n' > "$EMPTY_ROOT/config/rule-domains.txt"
mkdir -p "$TMP_ROOT/empty-target"
assert_command_fails "$EMPTY_ROOT/bin/pah" install "$TMP_ROOT/empty-target"

UNREGISTERED_ROOT="$TMP_ROOT/unregistered-domain"
cp -a "$ROOT" "$UNREGISTERED_ROOT"
mkdir -p "$UNREGISTERED_ROOT/standards/unregistered"
printf '# Unregistered standard\n' > "$UNREGISTERED_ROOT/standards/unregistered/unregistered-standards.md"
printf '# Unregistered standard translation\n' > "$UNREGISTERED_ROOT/standards/unregistered/unregistered-standards.ko.md"
mkdir -p "$TMP_ROOT/unregistered-target"
"$UNREGISTERED_ROOT/bin/pah" install "$TMP_ROOT/unregistered-target"
assert_not_file "$TMP_ROOT/unregistered-target/docs/unregistered/unregistered-standards.md"

KO_REF_TARGET="$TMP_ROOT/ko-ref-target"
mkdir -p "$KO_REF_TARGET"
"$PAH" install "$KO_REF_TARGET"
printf '\nRead docs/git-workflow/git-workflow-standards.ko.md\n' >> "$KO_REF_TARGET/.cursor/rules/git-workflow-standards.mdc"
assert_command_fails "$PAH" verify "$KO_REF_TARGET"

BLOCK_DRIFT_TARGET="$TMP_ROOT/block-drift-target"
mkdir -p "$BLOCK_DRIFT_TARGET"
"$PAH" install "$BLOCK_DRIFT_TARGET"
sed -i '/<!-- pah:devcontainer:start -->/a Managed block drift.' "$BLOCK_DRIFT_TARGET/AGENTS.md"
assert_command_fails "$PAH" verify "$BLOCK_DRIFT_TARGET"

SOURCE_KO_REF_ROOT="$TMP_ROOT/source-ko-ref-root"
cp -a "$ROOT" "$SOURCE_KO_REF_ROOT"
printf '\nRead docs/git-workflow/git-workflow-standards.ko.md\n' >> "$SOURCE_KO_REF_ROOT/templates/stubs/cursor/git-workflow-standards.mdc"
mkdir -p "$TMP_ROOT/source-ko-ref-target"
assert_command_fails "$SOURCE_KO_REF_ROOT/bin/pah" install "$TMP_ROOT/source-ko-ref-target"
assert_not_dir "$TMP_ROOT/source-ko-ref-target/.harness"

BACKUP_TARGET="$TMP_ROOT/backup-target"
mkdir -p "$BACKUP_TARGET"
printf '# Existing Agent Rules\n' > "$BACKUP_TARGET/AGENTS.md"
"$PAH" install "$BACKUP_TARGET"
printf '\nProject rule after first install.\n' >> "$BACKUP_TARGET/AGENTS.md"
"$PAH" install "$BACKUP_TARGET"
printf '\nProject rule after second install.\n' >> "$BACKUP_TARGET/AGENTS.md"
"$PAH" install "$BACKUP_TARGET"
assert_dir_count "$BACKUP_TARGET/.harness/backups" 3

MANIFEST_TARGET="$TMP_ROOT/manifest-target"
mkdir -p "$MANIFEST_TARGET"
"$PAH" install "$MANIFEST_TARGET"
sed -i 's/"sha256": "[^"]*"/"sha256": "damaged"/' "$MANIFEST_TARGET/.harness/manifest.json"
assert_command_fails "$PAH" verify "$MANIFEST_TARGET"

MALFORMED_MANIFEST_TARGET="$TMP_ROOT/malformed-manifest-target"
mkdir -p "$MALFORMED_MANIFEST_TARGET"
"$PAH" install "$MALFORMED_MANIFEST_TARGET"
{
  printf 'not-json\n'
  cat "$MALFORMED_MANIFEST_TARGET/.harness/manifest.json"
} > "$MALFORMED_MANIFEST_TARGET/.harness/manifest.json.tmp"
mv "$MALFORMED_MANIFEST_TARGET/.harness/manifest.json.tmp" "$MALFORMED_MANIFEST_TARGET/.harness/manifest.json"
assert_command_fails "$PAH" verify "$MALFORMED_MANIFEST_TARGET"

UNKNOWN_COMPONENT_TARGET="$TMP_ROOT/unknown-component-target"
mkdir -p "$UNKNOWN_COMPONENT_TARGET"
assert_command_fails "$PAH" install "$UNKNOWN_COMPONENT_TARGET" --components typo
assert_not_file "$UNKNOWN_COMPONENT_TARGET/.harness/manifest.json"
assert_command_fails "$PAH" install "$UNKNOWN_COMPONENT_TARGET" --components rules,
assert_not_file "$UNKNOWN_COMPONENT_TARGET/.harness/manifest.json"

ESCAPE_ROOT="$TMP_ROOT/escape-root"
cp -a "$ROOT" "$ESCAPE_ROOT"
sed -i '/<!-- pah:git-workflow:end -->/i Literal escapes: \\d+ \\n \\\\server' "$ESCAPE_ROOT/templates/stubs/agent-blocks/git-workflow.md"
ESCAPE_TARGET="$TMP_ROOT/escape-target"
mkdir -p "$ESCAPE_TARGET"
"$ESCAPE_ROOT/bin/pah" install "$ESCAPE_TARGET"
"$ESCAPE_ROOT/bin/pah" install "$ESCAPE_TARGET"
assert_contains "$ESCAPE_TARGET/AGENTS.md" 'Literal escapes: \d+ \n \\server'
assert_contains "$ESCAPE_TARGET/CLAUDE.md" 'Literal escapes: \d+ \n \\server'

# hooks: unknown component still rejected
assert_command_fails "$PAH" install "$TMP_ROOT/unknown-component-target" --components typo

if ! command -v jq >/dev/null 2>&1; then
  # hooks: no jq — install succeeds with warning, hook files not created
  HOOKS_TARGET="$TMP_ROOT/hooks-no-jq"
  mkdir -p "$HOOKS_TARGET"
  "$PAH" install "$HOOKS_TARGET" --components rules,hooks
  assert_not_file "$HOOKS_TARGET/.harness/hooks/git-workflow.hook.sh"
  assert_not_file "$HOOKS_TARGET/.claude/settings.json"
  "$PAH" verify "$HOOKS_TARGET"
else
  # hooks: rules,hooks combined install
  HOOKS_TARGET="$TMP_ROOT/hooks-target"
  mkdir -p "$HOOKS_TARGET"
  "$PAH" install "$HOOKS_TARGET" --components rules,hooks
  assert_file "$HOOKS_TARGET/.harness/hooks/git-workflow.hook.sh"
  assert_file "$HOOKS_TARGET/.harness/hooks/devcontainer.hook.sh"
  assert_file "$HOOKS_TARGET/.claude/settings.json"
  assert_contains "$HOOKS_TARGET/.claude/settings.json" '.harness/hooks/git-workflow.hook.sh'
  assert_contains "$HOOKS_TARGET/.claude/settings.json" '.harness/hooks/devcontainer.hook.sh'
  assert_contains "$HOOKS_TARGET/.claude/settings.json" '"PreToolUse"'

  # hooks: verify passes after hooks install
  "$PAH" verify "$HOOKS_TARGET"

  # hooks: idempotent re-install does not duplicate entries
  "$PAH" install "$HOOKS_TARGET" --components rules,hooks
  BASH_COUNT="$(grep -c '"Bash"' "$HOOKS_TARGET/.claude/settings.json" || true)"
  [ "$BASH_COUNT" = "1" ] || fail "expected exactly 1 Bash entry in settings.json after re-install, found $BASH_COUNT"
  "$PAH" verify "$HOOKS_TARGET"

  # hooks: manifest includes hook files
  assert_contains "$HOOKS_TARGET/.harness/manifest.json" '.harness/hooks/git-workflow.hook.sh'
  assert_contains "$HOOKS_TARGET/.harness/manifest.json" '.harness/hooks/devcontainer.hook.sh'

  # hooks: verify fails if hook script is deleted
  HOOKS_VERIFY_TARGET="$TMP_ROOT/hooks-verify-target"
  mkdir -p "$HOOKS_VERIFY_TARGET"
  "$PAH" install "$HOOKS_VERIFY_TARGET" --components rules,hooks
  rm "$HOOKS_VERIFY_TARGET/.harness/hooks/git-workflow.hook.sh"
  assert_command_fails "$PAH" verify "$HOOKS_VERIFY_TARGET"

  # hooks: verify fails if settings.json hook entry is missing
  HOOKS_SETTINGS_TARGET="$TMP_ROOT/hooks-settings-target"
  mkdir -p "$HOOKS_SETTINGS_TARGET"
  "$PAH" install "$HOOKS_SETTINGS_TARGET" --components rules,hooks
  printf '{"hooks":{"PreToolUse":[]}}\n' > "$HOOKS_SETTINGS_TARGET/.claude/settings.json"
  assert_command_fails "$PAH" verify "$HOOKS_SETTINGS_TARGET"

  # hooks: verify fails if matcher exists but command shape is wrong
  HOOKS_SHAPE_TARGET="$TMP_ROOT/hooks-shape-target"
  mkdir -p "$HOOKS_SHAPE_TARGET"
  "$PAH" install "$HOOKS_SHAPE_TARGET" --components rules,hooks
  jq '.hooks.PreToolUse |= map(if .matcher == "Bash" then .hooks = [{type: "prompt", command: "bash .harness/hooks/git-workflow.hook.sh"}] else . end)' \
    "$HOOKS_SHAPE_TARGET/.claude/settings.json" > "$HOOKS_SHAPE_TARGET/.claude/settings.json.tmp"
  mv "$HOOKS_SHAPE_TARGET/.claude/settings.json.tmp" "$HOOKS_SHAPE_TARGET/.claude/settings.json"
  assert_command_fails "$PAH" verify "$HOOKS_SHAPE_TARGET"

  # hooks: verify fails if hook script loses execute permission
  HOOKS_MODE_TARGET="$TMP_ROOT/hooks-mode-target"
  mkdir -p "$HOOKS_MODE_TARGET"
  "$PAH" install "$HOOKS_MODE_TARGET" --components rules,hooks
  chmod 644 "$HOOKS_MODE_TARGET/.harness/hooks/git-workflow.hook.sh"
  assert_command_fails "$PAH" verify "$HOOKS_MODE_TARGET"

  # hooks: hooks-only install on top of existing rules installation
  HOOKS_ONLY_TARGET="$TMP_ROOT/hooks-only-target"
  mkdir -p "$HOOKS_ONLY_TARGET"
  "$PAH" install "$HOOKS_ONLY_TARGET" --components rules
  "$PAH" install "$HOOKS_ONLY_TARGET" --components hooks
  assert_file "$HOOKS_ONLY_TARGET/.harness/hooks/git-workflow.hook.sh"
  assert_contains "$HOOKS_ONLY_TARGET/.claude/settings.json" '.harness/hooks/git-workflow.hook.sh'
  "$PAH" verify "$HOOKS_ONLY_TARGET"

  # hooks: hooks-only install without prior rules installation fails
  HOOKS_NORULES_TARGET="$TMP_ROOT/hooks-norules-target"
  mkdir -p "$HOOKS_NORULES_TARGET"
  assert_command_fails "$PAH" install "$HOOKS_NORULES_TARGET" --components hooks

  # hooks: dry-run shows expected output without creating files
  HOOKS_DRYRUN_TARGET="$TMP_ROOT/hooks-dryrun-target"
  mkdir -p "$HOOKS_DRYRUN_TARGET"
  "$PAH" install "$HOOKS_DRYRUN_TARGET" --components rules
  "$PAH" install "$HOOKS_DRYRUN_TARGET" --components rules,hooks --dry-run > "$TMP_ROOT/hooks-dry-run.log"
  assert_contains "$TMP_ROOT/hooks-dry-run.log" "[DRY-RUN]"
  assert_contains "$TMP_ROOT/hooks-dry-run.log" "git-workflow.hook.sh"
  assert_not_file "$HOOKS_DRYRUN_TARGET/.harness/hooks/git-workflow.hook.sh"
fi

STATUS_TARGET="$TMP_ROOT/status-target"
mkdir -p "$STATUS_TARGET"
"$PAH" install "$STATUS_TARGET"

STATUS_LOG="$TMP_ROOT/status.log"
"$PAH" status "$STATUS_TARGET" > "$STATUS_LOG"
assert_contains "$STATUS_LOG" "harness_version:"
assert_contains "$STATUS_LOG" "$HARNESS_VERSION"

OLD_VERSION_ROOT="$TMP_ROOT/old-version-root"
cp -a "$ROOT" "$OLD_VERSION_ROOT"
printf '0.1.0\n' > "$OLD_VERSION_ROOT/VERSION"

STATUS_COMPARE_LOG="$TMP_ROOT/status-compare.log"
"$PAH" status "$STATUS_TARGET" --harness-root "$OLD_VERSION_ROOT" > "$STATUS_COMPARE_LOG"
assert_contains "$STATUS_COMPARE_LOG" "update available"

STATUS_CURRENT_LOG="$TMP_ROOT/status-current.log"
"$PAH" status "$STATUS_TARGET" > "$STATUS_CURRENT_LOG"
assert_contains "$STATUS_CURRENT_LOG" "cli version:"
assert_contains "$STATUS_CURRENT_LOG" "up to date with cli"

echo "All pah tests passed"
