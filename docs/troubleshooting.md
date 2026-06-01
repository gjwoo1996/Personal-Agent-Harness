# 문제 해결

> **관련 문서:** [문서 목록](README.md) · [사용법](usage.md) · [CLI 레퍼런스](reference.md) · [README](../README.md)

하네스 적용·업데이트 중 문제가 생겼을 때 확인할 순서입니다.

## 1. verify 실행

```bash
./Personal-Agent-Harness/bin/pah verify .
```

실패 메시지에 누락된 파일이나 잘못된 stub 참조가 표시됩니다.

## 2. manifest 확인

```bash
cat .harness/manifest.json
```

하네스 버전, 설치 모드, 관리 파일 목록, 표준 문서 checksum을 확인합니다.

## 3. 백업에서 이전 버전 확인

install 또는 update 시 기존 관리 파일은 갱신 전에 백업됩니다.

```text
.harness/backups/<timestamp>/
```

가장 최근 타임스탬프 디렉터리에서 이전 파일을 찾아 수동 복구할 수 있습니다.

## 4. dry-run으로 변경 미리보기

```bash
./Personal-Agent-Harness/bin/pah install . --dry-run
```

실제 변경 없이 어떤 파일이 생성·수정될지 확인합니다.

## 자주 발생하는 상황

### `update.sh`에서 `git pull` 실패

`update.sh`는 `git pull --ff-only`를 사용합니다. 로컬 harness clone에 커밋이 있거나 원격과 diverge하면 실패합니다.

- harness clone을 수정하지 않았는지 확인
- 필요하면 `Personal-Agent-Harness/`를 삭제 후 다시 clone

### 기존 `AGENTS.md` / `CLAUDE.md`와 충돌

installer는 managed block만 갱신합니다. block 밖 내용은 유지됩니다. block 마커(`<!-- pah:devcontainer:start -->`)가 손상되었으면 [작동 방식](how-it-works.md)의 Managed block 섹션을 참고해 수정하세요.

### devcontainer 스캐폴드가 설치되지 않음

기본 `setup.sh` / `update.sh`는 `rules`만 설치합니다. 스캐폴드가 필요하면 [사용법](usage.md)의 선택적 devcontainer 섹션을 참고하세요.

### verify: AI stub이 ko.md를 참조

AI stub은 영문 표준(`devcontainer-standards.md`)만 규칙 출처로 참조해야 합니다. stub 파일을 수동 편집했다면 ko.md 참조를 제거하고 `./Personal-Agent-Harness/setup.sh` 또는 `update.sh`로 다시 적용하세요.
