# Git 전용 배포 전환

npm registry 배포를 중단하고, GitHub를 유일한 배포 채널로 쓰는 작업 문서입니다.

| 문서 | 내용 |
|------|------|
| [2026-07-28-git-only-distribution-roadmap.md](./2026-07-28-git-only-distribution-roadmap.md) | C안 로드맵. **§0에 고정 결정·핸드오프** 있음 |

## 한 줄 요약

**유지:** `package.json` + `bin` + copy mode
**중단:** `npm publish` / registry `npx personal-agent-harness`
**권장:** `npx --yes github:gjwoo1996/Personal-Agent-Harness` 또는 git dependency

**병행 Phase 7:** Cursor/Bun/gh 영속화 + 컨테이너 git 인증

## 다른 세션

로드맵 **§0** 복사용 지시 + 고정 결정표를 따른다. 배포 옵션을 사용자에게 다시 묻지 말 것.
