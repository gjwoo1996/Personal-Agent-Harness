# Agent Instructions

## Personal-Agent-Harness Development

When modifying **this repository** (adding rule domains, changing `bin/pah`, stubs, or standards), first read:

- `dev-docs/internal/adding-rule-domains.md`
- `dev-docs/internal/development.md`

These are harness-internal docs. They are **not** installed to target projects by `pah install`.

Do not confuse harness development with applying the harness to other projects. Target-project work uses `setup.sh`, `update.sh`, and devcontainer standards.

After harness changes, run:

```bash
bash tests/test_pah.sh
```

## 커밋 규칙

이 규칙은 **이 저장소(Personal-Agent-Harness)를 개발할 때만** 적용되며 대상 프로젝트에는 배포되지 않습니다. 우선순위: 직접적인 사용자 지시 > 이 규칙 > `git-workflow` 표준.

- **메시지**: Conventional 접두사(`feat`/`fix`/`docs`/`refactor`/`test`/`chore`/`style`)를 유지하되 요약·본문은 반드시 한글로 작성합니다. 예) `feat: 사용자 설치 스크립트 추가`
- **분할**: 변경을 성격별로 나눠 여러 커밋으로 작성합니다. 독립적인 기능/수정/문서/리팩터/테스트 변경은 분리하고, 모든 수정사항을 하나의 커밋에 몰아넣지 않습니다.
- **main merge**: `main` 브랜치로의 merge는 사용자의 명시적 동의 없이는 절대 하지 않습니다.
- **push**: push는 사용자가 명시적으로 요청했을 때만 실행합니다.
