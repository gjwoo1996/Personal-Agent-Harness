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

HARNESS_DEV="$TMP_ROOT/harness-dev"
mkdir -p "$HARNESS_DEV"
"$PAH" install "$HARNESS_DEV" --components harness-dev
assert_file "$HARNESS_DEV/.cursor/rules/harness-development.mdc"
assert_contains "$HARNESS_DEV/.cursor/rules/harness-development.mdc" "Personal-Agent-Harness/**"
assert_contains "$HARNESS_DEV/.cursor/rules/harness-development.mdc" "adding-rule-domains.md"
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

ESCAPE_ROOT="$TMP_ROOT/escape-root"
cp -a "$ROOT" "$ESCAPE_ROOT"
sed -i '/<!-- pah:git-workflow:end -->/i Literal escapes: \\d+ \\n \\\\server' "$ESCAPE_ROOT/templates/stubs/agent-blocks/git-workflow.md"
ESCAPE_TARGET="$TMP_ROOT/escape-target"
mkdir -p "$ESCAPE_TARGET"
"$ESCAPE_ROOT/bin/pah" install "$ESCAPE_TARGET"
"$ESCAPE_ROOT/bin/pah" install "$ESCAPE_TARGET"
assert_contains "$ESCAPE_TARGET/AGENTS.md" 'Literal escapes: \d+ \n \\server'
assert_contains "$ESCAPE_TARGET/CLAUDE.md" 'Literal escapes: \d+ \n \\server'

echo "All pah tests passed"
