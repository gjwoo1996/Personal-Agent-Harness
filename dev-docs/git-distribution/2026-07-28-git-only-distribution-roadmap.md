# Git 전용 배포 전환 로드맵 (C안)

> **For agentic workers:** 구현 시 `superpowers:subagent-driven-development` 또는 `superpowers:executing-plans`로 단계별 실행. 체크박스로 진행을 추적한다.
> **다른 세션:** 아래 [§0 핸드오프](#0-다른-세션-핸드오프--고정-결정)만 읽고 Phase를 순서대로 실행하면 된다. 사용자에게 채널·옵션을 다시 묻지 말 것(이미 고정됨).

**Goal:** npmjs.com registry 배포를 제거하고, GitHub 저장소를 유일한 배포 채널로 삼아 `npx github:…`와 git dependency로 `pah`를 쓰게 한다. 병행으로 SosDrug식 AI/git 데브컨테이너 영속화를 PAH에 반영한다.

**Architecture:** copy mode는 유지한다. `package.json`의 `name`/`bin`/`files`는 남겨 npm이 GitHub에서 패키지를 해석할 수 있게 한다. 바꾸는 것은 **배포 채널·문서·테스트·메인테이너 절차·데브컨테이너 영속화**이며, 규칙 설치 로직(`bin/pah` install/verify)의 핵심은 그대로 둔다.

**Tech Stack:** Bash CLI (`bin/pah`, `bin/pah-entry`), npm 메타데이터(registry 없이 GitHub 설치용), Markdown 문서, `tests/test_pah.sh`, Docker Compose named volumes

**결정일:** 2026-07-28
**결정:** C안 — registry 제거, GitHub 전용

---

## 0. 다른 세션 핸드오프 · 고정 결정

이 절이 **단일 진실 공급원**이다. 아래와 다른 “또는/선택/검토” 문구가 본문에 남아 있으면 **이 표를 따른다**.

### 0.1 세션 시작 시 붙여넣을 지시 (복사용)

```text
Personal-Agent-Harness 로드맵 실행:
dev-docs/git-distribution/2026-07-28-git-only-distribution-roadmap.md

- §0 고정 결정을 따르고, 사용자에게 배포 채널·Phase 5·템플릿 볼륨을 다시 묻지 말 것
- 기본 순서: Phase 0 → 1 → 2 → 4 → 3 → 5 → 6 → 7a → 7b
- 커밋은 사용자가 요청할 때만. 메시지는 AGENTS.md (한글 Conventional)
- SosDrug 디렉터리는 없어도 됨 (§12·§12.8만으로 구현)
- 명령 표기는 항상: npx --yes github:gjwoo1996/Personal-Agent-Harness …
  태그 고정: npx --yes github:gjwoo1996/Personal-Agent-Harness#vX.Y.Z …
```

### 0.2 고정 결정표

| ID | 항목 | 고정값 | 비고 |
|----|------|--------|------|
| D-C | 배포 채널 | **GitHub only (C안)** | npm registry publish 중단 |
| D-DIST | `PAH_DISTRIBUTION` | **`package`** | `npm`/`git` 쓰지 않음. registry·github·로컬 패키지 공통 |
| D-HINT | status/update 안내 명령 | `npx --yes github:gjwoo1996/Personal-Agent-Harness update <target>` | `PAH_DISTRIBUTION=package`일 때. 로컬 checkout만 `update.sh` |
| D-NPX | npx 표기 | **`npx --yes github:gjwoo1996/Personal-Agent-Harness`** | `#vX.Y.Z`로 핀. **`@tag` / `@latest` 쓰지 않음** (github: 프로토콜) |
| D-DEP | git dependency 문서화 | **한다** (선택 UX로 README에 짧은 절) | `#vX.Y.Z` 핀 권장 |
| D-P5 | npm registry 정리 | **D1 `npm deprecate`** | 메시지: `Use npx --yes github:gjwoo1996/Personal-Agent-Harness instead` |
| D-P5-AUTH | deprecate 실행 | npm 로그인된 환경에서 실행. 실패 시 문서에 “blocked: need npm login”만 남기고 Phase 5를 partial로 표시 | 사용자에게 옵션 재질문 금지 |
| D-VOL-T | 템플릿 compose 볼륨 | Cursor/Bun/gh **실제로 추가** (`${aiStateVolumePrefix}-…`) | host `.gitconfig`는 **주석 예시만** |
| D-VOL-M | 메인테이너 compose | Cursor/Bun/gh + host `.gitconfig:ro` **기본 ON** | §12.4 |
| D-GITAUTH | git auth 스크립트 | **`commands/ensure-git-auth.sh` 파일로 신설** | post-create에서 호출. 인라인 복붙 금지(유일 구현) |
| D-GSTACK | gstack hosts | `claude` + `codex` **유지** + **`cursor` 추가** | cursor 실패 시 WARN만 |
| D-SOS | SosDrug 트리 | **참고 전용, 필수 아님** | 경로가 없으면 §12만 보고 구현 |
| D-README | `.devcontainer/README.md` | **Phase 7a가 단일 담당** | 전체 실행 시 Phase 3은 README 미수정(dev-docs + post-create만). Phase 7 스킵 세션만 Phase 3이 publish 문구 삭제 |
| D-ORDER | 기본 실행 순서 | `0→1→2→4→3→5→6→7a→7b` | Phase 7만 할 때는 `7a→7b`만 |
| D-COMMIT | 커밋 | 사용자 요청 시에만 | `feat`/`fix`/`docs`/`refactor`/`test`/`chore` + 한글 요약 (AGENTS.md) |
| D-KO | `*.ko.md` | 표준 영문 변경 시 **한글본도 같은 PR/커밋 묶음에서 동기화** | AI 규칙 출처는 영문만 |

### 0.3 명령 치트시트 (문서·코드·로그에 이 형태만 사용)

```bash
# 일반
npx --yes github:gjwoo1996/Personal-Agent-Harness init .
npx --yes github:gjwoo1996/Personal-Agent-Harness update .
npx --yes github:gjwoo1996/Personal-Agent-Harness verify .
npx --yes github:gjwoo1996/Personal-Agent-Harness status .

# 태그 핀
npx --yes github:gjwoo1996/Personal-Agent-Harness#vX.Y.Z update .

# 로컬 개발 체크아웃
./bin/pah init /tmp/pah-demo
./bin/pah-entry init /tmp/pah-demo
bash tests/test_pah.sh
```

### 0.4 Phase 5 deprecate 명령 (고정)

```bash
npm deprecate personal-agent-harness@"*" "Use npx --yes github:gjwoo1996/Personal-Agent-Harness instead"
```

### 0.5 이미 반영된 것 (중복 작업 금지)

- [x] `dev-docs/git-distribution/` 폴더·본 로드맵 존재
- [x] `dev-docs/README.md`에 git-distribution 링크 있음
  → Phase 3의 “인덱스에 링크 추가”는 **확인만** 하고 없으면 추가

### 0.6 SosDrug 참고 경로 (없어도 됨)

| 환경 | 경로 |
|------|------|
| 이 monorepo에서 열 때 | `/home/gjwoo96/gw-personal/tmp/k8s.Kpanet.SosDrug.Web/.devcontainer/` |
| PAH만 clone | **없음 → 무시.** §12·§12.8 스펙으로 구현 |

---

## 1. 배경과 결정

### 현재

- 공개 npm 패키지 `personal-agent-harness` (예: `0.3.1`/`0.3.2`)에 publish됨
- 권장 UX: `npx personal-agent-harness init .`
- 소스는 GitHub `gjwoo1996/Personal-Agent-Harness`와 npm tarball 이중 채널

### 왜 C안인가

- 사용자는 사실상 본인뿐이라 publish(OTP·버전 bump) 비용이 이득보다 큼
- copy mode라 registry에 있든 GitHub에 있든 **대상 프로젝트 산출물은 동일**
- 채널을 하나로 줄이면 문서·테스트·개발 컨테이너 안내가 단순해짐

### C안의 정확한 의미

| 항목 | 처리 |
|------|------|
| `npm publish` / npmjs 최신 유지 | **중단** |
| `package.json`, `bin/`, `files` | **유지** (git/`npx github:`에 필요) |
| copy mode, registry 도메인, manifest | **유지** |
| `npx personal-agent-harness` (registry) | **비권장 → 문서에서 제거** |
| `npx github:gjwoo1996/Personal-Agent-Harness` | **권장** |
| 대상 `package.json` git dependency | **지원·문서화** (선택 UX) |
| 로컬 git checkout + `bin/pah` / `bootstrap.sh` | **개발·오프라인용으로 유지** |

### 권장 사용법 (전환 후)

§0.3 치트시트와 동일. 문서에 적을 때도 그 형태만 쓴다.

```bash
npx --yes github:gjwoo1996/Personal-Agent-Harness init .
npx --yes github:gjwoo1996/Personal-Agent-Harness update .
```

```json
{
  "devDependencies": {
    "personal-agent-harness": "github:gjwoo1996/Personal-Agent-Harness#vX.Y.Z"
  }
}
```

```bash
npx pah init .
npx pah update .
```

태그/`#commit`으로 고정한다. `#main`은 문서 예시에 쓰지 않는다.

---

## 2. 범위

### In scope

1. 사용자 문서(`README.md`, `docs/*`)를 GitHub 채널 우선으로 재작성
2. 개발 문서(`dev-docs/internal/development.md`, `dev-docs/etc/05-npm-배포-가이드.md`)를 “registry 중단 / 이력”으로 정리
3. 테스트: registry `npx` 가정 대신 GitHub/`pah-entry` git 설치 시나리오 반영
4. `PAH_DISTRIBUTION` 값·로그·status 문구를 git 배포에 맞게 정리
5. 이미 올라간 npm 패키지 처리 — **D1 deprecate 고정** (§0.2 D-P5)
6. `.devcontainer` 메인테이너 안내에서 `npm publish` 제거/축소
7. Phase 7 AI/git 데브컨테이너 영속화 (§12)

### Out of scope

- copy mode → symlink/submodule 전환
- 규칙 도메인 내용 변경
- private GitHub / private npm
- GitHub Actions 자동 릴리즈(원하면 후속)
- 이미 설치한 대상 프로젝트의 강제 마이그레이션 스크립트(문서 안내만)

### 명시적 비목표

- `package.json` 삭제
- Node/`npx` 자체를 버리는 것 (GitHub에서 받는 설치에도 npm 클라이언트가 필요)

---

## 3. 영향 파일 지도

| 경로 | 역할 | 전환 시 |
|------|------|---------|
| `package.json` | name, bin, files, repository | 유지. `repository`가 권위 소스임을 문서에 명시. publish 스크립트는 추가하지 않음 |
| `bin/pah-entry` | npm/git 설치 시 bin 진입점 | `export PAH_DISTRIBUTION=package` 로 **고정 변경** (§0.2 D-DIST) |
| `bin/pah` | CLI 본체 | `update_command_hint` / `cmd_status`: `package`이면 §0.3 github npx 안내, 그 외(미설정·로컬)면 `update.sh` |
| `README.md` | 첫 사용법 | GitHub `npx` / git dependency 우선 |
| `docs/usage.md`, `how-it-works.md`, `reference.md`, `troubleshooting.md` | 사용자 문서 | registry 명령 제거, git 채널 설명 |
| `docs/README.md` | 문서 인덱스 | 배포 채널 문구 갱신 |
| `tests/test_pah.sh` | smoke | `PAH_DISTRIBUTION=npm` 시뮬레이션을 git 패키지 레이아웃에 맞게 정리 |
| `dev-docs/internal/development.md` | 개발 절차 | publish 절 삭제 → push/tag + `npx github:` 검증 |
| `dev-docs/etc/05-npm-배포-가이드.md` | publish 가이드 | **이력/폐기** 표시 후 git 사용으로 링크 |
| `.devcontainer/README.md`, `post-create.sh` | 개발 컨테이너 | `npm publish` 안내 제거, `npm pack`은 선택적 로컬 검증용으로만 |
| `VERSION` / git tag | 버전 | npm dist-tag 대신 **git tag** (`vX.Y.Z`)를 릴리즈 단위로 |

---

## 4. 단계별 로드맵

### Phase 0 — 사전 확인 (반나절)

- [x] 현재 GitHub remote URL·기본 브랜치·최신 태그 확인
- [x] `npx --yes github:gjwoo1996/Personal-Agent-Harness --help` (또는 `init --help`)가 **현 상태**에서 되는지 스모크
- [x] 실패 시 원인 기록: `files` 화이트리스트, `bin` 경로, 기본 브랜치에 `package.json` 부재 등 (실패 없음)
- [x] npm에 올라간 버전 목록 확인: `npm view personal-agent-harness versions --json`
- [x] 이미 registry로 설치한 개인 프로젝트가 있으면 목록화 (검색 범위에서 발견되지 않음)

**완료 기준:** “지금 당장 `npx github:…`가 되는지 / 안 되면 막힌 지점”이 한 문단으로 적혀 있다.

**2026-07-28 실행 기록:** `origin`은 `https://github.com/gjwoo1996/Personal-Agent-Harness.git`, 원격 기본 브랜치는 `main`이다. 현재 Git 태그는 없고 `VERSION`은 `0.3.2`다. `npx --yes github:gjwoo1996/Personal-Agent-Harness init <tmp>`와 `verify <tmp>`가 실제로 성공했다. npm registry에는 `0.3.0`, `0.3.1`, `0.3.2`가 있으며, `/home/gjwoo96/gw-personal` 검색 범위에서는 기존 `.harness/manifest.json` 설치 프로젝트가 발견되지 않았다.

### Phase 1 — 배포 메타·CLI 정리 (작음)

- [x] `bin/pah-entry`: `export PAH_DISTRIBUTION=package` (§0.2 D-DIST)
- [x] `bin/pah`의 `update_command_hint`와 `cmd_status` 분기 교체:

```bash
# package (pah-entry / npx github / git dependency)
if [ "${PAH_DISTRIBUTION:-}" = "package" ]; then
  log "update command: npx --yes github:gjwoo1996/Personal-Agent-Harness update $target"
else
  # 로컬 git checkout에서 bin/pah를 직접 실행하는 경우
  log "update command: $ROOT/update.sh $target"
fi
```

`cmd_status`의 update available 분기도 동일 규칙. 기존 `= "npm"` 분기는 삭제.
- [x] `tests/test_pah.sh`: `PAH_DISTRIBUTION=npm` → `PAH_DISTRIBUTION=package`, 변수/주석명 `npm-package` → `package-layout` 등으로 정리. 실제 `npm pack` tarball을 풀어 `pah-entry`를 실행.
- [x] `package.json` description을 GitHub distribution 문구로 조정
  예: `"Personal dev standards and AI agent rules installer (copy mode, GitHub distribution)"`
- [x] **커밋 (요청 시):** `refactor: PAH_DISTRIBUTION을 package로 통일하고 github 업데이트 안내`

**완료 기준:** `bash tests/test_pah.sh` 통과. 로컬 `bin/pah-entry init /tmp/...` 동작. grep으로 `PAH_DISTRIBUTION=npm` 잔존 없음.

### Phase 2 — 사용자 문서 전환 (핵심 UX)

- [x] `README.md`: 권장 사용법을 §0.3 형태로 교체. git dependency 짧은 절 추가 (D-DEP).
- [x] 로컬 checkout/`bootstrap.sh`는 “하네스 개발·오프라인”으로 유지
- [x] `docs/usage.md`, `how-it-works.md`, `reference.md`, `troubleshooting.md`
  - `npx personal-agent-harness` / `@latest` → §0.3 `npx --yes github:…` 로 일괄 치환
  - “npm publish 후 update” → “git tag 푸시 후 `npx --yes github:…#vX.Y.Z update`”
  - WSL+Windows npm 절은 유지(클라이언트로 `npx github`에도 필요). publish 전용 절만 삭제
- [x] README에 registry 폐기 한 줄:
  “npmjs의 `personal-agent-harness`는 더 이상 갱신되지 않습니다. GitHub를 사용하세요.”
- [x] **커밋 (요청 시):** `docs: GitHub를 유일한 배포 채널로 안내`

**완료 기준:** 사용자 문서에 `npm publish` / `npx personal-agent-harness@latest`가 **권장 경로로** 남아 있지 않다. `@tag` github 표기 없음.

### Phase 3 — 개발 문서·컨테이너 문구

- [x] `dev-docs/internal/development.md`: publish 절차 삭제 →
  `git tag` + §0.3 `npx --yes github:…#vX.Y.Z` 스모크 + (선택) `npm pack`으로 `files` 검증
- [x] `dev-docs/etc/05-npm-배포-가이드.md` 상단에 **폐기(archived)** 배너 + 본 로드맵 링크
- [x] `dev-docs/etc/README.md` 갱신. `dev-docs/README.md` git-distribution 링크는 **이미 있음** → 확인만 (§0.5)
- [x] `.devcontainer/commands/post-create.sh`: `npm login`/`npm publish` echo 제거
- [x] `.devcontainer/README.md`:
  - **Phase 7a를 이 세션에서 할 예정이면 여기서 수정하지 말 것** (D-README)
  - Phase 7을 스킵하는 세션이면 publish/`npm login` 안내만 삭제
- [x] **커밋 (요청 시):** `docs: registry publish 절차 폐기 및 개발 가이드 정리`

**완료 기준:** 새 메인테이너가 development.md만 읽고도 publish 없이 릴리즈(태그) 방법을 알 수 있다.

### Phase 4 — 테스트 갱신

- [x] Phase 1에서 이름/`PAH_DISTRIBUTION`을 바꿨다면 여기서 동작 재확인
- [x] 패키지 레이아웃 시뮬이 `package.json`의 `files` 목록과 일치하는지 확인
- [x] `npx --yes github:…` 네트워크 테스트는 **수동** (테스트 스위트에 넣지 않음). Phase 0·6 체크리스트로 충분
- [x] **커밋 (요청 시):** `test: package 배포 레이아웃 smoke 정리` (Phase 1과 합쳐도 됨)

**완료 기준:** `bash tests/test_pah.sh` 전부 통과.

### Phase 5 — 기존 npm registry 정리 (**D1 고정**)

다른 옵션(D2/D3)은 선택하지 않는다.

- [x] `npm whoami`로 로그인 확인. 실패 시: 로드맵/05 문서에 `Phase 5 blocked: npm login required` 한 줄 남기고 나머지 Phase는 계속 (D-P5-AUTH)
- [ ] 로그인 OK면 §0.4 명령 실행
- [x] `dev-docs/etc/05-npm-배포-가이드.md` 또는 본 로드맵에 deprecate 실행/blocked 일자 기록
- [x] `secret/` recovery codes는 삭제하지 않음
- [x] 커밋 보통 없음 (registry 측). 문서 기록이 있으면 `docs: npm deprecate 완료 기록`

**완료 기준:** deprecate 성공이거나, 문서에 blocked 사유가 명시됨. 사용자에게 D2/D3를 묻지 말 것.

**Phase 5 blocked (2026-07-28): npm login required.** `npm whoami`가 `ENEEDAUTH`로 실패했으므로 registry deprecate는 실행하지 않았다. 로그인된 환경에서 §0.4 명령을 실행해야 한다.

### Phase 6 — 릴리즈 습관 정착

- [x] 버전 규칙: `VERSION` + `package.json.version` + git tag `vX.Y.Z`를 동일하게 맞추도록 문서화·테스트
- [x] 태그 전 릴리스 변경 커밋·clean worktree 확인과 기존 npm 버전 번호 재사용 금지를 문서화
- [x] 변경 후 검증 순서 (development.md에 반영):

```bash
bash tests/test_pah.sh
git diff --check
# tag 푸시 후
npx --yes github:gjwoo1996/Personal-Agent-Harness#vX.Y.Z status /tmp/some-target
```

- [ ] (선택) 셸 alias:

```bash
alias pah='npx --yes github:gjwoo1996/Personal-Agent-Harness'
```

**완료 기준:** “코드 수정 → 테스트 → 태그 → `npx github:…#tag`로 확인”이 한 페이지에 있다.

**릴리스 버전 결정 필요:** 현재 `VERSION`과 `package.json.version`은 `0.3.2`이고 npm에도 `0.3.2`가 이미 존재한다. 이번 Git 전용 배포 변경을 담은 태그는 릴리스 커밋 시 두 파일을 함께 다음 버전으로 올려야 하며, 사용자 요청 없이 버전 변경·커밋·태그 생성은 하지 않는다.

---

## 5. 마이그레이션 (이미 registry로 깐 프로젝트)

대상 프로젝트에는 harness 소스가 없고 copy 산출물만 있다. 재설치만 하면 된다.

```bash
cd /path/to/project
npx --yes github:gjwoo1996/Personal-Agent-Harness update .
npx --yes github:gjwoo1996/Personal-Agent-Harness verify .
npx --yes github:gjwoo1996/Personal-Agent-Harness status .
```

- `.harness/manifest.json`의 `harness_version`은 새 CLI의 `VERSION`과 맞춰진다
- managed block 밖 사용자 문구는 기존과 같이 보존
- git dependency로 바꾸려면 프로젝트 `package.json`에 `github:gjwoo1996/Personal-Agent-Harness#v…`를 추가한 뒤 `npm i` → `npx pah update .`

---

## 6. 리스크와 완화

| 리스크 | 완화 |
|--------|------|
| `npx github:…`가 기본 브랜치/파일을 못 찾음 | Phase 0에서 검증. `package.json`이 루트에 있어야 함 |
| `#main` 유동성으로 재현 불가 | 문서에서 **태그 고정** 권장 |
| 옛 npm 사용자가 오래된 0.3.x를 계속 씀 | Phase 5 deprecate |
| WSL에서 Windows npm이 `npx github`도 실패 | 기존과 같이 Linux npm/devcontainer 안내 유지 |
| `files` 화이트리스트 때문에 git 설치 시 문서가 빠짐 | 의도됨(런타임만). 사용법은 GitHub README |

---

## 7. 성공 기준 (전체)

### Git 전용 배포 (Phase 0–6)

1. 권장 경로가 GitHub뿐이며, 사용자 문서에 registry publish가 없다
2. `npx --yes github:gjwoo1996/Personal-Agent-Harness init .`로 새 프로젝트에 rules+hooks 설치·verify 성공
3. git dependency로 `npx pah` 실행 가능(README에 문서화)
4. `bash tests/test_pah.sh` 통과
5. 메인테이너가 `npm publish` 없이 태그로 배포할 수 있다

### AI 데브컨테이너 (Phase 7)

6. Rebuild 후에도 Cursor skills/plugins·Bun·gh 인증이 named volume으로 유지된다
7. `post-start`마다 `.cursor` 및 AI 볼륨 권한 보정이 idempotent하게 돈다
8. gstack가 Cursor host(`--host cursor`)와 기존 Claude/Codex 설정을 모두 지원한다
9. Claude Feature·버전 핀·방화벽·copy mode 표준은 퇴행하지 않는다
10. `standards/devcontainer`과 `templates/devcontainer`에 Cursor/Bun/gh 볼륨이 **실제로** 반영된다 (D-VOL-T)
11. 메인테이너 컨테이너에서 host gitconfig(ro) + gh volume + XDG credential helper로 GitHub HTTPS git이 동작한다

---

## 8. 롤백

- 문서·코드 커밋은 git revert로 되돌림
- registry deprecate는 메시지를 완화하거나 재publish로 복구 가능(정책 확인)
- copy mode 산출물은 채널과 무관하므로 대상 프로젝트 데이터 손실 없음

---

## 9. 제안 구현 순서 (한눈에)

**기본 전체 실행 (D-ORDER):**

```text
Phase 0 → 1 → 2 → 4 → 3 → 5 → 6 → 7a → 7b
```

```text
Phase 0  스모크(npx github) · npm 잔존 버전 파악
   ↓
Phase 1  PAH_DISTRIBUTION=package / status 문구
   ↓
Phase 2  README + docs/*  (사용자 UX)
   ↓
Phase 4  tests/test_pah.sh
   ↓
Phase 3  dev-docs + post-create (README는 7a에 맡김)
   ↓
Phase 5  npm deprecate (D1)
   ↓
Phase 6  태그 기반 릴리즈 습관 고정
   ↓
Phase 7a 메인테이너 .devcontainer (볼륨·git auth·README)
   ↓
Phase 7b 표준 + templates/devcontainer
```

Phase 7만: `7a → 7b`. SosDrug 클론 불필요.

---

## 10. 관련 문서

| 문서 | 관계 |
|------|------|
| [../etc/02-논의-및-결정.md](../etc/02-논의-및-결정.md) | 과거 npm 채택 결정 (이번 C안이 이를 뒤집음) |
| [../etc/05-npm-배포-가이드.md](../etc/05-npm-배포-가이드.md) | publish 절차 → 폐기 예정 |
| [../internal/development.md](../internal/development.md) | 개발·테스트 → Phase 3에서 수정 |
| [../../docs/how-it-works.md](../../docs/how-it-works.md) | copy mode 설명 → 배포 채널 문단만 교체 |
| [../../.devcontainer/README.md](../../.devcontainer/README.md) | 메인테이너 AI 볼륨·스킬 → Phase 7 갱신 |
| [../../standards/devcontainer/devcontainer-standards.md](../../standards/devcontainer/devcontainer-standards.md) | AI state/skill 원칙 → Phase 7b |
| 참고(외부, 선택): monorepo의 `tmp/k8s.Kpanet.SosDrug.Web/.devcontainer/` | 없어도 §12로 구현 (§0.6) |

---

## 11. 다음 액션

고정 기본값: **전체 실행** = §0.2 D-ORDER (`0→1→2→4→3→5→6→7a→7b`).

사용자 지시가 `Phase 7만`이면 `7a→7b`만. 그 외에는 배포 채널·deprecate 옵션을 **다시 묻지 말고** §0을 따른다.

---

## 12. 병행 트랙: AI 데브컨테이너 개선 (SosDrug 패턴)

### 12.1 비교 대상

| 구분 | 경로 |
|------|------|
| 참고 프로젝트 | `tmp/k8s.Kpanet.SosDrug.Web/.devcontainer/` (`docker-compose.yml`, `post-create.sh`, `post-start.sh`, `fix-cursor-permissions.sh`, `Dockerfile`) |
| PAH 메인테이너 | `.devcontainer/` (`docker-compose.dev.yml`, `ensure-ai-skills.sh`, `ensure-ai-volume-permissions.sh`, …) |
| PAH 배포 템플릿 | `templates/devcontainer/` |

### 12.2 판단 요약

**SosDrug가 더 나은 점 (PAH에 가져올 가치):**

| 패턴 | SosDrug | PAH 현재 | 판정 |
|------|---------|----------|------|
| Cursor skills/plugins named volume | `~/.cursor/skills`, `~/.cursor/plugins` | 없음 → Rebuild 시 Cursor 마켓/스킬 유실 | **채택** |
| Bun home named volume | `~/.bun` | 런타임 설치, 볼륨 없음 → 매 Rebuild 재설치 | **채택** |
| gh config named volume | `~/.config/gh` | 없음 → `gh auth` Rebuild마다 재로그인 | **채택** |
| `.cursor` 권한 보정 | `fix-cursor-permissions.sh`를 create+**start마다** | Claude/Codex만 `ensure-ai-volume-permissions` | **채택** (기존 스크립트에 통합) |
| Dockerfile에서 AI 디렉터리 pre-chown | `.codex`/`.cursor` 사전 생성 | Codex만 이미지에 설치, `.cursor` 미준비 | **채택** |
| gstack `--host cursor` | Cursor 스킬 경로에 설치 | Claude+Codex만 (`bun run setup --host claude/codex`) | **채택** (기존 host 유지 + cursor 추가) |
| 컨테이너 내부 git 인증 (identity / gh / credential helper) | host gitconfig ro + gh volume + XDG helper | `safe.directory`만 | **채택** (D-VOL-M / D-GITAUTH) |

**PAH가 이미 더 나은 점 (퇴행 금지):**

- Claude Code Feature + `.claude` / `.ai-state/claude` 볼륨 + `.claude.json` 심볼릭 링크
- `CODEX_CLI_VERSION` / `versions.env` 핀, idempotent `ensure-ai-skills.sh`
- `post-start`에서 스킬 수리 후 firewall
- 프로젝트 slug prefix 볼륨 이름 (`pah-*`, `${aiStateVolumePrefix}-*`)
- 배포 템플릿은 스킬 **자동 설치 opt-in** (표준 원칙)

**가져오지 않는 것 (SosDrug 전용/비목표):**

- Playwright / `npm ci` / 앱 포트 (대상 앱 의존)
- Claude 없는 단순 Dockerfile
- 버전 핀 없는 `npm install -g @openai/codex`
- 특정 gstack fork URL (`MFS-code/gstack`) — PAH는 `versions.env`의 `GSTACK_REPO` 유지

### 12.3 적용 원칙

1. **메인테이너 `.devcontainer/`를 참조 구현으로 먼저 올린다** (Phase 7a).
2. **표준 + 템플릿:** Cursor/Bun/gh 볼륨은 **실제 추가** (D-VOL-T). host gitconfig는 주석. 스킬 자동 설치는 템플릿에 넣지 않음.
3. SosDrug 파일을 복사하지 말고 `ensure-ai-*.sh` / `ensure-git-auth.sh`에 통합 (D-SOS: 원본 트리 없어도 됨).
4. 볼륨 이름: `pah-…` (메인테이너) / `${aiStateVolumePrefix}-…` (템플릿).

### 12.4 Phase 7a — 메인테이너 `.devcontainer/` (우선)

**목표:** Rebuild해도 Cursor·Bun·gh·gstack(Cursor) 상태가 살아 있고, 권한 깨짐이 start마다 수리되며, **컨테이너 안에서 GitHub HTTPS git이 `gh` 로그인으로 동작**한다.

- [x] **`docker-compose.dev.yml` 볼륨 추가**

```yaml
# volumes: 섹션에도 동일 이름 선언
volumes:
  pah-claude-config:
  pah-claude-json:
  pah-codex-config:
  pah-cursor-skills:
  pah-cursor-plugins:
  pah-bun-home:
  pah-gh-config:
```

서비스 volume 목록:

```yaml
# 기존 pah-claude-config / pah-claude-json / pah-codex-config 유지
- pah-cursor-skills:/home/vscode/.cursor/skills
- pah-cursor-plugins:/home/vscode/.cursor/plugins
- pah-bun-home:/home/vscode/.bun
- pah-gh-config:/home/vscode/.config/gh
- ${HOME}/.gitconfig:/home/vscode/.gitconfig:ro
```

호스트에 `~/.gitconfig`가 없으면 compose가 실패할 수 있다. README에 “호스트에 gitconfig 필요(최소 user.name/email)”를 적고, 없으면 사용자가 호스트에서 `git config --global user.name` 등으로 생성하게 한다. 에이전트가 optional bind로 바꾸지 말 것(D-VOL-M).

- [x] **`ensure-ai-volume-permissions.sh` 확장**
  대상에 추가: `${HOME}/.cursor`, `${HOME}/.bun`, `${HOME}/.config/gh`
  (디렉터리 없으면 `mkdir -p` 후 소유자 보정; SosDrug의 `fix-cursor-permissions.sh`와 동일 역할, 파일은 하나로 유지)

- [x] **`post-start.sh`**
  스킬 설치 전에 **항상** 권한 스크립트 실행 (지금은 `ensure-ai-skills` 안에서만 호출). 권한 실패는 fail-fast 유지.

- [x] **`Dockerfile`**
  `USER root`에서 `/home/vscode/.codex`, `/home/vscode/.cursor/skills`, `/home/vscode/.cursor/plugins` 생성 + `chown vscode` (볼륨 마운트 전 부모 경로 준비).

- [x] **`ensure-ai-skills.sh` — gstack**
  기존 `bun run setup --host claude` / `--host codex` 유지.
  추가: `bun run setup --host cursor` (실패 시 WARN, 전체 중단 없음).
  Bun은 named volume에 설치되므로 `BUN_VERSION` 핀 검사는 유지.

- [x] **컨테이너 git 인증** — §12.8. `commands/ensure-git-auth.sh` **파일로** 추가 (D-GITAUTH). post-create에서 호출.

- [x] **`.devcontainer/README.md` (이 Phase가 단일 담당, D-README)**
  볼륨 표(cursor/bun/gh/gitconfig), reset one-liner(모든 `pah-*` 볼륨), git 인증 절, publish/`npm login` 안내 **삭제**, `npm pack`은 선택 검증으로만.

- [x] **수동 검증**

```bash
ls -la ~/.cursor/skills ~/.cursor/plugins ~/.bun ~/.config/gh
bash .devcontainer/commands/ensure-ai-volume-permissions.sh
bash .devcontainer/commands/ensure-ai-skills.sh
gh auth status
git config --file "$HOME/.config/git/config" --get credential.https://github.com.helper
# gh 로그인 후:
# git ls-remote https://github.com/gjwoo1996/Personal-Agent-Harness.git HEAD
```

추가로 §12.8 완료 기준 1–5를 확인한다.

**2026-07-28 검증 기록:** Dev Container CLI 이미지 빌드와 실제 `post-create`/`post-start` 실행이 성공했다. 7개 named volume 경로의 `vscode` 소유권, Bun `1.2.17` 재사용, XDG github/gist helper, host identity, `safe.directory` 멱등성, host `.gitconfig` 해시 불변, firewall 초기화를 확인했다. 재빌드한 이미지의 실제 `bash -lc`에서도 `/home/vscode/.bun/bin/bun`과 `1.2.17`을 확인했다. 호스트의 기존 `gh` 토큰을 stdout에 노출하지 않고 stdin으로 `pah-gh-config`에 등록한 뒤 컨테이너를 새로 생성했고, 새 컨테이너에서 `gh auth status`, HTTPS `git ls-remote https://github.com/gjwoo1996/Personal-Agent-Harness.git HEAD`, github/gist helper, host identity, `safe.directory` 1개, host `.gitconfig` 해시 불변을 다시 확인했다. 인증 후에도 현재 `GSTACK_REPO=https://github.com/briangwaltney/gstack.git`는 GitHub에서 `Repository not found`를 반환한다. 로드맵의 D-GSTACK/D-VOL-M 결정에 따라 특정 fork로 공급원을 임의 전환하지 않고 WARN 후 lifecycle을 계속하는 동작을 유지한다.

- [x] **커밋 (요청 시):**
  - `feat: 데브컨테이너에 Cursor/Bun/gh AI 상태 볼륨 영속화`
  - `feat: 데브컨테이너 git identity·gh credential helper 연결`
  (한 커밋으로 합쳐도 됨)

**완료 기준:** 볼륨을 지우지 않은 Rebuild에서 Cursor plugins·Bun·gh auth가 유지되고, `ensure-ai-skills.sh`가 기존처럼 통과하며, `gh auth login` 이후 컨테이너에서 GitHub HTTPS `git` 원격 접근이 된다.

### 12.5 Phase 7b — 표준 + `templates/devcontainer/`

**목표:** 배포 템플릿에 Cursor/Bun/gh 영속화 볼륨을 **기본 포함**하고, git auth helper 스크립트와 문서를 제공한다. 스킬 자동 설치는 넣지 않는다.

- [x] **`standards/devcontainer/devcontainer-standards.md` + `.ko.md` 동기화 (D-KO)**
  볼륨: `{slug}-cursor-skills|plugins`, `{slug}-bun-home`, `{slug}-gh-config`
  Git auth 절: identity / gh volume / XDG helper (Personal WSL). SSH·공유 머신은 비기본.

- [x] **`templates/devcontainer/docker-compose.dev.yml` (D-VOL-T)**
  다음을 **주석이 아니라 실제 volumes로 추가**:

```yaml
- ${aiStateVolumePrefix}-cursor-skills:/home/vscode/.cursor/skills
- ${aiStateVolumePrefix}-cursor-plugins:/home/vscode/.cursor/plugins
- ${aiStateVolumePrefix}-bun-home:/home/vscode/.bun
- ${aiStateVolumePrefix}-gh-config:/home/vscode/.config/gh
# optional identity (개인 WSL). 팀/CI 기본에서는 주석 유지:
# - ${HOME}/.gitconfig:/home/vscode/.gitconfig:ro
```

  `volumes:` 맵에도 동일 prefix 이름 선언.

- [x] **`templates/devcontainer/commands/ensure-ai-volume-permissions.sh`**
  메인테이너 스크립트와 같은 대상(claude/ai-state/codex/cursor/bun/gh).
- [x] **`templates/devcontainer/commands/ensure-git-auth.sh`**
  §12.8과 동일 내용 (D-GITAUTH).
- [x] **`post-create.sh`**: permissions + ensure-git-auth 호출 (기존 claude.json 링크 유지).
- [x] **`post-start.sh`**: permissions 호출.
- [x] **`ensure-ai-skills.sh`는 템플릿에 넣지 않음.** README에 메인테이너 경로 참조.
- [x] **Dockerfile**: `.cursor` pre-create/chown.
- [x] **README**: 볼륨·reset·git auth·SSH out of scope. host gitconfig long-bind 주석 해제 방법.
- [x] **커밋 (요청 시):** `feat: 데브컨테이너 템플릿에 Cursor/Bun/gh 영속화·git auth 반영`

**완료 기준:** 템플릿 compose에 cursor/bun/gh 볼륨이 실제 존재하고, 표준 영문+한글이 동기화되어 있다.

**2026-07-28 구현 정정:** Compose 파일의 host gitconfig bind는 `${HOME}`을 사용한다. `${localEnv:HOME}`은 `devcontainer.json` 치환 문법이며 Docker Compose YAML에서는 `invalid interpolation format`으로 실패한다. short bind가 누락된 호스트 파일을 디렉터리로 만들지 않도록 long bind의 `create_host_path: false`를 사용한다. 템플릿 `devcontainer.json`은 `postStartCommand`를 명시해 권한 보정 스크립트를 실제로 연결한다. host `.gitconfig:ro` 기본 ON/템플릿 주석 예시라는 D-VOL-M/D-VOL-T 결정은 그대로 유지한다.

**2026-07-28 템플릿 E2E 기록:** 새 임시 프로젝트에 `rules,devcontainer,gitignore`를 설치하고 `devcontainer up`을 실행해 `initializeCommand` → 이미지 빌드 → `postCreateCommand` → `postStartCommand` 전체 lifecycle 성공을 확인했다. 컨테이너 제거·재생성 전후에 Cursor skills/plugins, Bun, gh 네 named volume의 마커가 모두 유지됐고 경로 소유권은 `vscode:vscode`, XDG GitHub helper는 `!gh auth git-credential`이었다. `devcontainer build` 단독 명령은 lifecycle 초기화를 실행하지 않아 생성 전 `.env`가 없으면 실패하므로, 템플릿 README의 직접 Compose 검증 절차에는 `initializeCommand.sh` 선행 실행을 명시했다. 실제 `gh auth` 토큰 영속성은 민감한 호스트 토큰을 자동 복사하지 않았으므로 여전히 로그인 후 확인이 필요하다.

### 12.6 Phase 7 리스크

| 리스크 | 완화 |
|--------|------|
| 볼륨이 늘어 Rebuild/reset 절차가 복잡해짐 | README에 reset one-liner로 모든 `pah-*` 볼륨 나열 |
| `.cursor` 전체를 볼륨 마운트하면 IDE 설정 충돌 | **skills/plugins 하위만** 마운트 (SosDrug와 동일) |
| 템플릿에 볼륨만 있고 스킬 미설치 → “빈 볼륨” 오해 | README에 “볼륨=영속화, 스킬 설치는 opt-in/ensure-ai-skills 참조” |
| host gitconfig ro가 CI/공유 환경에서 깨짐 | **메인테이너만 기본 ON.** 템플릿 compose는 주석 예시 |
| host에 `.gitconfig` 없으면 컨테이너 기동 실패 | README에 호스트 gitconfig 필수 안내. **optional bind로 바꾸지 않음** (D-VOL-M) |
| SSH remote 사용자 | HTTPS+gh만 범위. SSH는 `~/.ssh` 마운트를 후속/예외로 |
| XDG `~/.config/git/config`가 비영속 | post-create마다 idempotent 재기록. **이번 로드맵에서 별도 git-config 볼륨은 만들지 않음** |

### 12.7 Phase 7 롤백

- compose 볼륨 줄·스크립트 확장은 git revert
- 이미 만든 Docker 볼륨은 `docker volume rm pah-cursor-skills …`로 정리 (데이터 삭제임)

### 12.8 컨테이너 git 인증 (SosDrug 패턴)

SosDrug 패턴을 PAH에 이식하는 상세 스펙이다. 원본 트리는 §0.6 — **없어도 이 절만으로 구현한다.**

#### 역할 분리

```text
호스트 ~/.gitconfig  ──(ro bind)──► 컨테이너 ~/.gitconfig
                                    user.name / user.email (identity)

named volume         ─────────────► ~/.config/gh
                                    gh auth 토큰 (Rebuild 생존)

XDG (매 create 기록) ─────────────► ~/.config/git/config
                                    credential.https://github.com.helper
                                    = !gh auth git-credential
```

host gitconfig가 **읽기 전용**이라 `gh auth setup-git`(host 파일에 helper를 씀)이 실패한다. 그래서 SosDrug처럼 **XDG 전역 설정**에 helper를 심어 `setup-git`을 대체한다.

#### Phase 7a 체크리스트 (메인테이너 — 기본 활성화)

- [x] compose: host `.gitconfig:ro` + `pah-gh-config` (§12.4)
- [x] **`commands/ensure-git-auth.sh` 신설** (아래 본문 그대로, D-GITAUTH):

```bash
#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$HOME/.config/git"
git config --file "$HOME/.config/git/config" \
  credential.https://github.com.helper '!gh auth git-credential'
git config --file "$HOME/.config/git/config" \
  credential.https://gist.github.com.helper '!gh auth git-credential'
```

- [x] `post-create.sh`: XDG `safe.directory` 이후 `ensure-git-auth.sh` 호출 (+ permissions)
- [x] README: `gh auth login` → status → HTTPS git. 한계·공유 머신 주의

#### Phase 7b (템플릿·표준)

- [x] 표준에 Personal WSL git auth 패턴 추가 (영문+ko, D-KO)
- [x] 템플릿: `ensure-git-auth.sh` **반드시 포함**, host gitconfig bind는 **주석만** (D-VOL-T)
- [x] 템플릿 README에 주석 해제 3줄 예시

#### 비범위

- SSH agent / `~/.ssh` 마운트
- GitLab·기타 호스트 credential
- host에 git credential을 다시 쓰는 방식 (`gh auth setup-git`에 의존)

#### 완료 기준 (git auth만)

1. 컨테이너에서 `git config --global --get user.name`이 호스트 identity를 반영한다 (bind ON일 때)
2. `~/.config/git/config`에 github/gist helper가 있다
3. `gh auth login` 후 HTTPS로 private/public 원격 읽기가 된다
4. Rebuild 후 `gh auth status`가 유지된다 (`pah-gh-config`)
5. host `~/.gitconfig` 내용이 컨테이너 작업으로 변경되지 않는다 (ro)
