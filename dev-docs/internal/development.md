# 하네스 개발·테스트

> **관련 문서:** [개발 문서 목록](../README.md) · [규칙 도메인 추가](adding-rule-domains.md) · [CLI 레퍼런스](../../docs/reference.md)

## 저장소 구조

```text
Personal-Agent-Harness/
├── bin/pah
├── config/rule-domains.txt
├── standards/<domain>/
├── templates/
│   ├── stubs/agent-blocks/
│   ├── stubs/cursor/
│   ├── devcontainer/
│   └── harness-dev/
├── dev-docs/
├── docs/
└── tests/test_pah.sh
```

`config/rule-domains.txt`에 등록된 도메인은 순서대로 install, manifest, verify 대상이 됩니다. 새 도메인을 추가할 때는 [adding-rule-domains.md](adding-rule-domains.md)를 따릅니다.

## 별도 컴포넌트

devcontainer 스캐폴드, `.gitignore` managed block, monorepo용 `harness-dev` rule은 규칙 도메인 registry에 포함되지 않습니다.

## AI 연결 활성화

### monorepo란?

`gw-personal`처럼 큰 프로젝트 폴더 하나를 Cursor로 열고 그 안에 `Personal-Agent-Harness/`가 하위 폴더로 들어 있는 구성을 말합니다.

Cursor는 보통 부모 프로젝트 루트의 `.cursor/rules/`를 읽습니다. PAH 저장소 내부 rule만으로는 monorepo에서 하네스 개발 가이드가 자동 적용되지 않을 수 있습니다.

### 워크스페이스별 설정

| 워크스페이스 | 활성화 방법 |
|-------------|-------------|
| PAH 단독 repo | `.cursor/rules/harness-development.mdc`가 저장소에 포함됨 |
| monorepo | 부모 프로젝트 루트에서 아래 명령을 한 번 실행 |

```bash
./Personal-Agent-Harness/bin/pah install . --components harness-dev
```

이 명령은 `.cursor/rules/harness-development.mdc`를 설치합니다. 기본 `setup.sh`와 `update.sh`에는 포함되지 않습니다.

### 언제 다시 실행해야 하나?

| 상황 | 다시 실행 필요? |
|------|----------------|
| 같은 monorepo에서 계속 작업 | 아니오 |
| monorepo 전체를 처음 clone | 예 |
| PC를 바꾸거나 monorepo 폴더를 다시 받음 | 예 |
| `Personal-Agent-Harness/` 하위 폴더만 다시 clone | 아니오 |

설치한 `.cursor/rules/harness-development.mdc`를 부모 프로젝트에 커밋하면 다른 PC에서 clone한 뒤 다시 설치하지 않아도 됩니다.

### 새 규칙 도메인을 추가할 때

Cursor에서 `@Personal-Agent-Harness`를 붙이고 새 규칙 도메인 추가 작업임을 명확히 요청합니다. 대상 프로젝트에 규칙을 적용하는 작업과 구분하기 위해서입니다.

PAH 단독 repo에서는 Codex와 Claude가 저장소 루트의 `AGENTS.md`를 읽습니다. 이 파일은 대상 프로젝트 install에 포함되지 않습니다.

## 테스트 실행

```bash
cd Personal-Agent-Harness
bash tests/test_pah.sh
```

테스트는 다음을 검증합니다.

- registry 기반 `rules` install, verify, status
- devcontainer와 git-workflow 기본 설치
- `AGENTS.md`, `CLAUDE.md` managed block 병합
- 잘못된 registry와 AI stub 참조 거부
- optional devcontainer, gitignore, harness-dev 컴포넌트
- `setup.sh`, `update.sh`

## 변경 후 확인 순서

1. `bash tests/test_pah.sh`
2. `git diff --check`
3. 임시 프로젝트에서 로컬 CLI 시나리오 확인:

```bash
mkdir -p /tmp/pah-demo && cd /tmp/pah-demo && git init
<PAH_HOME>/bin/pah init .
<PAH_HOME>/bin/pah update .
```

4. 릴리스 태그를 push한 뒤 GitHub 패키지 시나리오 확인:

```bash
npx --yes github:gjwoo1996/Personal-Agent-Harness#vX.Y.Z init /tmp/pah-demo
npx --yes github:gjwoo1996/Personal-Agent-Harness#vX.Y.Z verify /tmp/pah-demo
npx --yes github:gjwoo1996/Personal-Agent-Harness#vX.Y.Z status /tmp/pah-demo
```

## Dev container (권장)

WSL에서 Windows npm(`/mnt/c/Program Files/nodejs/`)이 WSL 경로의 `package.json`을 읽지 못하는 경우가 있습니다. 하네스 저장소에는 **개발자 전용** `.devcontainer/`가 있습니다.

| 워크스페이스 | Dev container |
|-------------|---------------|
| `Personal-Agent-Harness/` 단독 열기 | **Reopen in Container** 사용 |
| monorepo (`gw-personal/`) 루트 | 감지 안 됨 — 이 폴더를 직접 열기 |

상세: [.devcontainer/README.md](../../.devcontainer/README.md)

컨테이너 안에서:

```bash
bash tests/test_pah.sh
npm pack           # 선택: package.json files 화이트리스트 검증
```

## Git 태그 릴리스

GitHub 저장소가 유일한 배포 채널입니다. npm registry에는 새 버전을 publish하지 않습니다.
`VERSION`, `package.json.version`, Git 태그 `vX.Y.Z`는 항상 같은 버전을 가리켜야 합니다.

```bash
cd ~/gw-personal/Personal-Agent-Harness

# 1) 변경 검증
bash tests/test_pah.sh
git diff --check
npm pack --dry-run  # 선택: files 화이트리스트 확인

# 2) VERSION과 package.json.version을 함께 올리고 동일한지 확인
PAH_VERSION="$(tr -d '\r\n' < VERSION)"
PACKAGE_VERSION="$(node -e 'process.stdout.write(require("./package.json").version)')"
test "$PAH_VERSION" = "$PACKAGE_VERSION"

# 3) 릴리스 변경을 커밋한 뒤 작업 트리가 깨끗한지 확인
git status --short
# 출력이 없어야 한다. 태그는 미커밋 변경을 포함하지 않는다.

# 4) 동일 버전의 annotated tag 생성
git tag -a "v${PAH_VERSION}" -m "Personal-Agent-Harness v${PAH_VERSION}"

# 5) 브랜치와 태그 push (명시적 사용자 승인 후)
git push origin <release-branch>
git push origin "v${PAH_VERSION}"

# 6) push한 태그를 직접 검증
npx --yes github:gjwoo1996/Personal-Agent-Harness#vX.Y.Z status /tmp/pah-demo
```

`#main`은 재현 가능한 릴리스 검증에 사용하지 않습니다. 대상 프로젝트도 가능한 한 `#vX.Y.Z`를 고정합니다.
기존 npm 버전과 같은 번호를 새 내용에 재사용하지 말고, 릴리스 커밋 전에 `VERSION`과 `package.json.version`을 함께 다음 버전으로 올립니다.
