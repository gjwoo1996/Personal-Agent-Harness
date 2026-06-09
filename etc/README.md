# etc — 작업 정리 문서

Personal-Agent-Harness 워크플로우 개선 작업(2026-06-09~)의 요청·진행·잔여 사항을 정리한 폴더입니다.

## 문서 목록

| 문서 | 내용 |
|------|------|
| [01-요청-배경.md](01-요청-배경.md) | 사용자가 처음 요청한 문제와 목표 |
| [02-논의-및-결정.md](02-논의-및-결정.md) | brainstorming, 접근법 비교, 최종 결정 |
| [03-진행-완료.md](03-진행-완료.md) | 커밋·미커밋 포함 현재까지 완료된 작업 |
| [04-남은-작업.md](04-남은-작업.md) | 아직 하지 않은 작업과 우선순위 |
| [05-npm-배포-가이드.md](05-npm-배포-가이드.md) | npm 계정, publish, npx 사용 절차 |
| [06-사용법-요약.md](06-사용법-요약.md) | 변경 전/후 사용법 한눈에 보기 |

## 관련 기존 문서

| 경로 | 내용 |
|------|------|
| `docs/superpowers/specs/2026-06-09-external-harness-workflow-design.md` | 외부 워크플로우 설계 스펙 |
| `docs/superpowers/plans/2026-06-09-external-harness-workflow.md` | 외부 워크플로우 구현 계획 |
| `docs/superpowers/plans/` (npm CLI) | npm 전환 계획은 본 폴더 `04-남은-작업.md` 및 대화 기록 참고 |

## 현재 브랜치

`main` — `feat/external-harness-workflow` 작업 머지 완료

## 한 줄 요약

**문제:** 프로젝트 안에 harness를 clone하면 중첩 git + 불필요한 폴더 발생  
**해결 방향:** copy mode 유지 + 프로젝트 밖 도구화 → **npm/npx CLI**로 `init`/`update`  
**상태:** main 머지 완료, npm `0.3.1` 배포 완료

## 현재 주의점

작업 중 npm/npx 배포 전환 작업과 별개로 **하네스 저장소 개발용 `.devcontainer/` 작업**도 함께 있었다. 둘 다 npm publish 흐름과 관련은 있지만 변경 성격이 달라 커밋·리뷰·롤백 단위를 분리했다.

분리된 커밋:

1. `5b4d85b` — npm 패키지와 `pah init/update` CLI 변경
2. `184ed50` — 하네스 저장소 자체의 개발용 `.devcontainer/`
3. `fd8e810` — 대상 프로젝트에 복사되는 `templates/devcontainer/` 변경
4. `1345dc8` — npm `.bin` symlink 실행 수정, `0.3.1` 패치 배포 준비

## npm 배포 상태

- `0.3.0`: publish 성공했으나 npm `.bin` symlink 실행 오류가 있어 사용 비권장
- `0.3.1`: publish 성공, `npx personal-agent-harness@0.3.1 init/verify/status` 스모크 테스트 통과
