# 하네스 개발·테스트

> **관련 문서:** [문서 목록](README.md) · [규칙 도메인 추가](adding-rule-domains.md) · [CLI 레퍼런스](reference.md)

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
3. 임시 프로젝트에서 수동 시나리오 확인:

```bash
mkdir -p /tmp/pah-demo && cd /tmp/pah-demo && git init
/home/gjwoo96/gw-personal/Personal-Agent-Harness/bootstrap.sh .
/home/gjwoo96/gw-personal/Personal-Agent-Harness/update.sh .
```
