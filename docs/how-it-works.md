# Personal-Agent-Harness 작동 방식

> **관련 문서:** [문서 목록](README.md) · [사용법](usage.md) · [CLI 레퍼런스](reference.md)

## Copy mode

하네스 저장소가 원본이며 대상 프로젝트는 관리되는 복사본을 받습니다.

```text
PAH_HOME/  (예: ~/.local/share/personal-agent-harness)
  config/rule-domains.txt
  standards/<domain>/
  templates/stubs/
        |
        | bootstrap.sh / setup.sh / update.sh <target>
        v
target-project/
  docs/<domain>/
  .cursor/rules/<domain>-standards.mdc
  AGENTS.md
  CLAUDE.md
  .harness/manifest.json
```

하네스 소스는 PAH_HOME(프로젝트 밖)에 둡니다. 대상 프로젝트는 copy mode 산출물만 유지합니다.

기본 `rules` 설치에는 `devcontainer`, `git-workflow` 도메인이 포함됩니다.

## Copy mode를 기본으로 사용하는 이유

장점:

- 대상 프로젝트만 clone해도 규칙 문서가 함께 존재합니다.
- AI 에이전트가 하네스 저장소 위치를 알 필요가 없습니다.
- CI와 오프라인 환경에서도 프로젝트 내부 표준을 읽을 수 있습니다.
- managed block으로 기존 프로젝트 파일을 보존할 수 있습니다.

단점:

- 하네스 저장소 변경은 대상 프로젝트에 자동 반영되지 않습니다. `update.sh`를 실행해야 합니다.

## Rule Domain Registry

`config/rule-domains.txt`는 기본 도메인 registry입니다. 등록 순서가 install, manifest, verify 순서를 결정합니다.

각 등록 도메인은 다음 패키지를 가져야 합니다.

```text
standards/<domain>/<domain>-standards.md
standards/<domain>/<domain>-standards.ko.md
templates/stubs/agent-blocks/<domain>.md
templates/stubs/cursor/<domain>-standards.mdc
```

registry는 의도적으로 명시적입니다. `standards/*`를 자동 탐색하지 않으므로 미완성 도메인은 등록 전까지 기본 설치에 포함되지 않습니다.

## AI 연결

- Cursor rule은 `docs/<domain>/<domain>-standards.md`를 참조합니다.
- `agent-blocks/<domain>.md` 단일 원본은 `AGENTS.md`와 `CLAUDE.md` 양쪽에 병합됩니다.
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

`verify`는 등록 도메인의 파일, block marker, 영문 참조, ko 오참조 여부를 검사합니다. 이어서 현재 설치 상태에서 canonical manifest를 다시 생성하고 기존 manifest와 완전히 일치하는지 확인합니다.

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
~/.local/share/personal-agent-harness/bin/pah install . --components rules,devcontainer,gitignore
~/.local/share/personal-agent-harness/bin/pah install . --components harness-dev
```

## 업데이트

```text
PAH_HOME/.git  --bootstrap/update-->  target-project/.harness/manifest.json
                                      target-project/docs/...
```

```text
1. 하네스 저장소에 변경 push
2. PAH_HOME에서 git pull --ff-only (update.sh가 수행)
3. update.sh <target> → install → verify
4. 기존 관리 파일은 .harness/backups/<timestamp>/에 백업
```

프로젝트 안 in-project clone은 legacy입니다. `bootstrap.sh --clean-nested`로 마이그레이션합니다.

## 아직 하지 않는 일

- symlink 또는 submodule mode
- three-way merge
- 기존 커스텀 devcontainer 자동 마이그레이션
- verify 단계의 Docker build

이 항목들은 copy mode 흐름을 예측 가능하게 유지하기 위해 의도적으로 제외했습니다.
