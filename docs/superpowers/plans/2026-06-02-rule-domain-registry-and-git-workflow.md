# Rule Domain Registry And Git Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace devcontainer-specific rule installation with a registry-driven rule-domain system, then add `git-workflow` as the second default rule domain.

**Architecture:** Keep the existing Bash CLI and copy-mode behavior. Add an explicit `config/rule-domains.txt` registry, store one reusable Codex/Claude managed block per domain under `templates/stubs/agent-blocks/`, and make install, manifest generation, and verification iterate over registered domains. Keep optional components such as the devcontainer scaffold, gitignore merge, and harness-development Cursor rule outside the rule-domain registry.

**Tech Stack:** Bash, Markdown, Cursor MDC rules, JSON manifest, shell smoke tests

---

## File Structure

Create:

```text
config/rule-domains.txt
templates/stubs/agent-blocks/devcontainer.md
templates/stubs/agent-blocks/git-workflow.md
templates/stubs/cursor/git-workflow-standards.mdc
standards/git-workflow/git-workflow-standards.md
standards/git-workflow/git-workflow-standards.ko.md
```

Modify:

```text
bin/pah
tests/test_pah.sh
VERSION
README.md
docs/README.md
docs/adding-rule-domains.md
docs/development.md
docs/how-it-works.md
docs/reference.md
docs/troubleshooting.md
docs/usage.md
```

Delete after the single-source migration:

```text
templates/stubs/AGENTS.md
templates/stubs/CLAUDE.md
```

Keep unchanged:

```text
templates/devcontainer/**
templates/harness-dev/harness-development.mdc
.cursor/rules/harness-development.mdc
setup.sh
update.sh
install.sh
```

## Registry Contract

`config/rule-domains.txt` is the explicit ordered list of default domains installed by the `rules` component.

```text
devcontainer
git-workflow
```

Registry rules:

- Allow blank lines and lines beginning with `#`.
- Require each active domain ID to match `^[a-z0-9]+(-[a-z0-9]+)*$`.
- Reject duplicate active domain IDs.
- Install and verify domains in registry order.
- Fail with a clear error if a registered domain package is incomplete.
- Do not auto-discover `standards/*`; unregistered work-in-progress directories must not be deployed.
- Load and validate the registry in the current shell before iterating. Do not rely on process-substitution exit propagation for validation failures.

Each registered domain package contains:

```text
standards/<domain>/<domain>-standards.md
standards/<domain>/<domain>-standards.ko.md
templates/stubs/agent-blocks/<domain>.md
templates/stubs/cursor/<domain>-standards.mdc
```

## Manifest Contract

Change `.harness/manifest.json` from one devcontainer-specific standard pair to a domain-keyed object:

```json
{
  "harness": "Personal-Agent-Harness",
  "harness_version": "0.2.0",
  "mode": "copy",
  "standards": {
    "devcontainer": {
      "en": {
        "path": "docs/devcontainer/devcontainer-standards.md",
        "sha256": "<sha256>"
      },
      "ko": {
        "path": "docs/devcontainer/devcontainer-standards.ko.md",
        "sha256": "<sha256>",
        "ai_readable": false
      }
    },
    "git-workflow": {
      "en": {
        "path": "docs/git-workflow/git-workflow-standards.md",
        "sha256": "<sha256>"
      },
      "ko": {
        "path": "docs/git-workflow/git-workflow-standards.ko.md",
        "sha256": "<sha256>",
        "ai_readable": false
      }
    }
  },
  "managed_files": [
    "docs/devcontainer/devcontainer-standards.md",
    "docs/devcontainer/devcontainer-standards.ko.md",
    ".cursor/rules/devcontainer-standards.mdc",
    "docs/git-workflow/git-workflow-standards.md",
    "docs/git-workflow/git-workflow-standards.ko.md",
    ".cursor/rules/git-workflow-standards.mdc",
    "AGENTS.md",
    "CLAUDE.md"
  ]
}
```

## Task 1: Add Registry Regression Tests Before Refactoring

**Files:**
- Modify: `tests/test_pah.sh`

- [ ] **Step 1: Add reusable assertions**

Add helpers after `assert_not_file()`:

```bash
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
```

- [ ] **Step 2: Add devcontainer registry-era expectations**

After the first default install assertions, add:

```bash
assert_contains "$ROOT/config/rule-domains.txt" "devcontainer"
assert_file "$ROOT/templates/stubs/agent-blocks/devcontainer.md"
assert_contains "$TARGET/.harness/manifest.json" '"devcontainer": {'
assert_contains "$TARGET/.harness/manifest.json" '"path": "docs/devcontainer/devcontainer-standards.md"'
```

- [ ] **Step 3: Add repeated-install managed-block regression coverage**

After the first `"$PAH" verify "$TARGET"` call, add:

```bash
"$PAH" install "$TARGET"
assert_count "$TARGET/AGENTS.md" "<!-- pah:devcontainer:start -->" 1
assert_count "$TARGET/CLAUDE.md" "<!-- pah:devcontainer:start -->" 1
```

- [ ] **Step 4: Run the test and confirm it fails before implementation**

Run:

```bash
bash tests/test_pah.sh
```

Expected: FAIL because `config/rule-domains.txt` and `templates/stubs/agent-blocks/devcontainer.md` do not exist.

- [ ] **Step 5: Commit the failing regression test**

```bash
git add tests/test_pah.sh
git commit -m "test: 규칙 도메인 registry 전환 기준 추가"
```

## Task 2: Introduce The Explicit Domain Registry

**Files:**
- Create: `config/rule-domains.txt`
- Create: `templates/stubs/agent-blocks/devcontainer.md`
- Delete: `templates/stubs/AGENTS.md`
- Delete: `templates/stubs/CLAUDE.md`
- Modify: `bin/pah`

- [ ] **Step 1: Create the initial registry with only the existing domain**

Create `config/rule-domains.txt`:

```text
# Default rule domains installed by the rules component.
devcontainer
```

- [ ] **Step 2: Move the devcontainer managed block to one shared source**

Create `templates/stubs/agent-blocks/devcontainer.md` by moving the current managed block from `templates/stubs/AGENTS.md` unchanged:

```markdown
<!-- pah:devcontainer:start -->
## Dev Container Requests

For dev-container-related requests, first read:
`docs/devcontainer/devcontainer-standards.md`

Use that English document as the authoritative dev container rule source.

Do not use Korean translations (`*.ko.md`) as AI rule sources. Those files are for human reading only.

Priority order:

1. Direct user instruction
2. Project-specific exceptions and project rules
3. `docs/devcontainer/devcontainer-standards.md`
4. Historical notes or translations

Document project exceptions in `.devcontainer/README.md`.
<!-- pah:devcontainer:end -->
```

Delete the duplicated `templates/stubs/AGENTS.md` and `templates/stubs/CLAUDE.md` files.

- [ ] **Step 3: Add registry loading and validation functions**

In `bin/pah`, add the registry path near `ROOT` and `VERSION`:

```bash
RULE_DOMAINS_FILE="$ROOT/config/rule-domains.txt"
RULE_DOMAINS=()
```

Move `verify_file()` and `verify_contains()` above the domain functions, then add:

```bash
load_rule_domains() {
  [ -f "$RULE_DOMAINS_FILE" ] || die "missing rule domain registry: $RULE_DOMAINS_FILE"

  RULE_DOMAINS=()
  local domain
  local seen=","
  while IFS= read -r domain || [ -n "$domain" ]; do
    domain="${domain%%#*}"
    domain="${domain#"${domain%%[![:space:]]*}"}"
    domain="${domain%"${domain##*[![:space:]]}"}"
    [ -n "$domain" ] || continue

    [[ "$domain" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || die "invalid rule domain id: $domain"
    case "$seen" in
      *",$domain,"*) die "duplicate rule domain id: $domain" ;;
    esac
    seen="${seen}${domain},"
    RULE_DOMAINS+=("$domain")
  done < "$RULE_DOMAINS_FILE"

  [ "${#RULE_DOMAINS[@]}" -gt 0 ] || die "rule domain registry is empty: $RULE_DOMAINS_FILE"
}

require_rule_domain_source() {
  local domain="$1"
  verify_file "$ROOT/standards/$domain/$domain-standards.md"
  verify_file "$ROOT/standards/$domain/$domain-standards.ko.md"
  verify_file "$ROOT/templates/stubs/agent-blocks/$domain.md"
  verify_file "$ROOT/templates/stubs/cursor/$domain-standards.mdc"
  verify_contains "$ROOT/templates/stubs/agent-blocks/$domain.md" "<!-- pah:$domain:start -->"
  verify_contains "$ROOT/templates/stubs/agent-blocks/$domain.md" "<!-- pah:$domain:end -->"
  verify_contains "$ROOT/templates/stubs/cursor/$domain-standards.mdc" "docs/$domain/$domain-standards.md"
}
```

Use a global array deliberately: registry parsing must run in the current shell so malformed entries and duplicates stop installation reliably.

- [ ] **Step 4: Preserve the first backup when several domain blocks update the same file**

Add the early return below to `backup_file()` after checking that the target file exists:

```bash
[ -f "$backup_dir/$rel" ] && return 0
```

This keeps the original project-owned `AGENTS.md` and `CLAUDE.md` content. Without it, the second domain merge would overwrite the backup with an intermediate file that already contains the first updated block.

- [ ] **Step 5: Parameterize managed-block extraction and merging**

Replace the devcontainer-specific functions with:

```bash
extract_block() {
  local src="$1"
  local domain="$2"
  awk -v start="<!-- pah:$domain:start -->" -v end="<!-- pah:$domain:end -->" '
    $0 == start { flag=1 }
    flag { print }
    $0 == end { flag=0 }
  ' "$src"
}

merge_agent_block() {
  local block_src="$1"
  local target="$2"
  local rel="$3"
  local title="$4"
  local domain="$5"
  local dry_run="$6"
  local backup_dir="$7"
  local dest="$target/$rel"
  local start="<!-- pah:$domain:start -->"
  local end="<!-- pah:$domain:end -->"

  if [ "$dry_run" = "1" ]; then
    if [ -f "$dest" ]; then
      log "[DRY-RUN] MERGE   $rel ($domain)"
    else
      log "[DRY-RUN] CREATE  $rel ($domain)"
    fi
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  backup_file "$target" "$rel" "$backup_dir"

  local block
  block="$(extract_block "$block_src" "$domain")"
  [ -n "$block" ] || die "missing managed block for rule domain: $domain"

  if [ ! -f "$dest" ]; then
    {
      printf '# %s\n\n' "$title"
      printf '%s\n' "$block"
    } > "$dest"
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  if grep -Fq "$start" "$dest"; then
    awk -v start="$start" -v end="$end" -v block="$block" '
      $0 == start {
        print block
        skipping=1
        next
      }
      $0 == end {
        skipping=0
        next
      }
      !skipping { print }
    ' "$dest" > "$tmp"
  else
    {
      cat "$dest"
      printf '\n%s\n' "$block"
    } > "$tmp"
  fi
  mv "$tmp" "$dest"
}
```

- [ ] **Step 6: Add registry-driven install**

Add:

```bash
install_rule_domain() {
  local domain="$1"
  local target="$2"
  local dry_run="$3"
  local force="$4"
  local backup_dir="$5"

  require_rule_domain_source "$domain"
  copy_managed_file "$ROOT/standards/$domain/$domain-standards.md" "$target" "docs/$domain/$domain-standards.md" "$dry_run" "$force" "$backup_dir"
  copy_managed_file "$ROOT/standards/$domain/$domain-standards.ko.md" "$target" "docs/$domain/$domain-standards.ko.md" "$dry_run" "$force" "$backup_dir"
  copy_managed_file "$ROOT/templates/stubs/cursor/$domain-standards.mdc" "$target" ".cursor/rules/$domain-standards.mdc" "$dry_run" "$force" "$backup_dir"
  merge_agent_block "$ROOT/templates/stubs/agent-blocks/$domain.md" "$target" "AGENTS.md" "Agent Instructions" "$domain" "$dry_run" "$backup_dir"
  merge_agent_block "$ROOT/templates/stubs/agent-blocks/$domain.md" "$target" "CLAUDE.md" "Claude Instructions" "$domain" "$dry_run" "$backup_dir"
}
```

Replace the hardcoded `rules` install body with:

```bash
if has_component "$components" "rules"; then
  load_rule_domains
  for domain in "${RULE_DOMAINS[@]}"; do
    install_rule_domain "$domain" "$target" "$dry_run" "$force" "$backup_dir"
  done
fi
```

- [ ] **Step 7: Generate the manifest from the registry**

Replace `write_manifest()` with this loop-based implementation. It uses `printf` and a temporary file so JSON comma placement is deterministic without adding `jq`, Python, or a YAML parser dependency:

```bash
write_manifest() {
  local target="$1"
  local mode="$2"
  local dry_run="$3"
  [ "$dry_run" = "1" ] && return 0

  local manifest_dir="$target/.harness"
  local tmp
  local domain
  local rel
  local first
  mkdir -p "$manifest_dir"
  tmp="$(mktemp)"

  {
    printf '{\n'
    printf '  "harness": "Personal-Agent-Harness",\n'
    printf '  "harness_version": "%s",\n' "$VERSION"
    printf '  "mode": "%s",\n' "$mode"
    printf '  "standards": {\n'

    first=1
    for domain in "${RULE_DOMAINS[@]}"; do
      [ "$first" = "1" ] || printf ',\n'
      first=0
      printf '    "%s": {\n' "$domain"
      printf '      "en": {\n'
      printf '        "path": "docs/%s/%s-standards.md",\n' "$domain" "$domain"
      printf '        "sha256": "%s"\n' "$(sha256_file "$target/docs/$domain/$domain-standards.md")"
      printf '      },\n'
      printf '      "ko": {\n'
      printf '        "path": "docs/%s/%s-standards.ko.md",\n' "$domain" "$domain"
      printf '        "sha256": "%s",\n' "$(sha256_file "$target/docs/$domain/$domain-standards.ko.md")"
      printf '        "ai_readable": false\n'
      printf '      }\n'
      printf '    }'
    done

    printf '\n  },\n'
    printf '  "managed_files": [\n'
    first=1
    for domain in "${RULE_DOMAINS[@]}"; do
      for rel in \
        "docs/$domain/$domain-standards.md" \
        "docs/$domain/$domain-standards.ko.md" \
        ".cursor/rules/$domain-standards.mdc"; do
        [ "$first" = "1" ] || printf ',\n'
        first=0
        printf '    "%s"' "$rel"
      done
    done
    for rel in "AGENTS.md" "CLAUDE.md"; do
      [ "$first" = "1" ] || printf ',\n'
      first=0
      printf '    "%s"' "$rel"
    done
    printf '\n  ]\n'
    printf '}\n'
  } > "$tmp"

  mv "$tmp" "$manifest_dir/manifest.json"
}
```

- [ ] **Step 8: Add registry-driven target verification**

Add:

```bash
verify_rule_domain() {
  local domain="$1"
  local target="$2"
  local en_rel="docs/$domain/$domain-standards.md"
  local ko_rel="docs/$domain/$domain-standards.ko.md"
  local cursor_rel=".cursor/rules/$domain-standards.mdc"

  verify_file "$target/$en_rel"
  verify_file "$target/$ko_rel"
  verify_file "$target/$cursor_rel"
  verify_contains "$target/$cursor_rel" "$en_rel"
  verify_contains "$target/AGENTS.md" "<!-- pah:$domain:start -->"
  verify_contains "$target/CLAUDE.md" "<!-- pah:$domain:start -->"

  if grep -Fq "$domain-standards.ko.md" "$target/$cursor_rel" "$target/AGENTS.md" "$target/CLAUDE.md"; then
    die "AI stubs must not reference $domain-standards.ko.md as a rule source"
  fi
}
```

Replace the devcontainer-specific `cmd_verify()` checks with:

```bash
verify_file "$target/.harness/manifest.json"
verify_file "$target/AGENTS.md"
verify_file "$target/CLAUDE.md"

load_rule_domains
for domain in "${RULE_DOMAINS[@]}"; do
  require_rule_domain_source "$domain"
  verify_rule_domain "$domain" "$target"
done
```

- [ ] **Step 9: Run regression tests**

Run:

```bash
bash tests/test_pah.sh
```

Expected: PASS with `All pah tests passed`.

- [ ] **Step 10: Inspect the generated manifest manually**

Run:

```bash
tmp="$(mktemp -d)"
./bin/pah install "$tmp"
cat "$tmp/.harness/manifest.json"
rm -rf "$tmp"
```

Expected: valid JSON-shaped output with `standards.devcontainer`, the three devcontainer managed paths, `AGENTS.md`, and `CLAUDE.md`.

- [ ] **Step 11: Commit the registry refactor**

```bash
git add config/rule-domains.txt templates/stubs/agent-blocks/devcontainer.md bin/pah
git rm templates/stubs/AGENTS.md templates/stubs/CLAUDE.md
git commit -m "refactor: 규칙 도메인 설치를 registry 기반으로 일반화"
```

## Task 3: Add Failing Tests For The Git Workflow Domain

**Files:**
- Modify: `tests/test_pah.sh`

- [ ] **Step 1: Add default-install expectations**

After the existing devcontainer assertions, add:

```bash
assert_contains "$TMP_ROOT/dry-run.log" "docs/git-workflow/git-workflow-standards.md"
assert_file "$TARGET/docs/git-workflow/git-workflow-standards.md"
assert_file "$TARGET/docs/git-workflow/git-workflow-standards.ko.md"
assert_file "$TARGET/.cursor/rules/git-workflow-standards.mdc"
assert_contains "$TARGET/AGENTS.md" "<!-- pah:git-workflow:start -->"
assert_contains "$TARGET/CLAUDE.md" "<!-- pah:git-workflow:start -->"
assert_contains "$TARGET/.cursor/rules/git-workflow-standards.mdc" "docs/git-workflow/git-workflow-standards.md"
assert_not_contains "$TARGET/.cursor/rules/git-workflow-standards.mdc" "git-workflow-standards.ko.md"
assert_contains "$TARGET/.harness/manifest.json" '"git-workflow": {'
assert_contains "$TARGET/.harness/manifest.json" '"path": "docs/git-workflow/git-workflow-standards.md"'
```

- [ ] **Step 2: Add repeated-install expectations**

After reinstalling `TARGET`, add:

```bash
assert_count "$TARGET/AGENTS.md" "<!-- pah:git-workflow:start -->" 1
assert_count "$TARGET/CLAUDE.md" "<!-- pah:git-workflow:start -->" 1
```

- [ ] **Step 3: Extend existing-file preservation coverage**

After installing into `SECOND`, add:

```bash
assert_contains "$SECOND/AGENTS.md" "<!-- pah:git-workflow:start -->"

SECOND_AGENTS_BACKUP="$(find "$SECOND/.harness/backups" -path '*/AGENTS.md' -type f | head -n 1)"
[ -n "$SECOND_AGENTS_BACKUP" ] || fail "expected original AGENTS.md backup"
assert_contains "$SECOND_AGENTS_BACKUP" "Keep this project-specific rule."
assert_not_contains "$SECOND_AGENTS_BACKUP" "<!-- pah:devcontainer:start -->"
assert_not_contains "$SECOND_AGENTS_BACKUP" "<!-- pah:git-workflow:start -->"
```

- [ ] **Step 4: Extend setup and update coverage**

After the setup assertions, add:

```bash
assert_file "$SETUP_PROJECT/docs/git-workflow/git-workflow-standards.md"
```

After the devcontainer update-marker assertion, add a git-workflow marker scenario:

```bash
GIT_WORKFLOW_UPDATE_MARKER="pah-git-workflow-update-test-marker-$$"
echo "$GIT_WORKFLOW_UPDATE_MARKER" >> "$SETUP_PROJECT/Personal-Agent-Harness/standards/git-workflow/git-workflow-standards.md"
(
  cd "$SETUP_PROJECT"
  PAH_SKIP_PULL=1 ./Personal-Agent-Harness/update.sh .
)
assert_contains "$SETUP_PROJECT/docs/git-workflow/git-workflow-standards.md" "$GIT_WORKFLOW_UPDATE_MARKER"
```

- [ ] **Step 5: Run tests and confirm failure**

Run:

```bash
bash tests/test_pah.sh
```

Expected: FAIL because `git-workflow` is not registered and its package files do not exist.

- [ ] **Step 6: Commit the failing tests**

```bash
git add tests/test_pah.sh
git commit -m "test: git workflow 기본 배포 시나리오 추가"
```

## Task 4: Add The Git Workflow Rule Domain Package

**Files:**
- Modify: `config/rule-domains.txt`
- Create: `standards/git-workflow/git-workflow-standards.md`
- Create: `standards/git-workflow/git-workflow-standards.ko.md`
- Create: `templates/stubs/agent-blocks/git-workflow.md`
- Create: `templates/stubs/cursor/git-workflow-standards.mdc`

- [ ] **Step 1: Register the new default domain**

Append:

```text
git-workflow
```

to `config/rule-domains.txt`.

- [ ] **Step 2: Write the authoritative English standard**

Create `standards/git-workflow/git-workflow-standards.md` with these sections:

```markdown
# Git Workflow Standards

This is the authoritative git workflow rule document distributed by Personal-Agent-Harness.
AI agents should read this English document before preparing commits or changing git history.

## Status

Priority order:

1. Direct user instruction
2. Project-specific git workflow rules and documented exceptions
3. This document
4. Historical notes or translations

Korean translations are for human reading only. Do not use `*.ko.md` files as AI rule sources.

## Before Creating Commits

- Run `git status --short`.
- Inspect tracked unstaged changes with `git diff`.
- Inspect staged changes with `git diff --staged`.
- Read new files that are candidates for the commit because they do not appear in a normal tracked diff.
- Preserve user-owned and unrelated changes.
- Exclude temporary files, generated files, secrets, and unrelated local files.

## Commit Grouping

- Keep one clear purpose in each commit.
- Split independent feature, fix, refactor, docs, test, configuration, dependency, formatting, and file-move changes when they can stand alone.
- Keep tightly coupled code and tests together when separating them would make the commit misleading or unusable.
- Explain the proposed grouping before committing when multiple commits are needed.

## Commit Messages

Use Conventional Commits by default:

```text
<type>: <summary>

<body>
```

Common types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`.

- Make the summary specific and easy to scan.
- Use the body when the reason, behavioral difference, or verification result is not obvious.
- Prefer explaining why the change exists instead of merely listing edited files.
- Follow a project-specific message language rule when one exists.

## History Safety

Without an explicit user request:

- Do not amend existing commits.
- Do not rebase or squash commits.
- Do not force-push.
- Do not discard changes with destructive commands.
- Do not revert changes that appear to belong to the user.

## After Creating Commits

- Run `git status --short`.
- Report the created commit hashes and summaries.
- Report any remaining changes separately.

## Project Exceptions

Document project-specific differences in `docs/git-workflow/README.md`.

Examples:

- Required commit message language
- Additional commit types such as `infra`
- Branch naming rules
- Pull request and review requirements
- Whether user confirmation is required immediately before creating commits
```

- [ ] **Step 3: Write the Korean human-readable translation**

Create `standards/git-workflow/git-workflow-standards.ko.md`:

```markdown
# Git 워크플로우 표준

이 문서는 Personal-Agent-Harness가 배포하는 Git 워크플로우 규칙 문서입니다.
AI 에이전트는 커밋을 준비하거나 Git 히스토리를 변경하기 전에 영문 원본을 읽어야 합니다.

## 상태

우선순위:

1. 사용자의 직접 지시
2. 프로젝트별 Git 워크플로우 규칙과 문서화된 예외
3. 영문 원본 문서
4. 과거 참고 문서 또는 번역본

이 한글 문서는 사람이 읽기 위한 번역본입니다. AI 규칙 출처로 사용하지 않습니다.

## 커밋 생성 전 확인

- `git status --short`를 실행합니다.
- `git diff`로 tracked unstaged 변경사항을 확인합니다.
- `git diff --staged`로 staged 변경사항을 확인합니다.
- 신규 파일은 일반 tracked diff에 나타나지 않으므로 커밋 후보 파일의 내용을 읽습니다.
- 사용자가 만든 변경사항과 현재 작업과 무관한 변경사항을 보존합니다.
- 임시 파일, 생성 파일, 비밀정보, 무관한 로컬 파일을 제외합니다.

## 커밋 분리

- 각 커밋에는 하나의 명확한 목적만 담습니다.
- 독립적으로 유지할 수 있는 기능, 버그 수정, 리팩터링, 문서, 테스트, 설정, 의존성, 포맷, 파일 이동 변경은 분리합니다.
- 코드와 테스트처럼 강하게 연결된 변경은 분리하면 의미가 흐려지거나 사용할 수 없게 되는 경우 함께 유지합니다.
- 여러 커밋이 필요하면 커밋 전에 분리 방식을 설명합니다.

## 커밋 메시지

기본적으로 Conventional Commits를 사용합니다.

```text
<type>: <summary>

<body>
```

일반적인 타입: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`.

- 제목은 구체적이고 빠르게 읽을 수 있게 작성합니다.
- 변경 이유, 동작 차이, 검증 결과가 명확하지 않으면 본문을 작성합니다.
- 수정한 파일 목록만 나열하기보다 변경이 필요한 이유를 우선 설명합니다.
- 프로젝트별 메시지 언어 규칙이 있으면 따릅니다.

## 히스토리 안전

사용자의 명시적인 요청이 없으면 다음 작업을 수행하지 않습니다.

- 기존 커밋 amend
- rebase 또는 squash
- force push
- 파괴적인 명령으로 변경사항 폐기
- 사용자 소유로 보이는 변경사항 되돌리기

## 커밋 생성 후 확인

- `git status --short`를 실행합니다.
- 생성한 커밋 hash와 요약을 보고합니다.
- 남아 있는 변경사항을 별도로 보고합니다.

## 프로젝트별 예외

프로젝트별 차이는 `docs/git-workflow/README.md`에 기록합니다.

예시:

- 필수 커밋 메시지 언어
- `infra` 같은 추가 커밋 타입
- 브랜치 이름 규칙
- Pull Request와 리뷰 요구사항
- 커밋 생성 직전에 사용자 확인이 필요한지 여부
```

- [ ] **Step 4: Add the shared Codex and Claude managed block**

Create `templates/stubs/agent-blocks/git-workflow.md`:

```markdown
<!-- pah:git-workflow:start -->
## Git Workflow Requests

For commit preparation, commit creation, or git history changes, first read:
`docs/git-workflow/git-workflow-standards.md`

Use that English document as the authoritative git workflow rule source.

Do not use Korean translations (`*.ko.md`) as AI rule sources. Those files are for human reading only.

Priority order:

1. Direct user instruction
2. Project-specific exceptions and project rules
3. `docs/git-workflow/git-workflow-standards.md`
4. Historical notes or translations

Document project exceptions in `docs/git-workflow/README.md`.
<!-- pah:git-workflow:end -->
```

- [ ] **Step 5: Add the Cursor rule**

Create `templates/stubs/cursor/git-workflow-standards.mdc`:

```markdown
---
description: Git workflow standards managed by Personal-Agent-Harness
alwaysApply: true
harness-managed: true
---

# Git Workflow Standards

Before preparing commits or changing git history, first read:

`docs/git-workflow/git-workflow-standards.md`

Follow that English document as the authoritative source for git workflow decisions.

Do not use Korean translations (`*.ko.md`) as AI rule sources. They exist only for human reading.

If the standard does not fit a project, document the exception in that project's `docs/git-workflow/README.md`.
```

- [ ] **Step 6: Run the full smoke test**

Run:

```bash
bash tests/test_pah.sh
```

Expected: PASS with `All pah tests passed`.

- [ ] **Step 7: Commit the new domain**

```bash
git add config/rule-domains.txt standards/git-workflow templates/stubs/agent-blocks/git-workflow.md templates/stubs/cursor/git-workflow-standards.mdc
git commit -m "feat: git workflow 규칙 도메인 추가"
```

## Task 5: Add Registry Failure-Mode Tests

**Files:**
- Modify: `tests/test_pah.sh`

- [ ] **Step 1: Add missing-source failure coverage**

Append before the final success message:

```bash
BROKEN_ROOT="$TMP_ROOT/broken-registry"
cp -a "$ROOT" "$BROKEN_ROOT"
printf '\nmissing-domain\n' >> "$BROKEN_ROOT/config/rule-domains.txt"
mkdir -p "$TMP_ROOT/broken-target"
assert_command_fails "$BROKEN_ROOT/bin/pah" install "$TMP_ROOT/broken-target"
```

- [ ] **Step 2: Add duplicate-domain failure coverage**

Append:

```bash
DUPLICATE_ROOT="$TMP_ROOT/duplicate-registry"
cp -a "$ROOT" "$DUPLICATE_ROOT"
printf '\ndevcontainer\n' >> "$DUPLICATE_ROOT/config/rule-domains.txt"
mkdir -p "$TMP_ROOT/duplicate-target"
assert_command_fails "$DUPLICATE_ROOT/bin/pah" install "$TMP_ROOT/duplicate-target"
```

- [ ] **Step 3: Add invalid-domain-ID failure coverage**

Append:

```bash
INVALID_ROOT="$TMP_ROOT/invalid-registry"
cp -a "$ROOT" "$INVALID_ROOT"
printf '\nInvalid Domain\n' >> "$INVALID_ROOT/config/rule-domains.txt"
mkdir -p "$TMP_ROOT/invalid-target"
assert_command_fails "$INVALID_ROOT/bin/pah" install "$TMP_ROOT/invalid-target"
```

- [ ] **Step 4: Add Korean-source-reference verification failure coverage**

Append:

```bash
KO_REF_TARGET="$TMP_ROOT/ko-ref-target"
mkdir -p "$KO_REF_TARGET"
"$PAH" install "$KO_REF_TARGET"
printf '\nRead docs/git-workflow/git-workflow-standards.ko.md\n' >> "$KO_REF_TARGET/.cursor/rules/git-workflow-standards.mdc"
assert_command_fails "$PAH" verify "$KO_REF_TARGET"
```

- [ ] **Step 5: Run tests**

Run:

```bash
bash tests/test_pah.sh
```

Expected: PASS. The nested negative scenarios print expected `ERROR:` lines but do not stop the test script.

- [ ] **Step 6: Commit failure-mode coverage**

```bash
git add tests/test_pah.sh
git commit -m "test: 규칙 도메인 registry 오류 검증 추가"
```

## Task 6: Update User And Harness Development Documentation

**Files:**
- Modify: `VERSION`
- Modify: `README.md`
- Modify: `docs/README.md`
- Modify: `docs/adding-rule-domains.md`
- Modify: `docs/development.md`
- Modify: `docs/how-it-works.md`
- Modify: `docs/reference.md`
- Modify: `docs/troubleshooting.md`
- Modify: `docs/usage.md`

- [ ] **Step 1: Bump the harness version**

Change `VERSION`:

```text
0.2.0
```

- [ ] **Step 2: Rewrite the internal domain-addition procedure**

Update `docs/adding-rule-domains.md` so the official procedure becomes:

```text
1. Choose a kebab-case domain ID.
2. Add standards/<domain>/<domain>-standards.md.
3. Add standards/<domain>/<domain>-standards.ko.md.
4. Add templates/stubs/agent-blocks/<domain>.md.
5. Add templates/stubs/cursor/<domain>-standards.mdc.
6. Register the domain in config/rule-domains.txt when it is ready for default deployment.
7. Extend tests/test_pah.sh for domain-specific behavior.
8. Run bash tests/test_pah.sh.
9. Update user-facing docs when installed files or behavior changed.
```

Explicitly document:

- `bin/pah` normally does not need domain-specific edits anymore.
- Registry order controls install, manifest, and verify order.
- Optional scaffolds remain separate components.
- Work-in-progress domain packages stay unregistered until complete.
- The registry is explicit by design; do not replace it with automatic `standards/*` discovery.

- [ ] **Step 3: Update user-facing installation trees**

In `README.md`, `docs/usage.md`, `docs/how-it-works.md`, and `docs/reference.md`, describe that default `rules` installation now includes:

```text
docs/devcontainer/**
docs/git-workflow/**
.cursor/rules/devcontainer-standards.mdc
.cursor/rules/git-workflow-standards.mdc
AGENTS.md
CLAUDE.md
.harness/manifest.json
```

- [ ] **Step 4: Update managed-block documentation**

Document both block IDs:

```markdown
<!-- pah:devcontainer:start -->
...
<!-- pah:devcontainer:end -->

<!-- pah:git-workflow:start -->
...
<!-- pah:git-workflow:end -->
```

Explain that each block is independently replaced and project-owned content outside blocks is preserved.

- [ ] **Step 5: Update manifest and troubleshooting documentation**

Document the domain-keyed manifest shape and update troubleshooting examples so they are not devcontainer-only. Include:

- missing registered package file
- malformed or duplicate registry entry
- damaged domain-specific managed block
- AI stub referring to any `*-standards.ko.md`

- [ ] **Step 6: Update the development inventory**

In `docs/development.md` and `docs/README.md`, list:

```text
config/rule-domains.txt
templates/stubs/agent-blocks/
standards/git-workflow/
templates/stubs/cursor/git-workflow-standards.mdc
```

Replace references to duplicated `templates/stubs/AGENTS.md` and `templates/stubs/CLAUDE.md`.

- [ ] **Step 7: Run documentation-oriented searches**

Run:

```bash
rg -n "templates/stubs/(AGENTS|CLAUDE)\\.md|devcontainer-standards\\.ko\\.md as a rule source|현재 범위: 데브컨테이너" README.md docs
```

Expected: no stale description that incorrectly presents the old duplicated stub structure or devcontainer-only default scope.

- [ ] **Step 8: Run full verification**

Run:

```bash
bash tests/test_pah.sh
```

Expected: PASS with `All pah tests passed`.

- [ ] **Step 9: Commit documentation and version changes**

```bash
git add VERSION README.md docs
git commit -m "docs: registry 기반 규칙 도메인 확장 절차 반영"
```

## Task 7: Final Verification And Review

**Files:**
- Review: all modified files

- [ ] **Step 1: Run shell syntax checks**

```bash
bash -n bin/pah setup.sh update.sh install.sh tests/test_pah.sh
```

Expected: no output and exit code `0`.

- [ ] **Step 2: Run the complete smoke test**

```bash
bash tests/test_pah.sh
```

Expected: PASS with `All pah tests passed`.

- [ ] **Step 3: Validate generated JSON with an available standard parser**

Run:

```bash
tmp="$(mktemp -d)"
./bin/pah install "$tmp"
python3 -m json.tool "$tmp/.harness/manifest.json" >/dev/null
./bin/pah verify "$tmp"
rm -rf "$tmp"
```

Expected: JSON parser succeeds and verify prints `Personal-Agent-Harness verification passed`.

- [ ] **Step 4: Confirm default setup behavior**

Run:

```bash
tmp="$(mktemp -d)"
cp -a . "$tmp/Personal-Agent-Harness"
(
  cd "$tmp"
  ./Personal-Agent-Harness/setup.sh .
  test -f docs/devcontainer/devcontainer-standards.md
  test -f docs/git-workflow/git-workflow-standards.md
  grep -Fq '<!-- pah:devcontainer:start -->' AGENTS.md
  grep -Fq '<!-- pah:git-workflow:start -->' AGENTS.md
)
rm -rf "$tmp"
```

Expected: no errors.

- [ ] **Step 5: Review the final diff**

Run:

```bash
git status --short
git diff --stat HEAD~6..HEAD
git log --oneline -6
```

Expected:

- Registry and package files are present.
- Deleted duplicated stubs are intentional.
- No generated `.harness/backups/` files are staged.
- The six planned commits are visible and purpose-specific.

- [ ] **Step 6: Record final verification in the completion report**

Report:

- registry migration outcome
- new `git-workflow` domain behavior
- manifest format change
- tests and syntax checks executed
- any remaining uncommitted files
