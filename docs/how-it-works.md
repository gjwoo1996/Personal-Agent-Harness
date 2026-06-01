# Personal-Agent-Harness 작동 방식

> **관련 문서:** [문서 목록](README.md) · [사용법](usage.md) · [CLI 레퍼런스](reference.md) · [README](../README.md)

`Personal-Agent-Harness`가 대상 프로젝트에 적용되는 프로세스를 설명합니다.

## 목표

개인 개발 표준을 하나의 저장소에서 관리하고, 여러 프로젝트에 일관되게 적용하기 위한 하네스입니다.

현재 범위: 데브컨테이너 표준 + AI 에이전트 연결 파일.

## 이 저장소가 제공하는 것

- AI용 영문 단일 원본: `standards/devcontainer/devcontainer-standards.md`
- 사람용 한글 번역본: `standards/devcontainer/devcontainer-standards.ko.md`
- Cursor rule, Codex/Claude managed block 템플릿
- 선택적 `.devcontainer` 스캐폴드
- `setup.sh`, `update.sh`, `pah` CLI

원칙:

- **AI는 영문 원본만** 규칙 출처로 읽습니다.
- **사람은 한글 문서**를 읽습니다.
- 대상 프로젝트에는 규칙 문서와 AI 연결 파일이 **복사**됩니다.

## 핵심 프로세스

```text
my-app/  (대상 프로젝트)
  |
  | git clone Personal-Agent-Harness
  | ./Personal-Agent-Harness/setup.sh
  v
my-app/
  Personal-Agent-Harness/     ← harness 원본 (업데이트용 유지)
  docs/devcontainer/          ← 복사된 표준
  .cursor/rules/
  AGENTS.md, CLAUDE.md
  .harness/manifest.json
```

하네스 저장소가 원본입니다. 대상 프로젝트는 관리되는 복사본을 받습니다.

## Copy mode를 기본으로 사용하는 이유

장점:

- 대상 프로젝트만 clone해도 규칙 문서가 함께 존재합니다.
- AI 에이전트가 하네스 저장소 위치를 알 필요가 없습니다.
- CI·오프라인 환경에서도 프로젝트 내부 표준 문서를 읽을 수 있습니다.
- managed block으로 기존 프로젝트 파일을 보존할 수 있습니다.

단점:

- 하네스 저장소가 변경되어도 대상 프로젝트가 자동으로 바뀌지 않습니다. `./Personal-Agent-Harness/update.sh`로 갱신해야 합니다.

## 단일 원본

AI 규칙 출처:

```text
standards/devcontainer/devcontainer-standards.md
  → target-project/docs/devcontainer/devcontainer-standards.md
```

한글 번역본 (사람용):

```text
standards/devcontainer/devcontainer-standards.ko.md
  → target-project/docs/devcontainer/devcontainer-standards.ko.md
```

AI stub에는 `*.ko.md`를 규칙 출처로 사용하지 말라고 명시되어 있습니다.

## AI 연결 흐름

### Cursor

- 파일: `.cursor/rules/devcontainer-standards.mdc`
- `globs`로 데브컨테이너 관련 파일에만 적용, `alwaysApply: false`
- `docs/devcontainer/devcontainer-standards.md`를 읽도록 안내

### Codex

- 파일: `AGENTS.md` (managed block)
- 파일이 없으면 생성, 있으면 block만 갱신

### Claude

- 파일: `CLAUDE.md` (managed block)
- `AGENTS.md`와 동일한 전략

## 하네스 개발용 vs 대상 프로젝트용

두 종류의 AI 연결을 **분리**합니다.

| 구분 | 적용 시점 | 설치 |
|------|-----------|------|
| **대상 프로젝트용** | `.devcontainer/**` 등 | 기본 `pah install` (`rules`) |
| **하네스 개발용** | PAH 저장소 수정 | 기본 install **제외**, opt-in |

대상 프로젝트용:

- `templates/stubs/` → `.cursor/rules/devcontainer-standards.mdc`, `AGENTS.md` / `CLAUDE.md` managed block
- 모든 `pah install` 대상 프로젝트에 배포

하네스 개발용:

- `.cursor/rules/harness-development.mdc` — PAH 저장소 내부 (단독 repo)
- `templates/harness-dev/` — monorepo opt-in (`--components harness-dev`)
- `AGENTS.md` — PAH 저장소 루트 (install 대상 아님)
- `docs/adding-rule-domains.md`, `docs/development.md` 참조

`templates/stubs/AGENTS.md`에 harness-dev block을 넣지 않습니다. 대상 프로젝트 `AGENTS.md`에 개발용 지시가 섞이지 않도록 하기 위함입니다.

## Managed block

installer가 소유하는 영역:

```markdown
<!-- pah:devcontainer:start -->
...
<!-- pah:devcontainer:end -->
```

block 밖은 프로젝트가 소유합니다.

## Manifest와 백업

installer는 `.harness/manifest.json`을 작성합니다 (하네스 버전, checksum, 관리 파일 목록).

갱신 전 기존 파일은 `.harness/backups/<timestamp>/`에 백업됩니다.

## 규칙 우선순위

1. 사용자의 직접 지시
2. 프로젝트별 예외와 프로젝트 고유 규칙
3. `docs/devcontainer/devcontainer-standards.md`
4. 과거 참고 문서 또는 번역본

프로젝트별 예외: `target-project/.devcontainer/README.md`

## 선택적 devcontainer 스캐폴드

기본 `setup.sh` / `update.sh`는 `rules`만 설치합니다. 스캐폴드는 `--components rules,devcontainer,gitignore`로 명시적 요청 시 복사됩니다. [사용법](usage.md#선택적-devcontainer-스캐폴드) 참고.

## 업데이트 프로세스

```text
1. 하네스 저장소에 변경 push
2. 대상 프로젝트에서 ./Personal-Agent-Harness/update.sh 실행
3. git pull → install → verify
4. 이전 관리 파일은 .harness/backups/<timestamp>/에 백업
```

## 아직 하지 않는 일

- symlink / submodule mode
- three-way merge
- 기존 커스텀 devcontainer 자동 마이그레이션
- verify 단계 Docker build

이 항목들은 MVP를 예측 가능하게 유지하기 위해 의도적으로 제외했습니다.
