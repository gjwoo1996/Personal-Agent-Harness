# External Harness Workflow (Approach C) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 프로젝트 안에 `Personal-Agent-Harness/`(중첩 `.git` 포함)를 남기지 않고 하네스를 적용·갱신할 수 있는 공식 워크플로우로 전환한다.

**Architecture:** copy mode는 유지한다. 하네스 소스는 프로젝트 밖 고정 경로(`PAH_HOME`, 기본 `~/.local/share/personal-agent-harness`)에 두고, `bootstrap.sh` / `setup.sh` / `update.sh`가 대상 경로 인자로 규칙만 복사한다. 설치 추적은 기존 `.harness/manifest.json`의 `harness_version` + checksum으로 유지하고, `pah status --harness-root`로 로컬 하네스 버전과 비교한다. 실수로 in-project clone한 경우를 위해 `gitignore` 컴포넌트에 `Personal-Agent-Harness/`를 추가하고 `bootstrap.sh --clean-nested`로 마이그레이션한다.

**Tech Stack:** Bash, JSON manifest, shell smoke tests (`tests/test_pah.sh`)

**Design context:** brainstorming에서 합의한 Approach C. in-project clone은 legacy/마이그레이션 경로로만 문서화한다.

---

## File Structure

Create:

```text
bootstrap.sh
docs/superpowers/specs/2026-06-09-external-harness-workflow-design.md
```

Modify:

```text
bin/pah
tests/test_pah.sh
VERSION                         # 0.2.0 → 0.3.0
README.md
docs/usage.md
docs/how-it-works.md
docs/reference.md
docs/troubleshooting.md
docs/development.md
```

Keep unchanged (동작은 이미 target 인자 지원):

```text
setup.sh
update.sh
install.sh
```

## Workflow Contract (After Change)

### 권장: 외부 고정 위치

```bash
# 1) 하네스는 프로젝트 밖에 한 번만 clone
git clone <your-repo-url> ~/.local/share/personal-agent-harness

# 2) 대상 프로젝트에 적용 (프로젝트 안에 harness 폴더 생기지 않음)
~/.local/share/personal-agent-harness/bootstrap.sh /path/to/my-project

# 3) 업데이트
~/.local/share/personal-agent-harness/update.sh /path/to/my-project

# 4) 설치 버전 확인 + 로컬 하네스와 비교
~/.local/share/personal-agent-harness/bin/pah status /path/to/my-project --harness-root ~/.local/share/personal-agent-harness
```

### 환경 변수

| 변수 | 기본값 | 용도 |
|------|--------|------|
| `PAH_HOME` | `~/.local/share/personal-agent-harness` | 문서·status에서 권장 경로 안내 |
| `PAH_SKIP_PULL` | `0` | 기존과 동일. `update.sh`에서 pull 건너뜀 |

### 프로젝트에 남는 것 (변경 없음)

```text
target-project/
├── docs/<domain>/
├── .cursor/rules/
├── AGENTS.md, CLAUDE.md
└── .harness/manifest.json    # harness_version + sha256
```

### 프로젝트에 남지 않아야 하는 것

```text
target-project/Personal-Agent-Harness/   # 전체 제거 대상
```

---

## Task 1: Design Spec Document

**Files:**
- Create: `docs/superpowers/specs/2026-06-09-external-harness-workflow-design.md`

- [ ] **Step 1: Write design spec**

```markdown
# External Harness Workflow Design

## Problem
In-project `git clone Personal-Agent-Harness` nests a second `.git` inside the target project and leaves the full harness source tree in the project.

## Decision
- Primary workflow: external `PAH_HOME` clone + `bootstrap.sh <target>`.
- Installed-state tracking: existing `.harness/manifest.json` (`harness_version`, checksums).
- Update tracking: `pah status --harness-root <pah-checkout>` compares installed vs local harness `VERSION`.
- Legacy in-project clone: supported for migration via `bootstrap.sh --clean-nested`; discouraged in docs.
- Out of scope v1: curl installer, remote git fetch in status, submodule mode.

## Migration
1. External-clone harness to PAH_HOME.
2. Run `bootstrap.sh <target> --clean-nested`.
3. Optionally `pah install <target> --components gitignore` to ignore future accidental clones.
```

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/specs/2026-06-09-external-harness-workflow-design.md
git commit -m "docs: add external harness workflow design spec"
```

---

## Task 2: `bootstrap.sh`

**Files:**
- Create: `bootstrap.sh`

- [ ] **Step 1: Write bootstrap.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET="${1:-}"
CLEAN_NESTED=0

usage() {
  cat <<'USAGE'
Usage:
  bootstrap.sh <target> [--clean-nested]

Install harness rules into <target> using this harness checkout.
Does not copy the harness repository into the target project.

Options:
  --clean-nested   Remove <target>/Personal-Agent-Harness after a successful install
USAGE
}

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --clean-nested) CLEAN_NESTED=1; shift ;;
    -h|--help|help) usage; exit 0 ;;
    *)
      if [ -z "$TARGET" ]; then
        TARGET="$1"
        shift
      else
        die "unexpected argument: $1"
      fi
      ;;
  esac
done

[ -n "$TARGET" ] || { usage; exit 1; }
TARGET="$(cd "$TARGET" && pwd -P)"

if [ -d "$TARGET/Personal-Agent-Harness/.git" ]; then
  log "WARNING: nested harness clone detected at $TARGET/Personal-Agent-Harness"
  log "WARNING: recommended: use external PAH_HOME and remove the nested folder"
fi

"$ROOT/setup.sh" "$TARGET"

if [ "$CLEAN_NESTED" = "1" ] && [ -d "$TARGET/Personal-Agent-Harness" ]; then
  rm -rf "$TARGET/Personal-Agent-Harness"
  log "Removed nested harness folder: $TARGET/Personal-Agent-Harness"
fi

log "Harness rules installed into: $TARGET"
log "Harness source (keep for updates): $ROOT"
log "Update command: $ROOT/update.sh $TARGET"
log "Status command: $ROOT/bin/pah status $TARGET --harness-root $ROOT"
```

- [ ] **Step 2: Make executable**

```bash
chmod +x bootstrap.sh
```

- [ ] **Step 3: Commit**

```bash
git add bootstrap.sh
git commit -m "feat: add bootstrap.sh for external harness workflow"
```

---

## Task 3: Extend `gitignore` Managed Block

**Files:**
- Modify: `bin/pah` (`install_gitignore_block` heredoc, ~line 355)

- [ ] **Step 1: Write failing test** in `tests/test_pah.sh` after existing gitignore assertions (~line 145):

```bash
assert_contains "$SCAFFOLD/.gitignore" "Personal-Agent-Harness/"
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/gjwoo96/gw-personal/Personal-Agent-Harness
bash tests/test_pah.sh
```

Expected: FAIL — `Personal-Agent-Harness/` not in `.gitignore`

- [ ] **Step 3: Update gitignore block in `bin/pah`**

```bash
  block="$(cat <<'EOF'
# pah:managed:start
.env
.devcontainer/.env
.harness/backups/
Personal-Agent-Harness/
# pah:managed:end
EOF
)"
```

- [ ] **Step 4: Run tests**

```bash
bash tests/test_pah.sh
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add bin/pah tests/test_pah.sh
git commit -m "feat: ignore Personal-Agent-Harness/ in pah gitignore block"
```

---

## Task 4: Enhance `pah status`

**Files:**
- Modify: `bin/pah` (`usage`, `cmd_status`, argument parsing in `main`)

- [ ] **Step 1: Write failing tests** — append to `tests/test_pah.sh` before final success echo:

```bash
STATUS_TARGET="$TMP_ROOT/status-target"
mkdir -p "$STATUS_TARGET"
"$PAH" install "$STATUS_TARGET"

STATUS_LOG="$TMP_ROOT/status.log"
"$PAH" status "$STATUS_TARGET" > "$STATUS_LOG"
assert_contains "$STATUS_LOG" "harness_version:"
assert_contains "$STATUS_LOG" "0.2.0"

OLD_VERSION_ROOT="$TMP_ROOT/old-version-root"
cp -a "$ROOT" "$OLD_VERSION_ROOT"
printf '0.1.0\n' > "$OLD_VERSION_ROOT/VERSION"

STATUS_COMPARE_LOG="$TMP_ROOT/status-compare.log"
"$PAH" status "$STATUS_TARGET" --harness-root "$OLD_VERSION_ROOT" > "$STATUS_COMPARE_LOG"
assert_contains "$STATUS_COMPARE_LOG" "update available"
```

Note: bump `VERSION` to `0.3.0` in Task 6; until then test expects current `0.2.0` for installed version and uses a copied root with `0.1.0` for update-available path. After VERSION bump, change `assert_contains "$STATUS_LOG" "0.2.0"` to `"0.3.0"`.

- [ ] **Step 2: Run test to verify it fails**

```bash
bash tests/test_pah.sh
```

Expected: FAIL — status output lacks `harness_version:` / `update available`

- [ ] **Step 3: Implement `cmd_status` and CLI flags**

Update `usage()`:

```bash
  pah status <target> [--harness-root <path>]
```

Replace `cmd_status()`:

```bash
read_manifest_field() {
  local manifest="$1"
  local field="$2"
  python3 - "$manifest" "$field" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
print(data[sys.argv[2]])
PY
}

cmd_status() {
  local target=""
  local harness_root=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --harness-root)
        [ $# -ge 2 ] || die "status --harness-root requires a path"
        harness_root="$2"
        shift 2
        ;;
      *)
        if [ -z "$target" ]; then
          target="$1"
          shift
        else
          die "unexpected status argument: $1"
        fi
        ;;
    esac
  done

  [ -n "$target" ] || die "status requires target"
  target="$(cd "$target" && pwd -P)"
  ensure_target "$target"

  local manifest="$target/.harness/manifest.json"
  if [ ! -f "$manifest" ]; then
    log "Personal-Agent-Harness not installed: $target"
    return 0
  fi

  log "Personal-Agent-Harness installed: $target"
  log "Manifest: .harness/manifest.json"

  local installed_version
  installed_version="$(read_manifest_field "$manifest" "harness_version")"
  log "harness_version: $installed_version"

  if [ -d "$target/Personal-Agent-Harness/.git" ]; then
    log "WARNING: nested harness clone detected at $target/Personal-Agent-Harness"
    log "WARNING: recommended: $target/../.local/share/personal-agent-harness/bootstrap.sh $target --clean-nested"
  fi

  if [ -n "$harness_root" ]; then
    harness_root="$(cd "$harness_root" && pwd -P)"
    local remote_version_file="$harness_root/VERSION"
    [ -f "$remote_version_file" ] || die "harness VERSION file not found: $remote_version_file"
    local available_version
    available_version="$(tr -d '\n' < "$remote_version_file")"
    log "harness_root version: $available_version"
    if [ "$installed_version" != "$available_version" ]; then
      log "update available: installed $installed_version, harness_root $available_version"
      log "update command: $harness_root/update.sh $target"
    else
      log "up to date with harness_root"
    fi
  fi
}
```

Implementation note: if `python3` is undesirable, use `jq` when available and fall back to `grep/sed` on manifest — match existing project style (jq is optional elsewhere). Prefer `jq` first since docs already mention it:

```bash
installed_version="$(jq -r '.harness_version' "$manifest")"
```

- [ ] **Step 4: Run tests**

```bash
bash tests/test_pah.sh
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add bin/pah tests/test_pah.sh
git commit -m "feat: show harness_version and compare status with --harness-root"
```

---

## Task 5: External Workflow Smoke Tests

**Files:**
- Modify: `tests/test_pah.sh`

- [ ] **Step 1: Add external bootstrap test** after existing `SETUP_PROJECT` block (~line 158):

```bash
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

EXTERNAL_UPDATE_MARKER="pah-external-update-marker-$$"
echo "$EXTERNAL_UPDATE_MARKER" >> "$ROOT/standards/devcontainer/devcontainer-standards.md"
PAH_SKIP_PULL=1 "$ROOT/update.sh" "$EXTERNAL_PROJECT"
assert_contains "$EXTERNAL_PROJECT/docs/devcontainer/devcontainer-standards.md" "$EXTERNAL_UPDATE_MARKER"
"$PAH" verify "$EXTERNAL_PROJECT"
```

- [ ] **Step 2: Run tests**

```bash
bash tests/test_pah.sh
```

Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add tests/test_pah.sh
git commit -m "test: cover external bootstrap and clean-nested migration"
```

---

## Task 6: Version Bump

**Files:**
- Modify: `VERSION`
- Modify: `tests/test_pah.sh` (status test expected version `0.2.0` → `0.3.0`)

- [ ] **Step 1: Bump version**

```bash
printf '0.3.0\n' > VERSION
```

- [ ] **Step 2: Update status test expectation**

Change:

```bash
assert_contains "$STATUS_LOG" "0.2.0"
```

to:

```bash
assert_contains "$STATUS_LOG" "0.3.0"
```

- [ ] **Step 3: Run tests**

```bash
bash tests/test_pah.sh
```

Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add VERSION tests/test_pah.sh
git commit -m "chore: bump harness version to 0.3.0"
```

---

## Task 7: Documentation Updates

**Files:**
- Modify: `README.md`
- Modify: `docs/usage.md`
- Modify: `docs/how-it-works.md`
- Modify: `docs/reference.md`
- Modify: `docs/troubleshooting.md`
- Modify: `docs/development.md`

- [ ] **Step 1: Update README.md quick start**

Replace in-project clone example with:

```bash
git clone <your-repo-url> ~/.local/share/personal-agent-harness
~/.local/share/personal-agent-harness/bootstrap.sh .
```

Update section:

```bash
~/.local/share/personal-agent-harness/update.sh .
```

Add short "Legacy (in-project clone)" note pointing to `docs/usage.md#legacy-in-project-clone`.

- [ ] **Step 2: Update docs/usage.md**

Add sections:

1. **권장 워크플로우** — external PAH_HOME + bootstrap + update + status
2. **`Personal-Agent-Harness/` 폴더** — rewrite: 프로젝트 안에 두지 않음. manifest로 추적.
3. **Legacy in-project clone** — old command + migration:

```bash
~/.local/share/personal-agent-harness/bootstrap.sh . --clean-nested
```

4. **커밋 가이드** — `Personal-Agent-Harness/`는 커밋하지 않음. `gitignore` 컴포넌트 권장.

- [ ] **Step 3: Update docs/how-it-works.md**

Replace "폴더 유지" narrative with:

```text
하네스 소스는 PAH_HOME(프로젝트 밖)에 둡니다.
대상 프로젝트는 copy mode 산출물만 유지합니다.
```

Add diagram:

```text
PAH_HOME/.git  --bootstrap/update-->  target-project/.harness/manifest.json
                                      target-project/docs/...
```

Keep "아직 하지 않는 일" list; add note that in-project clone is legacy only.

- [ ] **Step 4: Update docs/reference.md**

Add `bootstrap.sh` to 진입점 table.

Document `pah status --harness-root`.

- [ ] **Step 5: Update docs/troubleshooting.md**

Add sections:

- **Nested harness / duplicate git repos** — detect `Personal-Agent-Harness/.git`, fix with `--clean-nested`
- **How to check for harness updates** — `pah status . --harness-root ~/.local/share/personal-agent-harness`

- [ ] **Step 6: Update docs/development.md**

Change manual demo (~line 87) from in-project clone to:

```bash
mkdir -p /tmp/pah-demo && cd /tmp/pah-demo && git init
/home/gjwoo96/gw-personal/Personal-Agent-Harness/bootstrap.sh .
```

Keep monorepo `harness-dev` section as-is (PAH inside monorepo for harness engineering is a separate case).

- [ ] **Step 7: Run full test suite**

```bash
bash tests/test_pah.sh
git diff --check
```

Expected: PASS, no whitespace errors

- [ ] **Step 8: Commit**

```bash
git add README.md docs/usage.md docs/how-it-works.md docs/reference.md docs/troubleshooting.md docs/development.md
git commit -m "docs: adopt external harness workflow as the default"
```

---

## Self-Review

| Spec requirement | Task |
|------------------|------|
| No nested harness in target by default | Task 2, 5, 7 |
| bootstrap entry point | Task 2 |
| Migration from in-project clone | Task 2 (`--clean-nested`), Task 7 |
| Installed version tracking | Existing manifest; Task 4 surfaces it |
| Update availability check | Task 4 (`--harness-root`) |
| gitignore safety net | Task 3 |
| Tests | Tasks 3–6 |
| Docs | Task 7 |

No TBD placeholders remain. `python3` dependency in status was replaced with `jq`/grep approach in implementation note — final code must not require python3.

## Verification Checklist (Manual)

After all tasks:

```bash
# 1) Full test suite
bash tests/test_pah.sh

# 2) Simulated new project
mkdir -p /tmp/pah-external-demo && cd /tmp/pah-external-demo && git init
/home/gjwoo96/gw-personal/Personal-Agent-Harness/bootstrap.sh .
test ! -d Personal-Agent-Harness
/home/gjwoo96/gw-personal/Personal-Agent-Harness/bin/pah verify .
/home/gjwoo96/gw-personal/Personal-Agent-Harness/bin/pah status . --harness-root /home/gjwoo96/gw-personal/Personal-Agent-Harness

# 3) Simulated migration
mkdir -p /tmp/pah-nested-demo && cd /tmp/pah-nested-demo && git init
git clone <local-path-or-skip> ... # or cp -a harness
# use cp -a for local test:
cp -a /home/gjwoo96/gw-personal/Personal-Agent-Harness /tmp/pah-nested-demo/Personal-Agent-Harness
/home/gjwoo96/gw-personal/Personal-Agent-Harness/bootstrap.sh /tmp/pah-nested-demo --clean-nested
test ! -d /tmp/pah-nested-demo/Personal-Agent-Harness
```

---

## Out of Scope (v1 — YAGNI)

- `curl | bash` 원격 bootstrap installer
- `pah status --check-remote` (git fetch against GitHub)
- submodule / symlink mode
- `setup.sh` / `update.sh` signature change
- CI workflow template for `pah verify` in target repos

These can be a follow-up plan if needed.
