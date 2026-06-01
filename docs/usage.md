# 사용 가이드

이 문서는 `Personal-Agent-Harness`를 사용해서 데브컨테이너 표준을 다른 프로젝트에 적용하는 방법을 설명합니다.

## 기본 개념

`Personal-Agent-Harness`는 표준 규칙을 한 저장소에서 관리하고, 각 대상 프로젝트에는 관리되는 복사본을 넣습니다.

적용된 대상 프로젝트는 다음처럼 스스로 규칙을 포함하게 됩니다.

- AI 에이전트는 대상 프로젝트 안의 `docs/devcontainer/devcontainer-standards.md`를 읽습니다.
- 사람은 대상 프로젝트 안의 `docs/devcontainer/devcontainer-standards.ko.md`를 읽습니다.
- Cursor, Codex, Claude는 각각 짧은 연결 파일을 통해 표준 문서 위치를 알게 됩니다.

## 준비물

- Linux 또는 WSL에서 실행되는 Bash
- clone된 `Personal-Agent-Harness` 저장소
- 하네스를 적용할 대상 프로젝트 디렉토리

기본 설치 흐름에서는 대상 프로젝트가 꼭 git 저장소일 필요는 없습니다. 다만 생성된 파일을 검토하기 쉽도록 git 저장소에서 사용하는 것을 권장합니다.

## 첫 적용 권장 순서

하네스 저장소에서 다음 순서로 실행합니다.

```bash
cd /path/to/Personal-Agent-Harness

./bin/pah install /path/to/project --dry-run
./bin/pah install /path/to/project
./bin/pah verify /path/to/project
```

각 단계의 의미는 다음과 같습니다.

1. `--dry-run`은 실제 변경 없이 생성/수정될 파일 목록을 보여줍니다.
2. `install`은 표준 문서와 AI 연결 파일을 대상 프로젝트에 복사/병합합니다.
3. `verify`는 대상 프로젝트에 하네스 파일이 제대로 들어갔는지 확인합니다.

## 기본 설치 결과

기본 설치는 `rules` 컴포넌트만 사용합니다.

```text
target-project/
├── docs/devcontainer/devcontainer-standards.md
├── docs/devcontainer/devcontainer-standards.ko.md
├── .cursor/rules/devcontainer-standards.mdc
├── AGENTS.md
├── CLAUDE.md
└── .harness/manifest.json
```

영문 표준은 AI가 읽는 규칙 출처입니다. 한글 번역본은 사람이 읽기 위해 복사됩니다.

## 선택적 devcontainer 스캐폴드 적용

대상 프로젝트에 아직 데브컨테이너가 없거나, `Personal-Agent-Harness`의 기본 스캐폴드를 의도적으로 넣고 싶을 때 사용합니다.

```bash
./bin/pah install /path/to/project --components rules,devcontainer,gitignore
./bin/pah verify /path/to/project
```

이 명령은 다음 파일들을 추가할 수 있습니다.

```text
target-project/
├── .devcontainer/
│   ├── devcontainer.json
│   ├── docker-compose.dev.yml
│   ├── Dockerfile
│   ├── commands/
│   │   ├── initializeCommand.sh
│   │   ├── post-create.sh
│   │   └── post-start.sh
│   ├── .env.example
│   └── README.md
└── .gitignore
```

기존 `.devcontainer` 파일이 있으면 기본적으로 건너뜁니다. 관리 파일을 의도적으로 덮어쓰고 싶을 때만 `--force`를 사용하세요.

## 명령어 상세

### `install`

```bash
./bin/pah install <target> [--dry-run] [--force] [--components rules,devcontainer,gitignore]
```

대상 프로젝트에 하네스가 관리하는 파일을 설치하거나 갱신합니다.

자주 쓰는 예시는 다음과 같습니다.

```bash
# 기본 rules 설치에서 어떤 파일이 생길지 미리 확인
./bin/pah install ~/projects/my-app --dry-run

# AI 규칙 연결만 설치
./bin/pah install ~/projects/my-app

# rules, devcontainer 스캐폴드, gitignore block까지 설치
./bin/pah install ~/projects/my-app --components rules,devcontainer,gitignore

# 관리 파일을 강제로 갱신
./bin/pah install ~/projects/my-app --force
```

### `verify`

```bash
./bin/pah verify <target>
```

대상 프로젝트에 다음 파일들이 있는지 확인합니다.

- `docs/devcontainer/devcontainer-standards.md`
- `docs/devcontainer/devcontainer-standards.ko.md`
- `.cursor/rules/devcontainer-standards.mdc`
- `AGENTS.md`
- `CLAUDE.md`
- `.harness/manifest.json`

또한 AI stub이 `devcontainer-standards.ko.md`를 규칙 출처로 직접 참조하지 않는지도 확인합니다.

### `status`

```bash
./bin/pah status <target>
```

대상 프로젝트에 하네스 manifest가 있는지 확인합니다.

## 기존 AI 파일 처리 방식

`AGENTS.md`와 `CLAUDE.md`는 전체 덮어쓰지 않습니다.

installer는 아래 managed section만 삽입하거나 갱신합니다.

```markdown
<!-- pah:devcontainer:start -->
...
<!-- pah:devcontainer:end -->
```

이 block 밖에 있는 프로젝트 고유 규칙은 보존됩니다.

## 하네스 변경 후 대상 프로젝트 업데이트

하네스 저장소를 업데이트했다면 다음 순서로 대상 프로젝트에 반영합니다.

```bash
cd /path/to/Personal-Agent-Harness
git pull

./bin/pah install /path/to/project
./bin/pah verify /path/to/project
```

관리 파일은 갱신 전에 다음 위치에 백업됩니다.

```text
target-project/.harness/backups/<timestamp>/
```

## 대상 프로젝트에서 커밋할 파일

보통 커밋하는 파일:

- `docs/devcontainer/devcontainer-standards.md`
- `docs/devcontainer/devcontainer-standards.ko.md`
- `.cursor/rules/devcontainer-standards.mdc`
- `AGENTS.md`
- `CLAUDE.md`
- `.harness/manifest.json`
- 선택적으로 추가한 `.devcontainer/` 스캐폴드 파일

보통 커밋하지 않는 파일:

- `.harness/backups/`
- `.devcontainer/.env`
- 루트 `.env`

## 문제가 생겼을 때

1. `./bin/pah verify <target>`를 실행합니다.
2. `.harness/manifest.json`을 확인합니다.
3. `.harness/backups/<timestamp>/`에서 이전 버전을 확인합니다.
4. `--dry-run`으로 다시 실행해 어떤 변경이 일어날지 확인합니다.

## 현재 제한사항

MVP는 copy mode만 사용합니다. symlink mode와 submodule mode는 의도적으로 이후 확장으로 남겨두었습니다.
