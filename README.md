# Personal-Agent-Harness

개인 개발 표준과 AI 에이전트 규칙을 프로젝트에 적용하는 하네스입니다.

기본 `rules` 설치에는 devcontainer와 git-workflow 규칙 도메인이 포함됩니다.

## 사용법

대상 **프로젝트 루트**에서 실행합니다.

### 첫 적용

```bash
git clone <your-repo-url> Personal-Agent-Harness && ./Personal-Agent-Harness/setup.sh
```

### 업데이트

```bash
./Personal-Agent-Harness/update.sh
```

## 문서

| 문서 | 내용 |
|------|------|
| [docs/README.md](docs/README.md) | 전체 문서 목록 |
| [docs/usage.md](docs/usage.md) | 상세 사용법·고급 옵션·커밋 가이드 |
| [docs/how-it-works.md](docs/how-it-works.md) | copy mode, managed block, 규칙 우선순위 |
| [docs/reference.md](docs/reference.md) | `pah` CLI 레퍼런스, 설치 결과, verify 항목 |
| [docs/troubleshooting.md](docs/troubleshooting.md) | 문제 해결, 백업 복구 |
| [docs/development.md](docs/development.md) | 하네스 개발·테스트 |
