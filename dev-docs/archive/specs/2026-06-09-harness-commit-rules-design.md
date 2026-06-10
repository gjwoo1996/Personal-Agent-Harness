# 하네스 개발 전용 커밋 규칙 설계 (Harness Commit Rules)

> **문서 유형:** 설계 스펙. `pah install` 대상이 아닙니다.
> **작성일:** 2026-06-09

## 배경

하네스 저장소 **자체를 개발할 때만** AI 에이전트가 따라야 할 커밋 규칙이 필요하다.
이 규칙은 대상(제품) 프로젝트로 배포되면 안 된다.

`bin/pah`의 설치 로직을 확인한 결과, `pah install`은 다음 소스만 대상 프로젝트로
복사한다.

- `standards/<domain>/`
- `templates/stubs/cursor/<domain>-standards.mdc`
- `templates/stubs/agent-blocks/<domain>.md`
- (옵션) `templates/harness-dev/`, devcontainer/gitignore 템플릿

그리고 `config/rule-domains.txt`에 등록된 도메인(`devcontainer`, `git-workflow`)만
반복 설치된다. 설치기는 **저장소 루트의 `AGENTS.md`나 루트 `.cursor/rules/*.mdc`를
읽지 않는다.** 따라서 이 두 위치에 규칙을 두면 제품에 영향이 없다.

## 결정 사항 (사용자 합의)

- 규칙 성격: 개발 워크플로(커밋 규칙).
- 적용 대상: Cursor + Codex/Claude 모두.
- 커밋 메시지 형식: Conventional 접두사 유지 + 요약·본문은 한글.
- 격리 가드레일: `config/rule-domains.txt` 미등록, `templates/stubs/` 미수정.
- 우선순위: 직접적인 사용자 지시 > 이 규칙 > 기존 `git-workflow` 표준.

## 작업 범위

### 1. 신규 Cursor 규칙 — `.cursor/rules/harness-commit-rules.mdc`

frontmatter:

- `harness-internal: true` (기존 `harness-development.mdc`와 동일한 내부 전용 표식)
- `alwaysApply: true` (커밋 시점은 특정 파일 편집과 무관하므로 globs 대신 항상 적용)

본문에 아래 4개 규칙을 한글로 기술한다.

### 2. 루트 `AGENTS.md` — `## 커밋 규칙` 섹션 추가

Codex/Claude용으로 동일한 4개 규칙을 추가한다. 기존 `## Personal-Agent-Harness
Development` 섹션은 보존한다.

## 규칙 내용

1. **메시지**: Conventional 접두사(`feat`/`fix`/`docs`/`refactor`/`test`/`chore`/`style`)를
   유지하되 요약·본문은 한글로 작성한다. 예) `feat: 사용자 설치 스크립트 추가`
2. **분할**: 변경을 성격별로 나눠 여러 커밋으로 작성한다. 서로 독립적인
   기능/수정/문서/리팩터/테스트 변경은 분리하고, 한 커밋에 전부 몰지 않는다.
3. **main merge**: `main` 브랜치 merge는 사용자의 명시적 동의 없이는 절대 하지 않는다.
4. **push**: push는 사용자가 명시적으로 요청했을 때만 실행한다.

기존 `git-workflow` 표준의 Commit Grouping·History Safety를 보강하는 관계이며,
충돌 시 우선순위는 위 "결정 사항"을 따른다.

## 하지 않는 것 (YAGNI / 범위 보호)

- `config/rule-domains.txt`에 도메인 등록
- `templates/stubs/`·`standards/` 신규 파일 추가 (배포 경로)
- 기존 `git-workflow` 표준 문서 변경
- `CLAUDE.md` 신규 생성 (저장소 루트에 존재하지 않으며, AI는 `AGENTS.md`를 읽음)

## 검증

- `config/rule-domains.txt`에 신규 도메인이 없는지 확인
- `bin/pah`가 루트 `AGENTS.md`·루트 `.cursor/rules/`를 복사 소스로 참조하지 않음을 재확인
- `bash tests/test_pah.sh` 회귀 (저장소 로컬 파일 추가가 설치/검증에 영향 없음을 확인)
