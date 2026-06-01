# Personal-Agent-Harness

`Personal-Agent-Harness`는 여러 프로젝트에 개인 개발환경 하네스를 적용하기 위한 저장소입니다.

현재 1차로 지원하는 하네스는 **데브컨테이너 표준 + AI 에이전트 연결 규칙**입니다.

## 먼저 볼 문서

- [`docs/README.md`](docs/README.md): 문서 인덱스
- [`docs/usage.md`](docs/usage.md): 설치, 업데이트, 검증 상세 사용법
- [`docs/how-it-works.md`](docs/how-it-works.md): 하네스가 대상 프로젝트에 적용되는 과정
- [`standards/devcontainer/devcontainer-standards.ko.md`](standards/devcontainer/devcontainer-standards.ko.md): 사람이 읽는 한글 표준 문서
- [`standards/devcontainer/devcontainer-standards.md`](standards/devcontainer/devcontainer-standards.md): AI 에이전트가 읽는 영문 원본

## 이 저장소가 제공하는 것

- AI가 읽는 영문 단일 원본: `standards/devcontainer/devcontainer-standards.md`
- 사람이 읽는 한글 번역본: `standards/devcontainer/devcontainer-standards.ko.md`
- Cursor용 규칙 템플릿: `templates/stubs/cursor/devcontainer-standards.mdc`
- Codex용 `AGENTS.md` managed block 템플릿
- Claude용 `CLAUDE.md` managed block 템플릿
- 선택적으로 복사할 수 있는 `.devcontainer` 스캐폴드
- 설치, 검증, 상태 확인을 위한 `pah` CLI

중요한 원칙은 간단합니다.

- **AI는 영문 원본만 규칙 출처로 읽습니다.**
- **사람은 한글 문서를 읽습니다.**
- 대상 프로젝트에는 규칙 문서와 AI 연결 파일이 복사됩니다.

## 빠른 시작

```bash
git clone <this-repository-url> Personal-Agent-Harness
cd Personal-Agent-Harness

./bin/pah install /path/to/project --dry-run
./bin/pah install /path/to/project
./bin/pah verify /path/to/project
```

`install.sh`는 `bin/pah install`의 짧은 래퍼입니다.

```bash
./install.sh /path/to/project
```

## 기본 설치 결과

기본 명령인 `pah install <target>`은 AI 규칙 연결에 필요한 파일만 설치합니다.

```text
<target>/
├── docs/devcontainer/devcontainer-standards.md
├── docs/devcontainer/devcontainer-standards.ko.md
├── .cursor/rules/devcontainer-standards.mdc
├── AGENTS.md
├── CLAUDE.md
└── .harness/manifest.json
```

기존 `AGENTS.md`와 `CLAUDE.md`는 전체 덮어쓰지 않습니다. 아래 managed block만 삽입하거나 갱신합니다.

```markdown
<!-- pah:devcontainer:start -->
<!-- pah:devcontainer:end -->
```

자세한 사용법은 [`docs/usage.md`](docs/usage.md)를 보세요.

## 선택 컴포넌트

새 프로젝트에 `.devcontainer` 스캐폴드와 `.gitignore` 항목까지 넣고 싶다면 다음처럼 실행합니다.

```bash
./bin/pah install /path/to/project --components rules,devcontainer,gitignore
```

`.devcontainer` 스캐폴드는 명시적으로 요청했을 때만 복사됩니다. 기존 파일이 있으면 기본적으로 건너뛰며, 덮어쓰려면 `--force`를 사용해야 합니다.

하네스 적용 과정은 [`docs/how-it-works.md`](docs/how-it-works.md)에 정리되어 있습니다.

## 명령어 요약

```bash
./bin/pah install <target> [--dry-run] [--force] [--components rules,devcontainer,gitignore]
./bin/pah verify <target>
./bin/pah status <target>
```

### `install`

대상 프로젝트에 표준 문서, Cursor rule, Codex/Claude managed block을 설치하거나 갱신합니다.

### `verify`

다음을 확인합니다.

- `docs/devcontainer/devcontainer-standards.md` 존재
- `docs/devcontainer/devcontainer-standards.ko.md` 존재
- `.cursor/rules/devcontainer-standards.mdc` 존재
- `AGENTS.md`와 `CLAUDE.md`에 managed block 존재
- AI stub이 `devcontainer-standards.ko.md`를 규칙 출처로 직접 참조하지 않음

### `status`

대상 프로젝트에 `.harness/manifest.json`이 있는지 확인해 하네스 적용 여부를 알려줍니다.

## 업데이트 흐름

하네스 저장소를 업데이트한 뒤 대상 프로젝트에 다시 반영하려면 다음 순서로 실행합니다.

```bash
cd Personal-Agent-Harness
git pull
./bin/pah install /path/to/project
./bin/pah verify /path/to/project
```

관리되는 파일은 갱신 전에 `.harness/backups/<timestamp>/` 아래에 백업됩니다.

## 규칙 우선순위

데브컨테이너 관련 요청에서 우선순위는 다음과 같습니다.

1. 사용자의 직접 지시
2. 프로젝트별 예외와 프로젝트 고유 규칙
3. `docs/devcontainer/devcontainer-standards.md`
4. 과거 참고 문서 또는 번역본

프로젝트별 예외는 대상 프로젝트의 `.devcontainer/README.md`에 기록합니다.

## 개발/검증

하네스 자체 테스트는 다음으로 실행합니다.

```bash
bash tests/test_pah.sh
```