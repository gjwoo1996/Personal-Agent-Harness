# 문서 인덱스

> **관련 문서:** [README](../README.md)

`Personal-Agent-Harness` 문서·표준·템플릿을 빠르게 찾기 위한 목록입니다.

## 사용법

| 문서 | 내용 |
|------|------|
| [../README.md](../README.md) | **첫 적용·업데이트** 한 줄 사용법 |
| [usage.md](./usage.md) | 상세 사용법, 고급 옵션, 커밋 가이드 |
| [how-it-works.md](./how-it-works.md) | copy mode, AI 연결, managed block, 규칙 우선순위 |
| [reference.md](./reference.md) | `pah` CLI, 설치 결과, verify 항목 |
| [troubleshooting.md](./troubleshooting.md) | 문제 해결, 백업 복구 |
| [development.md](./development.md) | 하네스 개발·테스트 |

## 진입점 스크립트

| 스크립트 | 용도 |
|----------|------|
| [../setup.sh](../setup.sh) | 대상 프로젝트 첫 적용 |
| [../update.sh](../update.sh) | 하네스 갱신 반영 |
| [../install.sh](../install.sh) | `pah install` 래퍼 (고급 옵션) |
| [../bin/pah](../bin/pah) | 저수준 CLI |

## 표준 문서

- [../standards/devcontainer/devcontainer-standards.ko.md](../standards/devcontainer/devcontainer-standards.ko.md): 사람용 한글 번역본
- [../standards/devcontainer/devcontainer-standards.md](../standards/devcontainer/devcontainer-standards.md): AI용 영문 원본

## 템플릿

- [../templates/stubs/AGENTS.md](../templates/stubs/AGENTS.md): Codex managed block
- [../templates/stubs/CLAUDE.md](../templates/stubs/CLAUDE.md): Claude managed block
- [../templates/stubs/cursor/devcontainer-standards.mdc](../templates/stubs/cursor/devcontainer-standards.mdc): Cursor rule
- [../templates/devcontainer/](../templates/devcontainer/): 선택적 devcontainer 스캐폴드

## 검증

- [../tests/test_pah.sh](../tests/test_pah.sh): install, verify, setup/update smoke test
