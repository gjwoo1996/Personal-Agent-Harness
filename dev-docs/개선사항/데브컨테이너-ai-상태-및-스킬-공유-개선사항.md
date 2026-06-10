# 데브컨테이너 AI 상태 및 스킬 공유 개선사항

작성일: 2026-06-10

## 목적

Personal-Agent-Harness의 devcontainer 템플릿과 규칙 배포 구조가 다음 요구를 만족하는지 점검하고, 필요한 개선사항을 정리한다.

- Codex와 Claude를 CLI 및 VS Code extension으로 사용할 수 있는지
- 로그인 및 대화 내역 유지를 위해 named volume으로 AI config/state 파일을 관리하는지
- `superpowers`, `gstack` 두 스킬을 Codex, Claude, Cursor 3개 AI에서 사용할 수 있도록 설정되어 있는지

## 현재 판정

| 항목 | 상태 | 요약 |
| --- | --- | --- |
| Claude/Codex CLI 설치 | 부분 충족 | Dockerfile에서 npm global install을 수행한다. 다만 `.env.example`은 placeholder라 실제 고정 버전은 아직 템플릿에 들어 있지 않다. |
| Claude/Codex VS Code extension | 충족 | `anthropic.claude-code`, `openai.chatgpt` extension이 devcontainer 설정에 포함되어 있다. |
| 로그인/대화 내역 유지를 위한 named volume | 미충족 | Compose volume은 워크스페이스 bind mount만 있으며 `~/.claude`, `~/.claude.json`, `~/.codex` 보존용 named volume이 없다. |
| AI state 저장 전략 문서화 | 미충족 | `.devcontainer/README.md` 템플릿에 host bind 또는 named volume 선택 결과가 문서화되어 있지 않다. |
| `superpowers` 스킬 공유 | 미충족 | archive 및 historical note에는 언급이 있으나 설치 대상이나 devcontainer 템플릿에는 포함되어 있지 않다. |
| `gstack` 스킬 공유 | 미충족 | 저장소에서 `gstack` 관련 설정을 찾을 수 없다. |
| Codex/Claude/Cursor 규칙 배포 | 충족 | PAH는 `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/*.mdc`, Claude hooks를 설치한다. 단, 이는 스킬 설치가 아니라 규칙 문서 배포이다. |

## 확인 근거

### CLI 및 extension

- `templates/devcontainer/Dockerfile`
  - `CLAUDE_CODE_VERSION`, `CODEX_CLI_VERSION` build arg를 사용한다.
  - `@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}`와 `@openai/codex@${CODEX_CLI_VERSION}`를 설치한다.
  - `claude --version`, `codex --version`을 실행한다.
- `templates/devcontainer/devcontainer.json`
  - VS Code extension으로 `anthropic.claude-code`, `openai.chatgpt`가 포함되어 있다.
- `templates/devcontainer/.env.example`
  - 현재 값은 `<validated-version>` placeholder이다.

### AI state storage

- `standards/devcontainer/devcontainer-standards.md`
  - named volume을 사용할 경우 `{project-slug}-claude-config`, `{project-slug}-codex-config`처럼 안정적인 볼륨명을 사용해야 한다.
  - `${devcontainerId}`를 AI state volume name에 포함하지 않아야 한다.
  - 디렉터리 state와 file state를 모두 보존해야 하며, 필요 시 Claude의 `.claude.json`도 포함해야 한다.
  - 선택한 storage strategy를 `.devcontainer/README.md`에 문서화해야 한다.
- `templates/devcontainer/docker-compose.dev.yml`
  - 현재는 `..:${containerWorkspaceFolder}:cached` 워크스페이스 mount만 존재한다.
  - Claude/Codex config/state 보존용 named volume은 없다.
- `templates/devcontainer/README.md`
  - 예외 문서화 템플릿만 있고 실제 AI state 전략은 적혀 있지 않다.

### 스킬 공유

- `superpowers`
  - `dev-docs/archive/*`, `dev-docs/etc/*` 등의 과거 기록에는 등장한다.
  - 실제 설치 대상 템플릿, devcontainer 설정, PAH installer 구성에는 포함되어 있지 않다.
- `gstack`
  - 저장소 검색 결과 관련 설정이 없다.
- 현재 PAH installer의 범위
  - Cursor: `.cursor/rules/<domain>-standards.mdc`
  - Codex: `AGENTS.md` managed block
  - Claude: `CLAUDE.md` managed block 및 `.claude/settings.json` hooks
  - 위 구조는 규칙 배포이며, Codex/Claude/Cursor 공통 스킬 설치 체계는 아니다.

## 개선 제안

### 1. devcontainer 템플릿에 AI state named volume 추가

개인 하네스 템플릿의 기본 목표가 컨테이너 재빌드 후에도 로그인 및 대화 내역을 유지하는 것이라면, `templates/devcontainer/docker-compose.dev.yml`에 안정적인 named volume을 추가한다.

예시 방향:

```yaml
services:
  workspace:
    volumes:
      - ..:${containerWorkspaceFolder}:cached
      - ${localWorkspaceFolderBasename}-claude-config:/home/vscode/.claude
      - ${localWorkspaceFolderBasename}-claude-json:/home/vscode/.claude.json
      - ${localWorkspaceFolderBasename}-codex-config:/home/vscode/.codex

volumes:
  ${localWorkspaceFolderBasename}-claude-config:
  ${localWorkspaceFolderBasename}-claude-json:
  ${localWorkspaceFolderBasename}-codex-config:
```

주의: Docker Compose의 volume key에서 환경 변수 interpolation을 쓸 때 실제 지원 범위와 생성 결과를 `docker compose config`로 확인해야 한다. 필요하면 `initializeCommand.sh`에서 안정적인 slug 변수를 생성하는 방식이 더 안전하다.

### 2. `.devcontainer/README.md`에 선택한 AI state 전략 문서화

템플릿 README에 다음 내용을 기본으로 포함한다.

- 선택 전략: named volume
- 보존 대상:
  - `/home/vscode/.claude`
  - `/home/vscode/.claude.json`
  - `/home/vscode/.codex`
- 보안 영향: 프로젝트별 AI 로그인 state가 Docker named volume에 남는다.
- 초기화 방법: 필요한 경우 `docker volume rm <volume-name>`으로 제거한다.
- 검증 방법:
  - 컨테이너에서 Claude/Codex 로그인
  - rebuild 후 로그인 유지 확인
  - `docker compose -f .devcontainer/docker-compose.dev.yml config` 확인

### 3. CLI 버전 placeholder를 실제 검증 버전으로 교체

`templates/devcontainer/.env.example`의 `<validated-version>`을 실제 검증된 버전으로 바꾼다.

현재 문서는 version pinning을 요구하므로, placeholder는 scaffold 직후 기준으로는 미완성 상태이다.

### 4. 스킬 배포 모델을 별도 설계

`superpowers`, `gstack`을 Codex, Claude, Cursor에서 모두 쓰려면 PAH의 기존 rule-domain 모델과 별도의 skill-domain 또는 tool-skill 모델이 필요하다.

권장 방향:

- `skills/superpowers/`, `skills/gstack/` 또는 `templates/skills/`처럼 원본 위치를 만든다.
- 각 AI별 연결 방식을 명시한다.
  - Codex: Codex가 읽을 수 있는 skill instruction 또는 `AGENTS.md` 연결 문서
  - Claude: Claude Code skill 위치 또는 `CLAUDE.md` 연결 문서
  - Cursor: `.cursor/rules/*.mdc` 또는 Cursor에서 지원하는 rule/plugin 연결
- 설치 결과를 `pah verify`가 검증하도록 한다.
- 스킬이 실제 실행 도구인지, 지침 문서인지, MCP/plugin인지 구분한다.

### 5. 테스트 추가

현재 `tests/test_pah.sh`는 rules, hooks, devcontainer scaffold를 검증하지만 AI state named volume과 스킬 설치를 검증하지 않는다.

추가할 테스트:

- devcontainer scaffold 결과에 Claude/Codex named volume mount가 포함되는지
- `${devcontainerId}`가 volume name에 포함되지 않는지
- `.devcontainer/README.md`에 AI state storage strategy가 문서화되는지
- `superpowers`, `gstack` 설치 대상 파일이 생성되는지
- Codex, Claude, Cursor 각각의 연결 파일이 생성되는지

## 우선순위

1. Named volume 기반 AI state 보존을 devcontainer 템플릿에 추가한다.
2. `.devcontainer/README.md`에 선택한 storage strategy를 기본 문서화한다.
3. `.env.example`의 Claude/Codex CLI 버전을 실제 검증 버전으로 고정한다.
4. `superpowers`, `gstack`의 원본 위치와 AI별 설치 방식을 설계한다.
5. 위 내용을 `tests/test_pah.sh`에 회귀 테스트로 추가한다.

## 최종 결론

현재 Personal-Agent-Harness는 Codex, Claude, Cursor에 규칙을 배포하는 구조는 갖추고 있다. 그러나 로그인 및 대화 내역 유지를 위한 named volume 기반 config/state 관리는 아직 구현되어 있지 않다. 또한 `superpowers`, `gstack`을 세 AI에서 공통으로 사용할 수 있게 설치하는 기능도 현재 범위에는 포함되어 있지 않다.
