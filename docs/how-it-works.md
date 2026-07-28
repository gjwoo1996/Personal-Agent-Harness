# Personal-Agent-Harness 작동 방식

> **관련 문서:** [문서 목록](README.md) · [사용법](usage.md) · [CLI 레퍼런스](reference.md)

## Copy mode

GitHub 저장소가 권위 원본이며 대상 프로젝트는 GitHub에서 해석한 패키지의 관리되는 복사본을 받습니다.

```text
GitHub: gjwoo1996/Personal-Agent-Harness
  package.json (bin/files metadata)
  bin/pah
  config/rule-domains.txt
  standards/<domain>/
  templates/stubs/
        |
        | npx --yes github:gjwoo1996/Personal-Agent-Harness <command> <target>
        v
target-project/
  docs/<domain>/
  .cursor/rules/<domain>-standards.mdc
  AGENTS.md
  CLAUDE.md
  .harness/hooks/<domain>.hook.sh
  .claude/settings.json
  .harness/manifest.json
```

GitHub `npx` 사용 시 하네스 소스는 npm 캐시에 있고, 대상 프로젝트에는 copy mode 산출물만 남습니다. 로컬 git checkout은 하네스 개발이나 오프라인 사용 경로입니다.

기본 `rules` 설치에는 `devcontainer`, `git-workflow` 도메인이 포함됩니다. 기본 install/init/update 흐름은 `rules,hooks`를 설치하며, jq가 없으면 hooks만 건너뛰고 advisory 모드로 동작합니다.

## Copy mode를 기본으로 사용하는 이유

장점:

- 대상 프로젝트만 clone해도 규칙 문서가 함께 존재합니다.
- AI 에이전트가 하네스 저장소 위치를 알 필요가 없습니다.
- CI와 오프라인 환경에서도 프로젝트 내부 표준을 읽을 수 있습니다.
- managed block으로 기존 프로젝트 파일을 보존할 수 있습니다.

단점:

- 새 Git 태그의 내용은 대상 프로젝트에 자동 반영되지 않습니다. `npx --yes github:gjwoo1996/Personal-Agent-Harness#vX.Y.Z update .`를 실행해야 합니다.

## Rule Domain Registry

`config/rule-domains.txt`는 기본 도메인 registry입니다. 등록 순서가 install, manifest, verify 순서를 결정합니다.

각 등록 도메인은 다음 패키지를 가져야 합니다.

```text
standards/<domain>/<domain>-standards.md
standards/<domain>/<domain>-standards.ko.md
templates/stubs/agent-blocks/<domain>.md
templates/stubs/cursor/<domain>-standards.mdc
templates/stubs/hooks/<domain>.hook.sh  (선택)
```

registry는 의도적으로 명시적입니다. `standards/*`를 자동 탐색하지 않으므로 미완성 도메인은 등록 전까지 기본 설치에 포함되지 않습니다.

## AI 연결

- Cursor rule은 `docs/<domain>/<domain>-standards.md`를 참조합니다.
- `agent-blocks/<domain>.md` 단일 원본은 `AGENTS.md`와 `CLAUDE.md` 양쪽에 병합됩니다.
- hook stub이 있는 도메인은 `.harness/hooks/`에 설치되고 Claude Code `PreToolUse`에 연결됩니다.
- AI 연결 파일은 영문 표준만 규칙 출처로 사용합니다. `*.ko.md`는 사람용 번역입니다.

managed block은 도메인별로 독립 갱신됩니다.

```markdown
<!-- pah:devcontainer:start -->
...
<!-- pah:devcontainer:end -->

<!-- pah:git-workflow:start -->
...
<!-- pah:git-workflow:end -->
```

block 밖의 프로젝트 고유 내용은 보존됩니다.

## Manifest와 Verify

`.harness/manifest.json`의 `standards.<domain>.en`과 `standards.<domain>.ko`에는 설치 경로와 checksum이 기록됩니다. `ko` 항목은 `ai_readable: false`입니다.

`verify`는 등록 도메인의 파일, block marker, managed block 내용, 영문 참조, ko 오참조 여부를 검사합니다. 설치된 hook이 있으면 실행 권한과 Claude settings 연결도 확인합니다. 이어서 현재 설치 상태에서 canonical manifest를 다시 생성하고 기존 manifest와 완전히 일치하는지 확인합니다.

## 규칙 우선순위

각 도메인의 규칙 우선순위:

1. 사용자의 직접 지시
2. 프로젝트별 예외와 프로젝트 고유 규칙
3. `docs/<domain>/<domain>-standards.md`
4. 과거 참고 문서 또는 번역본

devcontainer 예외는 `.devcontainer/README.md`, git-workflow 예외는 `docs/git-workflow/README.md`에 기록합니다.

## 별도 컴포넌트

optional devcontainer 스캐폴드, `.gitignore` managed block, monorepo용 `harness-dev` rule은 registry 밖에서 별도로 유지됩니다.

```bash
npx --yes github:gjwoo1996/Personal-Agent-Harness install . --components rules,devcontainer,gitignore
npx --yes github:gjwoo1996/Personal-Agent-Harness install . --components harness-dev
```

## 업데이트

```text
1. 메인테이너가 VERSION과 같은 vX.Y.Z Git 태그를 push
2. 대상 프로젝트에서 npx --yes github:gjwoo1996/Personal-Agent-Harness#vX.Y.Z update .
3. CLI가 rules,hooks를 install한 뒤 verify 실행
4. 기존 관리 파일은 .harness/backups/<timestamp>/에 백업
```

로컬 git checkout에서 `update.sh`로 갱신하는 흐름은 하네스 개발·오프라인 경로입니다. 프로젝트 안 in-project clone은 legacy이며, `npx --yes github:gjwoo1996/Personal-Agent-Harness init . --clean-nested`로 마이그레이션합니다.

## 아직 하지 않는 일

- symlink 또는 submodule mode
- three-way merge
- 기존 커스텀 devcontainer 자동 마이그레이션
- verify 단계의 Docker build

이 항목들은 copy mode 흐름을 예측 가능하게 유지하기 위해 의도적으로 제외했습니다.
