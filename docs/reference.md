# CLI 레퍼런스

> **관련 문서:** [문서 목록](README.md) · [사용법](usage.md) · [작동 방식](how-it-works.md)

## 진입점

| 스크립트 | 용도 |
|----------|------|
| `setup.sh` | 첫 적용: `install` + `verify` |
| `update.sh` | 갱신: `git pull --ff-only` + `install` + `verify` |
| `install.sh` | `pah install` 래퍼 |
| `bin/pah` | 저수준 CLI |

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
└── .harness/manifest.json
```

각 `docs/<domain>/`에는 영문 표준과 사람용 `*.ko.md` 번역본이 들어갑니다.

## `pah install`

```bash
./Personal-Agent-Harness/bin/pah install <target> [--dry-run] [--force] [--components rules,devcontainer,gitignore,harness-dev]
```

| 옵션 | 설명 |
|------|------|
| `--dry-run` | 실제 변경 없이 대상 파일 목록 출력 |
| `--force` | 기존 관리 파일 강제 덮어쓰기 |
| `--components` | 설치 컴포넌트. 기본값: `rules` |

| 컴포넌트 | 내용 |
|----------|------|
| `rules` | registry에 등록된 표준, Cursor rule, Codex/Claude block |
| `devcontainer` | optional `.devcontainer/` 스캐폴드 |
| `gitignore` | optional `.gitignore` managed block |
| `harness-dev` | optional monorepo 하네스 개발 Cursor rule |

### Power user 예시

```bash
# 변경 미리보기
./Personal-Agent-Harness/bin/pah install . --dry-run

# devcontainer 스캐폴드와 gitignore까지 설치
./Personal-Agent-Harness/bin/pah install . --components rules,devcontainer,gitignore

# 관리 파일 강제 갱신
./Personal-Agent-Harness/bin/pah install . --force

# monorepo 부모에 하네스 개발 rule 설치
./Personal-Agent-Harness/bin/pah install . --components harness-dev
```

## `pah verify`

```bash
./Personal-Agent-Harness/bin/pah verify <target>
```

registry 순서대로 다음을 확인합니다.

- 도메인별 영문 표준, ko 번역본, Cursor rule 존재
- `AGENTS.md`, `CLAUDE.md`의 `pah:<domain>` block 존재
- AI stub의 영문 표준 참조와 `*.ko.md` 오참조 부재
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
./Personal-Agent-Harness/bin/pah status <target>
```

`.harness/manifest.json` 존재 여부로 하네스 적용 상태를 표시합니다.

## 현재 제한사항

현재는 copy mode만 사용합니다. symlink mode, submodule mode, three-way merge는 지원하지 않습니다.
