# 규칙 도메인 추가 가이드

> **하네스 저장소 내부 전용** — 이 문서는 `Personal-Agent-Harness`를 수정하는 사람·AI가 참고합니다.  
> `pah install` / `setup.sh` / `update.sh`로 **대상 프로젝트에 복사·배포되지 않습니다.**

> **관련 문서:** [문서 목록](README.md) · [하네스 개발·테스트](development.md) · [작동 방식](how-it-works.md)

`Personal-Agent-Harness`에 새 규칙 도메인(예: git, testing)을 추가할 때, **devcontainer와 동일한 형식**을 따르는 공식 절차입니다. devcontainer 구현이 **참조 구현(reference implementation)** 입니다.

## 언제 이 문서를 쓰는가

- `standards/<domain>/` 아래에 **새 표준 도메인**을 추가할 때
- 해당 도메인을 `pah install` / `verify` / manifest에 등록할 때
- Cursor stub, `AGENTS.md` / `CLAUDE.md` managed block을 추가할 때

대상 프로젝트(`gw-personal` 등)에 하네스를 적용하는 방법은 [usage.md](usage.md)를 참고하세요. 이 문서는 **하네스 엔지니어링** 전용입니다.

## 대상 프로젝트에 영향이 없는 이유

`pah install`이 복사하는 경로는 다음뿐입니다.

- `standards/<domain>/` → 대상 `docs/<domain>/`
- `templates/stubs/` → Cursor rule, managed block 병합

하네스 저장소의 `docs/`(usage, development, **이 문서**)는 install 대상이 **아닙니다**.

## AI 연결 (하네스 개발용)

하네스 **개발** 규칙은 대상 프로젝트용(`templates/stubs/`, 기본 `pah install`)과 **분리**되어 있습니다.

| 파일 | 용도 | install 대상 |
|------|------|--------------|
| `.cursor/rules/harness-development.mdc` | PAH 단독 repo에서 harness 파일 편집 시 | 아니오 (저장소 내부) |
| `templates/harness-dev/harness-development.mdc` | monorepo에서 `Personal-Agent-Harness/**` 편집 시 | opt-in (`--components harness-dev`) |
| `AGENTS.md` (저장소 루트) | PAH 단독 repo Codex/Claude | 아니오 |

`templates/stubs/AGENTS.md` / `CLAUDE.md`에는 harness-dev block을 **넣지 않습니다**. 모든 대상 프로젝트에 개발용 지시가 섞이는 것을 막기 위함입니다.

## 공통 불변 원칙

모든 규칙 도메인은 devcontainer와 같은 원칙을 따릅니다.

| 대상 | 규칙 |
|------|------|
| AI 에이전트 | 영문 `*-standards.md`만 규칙 출처로 읽음 |
| 사람 | `*-standards.ko.md` 번역본 읽음 |
| stub / managed block | `*.ko.md`를 AI 규칙 출처로 **참조 금지** |
| 배포 방식 | copy mode (대상 프로젝트에 복사) |
| `AGENTS.md` / `CLAUDE.md` | managed block 구간만 installer가 갱신 |

규칙 우선순위(도메인별 표준 문서 안에도 동일하게 기술):

1. 사용자의 직접 지시
2. 프로젝트별 예외와 프로젝트 고유 규칙
3. `docs/<domain>/<domain>-standards.md`
4. 과거 참고 문서 또는 번역본

## 도메인 ID·파일 규약

- **도메인 ID**: kebab-case (예: `devcontainer`, `git-workflow`, `testing`)
- **표준 파일명**: `<domain>-standards.md`, `<domain>-standards.ko.md`
- **managed block ID**: `pah:<domain>` (예: `pah:devcontainer`, `pah:git-workflow`)

| 역할 | 하네스 원본 | 대상 프로젝트 (install 후) |
|------|-------------|---------------------------|
| AI 표준 | `standards/<domain>/<domain>-standards.md` | `docs/<domain>/<domain>-standards.md` |
| 사람용 | `standards/<domain>/<domain>-standards.ko.md` | `docs/<domain>/<domain>-standards.ko.md` |
| Cursor | `templates/stubs/cursor/<domain>-standards.mdc` | `.cursor/rules/<domain>-standards.mdc` |
| Codex / Claude | `templates/stubs/AGENTS.md`, `CLAUDE.md` 내 block | 동일 파일, `<!-- pah:<domain>:start/end -->` |

### skeleton 예시 (가상 도메인 `git-workflow`)

하네스 저장소:

```text
Personal-Agent-Harness/
├── standards/git-workflow/
│   ├── git-workflow-standards.md
│   └── git-workflow-standards.ko.md
├── templates/stubs/cursor/git-workflow-standards.mdc
└── templates/stubs/AGENTS.md   # pah:git-workflow block 추가
```

`pah install` 후 대상 프로젝트:

```text
my-app/
├── docs/git-workflow/
│   ├── git-workflow-standards.md
│   └── git-workflow-standards.ko.md
├── .cursor/rules/git-workflow-standards.mdc
├── AGENTS.md    # pah:devcontainer + pah:git-workflow blocks
├── CLAUDE.md
└── .harness/manifest.json
```

## devcontainer 참조 구현 (정답 예시)

현재 devcontainer 도메인이 구현한 파일과 `bin/pah` 연동 지점입니다. 새 도메인도 **같은 종류의 작업**을 반복합니다.

### 1. 표준 문서

- [../standards/devcontainer/devcontainer-standards.md](../standards/devcontainer/devcontainer-standards.md) — AI용 영문
- [../standards/devcontainer/devcontainer-standards.ko.md](../standards/devcontainer/devcontainer-standards.ko.md) — 사람용 한글

### 2. AI 연결 stub

- [../templates/stubs/cursor/devcontainer-standards.mdc](../templates/stubs/cursor/devcontainer-standards.mdc) — `globs`, `alwaysApply: false`, 영문 경로만 참조
- [../templates/stubs/AGENTS.md](../templates/stubs/AGENTS.md) — `<!-- pah:devcontainer:start/end -->`
- [../templates/stubs/CLAUDE.md](../templates/stubs/CLAUDE.md) — 동일 block

### 3. `bin/pah` 수정 포인트

| 함수 / 구간 | devcontainer에서 하는 일 | 새 도메인 추가 시 |
|-------------|-------------------------|-------------------|
| `cmd_install` (`rules` 컴포넌트) | en/ko 표준, Cursor rule 복사; AGENTS/CLAUDE merge | 동일 패턴으로 `copy_managed_file` / `merge_stub_file` 호출 추가 |
| `extract_block` / `merge_stub_file` | `pah:devcontainer` block 추출·병합 | block ID를 인자로 받도록 일반화하거나, 도메인별 함수 추가 |
| `write_manifest` | `standards`, `managed_files`에 devcontainer 경로 등록 | 새 도메인 경로·checksum 추가 |
| `cmd_verify` | 파일 존재, 영문 경로 참조, ko 참조 금지, block 마커 | 새 도메인에 대한 동일 검사 추가 |

현재 `extract_block`과 `merge_stub_file`은 `pah:devcontainer`만 하드코딩되어 있습니다. 두 번째 도omain을 추가할 때는 **block ID를 매개변수화**하는 리팩터링을 권장합니다.

### 4. 테스트

- [../tests/test_pah.sh](../tests/test_pah.sh) — install, verify, 기존 AGENTS 병합, setup/update 경로
- 새 도메인 추가 시: 해당 파일 존재, stub이 영문만 참조, managed block 마커 assertion 추가

### 5. 선택 스캐폴드 (devcontainer만 해당)

- [../templates/devcontainer/](../templates/devcontainer/) — `--components devcontainer`로 복사
- `.gitignore` managed block — `--components gitignore`
- 모든 도메인에 스캐폴드가 필요한 것은 **아님**. 표준+stub+block+install/verify가 필수

## 새 도메인 추가 절차

1. **도메인 ID 확정** — kebab-case, 기존 도메인과 충돌 없음
2. **표준 작성** — `standards/<domain>/` en + ko
3. **Cursor stub** — `templates/stubs/cursor/<domain>-standards.mdc`
4. **managed block** — `templates/stubs/AGENTS.md`, `CLAUDE.md`에 `pah:<domain>` block **추가** (기존 block 수정·삭제 금지)
5. **`bin/pah` 수정** — install, manifest, verify
6. **테스트** — `tests/test_pah.sh` 확장 후 `bash tests/test_pah.sh`
7. **사용자-facing 문서** (대상 프로젝트 관점) — 필요 시 [how-it-works.md](how-it-works.md), [reference.md](reference.md), [usage.md](usage.md) 갱신
8. **하네스 push 후** — 대상 프로젝트에서 `./Personal-Agent-Harness/update.sh`로 반영

## 필수 vs 선택

| 구분 | 항목 |
|------|------|
| **필수** | en/ko 표준, Cursor stub, AGENTS/CLAUDE managed block, `cmd_install` / `write_manifest` / `cmd_verify`, smoke test |
| **선택** | `templates/<domain>/` 스캐폴드, `--components` 확장, 프로젝트 예외 문서 경로 (devcontainer는 `.devcontainer/README.md`) |

## PR 전 체크리스트

- [ ] 도메인 ID가 kebab-case이고 파일명 규약을 따름
- [ ] AI용 영문 표준과 사람용 ko 번역본이 쌍으로 존재
- [ ] Cursor stub·managed block이 **영문 경로만** 참조 (`*.ko.md` 없음)
- [ ] `AGENTS.md` / `CLAUDE.md` 템플릿에 **새 block만 추가**, 기존 `pah:*` block 유지
- [ ] `bin/pah` install / manifest / verify에 새 도메인 등록
- [ ] `tests/test_pah.sh`에 install·verify assertion 추가
- [ ] `bash tests/test_pah.sh` 통과
- [ ] 대상 프로젝트용 문서(how-it-works, reference, usage) 필요 시 갱신
- [ ] 이 문서(`adding-rule-domains.md`)는 하네스 내부용이며 install 대상이 **아님**을 확인

## 하지 않는 것

- symlink / submodule mode로 표준 배포
- `*.ko.md`를 AI stub의 규칙 출처로 지정
- `AGENTS.md` / `CLAUDE.md` managed block **밖** 내용 덮어쓰기
- verify 단계에서 Docker build 등 무거운 검증 (MVP 범위 밖)
- 하네스 `docs/` 전체를 대상 프로젝트에 복사

## 후속 작업 (별도 이슈)

도메인을 자주 늘릴 계획이면 `bin/pah`를 **registry 기반**으로 일반화하는 리팩터링을 검토하세요. devcontainer를 registry 첫 항목으로 두면, 이 가이드의 체크리스트와 구현이 더 잘 맞습니다.
