# 문제 해결

> **관련 문서:** [문서 목록](README.md) · [사용법](usage.md) · [CLI 레퍼런스](reference.md)

먼저 verify와 dry-run을 실행합니다.

```bash
npx personal-agent-harness verify .
npx personal-agent-harness install . --dry-run
```

갱신 전 파일은 `.harness/backups/<timestamp>/`에서 확인할 수 있습니다.

## Registry 오류

`config/rule-domains.txt`가 없거나 비어 있으면 기본 `rules` 설치를 진행할 수 없습니다.

- `missing required file`: 등록 도메인의 패키지 파일이 누락됨
- `duplicate rule domain id`: 같은 ID가 두 번 등록됨
- `invalid rule domain id`: ID가 소문자 kebab-case가 아님

미완성 도메인은 registry에서 제거하고 패키지를 완성한 뒤 다시 등록합니다. `standards/*` 자동 탐색은 사용하지 않습니다.

## Managed block 손상

`AGENTS.md`와 `CLAUDE.md`의 각 `pah:<domain>` block은 start/end marker가 정확히 한 쌍이고 순서가 맞아야 합니다.

```markdown
<!-- pah:git-workflow:start -->
...
<!-- pah:git-workflow:end -->
```

중복, 누락, 순서 뒤바뀜을 수정한 뒤 install을 다시 실행합니다. 도메인 block은 서로 독립적으로 갱신됩니다.

## AI stub이 ko 문서를 참조

AI stub은 `docs/<domain>/<domain>-standards.md`만 규칙 출처로 참조해야 합니다. `*.ko.md` 참조를 제거한 뒤 install 또는 update를 다시 실행합니다.

## Manifest 불일치

`verify`는 현재 설치 파일에서 canonical manifest를 다시 생성해 `.harness/manifest.json`과 비교합니다. checksum, 도메인 순서, 관리 파일 목록이 다르면 install 또는 update를 다시 실행합니다.

```bash
npx personal-agent-harness@latest update .
```

## Nested harness / 중첩 git 저장소

프로젝트 안에 `Personal-Agent-Harness/.git`이 있으면 중첩 git 저장소가 생깁니다.

```bash
npx personal-agent-harness init . --clean-nested
```

또는 `gitignore` 컴포넌트로 `Personal-Agent-Harness/`를 무시합니다.

```bash
npx personal-agent-harness install . --components gitignore
```

## 하네스 업데이트 확인

설치된 manifest 버전과 현재 실행 중인 npm CLI 버전을 비교합니다.

```bash
npx personal-agent-harness@latest status .
```

`update available`이 표시되면 다음 명령을 실행합니다.

```bash
npx personal-agent-harness@latest update .
```

## Legacy git checkout 사용 시

이 섹션은 PAH를 대상 프로젝트 밖에 의도적으로 clone해서 쓰는 git checkout 경로에만 해당합니다. 일반 대상 프로젝트에는 npm/npx 명령을 사용합니다.

`update.sh`는 `git pull --ff-only`를 사용합니다. harness clone의 로컬 커밋이나 원격과의 diverge 여부를 확인합니다.

```bash
~/.local/share/personal-agent-harness/update.sh .
```

## Devcontainer 스캐폴드가 없음

스캐폴드는 기본 `rules` 설치와 별도입니다.

```bash
npx personal-agent-harness install . --components rules,devcontainer,gitignore
```
