# 사용 가이드

> **관련 문서:** [문서 목록](README.md) · [작동 방식](how-it-works.md) · [CLI 레퍼런스](reference.md) · [문제 해결](troubleshooting.md) · [README](../README.md)

`Personal-Agent-Harness`를 사용해 데브컨테이너 표준을 프로젝트에 적용하는 상세 방법입니다.

## 기본 개념

하네스는 표준 규칙을 한 저장소에서 관리하고, 각 대상 프로젝트에는 관리되는 복사본을 넣습니다.

- AI 에이전트 → `docs/devcontainer/devcontainer-standards.md`
- 사람 → `docs/devcontainer/devcontainer-standards.ko.md`
- Cursor, Codex, Claude → 짧은 연결 파일을 통해 표준 문서 위치를 참조

## 준비물

- Linux 또는 WSL에서 실행되는 Bash
- 하네스를 적용할 대상 프로젝트 디렉터리

대상 프로젝트가 git 저장소일 필요는 없지만, 생성된 파일을 검토하기 쉽도록 git 저장소 사용을 권장합니다.

## 첫 적용

대상 **프로젝트 루트**에서 실행합니다.

```bash
cd /path/to/my-app
git clone <your-repo-url> Personal-Agent-Harness && ./Personal-Agent-Harness/setup.sh
```

`setup.sh`는 `rules` 컴포넌트를 설치하고 `verify`까지 실행합니다.

설치 결과 파일 트리는 [CLI 레퍼런스](reference.md#기본-설치-결과-rules)를 참고하세요.

## 업데이트

하네스 저장소에 변경이 push된 뒤, **같은 프로젝트**에서 한 줄로 반영합니다.

```bash
cd /path/to/my-app
./Personal-Agent-Harness/update.sh
```

`update.sh`는 harness clone에서 `git pull --ff-only` → `install` → `verify` 순으로 실행합니다.

관리 파일은 갱신 전에 다음 위치에 백업됩니다.

```text
.harness/backups/<timestamp>/
```

### `Personal-Agent-Harness/` 폴더 유지

`update.sh`가 `git pull`을 위해 프로젝트 안의 harness clone이 필요합니다. copy mode이므로 규칙 파일은 프로젝트에 복사되지만, 업데이트를 위해 harness 폴더는 유지하는 것을 권장합니다.

## 고급 옵션

기본 `setup.sh` / `update.sh`는 `rules`만 설치합니다. 추가 옵션이 필요하면 `bin/pah`를 직접 사용합니다. 자세한 옵션은 [CLI 레퍼런스](reference.md)를 참고하세요.

### dry-run

```bash
./Personal-Agent-Harness/bin/pah install . --dry-run
```

### 선택적 devcontainer 스캐폴드

대상 프로젝트에 데브컨테이너가 없거나, 하네스 기본 스캐폴드를 넣고 싶을 때:

```bash
./Personal-Agent-Harness/bin/pah install . --components rules,devcontainer,gitignore
./Personal-Agent-Harness/bin/pah verify .
```

```text
target-project/
├── .devcontainer/
│   ├── devcontainer.json
│   ├── docker-compose.dev.yml
│   ├── Dockerfile
│   ├── commands/
│   ├── .env.example
│   └── README.md
└── .gitignore  (# pah:managed block)
```

기존 `.devcontainer` 파일이 있으면 기본적으로 건너뜁니다. 덮어쓰려면 `--force`를 사용하세요.

### 하네스 개발용 rule (monorepo, opt-in)

`Personal-Agent-Harness/` **자체를 수정**할 때(새 규칙 도메인 추가, `bin/pah` 변경 등) AI가 하네스 개발 가이드를 읽게 하려면, monorepo **부모 프로젝트 루트**에서 한 번 실행합니다.

```bash
./Personal-Agent-Harness/bin/pah install . --components harness-dev
```

- `setup.sh` / `update.sh`에는 **포함되지 않습니다** (devcontainer 규칙과 겹치지 않도록 분리).
- monorepo를 처음 clone한 뒤, 또는 rule 파일을 커밋하지 않은 상태에서 PC를 바꿀 때만 다시 실행하면 됩니다.

자세한 설명: [하네스 개발·테스트 — AI 연결 활성화](development.md#ai-연결-활성화)

## 기존 AI 파일 처리

`AGENTS.md`와 `CLAUDE.md`는 managed block만 삽입·갱신합니다. block 밖의 프로젝트 고유 규칙은 보존됩니다. 자세한 내용은 [작동 방식](how-it-works.md#managed-block)을 참고하세요.

## 대상 프로젝트에서 커밋할 파일

보통 커밋:

- `docs/devcontainer/devcontainer-standards.md`
- `docs/devcontainer/devcontainer-standards.ko.md`
- `.cursor/rules/devcontainer-standards.mdc`
- `AGENTS.md`, `CLAUDE.md`
- `.harness/manifest.json`
- 선택적으로 `.devcontainer/` 스캐폴드
- monorepo에서 하네스 개발 시: `.cursor/rules/harness-development.mdc` (`--components harness-dev`, [설명](development.md#ai-연결-활성화))

보통 커밋하지 않음:

- `.harness/backups/`
- `.devcontainer/.env`, 루트 `.env`

## 문제가 생겼을 때

[문제 해결](troubleshooting.md) 문서를 참고하세요.
