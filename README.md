# Personal-Agent-Harness

개인 개발 표준과 AI 에이전트 규칙을 프로젝트에 적용하는 하네스입니다.

기본 `rules` 설치에는 devcontainer와 git-workflow 규칙 도메인이 포함됩니다.

## 환경 요구사항

| 항목 | 필수 여부 | 용도 |
|------|-----------|------|
| bash 4+ | 필수 | CLI 실행 |
| git | 필수 | `update.sh` pull, 대상 프로젝트 관리 |
| jq | **권장** | enforcement hooks 설치 — 없으면 advisory 모드로 동작 |
| Claude Code | 권장 | `.claude/settings.json` hooks 실행 |

> **jq 없을 때:** `rules`는 정상 설치되고, hooks 설치는 건너뜁니다(`WARNING: jq not found` 출력). AI가 표준 문서를 자발적으로 읽는 advisory 방식으로만 동작합니다.
>
> **jq 설치:** `brew install jq` (macOS) / `apt-get install jq` (Ubuntu/Debian)

## 사용법

하네스 소스는 프로젝트 밖 `PAH_HOME`(기본 `~/.local/share/personal-agent-harness`)에 한 번만 clone합니다. 대상 프로젝트에는 복사된 규칙만 남습니다.

### 첫 적용

```bash
git clone <your-repo-url> ~/.local/share/personal-agent-harness
~/.local/share/personal-agent-harness/bootstrap.sh /path/to/my-project
```

### 업데이트

```bash
~/.local/share/personal-agent-harness/update.sh /path/to/my-project
```

> **Legacy:** 예전처럼 프로젝트 안에 clone하는 방법은 [docs/usage.md#legacy-in-project-clone](docs/usage.md#legacy-in-project-clone)을 참고하세요.

## 문서

| 문서 | 내용 |
|------|------|
| [docs/README.md](docs/README.md) | 전체 문서 목록 |
| [docs/usage.md](docs/usage.md) | 상세 사용법·고급 옵션·커밋 가이드 |
| [docs/how-it-works.md](docs/how-it-works.md) | copy mode, managed block, 규칙 우선순위 |
| [docs/reference.md](docs/reference.md) | `pah` CLI 레퍼런스, 설치 결과, verify 항목 |
| [docs/troubleshooting.md](docs/troubleshooting.md) | 문제 해결, 백업 복구 |
| [docs/development.md](docs/development.md) | 하네스 개발·테스트 |
