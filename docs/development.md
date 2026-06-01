# 하네스 개발·테스트

> **관련 문서:** [문서 목록](README.md) · [규칙 도메인 추가](adding-rule-domains.md) · [CLI 레퍼런스](reference.md) · [README](../README.md)

`Personal-Agent-Harness` 저장소 자체를 수정·검증할 때 참고합니다.

## 저장소 구조

```text
Personal-Agent-Harness/
├── bin/pah              # 메인 CLI
├── setup.sh             # 대상 프로젝트 첫 적용
├── update.sh            # 대상 프로젝트 업데이트
├── install.sh           # pah install 래퍼
├── standards/           # 표준 문서 원본
├── templates/
│   ├── stubs/           # Cursor, AGENTS.md, CLAUDE.md 템플릿
│   └── devcontainer/    # 선택적 devcontainer 스캐폴드
├── docs/                # 사용자·개발 문서
└── tests/test_pah.sh    # smoke test
```

## 새 규칙 도메인 추가

devcontainer 다음의 규칙 도메인(git, testing 등)을 하네스에 추가할 때는 [adding-rule-domains.md](./adding-rule-domains.md)를 따릅니다. 해당 가이드는 **하네스 저장소 내부 전용**이며, 대상 프로젝트에는 배포되지 않습니다.

## AI 연결 활성화

하네스 개발용 AI rule은 대상 프로젝트용 devcontainer rule과 **겹치지 않도록** 분리되어 있습니다.

### monorepo란?

**monorepo**는 `gw-personal`처럼 **큰 프로젝트 폴더 하나**를 Cursor로 열고, 그 안에 `Personal-Agent-Harness/`가 **하위 폴더**로 들어 있는 경우를 말합니다.

이때 Cursor는 보통 **맨 바깥(부모 프로젝트 루트)** 의 `.cursor/rules/`만 읽습니다. PAH 저장소 안의 rule만으로는 monorepo에서 AI가 하네스 개발 가이드를 자동으로 읽지 못할 수 있습니다.

### 워크스페이스별 설정

| 워크스페이스 | 활성화 방법 |
|-------------|-------------|
| **PAH 단독 repo** | `.cursor/rules/harness-development.mdc`가 저장소에 포함됨 (**추가 작업 없음**) |
| **monorepo** (예: gw-personal) | 부모 프로젝트 루트에서 **한 번** 실행 (아래 참고) |

monorepo에서 한 번만 실행:

```bash
./Personal-Agent-Harness/bin/pah install . --components harness-dev
```

이 명령은 부모 프로젝트 루트에 `.cursor/rules/harness-development.mdc`를 설치합니다. `Personal-Agent-Harness/**` 파일을 편집할 때만 rule이 적용됩니다.

**`setup.sh` / `update.sh`와는 별개입니다.** `setup.sh`는 devcontainer 규칙(`rules`)만 설치하고, 하네스 개발용 rule(`harness-dev`)은 **포함하지 않습니다.**

### 언제 `harness-dev`를 다시 실행해야 하나?

| 상황 | 다시 실행 필요? |
|------|----------------|
| 평소 monorepo에서 계속 작업 | **아니오** (한 번만 하면 됨) |
| monorepo 전체를 **처음 clone** | **예** (루트에 rule 파일이 없음) |
| PC를 바꾸거나 monorepo 폴더를 통째로 다시 받음 | **예** |
| `Personal-Agent-Harness/` 폴더만 다시 clone | **아니오** (PAH 안 개발용 파일은 clone 시 함께 옴) |

monorepo에서 `harness-dev`로 설치한 rule 파일(`.cursor/rules/harness-development.mdc`)을 git에 커밋해 두면, 다른 PC에서 clone 후 **다시 install하지 않아도** 됩니다.

### 새 규칙 도메인 추가할 때

설정이 끝난 뒤에는 Cursor에서 `@Personal-Agent-Harness`를 붙이고 **「새 규칙 도메인 추가해줘」**라고 요청하면 됩니다. AI가 [adding-rule-domains.md](./adding-rule-domains.md) 절차를 따릅니다.

- `@Personal-Agent-Harness` — 하네스 저장소 작업임을 명확히
- 「규칙 도메인 추가」 — 대상 프로젝트에 devcontainer 적용하는 작업과 구분

작업이 끝나면 `bash Personal-Agent-Harness/tests/test_pah.sh`(monorepo) 또는 `bash tests/test_pah.sh`(PAH 단독 repo)로 확인합니다.

PAH 단독 repo에서는 Codex/Claude가 [../AGENTS.md](../AGENTS.md)를 읽습니다. 이 파일은 `pah install` 대상이 **아닙니다**.

## 테스트 실행

```bash
cd Personal-Agent-Harness
bash tests/test_pah.sh
```

테스트는 다음을 검증합니다.

- `pah install` / `verify` / `status`
- 기존 `AGENTS.md`와의 managed block 병합
- devcontainer + gitignore 컴포넌트
- `setup.sh` / `update.sh` (install + verify 경로)

## 변경 후 확인 순서

1. `bash tests/test_pah.sh`
2. 임시 프로젝트에서 수동 시나리오:

```bash
mkdir -p /tmp/pah-demo && cd /tmp/pah-demo
git clone <repo-url> Personal-Agent-Harness && ./Personal-Agent-Harness/setup.sh
./Personal-Agent-Harness/update.sh
```

## 이 저장소가 제공하는 것

- AI용 영문 단일 원본: `standards/devcontainer/devcontainer-standards.md`
- 사람용 한글 번역본: `standards/devcontainer/devcontainer-standards.ko.md`
- Cursor rule, Codex/Claude managed block 템플릿
- 선택적 `.devcontainer` 스캐폴드
- `pah` CLI 및 setup/update 진입점
