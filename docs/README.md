# 문서 인덱스

> **관련 문서:** [README](../README.md)

`Personal-Agent-Harness` 문서, 표준, 템플릿을 빠르게 찾기 위한 목록입니다.

## 사용법

| 문서 | 내용 |
|------|------|
| [../README.md](../README.md) | 첫 적용과 업데이트 한 줄 사용법 |
| [usage.md](./usage.md) | 상세 사용법, 고급 옵션, 커밋 가이드 |
| [how-it-works.md](./how-it-works.md) | registry, copy mode, managed block, 규칙 우선순위 |
| [reference.md](./reference.md) | `pah` CLI, 설치 결과, verify 항목 |
| [troubleshooting.md](./troubleshooting.md) | 문제 해결, 백업 복구 |

## 하네스 개발

아래 문서는 `Personal-Agent-Harness` 저장소를 수정할 때만 참고합니다. 대상 프로젝트에 복사되지 않습니다.

| 문서 | 내용 |
|------|------|
| [internal/README.md](./internal/README.md) | 내부 개발 문서 목록 |
| [internal/development.md](./internal/development.md) | 테스트, 변경 후 확인 순서, monorepo `harness-dev` 설정 |
| [internal/adding-rule-domains.md](./internal/adding-rule-domains.md) | registry 기반 규칙 도메인 추가 절차 |

## 이력 아카이브

아래 문서는 과거 설계, 구현 계획, 리뷰, handoff 기록입니다. 현재 사용법은 위의 사용자 문서와 하네스 개발 문서를 우선합니다.

| 폴더 | 내용 |
|------|------|
| [archive/README.md](./archive/README.md) | 이력 아카이브 안내 |
| [archive/specs/](./archive/specs/) | 설계 스펙 기록 |
| [archive/plans/](./archive/plans/) | 구현 계획 기록 |
| [archive/reviews/](./archive/reviews/) | 분석·리뷰 기록 |
| [archive/handoffs/](./archive/handoffs/) | 작업 인수인계 기록 |

## 진입점 스크립트

| 스크립트 | 용도 |
|----------|------|
| [../setup.sh](../setup.sh) | 대상 프로젝트 첫 적용 |
| [../update.sh](../update.sh) | 하네스 갱신 반영 |
| [../bin/pah](../bin/pah) | 저수준 CLI (`install`/`init`/`update`/`verify`/`status`) |

## 규칙 도메인 원본

기본 도메인은 [../config/rule-domains.txt](../config/rule-domains.txt)에 등록됩니다.

| 도메인 | 영문 표준 | 한글 번역본 |
|--------|-----------|-------------|
| `devcontainer` | [devcontainer-standards.md](../standards/devcontainer/devcontainer-standards.md) | [devcontainer-standards.ko.md](../standards/devcontainer/devcontainer-standards.ko.md) |
| `git-workflow` | [git-workflow-standards.md](../standards/git-workflow/git-workflow-standards.md) | [git-workflow-standards.ko.md](../standards/git-workflow/git-workflow-standards.ko.md) |

## 템플릿

- [../templates/stubs/agent-blocks/](../templates/stubs/agent-blocks/): 도메인별 Codex/Claude managed block 단일 원본
- [../templates/stubs/cursor/](../templates/stubs/cursor/): 도메인별 Cursor rule
- [../templates/devcontainer/](../templates/devcontainer/): 선택적 devcontainer 스캐폴드
- [../templates/harness-dev/](../templates/harness-dev/): 선택적 monorepo 하네스 개발 rule

## 검증

- [../tests/test_pah.sh](../tests/test_pah.sh): install, verify, setup/update smoke test
