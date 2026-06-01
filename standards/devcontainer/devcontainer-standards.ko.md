# 데브컨테이너 표준 규칙

> 이 문서는 사람을 위한 한글 번역본입니다.
> AI 에이전트가 따라야 할 기준 문서는 [`devcontainer-standards.md`](./devcontainer-standards.md)입니다.
> AI stub과 규칙 파일은 이 번역본을 규칙 출처로 사용하지 않아야 합니다.

## 상태

이 문서는 기존 Claude, Composer, Codex 데브컨테이너 노트에서 도출한 최종 합의안의 한글 번역본입니다. 기존 노트는 입력 자료였고, 하네스에서 AI가 따라야 할 기준은 영문 원본입니다.

우선순위:

1. 사용자의 직접 지시
2. 프로젝트별 데브컨테이너 규칙과 문서화된 예외
3. 영문 원본 `devcontainer-standards.md`
4. 기존 참고 문서 또는 번역본

한글 번역본은 사람용입니다. AI 규칙 출처로 `*.ko.md` 파일을 사용하지 않습니다.

## 최종 합의

Composer의 실무 개발자 경험을 기본 구조로 삼고, Codex의 재현성과 검증 규칙을 완료 기준으로 삼으며, Claude의 유지보수성과 온보딩 기준으로 예외를 통제합니다.

실제로는 다음 기준을 따릅니다.

- 처음에는 `workspace` 서비스만 있더라도 Docker Compose로 시작합니다.
- 기본 사용자와 워크스페이스 경로는 `vscode`와 `/home/vscode/${localWorkspaceFolderBasename}`를 사용합니다.
- 언어 런타임은 devcontainer features를 우선 사용합니다.
- AI CLI는 Dockerfile에서 명시적으로 고정된 버전으로 설치합니다.
- AI 상태 저장 방식은 하나로 고정하지 않고 아래 결정 트리에 따라 선택합니다.
- 장기 규칙은 AI별 진입 파일에 중복하지 않고 영문 원본 문서에 둡니다.

## 표준 파일 구조

새 데브컨테이너는 다음 구조를 사용합니다.

```text
.devcontainer/
├── devcontainer.json
├── docker-compose.dev.yml
├── Dockerfile
├── commands/
│   ├── initializeCommand.sh
│   ├── post-create.sh
│   └── post-start.sh
├── .env
├── .env.example
└── README.md

.env
.env.example
```

규칙:

- lifecycle 스크립트는 `.devcontainer/commands/`에 둡니다.
- `scripts/`와 `commands/`를 섞지 않습니다.
- 개발 전용 Compose 파일명은 `docker-compose.dev.yml`을 선호합니다.
- `.devcontainer/.env`는 `initializeCommand`가 생성하는 Compose 치환 값용으로 사용합니다.
- 루트 `.env`는 앱 실행 값, 루트 `.env.example`은 비밀이 아닌 예시 값용으로 사용합니다.

## Compose 우선 규칙

모든 새 프로젝트는 Compose에서 시작합니다.

- `devcontainer.json`은 `docker-compose.dev.yml`을 가리킵니다.
- 기본 서비스 이름은 `workspace`입니다.
- 데이터베이스, 캐시, 검색 엔진 같은 sidecar는 같은 프로젝트 Compose 파일에 둡니다.
- 서비스 간 통신은 `postgres:5432`처럼 Compose 서비스 이름을 사용합니다.

새 프로젝트가 `Common_Repo`나 공유 Docker 네트워크 같은 외부 스택에 기본 의존하도록 만들지 않습니다. 이런 구조는 레거시 또는 예외이며, 반드시 `.devcontainer/README.md`에 기록합니다.

## 사용자와 워크스페이스 경로

기본값:

```json
{
  "remoteUser": "vscode",
  "updateRemoteUserUID": true,
  "workspaceFolder": "/home/vscode/${localWorkspaceFolderBasename}"
}
```

규칙:

- `/workspace/<project-name>` 또는 `/workspaces/<project-name>`를 하드코딩하지 않습니다.
- Node.js 프로젝트라는 이유만으로 `node` 사용자를 기본값으로 삼지 않습니다.
- 선택한 베이스 이미지가 명시적으로 `node` 사용자를 전제로 할 때만 `node`를 사용하고, 그 예외를 문서화합니다.
- 원격 사용자를 바꾸면 홈 경로, 마운트, lifecycle 스크립트도 함께 일관되게 수정합니다.

## 런타임과 도구 설치

책임을 다음처럼 나눕니다.

- 언어 런타임과 일반 개발 스택: devcontainer features
- features로 적합하지 않은 AI CLI와 도구: Dockerfile
- 프로젝트 의존성: 보통 `post-create.sh`

기본 Dockerfile 베이스:

```dockerfile
FROM mcr.microsoft.com/devcontainers/base:ubuntu
```

다음 경우에만 더 무거운 스택 이미지나 커스텀 Dockerfile 로직을 사용합니다.

- 필요한 도구를 features로 깔끔하게 설치할 수 없습니다.
- 프로젝트가 특정 Microsoft devcontainer 스택 이미지를 필요로 합니다.
- Dockerfile에 이미 여러 apt/system 의존성이 필요합니다.
- 고정되고 감사 가능한 설치 경로가 필요합니다.

## 버전 고정

표준 템플릿에서는 `latest`나 떠다니는 `lts` 값을 사용하지 않습니다.

다음 항목은 고정합니다.

- 베이스 이미지
- devcontainer feature 버전
- 언어 런타임
- 데이터베이스와 sidecar 이미지
- `CLAUDE_CODE_VERSION`
- `CODEX_CLI_VERSION`

버전 업데이트는 의도적인 변경으로 처리하고, 리빌드와 smoke test 결과를 함께 확인합니다.

## AI CLI 설치

Claude Code와 Codex CLI는 `postCreateCommand`가 아니라 이미지 빌드 중에 설치합니다.

규칙:

- AI CLI 버전은 Dockerfile build arg로 받습니다.
- 해당 버전은 검증된 값으로 고정합니다.
- 빌드 또는 `post-create.sh`에서 CLI 버전을 출력하거나 검증합니다.
- 같은 AI CLI를 devcontainer feature와 Dockerfile 양쪽에서 중복 설치하지 않습니다.

예시 의도:

```dockerfile
ARG CLAUDE_CODE_VERSION
ARG CODEX_CLI_VERSION
RUN npm install -g \
    "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
    "@openai/codex@${CODEX_CLI_VERSION}" \
    && claude --version \
    && codex --version
```

## AI 상태 저장 결정 트리

하나의 보편 기본값은 없습니다. 프로젝트 상황에 따라 선택합니다.

호스트 bind mount를 사용합니다.

- 개인 WSL2 개발 환경입니다.
- 같은 사용자가 호스트 Cursor, 호스트 CLI, devcontainer CLI를 오가며 사용합니다.
- 프로젝트 격리보다 기존 호스트 로그인/세션 상태 재사용이 더 중요합니다.
- 필요한 호스트 경로와 준비 절차를 문서화할 수 있습니다.

named volume을 사용합니다.

- 팀 템플릿입니다.
- 프로젝트별 AI 계정 또는 API 격리가 필요합니다.
- CI, 온보딩, 새 머신 재현성이 호스트 편의보다 중요합니다.
- 기존 호스트 AI 상태 없이 컨테이너 환경이 동작해야 합니다.

항상 지킬 규칙:

- `{project-slug}-claude-config`, `{project-slug}-codex-config`처럼 안정적인 볼륨 이름을 사용합니다.
- AI 상태 볼륨 이름에 `${devcontainerId}`를 넣지 않습니다.
- 디렉토리 상태와 파일 상태를 모두 보존합니다. 필요하면 Claude의 `.claude.json`도 포함합니다.
- 선택한 전략을 `.devcontainer/README.md`에 문서화합니다.

OCI 또는 SSH 파일처럼 실제로 필요한 외부 인증 파일은 readonly host bind로 마운트할 수 있습니다. 이 경우 경로, 목적, 예상 권한을 문서화합니다.

## 비밀값과 환경 변수

비밀값과 설정은 책임별로 분리합니다.

- 개인/API 비밀값: `${localEnv:...}`를 사용하는 `containerEnv`
- 앱과 데이터베이스 실행 값: 루트 `.env`와 `.env.example`
- Compose 치환 값: `initializeCommand.sh`가 생성하는 `.devcontainer/.env`
- 비밀이 아닌 예시만: `.env.example`

규칙:

- 실제 비밀값을 커밋하지 않습니다.
- `.env.example`에 실제 API 키를 넣지 않습니다.
- Docker 이미지에 비밀값을 굽지 않습니다.
- 개발자가 비공개 값을 커밋되는 파일에 복사해야 하는 구조를 만들지 않습니다.

## Lifecycle 명령

`.devcontainer/commands/`만 사용합니다.

`initializeCommand.sh`:

- 호스트에서 실행됩니다.
- Compose 치환을 위한 `.devcontainer/.env`를 생성합니다.
- 빠르고 멱등적이어야 합니다.

`post-create.sh`:

- 컨테이너 생성 후 한 번 실행됩니다.
- `set -euo pipefail`을 사용해야 합니다.
- 프로젝트 의존성을 설치합니다.
- 런타임과 AI CLI 버전을 검증합니다.
- 필요한 경우 `git safe.directory`를 설정합니다.
- 멱등적이어야 합니다.

`post-start.sh`:

- 선택 사항입니다.
- 가볍게 유지합니다.
- 빠른 권한 확인이나 상태 힌트 정도에만 사용합니다.

다음처럼 파괴적이거나 상태를 바꾸는 앱 작업은 자동 실행하지 않습니다.

- 기본 DB 마이그레이션 금지
- 기본 seed data 삽입 금지
- 장기 실행 앱 서버 자동 시작 금지
- 실패를 숨기는 best-effort 처리 금지

## 포트와 VS Code 확장

호스트에는 개발자가 실제로 필요한 것만 노출합니다.

규칙:

- 앱 포트는 `forwardPorts`에 둘 수 있습니다.
- 각 포워딩 포트에는 `portsAttributes`를 함께 둡니다.
- 메인 웹 UI에는 필요하면 `openBrowser`를 사용합니다.
- 데이터베이스, 캐시, 검색 포트는 호스트 GUI 워크플로가 필요한 경우가 아니면 내부에 둡니다.
- host publish가 필요한 sidecar 포트는 예외로 문서화합니다.

공유 VS Code 확장은 최소화합니다.

- 기본 필수 확장은 AI 관련 확장만 둡니다.
- ESLint나 Prettier 같은 스택별 확장은 프로젝트 스택이 필요할 때만 허용합니다.
- 개인 취향의 확장, 테마, 아이콘 팩은 공유 devcontainer에서 요구하지 않습니다.

## 예외 문서화

표준에서 벗어나면 `.devcontainer/README.md`를 생성하거나 갱신합니다.

다음을 기록합니다.

- 표준과 다른 점
- 예외가 필요한 이유
- 보안과 재현성 영향
- 필요한 호스트 준비
- 환경 검증 명령
- 가능하다면 표준으로 되돌리는 방법

반드시 문서화해야 하는 예외:

- AI 상태용 host bind mount
- 공유 외부 Compose 스택 또는 Docker 네트워크
- host publish된 sidecar 포트
- `vscode`가 아닌 remote user
- 더 무거운 Dockerfile 기반 런타임 설치
- readonly 외부 인증 파일 bind

## 검증 체크리스트

데브컨테이너 변경은 관련 항목을 검토하고 통과하기 전까지 완료된 것으로 보지 않습니다.

- `docker compose -f .devcontainer/docker-compose.dev.yml config`
- 최초 "Reopen in Container" 성공
- rebuild 성공
- `whoami`가 예상 remote user를 반환
- 문서화된 예외가 없다면 `pwd`가 `/home/vscode/${localWorkspaceFolderBasename}`와 일치
- 런타임 버전이 고정 설정과 일치
- Claude Code가 포함된 경우 `claude --version` 성공
- Codex CLI가 포함된 경우 `codex --version` 성공
- 선택한 저장 전략에 맞게 rebuild 후 AI 상태 유지
- 앱 의존성 설치 성공
- 웹 앱이 있으면 메인 앱 포트 smoke test 성공
- 커밋된 파일에 실제 비밀값이 없음

## AI 에이전트 지침

AI 에이전트가 데브컨테이너 관련 요청을 받으면 다음 순서를 따릅니다.

1. 영문 원본 `devcontainer-standards.md`를 먼저 읽습니다.
2. 더 구체적인 프로젝트별 규칙이 있는지 확인합니다.
3. 사용자가 다르게 요청하지 않았다면 표준을 적용합니다.
4. 예외가 필요하면 `.devcontainer/README.md`에 문서화합니다.
5. 한글 번역본을 규칙 출처로 사용하지 않습니다. 번역본은 사람용입니다.
