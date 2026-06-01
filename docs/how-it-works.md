# Personal-Agent-Harness 작동 방식

이 문서는 `Personal-Agent-Harness`가 어떤 프로세스로 대상 프로젝트에 적용되는지 설명합니다.

## 목표

`Personal-Agent-Harness`는 개인 개발 표준을 하나의 저장소에서 관리하고, 여러 프로젝트에 일관되게 적용하기 위한 하네스입니다.

현재 하네스가 다루는 범위는 데브컨테이너 표준과 AI 에이전트 연결 파일입니다.

## 핵심 프로세스

```text
Personal-Agent-Harness
  standards/devcontainer/devcontainer-standards.md
  templates/stubs/*
  templates/devcontainer/*
        |
        | pah install <target>
        v
target project
  docs/devcontainer/devcontainer-standards.md
  .cursor/rules/devcontainer-standards.mdc
  AGENTS.md
  CLAUDE.md
```

하네스 저장소가 원본입니다. 대상 프로젝트는 관리되는 복사본을 받습니다.

## Copy mode를 기본으로 사용하는 이유

MVP는 copy mode를 사용합니다. 가장 이식성이 좋기 때문입니다.

장점:

- 대상 프로젝트만 clone해도 규칙 문서가 함께 존재합니다.
- AI 에이전트가 하네스 저장소의 위치를 알 필요가 없습니다.
- CI나 오프라인 환경에서도 프로젝트 내부의 표준 문서를 읽을 수 있습니다.
- 기존 프로젝트 파일은 managed block 방식으로 보존할 수 있습니다.

단점:

- 하네스 저장소가 변경되어도 대상 프로젝트가 자동으로 바뀌지는 않습니다. 갱신하려면 `pah install`을 다시 실행해야 합니다.

## 단일 원본

AI가 읽는 규칙 출처는 영문 문서입니다.

```text
standards/devcontainer/devcontainer-standards.md
```

설치 과정에서 이 문서는 대상 프로젝트의 다음 경로로 복사됩니다.

```text
target-project/docs/devcontainer/devcontainer-standards.md
```

AI 에이전트는 대상 프로젝트 안에 복사된 문서를 읽도록 안내받습니다. 이렇게 하면 각 프로젝트가 자기 안에 필요한 규칙을 포함하게 됩니다.

한글 번역본은 사람이 읽기 위해 복사됩니다.

```text
target-project/docs/devcontainer/devcontainer-standards.ko.md
```

AI stub에는 `*.ko.md` 파일을 규칙 출처로 사용하지 말라고 명시되어 있습니다.

## AI 연결 흐름

### Cursor Composer

설치되는 파일:

```text
target-project/.cursor/rules/devcontainer-standards.mdc
```

동작:

- `globs`를 통해 데브컨테이너 관련 파일에만 적용됩니다.
- `alwaysApply: false`를 사용해 관련 없는 작업에 데브컨테이너 규칙이 매번 로드되지 않게 합니다.
- Cursor에게 `docs/devcontainer/devcontainer-standards.md`를 읽으라고 안내합니다.

### Codex

생성 또는 갱신되는 파일:

```text
target-project/AGENTS.md
```

동작:

- 파일이 없으면 installer가 새로 만듭니다.
- 파일이 있으면 managed block만 갱신합니다.
- Codex는 데브컨테이너 섹션을 보고 관련 작업에서 영문 표준 문서를 읽습니다.

### Claude

생성 또는 갱신되는 파일:

```text
target-project/CLAUDE.md
```

동작:

- `AGENTS.md`와 같은 managed block 전략을 사용합니다.
- 기존 Claude 프로젝트 지침은 managed block 밖에 보존됩니다.

## Managed block

installer가 소유하는 영역은 `AGENTS.md`와 `CLAUDE.md` 안의 다음 구간뿐입니다.

```markdown
<!-- pah:devcontainer:start -->
...
<!-- pah:devcontainer:end -->
```

이 block 밖의 내용은 프로젝트가 소유하는 내용입니다.

이 방식 덕분에 하네스가 프로젝트 고유 AI 지침을 덮어쓰지 않습니다.

## Manifest와 백업

installer는 다음 파일을 작성합니다.

```text
target-project/.harness/manifest.json
```

manifest에는 다음 정보가 기록됩니다.

- 하네스 이름과 버전
- 설치 모드
- 표준 문서 경로
- checksum
- 관리 파일 목록
- 한글 번역본이 AI용이 아니라는 표시

관리 파일을 갱신하기 전에는 기존 버전을 다음 경로에 백업합니다.

```text
target-project/.harness/backups/<timestamp>/
```

## 규칙 우선순위

AI가 데브컨테이너 작업을 처리할 때 우선순위는 다음과 같습니다.

1. 사용자의 직접 지시
2. 프로젝트별 예외와 프로젝트 고유 규칙
3. `docs/devcontainer/devcontainer-standards.md`
4. 과거 참고 문서 또는 번역본

프로젝트별 예외는 다음 파일에 기록합니다.

```text
target-project/.devcontainer/README.md
```

## 선택적 devcontainer 스캐폴드

기본 설치는 AI 규칙 연결만 수행합니다.

다음 명령으로 설치하면:

```bash
./bin/pah install <target> --components rules,devcontainer,gitignore
```

하네스는 다음 템플릿도 복사합니다.

```text
templates/devcontainer/
```

복사 위치:

```text
target-project/.devcontainer/
```

이 기능은 새 프로젝트이거나, 의도적으로 하네스의 기본 스캐폴드를 쓰고 싶은 프로젝트를 위한 것입니다.

## 업데이트 프로세스

```text
1. Personal-Agent-Harness를 업데이트한다.
2. pah install <target>을 실행한다.
3. installer가 관리 파일을 갱신한다.
4. installer가 이전 버전을 백업한다.
5. pah verify <target>을 실행한다.
```

## 아직 하지 않는 일

- symlink mode를 지원하지 않습니다.
- submodule mode를 지원하지 않습니다.
- 완전한 three-way merge를 수행하지 않습니다.
- 기존 커스텀 devcontainer를 자동 마이그레이션하지 않습니다.
- `verify` 단계에서 Docker build를 실행하지 않습니다.

이 항목들은 첫 버전을 예측 가능하게 유지하기 위해 의도적으로 MVP에서 제외했습니다.
