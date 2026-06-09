# npm Transition Cleanup Implementation Plan

> **Status: CLOSED (2026-06-09, v0.3.1).** 모든 작업 완료. 아래는 이력 보존용 기록입니다.
>
> **최종 결과:**
> - 사용자용 문서(`troubleshooting`, `how-it-works`, `usage`, `reference`, `README`)를 npm/npx 우선으로 정리, git checkout은 개발·legacy 경로로 명시.
> - **래퍼 스크립트 정책(Task 4):** 하이브리드로 확정. `setup.sh`·`update.sh`·`bootstrap.sh`는 npm 패키지에 유지(`pah init/update`가 재사용). **`install.sh`는 저장소에서 삭제하고 패키지에서도 제외**(아래 "install.sh 최종 결정" 참고).
> - `package.json`의 `files` 최종값: `bin/pah`, `bin/pah-entry`, `bootstrap.sh`, `setup.sh`, `update.sh`, `VERSION`, `config/`, `standards/`, `templates/`.
>
> **install.sh 최종 결정:** 본문 Task 4의 Option A 예시에는 `install.sh`가 포함 파일로 남아 있으나, 이는 작성 시점 잔재입니다. **최종 상태에서 `install.sh`는 포함하지 않습니다.**

> **For agentic workers (이력):** REQUIRED SUB-SKILL: superpowers:subagent-driven-development 또는 superpowers:executing-plans. Steps use checkbox 구문으로 추적했습니다.

**Goal:** Make the npm/npx installation workflow the clear primary path, remove misleading git-clone-first guidance, and decide whether legacy shell wrappers remain part of the public npm package.

**Architecture:** Keep copy mode and the existing `pah` CLI behavior. First clean documentation so npm/npx is consistently primary and git checkout is explicitly development/legacy. Then make a small product decision on wrapper scripts: either document why they are shipped, or refactor `bin/pah` so npm can ship only the CLI and runtime assets.

**Tech Stack:** Bash CLI, npm package metadata, Markdown documentation, existing smoke test suite in `tests/test_pah.sh`.

---

## File Structure

- `docs/troubleshooting.md`: user-facing troubleshooting. Should use `npx personal-agent-harness...` as the default command shape.
- `docs/how-it-works.md`: conceptual architecture. Should describe npm package source first, with git checkout as a maintainer/development variant.
- `docs/usage.md`: already mostly correct; adjust wording around legacy checkout and advanced options.
- `README.md`: keep the short npm-first entry point; clarify legacy checkout is optional.
- `docs/reference.md`: keep CLI reference consistent with npm-first usage.
- `package.json`: decide whether legacy wrapper scripts stay in `"files"`.
- `bin/pah`: only modify if removing wrapper runtime dependency.
- `tests/test_pah.sh`: add or update assertions for whichever wrapper decision is chosen.

---

### Task 1: Make Troubleshooting npm-First

**Files:**
- Modify: `docs/troubleshooting.md`

- [x] **Step 1: Replace default verify and dry-run commands**

Change the opening command block from:

```bash
~/.local/share/personal-agent-harness/bin/pah verify .
~/.local/share/personal-agent-harness/bin/pah install . --dry-run
```

to:

```bash
npx personal-agent-harness verify .
npx personal-agent-harness install . --dry-run
```

- [x] **Step 2: Replace manifest repair command**

Change:

```bash
~/.local/share/personal-agent-harness/update.sh .
```

to:

```bash
npx personal-agent-harness@latest update .
```

- [x] **Step 3: Replace nested harness migration command**

Change:

```bash
~/.local/share/personal-agent-harness/bootstrap.sh . --clean-nested
```

to:

```bash
npx personal-agent-harness init . --clean-nested
```

- [x] **Step 4: Replace gitignore component command**

Change:

```bash
~/.local/share/personal-agent-harness/bin/pah install . --components gitignore
```

to:

```bash
npx personal-agent-harness install . --components gitignore
```

- [x] **Step 5: Replace update status guidance**

Change the "하네스 업데이트 확인" section so it says:

```markdown
## 하네스 업데이트 확인

설치된 manifest 버전과 현재 실행 중인 npm CLI 버전을 비교합니다.

```bash
npx personal-agent-harness@latest status .
```

`update available`이 표시되면 다음 명령을 실행합니다.

```bash
npx personal-agent-harness@latest update .
```
```

- [x] **Step 6: Move git checkout troubleshooting into a legacy subsection**

Keep `update.sh`/`git pull --ff-only` guidance, but under:

```markdown
## Legacy git checkout 사용 시
```

Explain that it applies only when the user intentionally cloned PAH outside the target project.

- [x] **Step 7: Verify docs no longer default to PAH_HOME**

Run:

```bash
rg -n "~/.local/share/personal-agent-harness|bootstrap.sh|update.sh|PAH_HOME" docs/troubleshooting.md
```

Expected: only the legacy git checkout subsection contains those terms.

---

### Task 2: Rewrite How-It-Works Around npm Package Distribution

**Files:**
- Modify: `docs/how-it-works.md`

- [x] **Step 1: Replace the copy-mode diagram source**

Change the source side from:

```text
PAH_HOME/  (예: ~/.local/share/personal-agent-harness)
```

to:

```text
npm package: personal-agent-harness
```

Use this updated flow:

```text
npm package: personal-agent-harness
  bin/pah
  config/rule-domains.txt
  standards/<domain>/
  templates/stubs/
        |
        | npx personal-agent-harness init/update/install <target>
        v
target-project/
  docs/<domain>/
  .cursor/rules/<domain>-standards.mdc
  AGENTS.md
  CLAUDE.md
  .harness/hooks/<domain>.hook.sh
  .claude/settings.json
  .harness/manifest.json
```

- [x] **Step 2: Update source-location wording**

Change wording that says the source lives in `PAH_HOME` to:

```markdown
npm/npx 사용 시 하네스 소스는 npm 캐시 또는 글로벌 설치 위치에 있고, 대상 프로젝트에는 copy mode 산출물만 남습니다. git checkout은 하네스 개발이나 npm 없이 쓰는 legacy 경로입니다.
```

- [x] **Step 3: Update the automatic update caveat**

Change:

```markdown
하네스 저장소 변경은 대상 프로젝트에 자동 반영되지 않습니다. `update.sh`를 실행해야 합니다.
```

to:

```markdown
새 npm 패키지 버전은 대상 프로젝트에 자동 반영되지 않습니다. `npx personal-agent-harness@latest update .`를 실행해야 합니다.
```

- [x] **Step 4: Replace optional component commands**

Change:

```bash
~/.local/share/personal-agent-harness/bin/pah install . --components rules,devcontainer,gitignore
~/.local/share/personal-agent-harness/bin/pah install . --components harness-dev
```

to:

```bash
npx personal-agent-harness install . --components rules,devcontainer,gitignore
npx personal-agent-harness install . --components harness-dev
```

- [x] **Step 5: Replace update flow**

Replace the git-push/git-pull/update.sh sequence with:

```text
1. 메인테이너가 새 npm 버전을 publish
2. 대상 프로젝트에서 npx personal-agent-harness@latest update .
3. CLI가 rules,hooks를 install한 뒤 verify 실행
4. 기존 관리 파일은 .harness/backups/<timestamp>/에 백업
```

- [x] **Step 6: Verify old flow is legacy-only**

Run:

```bash
rg -n "PAH_HOME|git pull|update.sh|bootstrap.sh|~/.local/share" docs/how-it-works.md
```

Expected: old terms appear only in a short legacy note, or not at all.

---

### Task 3: Tighten Usage and README Wording

**Files:**
- Modify: `README.md`
- Modify: `docs/usage.md`
- Modify: `docs/reference.md`

- [x] **Step 1: Keep README npm-first and mark checkout optional**

In `README.md`, keep the npm/npx section as primary. Change the `git checkout (하네스 개발·legacy)` heading or paragraph to make it explicit:

```markdown
## git checkout (선택: 하네스 개발·npm 없이 사용)
```

and:

```markdown
일반 대상 프로젝트에는 이 방식 대신 npm/npx를 사용합니다.
```

- [x] **Step 2: Clarify `docs/usage.md` legacy section**

In `docs/usage.md`, change the legacy checkout intro to:

```markdown
이 섹션은 하네스 자체를 수정하거나 npm 없이 써야 할 때만 사용합니다. 일반 대상 프로젝트 적용은 위의 npm/npx 워크플로우를 사용합니다.
```

- [x] **Step 3: Clarify advanced options wording**

In `docs/usage.md`, replace:

```markdown
기본 `setup.sh`와 `update.sh`는 `rules,hooks`를 설치합니다.
```

with:

```markdown
기본 `init`과 `update`는 `rules,hooks`를 설치합니다.
```

- [x] **Step 4: Adjust reference entry-point wording**

In `docs/reference.md`, change:

```markdown
git checkout 개발용: `bootstrap.sh`, `setup.sh`, `update.sh`, `bin/pah`
```

to:

```markdown
git checkout 개발·legacy용: `bootstrap.sh`, `setup.sh`, `update.sh`, `bin/pah`
```

- [x] **Step 5: Verify user-facing docs are npm-first**

Run:

```bash
rg -n "git clone|~/.local/share|setup.sh|update.sh|bootstrap.sh|PAH_HOME" README.md docs/usage.md docs/reference.md docs/how-it-works.md docs/troubleshooting.md
```

Expected: these terms appear only in explicitly labeled development or legacy sections.

---

### Task 4: Decide and Implement Wrapper Script Policy

**Files:**
- Option A Modify: `README.md`, `docs/reference.md`, `package.json` unchanged
- Option B Modify: `bin/pah`, `package.json`, `tests/test_pah.sh`

Choose exactly one option before editing.

## Option A: Keep Wrappers as Supported Legacy Runtime

- [x] **Step 1: Document why wrappers are shipped**

Add a short note to `docs/reference.md`:

```markdown
npm 패키지에는 `setup.sh`, `update.sh`, `bootstrap.sh`도 포함됩니다. 현재 `pah init/update`가 이 래퍼를 재사용하며, git checkout legacy 경로와 동일한 동작을 유지하기 위해 의도적으로 배포합니다. (`install.sh`는 최종적으로 제외했습니다.)
```

- [x] **Step 2: Add package-content assertion**

In `tests/test_pah.sh`, keep the existing npm package simulation and add:

```bash
assert_file "$NPM_ROOT/setup.sh"
assert_file "$NPM_ROOT/update.sh"
assert_file "$NPM_ROOT/bootstrap.sh"
# install.sh는 최종적으로 제외 — 포함 단언 없음
```

- [x] **Step 3: Run tests**

Run:

```bash
bash tests/test_pah.sh
```

Expected: `All pah tests passed`.

## Option B: Remove Wrapper Runtime Dependency From npm

- [x] **Step 1: Refactor `cmd_init` in `bin/pah`**

Replace:

```bash
"$ROOT/setup.sh" "$target"
```

with direct calls:

```bash
cmd_install "$target"
cmd_verify "$target"
```

- [x] **Step 2: Refactor `cmd_update` in `bin/pah`**

Replace:

```bash
PAH_SKIP_PULL=1 "$ROOT/update.sh" "$target"
```

with direct calls:

```bash
cmd_install "$target"
cmd_verify "$target"
```

- [x] **Step 3: Remove wrapper scripts from npm files**

In `package.json`, change:

```json
"files": [
  "bin/pah",
  "bin/pah-entry",
  "bootstrap.sh",
  "setup.sh",
  "update.sh",
  "install.sh",
  "VERSION",
  "config/",
  "standards/",
  "templates/"
]
```

to:

```json
"files": [
  "bin/pah",
  "bin/pah-entry",
  "VERSION",
  "config/",
  "standards/",
  "templates/"
]
```

- [x] **Step 4: Update npm package simulation test**

In `tests/test_pah.sh`, change:

```bash
cp -a "$ROOT/bootstrap.sh" "$ROOT/setup.sh" "$ROOT/update.sh" "$ROOT/install.sh" "$ROOT/VERSION" "$NPM_ROOT/"
```

to:

```bash
cp -a "$ROOT/VERSION" "$NPM_ROOT/"
```

Add:

```bash
assert_not_file "$NPM_ROOT/setup.sh"
assert_not_file "$NPM_ROOT/update.sh"
assert_not_file "$NPM_ROOT/bootstrap.sh"
assert_not_file "$NPM_ROOT/install.sh"
```

- [x] **Step 5: Keep git checkout wrapper tests**

Do not remove the earlier tests that copy the full repository and call `setup.sh`, `update.sh`, and `bootstrap.sh`. Those scripts still exist in the repo for development/legacy use.

- [x] **Step 6: Run tests**

Run:

```bash
bash tests/test_pah.sh
npm pack --dry-run
```

Expected:

```text
All pah tests passed
```

and `npm pack --dry-run` tarball contents do not include `setup.sh`, `update.sh`, `bootstrap.sh`, or `install.sh`.

---

### Task 5: Clean Repository-Only Planning Artifacts

**Files:**
- Review: `etc/`
- Review: `docs/superpowers/plans/`
- Review: `docs/superpowers/specs/`
- Review: `docs/superpowers/handoffs/`
- Do not modify: `secret/`

- [x] **Step 1: Confirm package excludes planning artifacts**

Run:

```bash
npm pack --dry-run
```

Expected: tarball contents do not include `etc/`, `docs/`, `secret/`, `.devcontainer/`, or `.cursor/`.

- [x] **Step 2: Decide what to keep in git**

Keep `etc/05-npm-배포-가이드.md` if it is useful maintainer documentation. Consider deleting or archiving old `docs/superpowers/plans/2026-06-09-external-harness-workflow.md` and matching spec once npm docs are corrected, because they describe the previous external-clone transition rather than the current npm-first state.

- [x] **Step 3: Verify secrets are ignored**

Run:

```bash
git check-ignore -v secret/npm_recovery_codes.txt .devcontainer/.env
git ls-files secret/npm_recovery_codes.txt .devcontainer/.env
```

Expected:

```text
.gitignore:1:secret/ secret/npm_recovery_codes.txt
.gitignore:2:.devcontainer/.env .devcontainer/.env
```

and `git ls-files` prints nothing for both files.

- [x] **Step 4: Do not commit local-only untracked AI/editor files unless intentionally wanted**

Check:

```bash
git status --short
```

Expected: review untracked files like `.cursor/rules/skill-usage-announcement.mdc` and devcontainer helper scripts before staging.

---

### Task 6: Final Verification

**Files:**
- Verify only

- [x] **Step 1: Run shell syntax checks**

Run:

```bash
bash -n bin/pah bin/pah-entry setup.sh update.sh bootstrap.sh tests/test_pah.sh
```

Expected: no output, exit code 0.

- [x] **Step 2: Run harness test suite**

Run:

```bash
bash tests/test_pah.sh
```

Expected:

```text
All pah tests passed
```

- [x] **Step 3: Inspect npm package contents**

Run:

```bash
npm pack --dry-run
```

Expected: tarball includes only intended runtime files. If Task 4 Option A was chosen, wrapper scripts are present. If Option B was chosen, wrapper scripts are absent.

- [x] **Step 4: Check formatting whitespace**

Run:

```bash
git diff --check
```

Expected: no whitespace errors.

- [x] **Step 5: Review remaining git clone references**

Run:

```bash
rg -n "git clone|~/.local/share|PAH_HOME|bootstrap.sh|setup.sh|update.sh" README.md docs/usage.md docs/reference.md docs/how-it-works.md docs/troubleshooting.md
```

Expected: every match is inside a section clearly labeled development, maintainer, or legacy.

---

## Recommended Path

Use Task 1, Task 2, Task 3, Task 4 Option A, Task 5, then Task 6.

Option A is the least risky because the current tests pass and `bin/pah` already depends on the wrapper scripts. Option B is cleaner for a minimal npm package, but it touches runtime code and should be treated as a small refactor rather than a documentation cleanup.
