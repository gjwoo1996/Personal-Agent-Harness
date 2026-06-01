# 하네스 개발·테스트

> **관련 문서:** [문서 목록](README.md) · [CLI 레퍼런스](reference.md) · [README](../README.md)

`Personal-Agent-Harness` 저장소 자체를 수정·검증할 때 참고합니다.

## 저장소 구조

```text
Personal-Agent-Harness/
├── bin/pah              # 메인 CLI
├── setup.sh             # 대상 프로젝트 첫 적용
├── update.sh            # 대상 프로젝트 업데이트
├── install.sh           # pah install 래퍼
├── standards/           # 표준 문서 원본
├── templates/
│   ├── stubs/           # Cursor, AGENTS.md, CLAUDE.md 템플릿
│   └── devcontainer/    # 선택적 devcontainer 스캐폴드
├── docs/                # 사용자·개발 문서
└── tests/test_pah.sh    # smoke test
```

## 테스트 실행

```bash
cd Personal-Agent-Harness
bash tests/test_pah.sh
```

테스트는 다음을 검증합니다.

- `pah install` / `verify` / `status`
- 기존 `AGENTS.md`와의 managed block 병합
- devcontainer + gitignore 컴포넌트
- `setup.sh` / `update.sh` (install + verify 경로)

## 변경 후 확인 순서

1. `bash tests/test_pah.sh`
2. 임시 프로젝트에서 수동 시나리오:

```bash
mkdir -p /tmp/pah-demo && cd /tmp/pah-demo
git clone <repo-url> Personal-Agent-Harness && ./Personal-Agent-Harness/setup.sh
./Personal-Agent-Harness/update.sh
```

## 이 저장소가 제공하는 것

- AI용 영문 단일 원본: `standards/devcontainer/devcontainer-standards.md`
- 사람용 한글 번역본: `standards/devcontainer/devcontainer-standards.ko.md`
- Cursor rule, Codex/Claude managed block 템플릿
- 선택적 `.devcontainer` 스캐폴드
- `pah` CLI 및 setup/update 진입점
