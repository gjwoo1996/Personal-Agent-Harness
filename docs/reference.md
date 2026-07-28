# CLI 레퍼런스

> **관련 문서:** [문서 목록](README.md) · [사용법](usage.md) · [작동 방식](how-it-works.md)

## 진입점

| 명령 | 용도 |
|------|------|
| `npx --yes github:gjwoo1996/Personal-Agent-Harness init <target>` | 권장 첫 적용: `install` + `verify` |
| `npx --yes github:gjwoo1996/Personal-Agent-Harness update <target>` | 갱신: `install` + `verify` |
| `npx --yes github:gjwoo1996/Personal-Agent-Harness verify <target>` | 설치 상태 검증 |
| `npx --yes github:gjwoo1996/Personal-Agent-Harness status <target>` | 설치 버전·업데이트 여부 |
| `npx pah` | 프로젝트 git dependency로 설치했을 때의 bin |

로컬 git checkout 개발·오프라인용: `bootstrap.sh`, `setup.sh`, `update.sh`, `bin/pah`

GitHub에서 npm 클라이언트가 해석하는 패키지에는 `setup.sh`, `update.sh`, `bootstrap.sh`도 포함됩니다. 현재 `pah init/update`가 이 래퍼를 재사용하며, 로컬 git checkout 경로와 동일한 동작을 유지하기 위해 의도적으로 배포합니다. `pah install`은 직접 호출하므로 별도 래퍼는 두지 않습니다.

## 기본 `rules` 설치 결과

`config/rule-domains.txt`에 등록된 devcontainer와 git-workflow가 기본 설치됩니다.

```text
target-project/
├── docs/devcontainer/
│   ├── devcontainer-standards.md
│   └── devcontainer-standards.ko.md
├── docs/git-workflow/
│   ├── git-workflow-standards.md
│   └── git-workflow-standards.ko.md
├── .cursor/rules/devcontainer-standards.mdc
├── .cursor/rules/git-workflow-standards.mdc
├── AGENTS.md
├── CLAUDE.md
├── .harness/
│   ├── hooks/
│   └── manifest.json
└── .claude/settings.json  (jq가 있으면 hooks 설치)
```

각 `docs/<domain>/`에는 영문 표준과 사람용 `*.ko.md` 번역본이 들어갑니다.

## `pah install`

```bash
pah install <target> [--dry-run] [--force] [--components rules,devcontainer,gitignore,harness-dev,hooks]
pah init <target> [--clean-nested]
pah update <target>
```

| 옵션 | 설명 |
|------|------|
| `--dry-run` | 실제 변경 없이 대상 파일 목록 출력 |
| `--force` | 기존 관리 파일 강제 덮어쓰기 |
| `--components` | 설치 컴포넌트. 기본값: `rules,hooks` |

| 컴포넌트 | 내용 |
|----------|------|
| `rules` | registry에 등록된 표준, Cursor rule, Codex/Claude block |
| `hooks` | Claude Code PreToolUse hooks. jq가 없으면 경고 후 advisory 모드 |
| `devcontainer` | optional `.devcontainer/` 스캐폴드 |
| `gitignore` | optional `.gitignore` managed block |
| `harness-dev` | optional monorepo 하네스 개발 Cursor rule |

### Power user 예시

```bash
# 변경 미리보기
pah install . --dry-run

# devcontainer 스캐폴드와 gitignore까지 설치
pah install . --components rules,devcontainer,gitignore

# 관리 파일 강제 갱신
pah install . --force

# monorepo 부모에 하네스 개발 rule 설치
pah install . --components harness-dev

# 중첩 clone 제거 후 재설치
pah init . --clean-nested
```

## `pah verify`

```bash
pah verify <target>
```

registry 순서대로 다음을 확인합니다.

- 도메인별 영문 표준, ko 번역본, Cursor rule 존재
- `AGENTS.md`, `CLAUDE.md`의 `pah:<domain>` block 존재와 원본 stub 일치
- AI stub의 영문 표준 참조와 `*.ko.md` 오참조 부재
- 설치된 hooks의 실행 권한과 Claude settings 연결
- `.harness/manifest.json` 존재
- 설치 상태로 다시 생성한 canonical manifest와 기존 manifest의 완전 일치

## Manifest

```json
{
  "standards": {
    "devcontainer": {
      "en": { "path": "docs/devcontainer/devcontainer-standards.md", "sha256": "..." },
      "ko": { "path": "docs/devcontainer/devcontainer-standards.ko.md", "sha256": "...", "ai_readable": false }
    }
  }
}
```

실제 manifest에는 registry의 모든 도메인과 `managed_files` 목록이 포함됩니다.

## Managed block

`AGENTS.md`와 `CLAUDE.md` 전체를 덮어쓰지 않습니다. installer는 registry에 등록된 도메인의 block만 삽입하거나 갱신합니다.

```markdown
<!-- pah:devcontainer:start -->
...
<!-- pah:devcontainer:end -->
```

`pah:git-workflow` 등 다른 도메인 block도 같은 방식으로 독립 관리됩니다. block 밖의 프로젝트 고유 규칙은 보존됩니다.

## `pah status`

```bash
pah status <target> [--harness-root <path>]
```

`.harness/manifest.json`의 `harness_version`과 CLI `VERSION`을 비교합니다.

```bash
pah status .
# update available 시:
npx --yes github:gjwoo1996/Personal-Agent-Harness update .
```

## 현재 제한사항

현재는 copy mode만 사용합니다. symlink mode, submodule mode, three-way merge는 지원하지 않습니다.
