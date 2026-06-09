# 문서 정리 설계 (Docs Cleanup)

> **문서 유형:** 설계 스펙. `pah install` 대상이 아닙니다.
> **작성일:** 2026-06-09
> **대상 버전:** v0.3.1

## 배경

전체 문서 31개를 실제 코드(`bin/pah`, `package.json`, git 상태)와 대조한 결과,
사실 오류·내부 모순·오래된 기록이 주로 `etc/`, `docs/superpowers/`, `docs/reviews/`에
몰려 있음을 확인했다. 사용자용 핵심 문서(`README`, `docs/usage`, `how-it-works`,
`reference`, `troubleshooting`, `adding-rule-domains`)와 표준/스텁은 정확했다.

## 결정 사항 (사용자 합의)

- 폴더 구조는 유지한다. 재배치·파일 삭제 없음.
- 사실 오류·내부 모순은 모두 수정한다.
- 이력성 문서(리뷰·플랜)는 보존하되 현재 상태(v0.3.1)에 맞게 전면 갱신한다.
- README는 제품(사용자) 진입 문서로 축소하고 메인테이너/개발 정보는 `docs/`로 위임한다.
- `bash` 최소 버전 표기는 `bash 3.2+`로 통일한다 (스크립트에 bash 4 전용 문법 없음, 검증 완료).

## 작업 범위

### 1. README.md — 제품용으로 축소

| 변경 | 내용 |
|------|------|
| 제거 | `## npm publish (메인테이너)` 섹션 (내용은 `docs/development.md`에 존재) |
| 제거 | `## git checkout (하네스 개발·npm 없이 사용)` 섹션 (내용은 `docs/usage.md`에 존재) |
| 제거 | 환경 요구사항 표의 `git` 행 (npm/npx 사용엔 불필요) |
| 제거 | 문서 표의 `docs/development.md` 행 |
| 추가 | 맨 아래 한 줄: 하네스 개발·배포는 `docs/development.md` 참고 |

근거: README는 GitHub 랜딩이자 사용자 진입 문서이며, 제거 대상 내용은 모두
`docs/usage.md`·`docs/development.md`에 더 자세히 중복돼 있다.

### 2. 명백한 사실 오류·내부 모순 수정

| 파일 | 위치 | 수정 |
|------|------|------|
| `etc/05-npm-배포-가이드.md` | 107행 | 포함 파일 목록에서 `install.sh` 제거 |
| `etc/03-진행-완료.md` | 66행 | `files` 목록에서 `install.sh` 제거 |
| `etc/README.md` | 24~32, 45~48 | "main 미머지/원격 push 남음" → 머지 완료 상태로 갱신 |
| `etc/06-사용법-요약.md` | 60행 | `bash 4+` → `bash 3.2+` |
| `docs/superpowers/specs/2026-06-09-harness-devcontainer-design.md` | 14행 | `bash 4+` → `bash 3.2+` |
| `docs/development.md` | 89~90행 | 하드코딩 `/home/gjwoo96/...` → `<PAH_HOME>/...` 일반화 |
| `etc/02-논의-및-결정.md` | 49행 | 과장된 별점 수치 완화 또는 보정 |

기준값: `package.json`의 `files`는 `bin/pah`, `bin/pah-entry`, `bootstrap.sh`,
`setup.sh`, `update.sh`, `VERSION`, `config/`, `standards/`, `templates/`이며
`install.sh`는 저장소에 존재하지 않는다.

### 3. 이력성 문서 전면 갱신

| 파일 | 작업 |
|------|------|
| `docs/reviews/2026-06-02-harness-engineering-review.md` | v0.3.1 기준 재분석. 이미 구현된 항목 반영: 2-1 enforcement hooks(존재), 2-2 `pah status` 버전 비교(존재), 2-5 `pah update` 서브커맨드(존재). 종합 평가표·우선순위표 갱신, CI 예시를 npm 명령으로 교체, 대상 버전·날짜 갱신 |
| `docs/superpowers/plans/2026-06-09-npm-transition-cleanup.md` | 완료 상태 반영: 체크박스 완료 처리, `install.sh` 포함/미포함 모순 정리(최종 = 미포함), 상단에 closed 명시 |

### 4. 부수 이력 문서 일관성 보정 (전면 재작성 아님)

| 파일 | 작업 |
|------|------|
| `docs/superpowers/plans/2026-06-09-external-harness-workflow.md` | `install.sh` 언급·`/home/gjwoo96/...` 경로를 사실에 맞게 보정 |
| `docs/superpowers/plans/2026-06-02-rule-domain-registry-and-git-workflow.md` | 동일 |
| `docs/superpowers/handoffs/2026-06-02-rule-domain-registry-and-git-workflow.md` | 동일 |

## 하지 않는 것 (YAGNI / 범위 보호)

- 폴더 구조 재배치·이동·파일 삭제
- 정확한 사용자용 문서(`docs/usage`, `how-it-works`, `reference`, `troubleshooting`,
  `adding-rule-domains`)·표준 문서·스텁 변경
- 새 문서 추가(본 spec 제외)

## 검증

- 수정 후 `grep`으로 `install.sh`, `bash 4+`, `/home/gjwoo96` 잔존 여부 확인
- README의 링크 대상 파일 존재 확인
- `bash tests/test_pah.sh` (문서 변경이 코드에 영향 없음을 확인하는 회귀 안전망)
