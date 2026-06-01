# CLI 레퍼런스

> **관련 문서:** [문서 목록](README.md) · [사용법](usage.md) · [작동 방식](how-it-works.md) · [README](../README.md)

`pah` CLI와 진입점 스크립트의 옵션, 설치 결과, verify 항목을 정리합니다.

## 진입점 스크립트

| 스크립트 | 실행 위치 | 용도 |
|----------|-----------|------|
| `setup.sh` | 대상 프로젝트 | 첫 적용 (`install` + `verify`, `rules`만) |
| `update.sh` | 대상 프로젝트 | 하네스 갱신 반영 (`git pull` + `install` + `verify`) |
| `install.sh` | 어디서든 | `pah install` 래퍼 (고급 옵션용) |
| `bin/pah` | 어디서든 | 저수준 CLI |

## 기본 설치 결과 (`rules`)

`setup.sh`와 기본 `pah install`은 다음 파일을 대상 프로젝트에 복사하거나 병합합니다.

```text
target-project/
├── docs/devcontainer/devcontainer-standards.md
├── docs/devcontainer/devcontainer-standards.ko.md
├── .cursor/rules/devcontainer-standards.mdc
├── AGENTS.md
├── CLAUDE.md
└── .harness/manifest.json
```

- 영문 표준: AI가 읽는 규칙 출처
- 한글 번역본: 사람이 읽기 위한 참고 문서 (AI stub이 직접 참조하지 않음)

## `pah install`

```bash
./Personal-Agent-Harness/bin/pah install <target> [--dry-run] [--force] [--components rules,devcontainer,gitignore]
```

대상 프로젝트에 하네스가 관리하는 파일을 설치하거나 갱신합니다.

| 옵션 | 설명 |
|------|------|
| `--dry-run` | 실제 변경 없이 생성/수정될 파일 목록만 출력 |
| `--force` | 기존 관리 파일을 강제로 덮어씀 |
| `--components` | 설치할 컴포넌트 (쉼표 구분). 기본값: `rules` |

### 컴포넌트

| 컴포넌트 | 내용 |
|----------|------|
| `rules` | 표준 문서 + Cursor/Codex/Claude 연결 파일 |
| `devcontainer` | `.devcontainer/` 스캐폴드 (기존 파일 있으면 건너뜀) |
| `gitignore` | `.gitignore`에 managed block 병합 |

### Power user 예시

```bash
# 변경 미리보기
./Personal-Agent-Harness/bin/pah install . --dry-run

# devcontainer 스캐폴드까지 설치
./Personal-Agent-Harness/bin/pah install . --components rules,devcontainer,gitignore

# 관리 파일 강제 갱신
./Personal-Agent-Harness/bin/pah install . --force
```

## `pah verify`

```bash
./Personal-Agent-Harness/bin/pah verify <target>
```

다음을 확인합니다.

- `docs/devcontainer/devcontainer-standards.md` 존재
- `docs/devcontainer/devcontainer-standards.ko.md` 존재
- `.cursor/rules/devcontainer-standards.mdc` 존재
- `AGENTS.md`, `CLAUDE.md` 존재 및 managed block 포함
- `.harness/manifest.json` 존재
- AI stub이 `devcontainer-standards.ko.md`를 규칙 출처로 직접 참조하지 않음

## `pah status`

```bash
./Personal-Agent-Harness/bin/pah status <target>
```

대상 프로젝트에 `.harness/manifest.json`이 있는지 확인해 하네스 적용 여부를 알려줍니다.

## Managed block

`AGENTS.md`와 `CLAUDE.md`는 전체를 덮어쓰지 않습니다. installer는 아래 구간만 삽입하거나 갱신합니다.

```markdown
<!-- pah:devcontainer:start -->
...
<!-- pah:devcontainer:end -->
```

block 밖의 프로젝트 고유 규칙은 보존됩니다. 자세한 내용은 [작동 방식](how-it-works.md)을 참고하세요.

## 현재 제한사항

MVP는 copy mode만 사용합니다. symlink mode, submodule mode, three-way merge는 이후 확장으로 남겨두었습니다.
