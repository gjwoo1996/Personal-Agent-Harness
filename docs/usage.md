# 사용 가이드

> **관련 문서:** [문서 목록](README.md) · [작동 방식](how-it-works.md) · [CLI 레퍼런스](reference.md) · [문제 해결](troubleshooting.md)

## 기본 개념

하네스는 registry에 등록된 표준 규칙을 대상 프로젝트에 복사합니다. 기본 `rules` 설치에는 devcontainer와 git-workflow가 포함됩니다.

- AI 에이전트: `docs/<domain>/<domain>-standards.md`
- 사람: `docs/<domain>/<domain>-standards.ko.md`
- Cursor, Codex, Claude: 짧은 연결 파일과 managed block

## 준비물

- Linux 또는 WSL에서 실행되는 Bash
- 하네스를 적용할 대상 프로젝트 디렉터리

대상 프로젝트가 git 저장소일 필요는 없지만, 생성된 파일을 검토하기 쉽도록 git 저장소 사용을 권장합니다.

## 권장 워크플로우 (외부 PAH_HOME)

WSL·Linux에서 하네스는 프로젝트 밖 고정 경로에 두고, 여러 프로젝트에서 재사용합니다.

```bash
# 1) 하네스 — 한 번만 clone
git clone <your-repo-url> ~/.local/share/personal-agent-harness

# 2) 대상 프로젝트에 적용
~/.local/share/personal-agent-harness/bootstrap.sh /path/to/my-project

# 3) 업데이트
~/.local/share/personal-agent-harness/update.sh /path/to/my-project

# 4) 설치 버전 확인
~/.local/share/personal-agent-harness/bin/pah status /path/to/my-project \
  --harness-root ~/.local/share/personal-agent-harness
```

`bootstrap.sh`는 `setup.sh`를 실행합니다. 기본 `rules`를 설치하고 verify를 실행합니다. 프로젝트 안에 `Personal-Agent-Harness/` 폴더를 만들지 않습니다.

환경 변수 `PAH_HOME`으로 경로를 바꿀 수 있습니다. 문서 예시는 기본값 `~/.local/share/personal-agent-harness`를 사용합니다.

## 업데이트

```bash
~/.local/share/personal-agent-harness/update.sh /path/to/my-project
```

`update.sh`는 PAH_HOME harness clone에서 `git pull --ff-only`, install, verify 순으로 실행합니다. 관리 파일은 `.harness/backups/<timestamp>/`에 백업됩니다.

### `Personal-Agent-Harness/` 폴더

copy mode이므로 규칙 파일은 대상 프로젝트에 복사됩니다. 하네스 소스 저장소는 PAH_HOME에만 둡니다.

- 프로젝트에 `Personal-Agent-Harness/`를 두지 않습니다.
- 설치 버전과 checksum은 `.harness/manifest.json`으로 추적합니다.
- `gitignore` 컴포넌트는 실수로 in-project clone한 `Personal-Agent-Harness/`를 무시합니다.

## Legacy in-project clone

예전 방식(프로젝트 안에 clone)을 쓰고 있다면 외부 PAH_HOME으로 옮긴 뒤 중첩 폴더를 제거합니다.

```bash
git clone <your-repo-url> ~/.local/share/personal-agent-harness
~/.local/share/personal-agent-harness/bootstrap.sh . --clean-nested
```

`--clean-nested`는 설치 후 프로젝트 안의 `Personal-Agent-Harness/`를 삭제합니다.

## 고급 옵션

기본 `setup.sh`와 `update.sh`는 `rules`만 설치합니다. 추가 옵션이 필요하면 `bin/pah`를 직접 사용합니다.

### dry-run

```bash
~/.local/share/personal-agent-harness/bin/pah install . --dry-run
```

실제 변경 없이 생성하거나 갱신할 파일을 확인합니다.

## Optional 컴포넌트

devcontainer 스캐폴드와 `.gitignore` block은 기본 registry 밖에서 별도로 설치합니다.

```bash
~/.local/share/personal-agent-harness/bin/pah install . --components rules,devcontainer,gitignore
~/.local/share/personal-agent-harness/bin/pah verify .
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

기존 `.devcontainer` 파일이 있으면 기본적으로 건너뜁니다. 덮어쓰려면 `--force`를 사용합니다.

monorepo에서 `Personal-Agent-Harness/` 자체를 수정할 때는 부모 프로젝트 루트에 `harness-dev` rule을 한 번 설치할 수 있습니다.

```bash
~/.local/share/personal-agent-harness/bin/pah install . --components harness-dev
```

- 기본 `setup.sh`와 `update.sh`에는 포함되지 않습니다.
- 자세한 설명은 [하네스 개발·테스트](development.md#ai-연결-활성화)를 참고하세요.

## 기존 AI 파일 처리

`AGENTS.md`와 `CLAUDE.md`는 도메인별 managed block만 삽입하거나 갱신합니다. 예를 들어 `pah:devcontainer`와 `pah:git-workflow` block은 독립적으로 관리되며 block 밖 내용은 보존됩니다.

## 대상 프로젝트에서 커밋할 파일

보통 커밋:

- `docs/devcontainer/`
- `docs/git-workflow/`
- `.cursor/rules/devcontainer-standards.mdc`
- `.cursor/rules/git-workflow-standards.mdc`
- `AGENTS.md`, `CLAUDE.md`
- `.harness/manifest.json`
- 선택적으로 `.devcontainer/`, `.gitignore`

보통 커밋하지 않음:

- `Personal-Agent-Harness/` (in-project clone 실수 방지: `gitignore` 컴포넌트 권장)
- `.harness/backups/`
- `.devcontainer/.env`, 루트 `.env`

## 문제가 생겼을 때

[문제 해결](troubleshooting.md) 문서를 참고하세요.
