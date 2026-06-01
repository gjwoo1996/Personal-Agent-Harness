# 문서 인덱스

`Personal-Agent-Harness`에서 필요한 문서를 빠르게 찾기 위한 인덱스입니다.

## 먼저 볼 문서

- [`../README.md`](../README.md): 프로젝트 개요와 명령어 요약
- [`usage.md`](./usage.md): 하네스를 프로젝트에 적용하는 단계별 사용법
- [`how-it-works.md`](./how-it-works.md): 표준 문서가 복사되고 AI가 규칙을 찾는 과정

## 표준 문서

- [`../standards/devcontainer/devcontainer-standards.ko.md`](../standards/devcontainer/devcontainer-standards.ko.md): 사람이 읽는 한글 번역본
- [`../standards/devcontainer/devcontainer-standards.md`](../standards/devcontainer/devcontainer-standards.md): AI 에이전트가 읽는 영문 원본

## 템플릿

- [`../templates/stubs/AGENTS.md`](../templates/stubs/AGENTS.md): Codex용 managed block 템플릿
- [`../templates/stubs/CLAUDE.md`](../templates/stubs/CLAUDE.md): Claude용 managed block 템플릿
- [`../templates/stubs/cursor/devcontainer-standards.mdc`](../templates/stubs/cursor/devcontainer-standards.mdc): Cursor rule 템플릿
- [`../templates/devcontainer/`](../templates/devcontainer/): 선택적으로 복사하는 devcontainer 스캐폴드

## 명령어와 검증

- [`../bin/pah`](../bin/pah): 메인 CLI
- [`../install.sh`](../install.sh): `pah install` 편의 래퍼
- [`../tests/test_pah.sh`](../tests/test_pah.sh): install, verify, scaffold 동작을 확인하는 smoke test
