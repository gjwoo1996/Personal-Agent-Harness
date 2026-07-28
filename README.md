# Personal-Agent-Harness

개인 개발 표준과 AI 에이전트 규칙을 프로젝트에 적용하는 하네스입니다.

기본 `rules` 설치에는 devcontainer와 git-workflow 규칙 도메인이 포함됩니다.

## 환경 요구사항

| 항목 | 필수 여부 | 용도 |
|------|-----------|------|
| Node.js 24 LTS | **권장** | `npx`로 CLI 실행 (최소 22) |
| bash 3.2+ | 필수 | CLI 실행 |
| jq | **권장** | enforcement hooks 설치 — 없으면 advisory 모드로 동작 |
| Claude Code | 권장 | `.claude/settings.json` hooks 실행 |

> **jq 없을 때:** `rules`는 정상 설치되고, hooks 설치는 건너뜁니다(`WARNING: jq not found` 출력). AI가 표준 문서를 자발적으로 읽는 advisory 방식으로만 동작합니다.
>
> **jq 설치:** `brew install jq` (macOS) / `apt-get install jq` (Ubuntu/Debian)

## 사용법 (GitHub `npx` — 권장)

대상 **프로젝트 루트**에서 실행합니다. 프로젝트 안에 harness 저장소가 생기지 않습니다.

> npmjs의 `personal-agent-harness`는 더 이상 갱신되지 않습니다. GitHub를 사용하세요.

### 첫 적용

```bash
npx --yes github:gjwoo1996/Personal-Agent-Harness init .
```

### 업데이트

```bash
npx --yes github:gjwoo1996/Personal-Agent-Harness update .
```

### 검증·상태

```bash
npx --yes github:gjwoo1996/Personal-Agent-Harness verify .
npx --yes github:gjwoo1996/Personal-Agent-Harness status .
```

재현 가능한 설치가 필요하면 릴리스 태그를 고정합니다.

```bash
npx --yes github:gjwoo1996/Personal-Agent-Harness#vX.Y.Z update .
```

### 프로젝트 devDependency로 고정

```json
{
  "devDependencies": {
    "personal-agent-harness": "github:gjwoo1996/Personal-Agent-Harness#vX.Y.Z"
  }
}
```

```bash
npm install
npx pah init .
npx pah update .
```

자세한 내용은 [docs/usage.md](docs/usage.md)를 참고하세요.

## 문서

| 문서 | 내용 |
|------|------|
| [docs/README.md](docs/README.md) | 전체 문서 목록 |
| [docs/usage.md](docs/usage.md) | 상세 사용법·고급 옵션·커밋 가이드 |
| [docs/how-it-works.md](docs/how-it-works.md) | copy mode, managed block, 규칙 우선순위 |
| [docs/reference.md](docs/reference.md) | `pah` CLI 레퍼런스, 설치 결과, verify 항목 |
| [docs/troubleshooting.md](docs/troubleshooting.md) | 문제 해결, 백업 복구 |

하네스 개발·태그 릴리스는 [dev-docs/internal/development.md](dev-docs/internal/development.md)를 참고하세요.
