# Devcontainer AI 스킬 공유 설계

작성일: 2026-06-10

## 배경

`데브컨테이너-ai-상태-및-스킬-공유-개선사항.md`는 두 종류의 개선을 다룬다.

1. devcontainer에서 Claude/Codex 로그인 및 대화 상태를 보존한다.
2. `superpowers`, `gstack` 스킬을 devcontainer 안에서 Codex와 Claude가 공통으로 사용할 수 있게 하고, Cursor에는 `gstack`만 연결한다.

1번은 별도 커밋에서 이미 처리했으므로 이 문서의 구현 범위에서 제외한다. 이 문서는 남은 2번, 즉 devcontainer 기반 AI 스킬 설치와 연결 모델만 설계한다.

## 문제 재정의

초기 논의에서는 PAH에 `skills` 컴포넌트를 추가해 대상 프로젝트에 `.harness/skills/<skill-id>/`를 복사하는 모델을 검토했다.

회의 결과, 이 방향은 현재 목표와 맞지 않는 것으로 정리했다. `superpowers`와 `gstack`은 대상 프로젝트의 규칙 문서라기보다 devcontainer 안에서 실행되는 AI 도구의 작업 환경 구성 요소다. 따라서 핵심 요구는 다음이다.

- devcontainer를 새로 만들거나 rebuild해도 Codex/Claude가 같은 스킬을 사용할 수 있어야 한다.
- 스킬 설치는 프로젝트 루트의 `.harness/skills`가 아니라 컨테이너 내부의 안정적인 경로에 모아야 한다.
- AI 로그인/대화 state 보존과 스킬 설치는 책임을 분리해야 한다.
- Cursor 연결은 대상 프로젝트 파일인 `.cursor/rules/`를 통해 제공하되, `gstack`만 연결한다.

## 목표

- devcontainer 템플릿이 `superpowers`, `gstack` 스킬을 컨테이너 내부에 idempotent하게 설치하게 한다.
- Codex와 Claude가 컨테이너 내부의 같은 스킬 원본을 참조하게 한다.
- Cursor에는 `gstack`만 `.cursor/rules/gstack-skill.mdc`로 연결한다.
- 기존 `rules` 도메인 설치 모델과 스킬 설치 모델을 섞지 않는다.
- `pah verify`와 `tests/test_pah.sh`가 devcontainer 스킬 bootstrap 결과를 검증하게 한다.

## 비목표

- 대상 프로젝트에 `.harness/skills/<skill-id>/`를 설치하지 않는다.
- `skills`라는 새 `pah install --components` 컴포넌트를 만들지 않는다.
- Codex/Claude의 비공개 또는 불안정한 native plugin API에 의존하지 않는다.
- Cursor에는 `gstack` 스킬만 연결한다. `superpowers`는 Cursor에 연결하지 않는다.
- 스킬 내부 구현을 PAH가 해석하거나 실행하지 않는다.
- npm install 또는 npx 패키지 다운로드 시점에 대상 프로젝트 파일을 수정하지 않는다.

## 핵심 결정

스킬은 PAH의 독립 설치 컴포넌트가 아니라 devcontainer AI bootstrap의 일부로 다룬다.

```text
pah init .
  -> setup.sh
  -> pah install . --components rules,hooks
  -> pah install . --components devcontainer  # 사용자가 선택한 경우
  -> devcontainer post-create/post-start에서 AI 스킬 bootstrap
```

기본 `pah init .`은 지금처럼 `rules,hooks`를 설치한다. devcontainer scaffold를 설치한 프로젝트에서는 `.devcontainer/` 템플릿 안의 bootstrap 스크립트가 컨테이너 내부 스킬 경로를 준비한다.

스킬 설치 대상은 대상 프로젝트가 아니라 컨테이너 사용자 홈 아래의 안정적인 경로다.

```text
/home/vscode/.local/share/pah/ai-skills/superpowers/
/home/vscode/.local/share/pah/ai-skills/gstack/
```

이 경로는 devcontainer rebuild 후에도 post-create가 다시 만들 수 있는 재현 가능한 설치물로 본다. 로그인 토큰, 대화 내역, AI config 같은 상태는 별도 named volume으로 보존하며, 스킬 파일 자체를 state volume에 의존시키지 않는다.

## 권장 설치 전략

스킬은 Docker image layer에 완전히 고정하기보다 post-create 단계에서 idempotent하게 설치한다.

이유:

- 스킬은 사용자 state가 아니라 재생성 가능한 개발 환경 구성물이다.
- Dockerfile build보다 post-create에서 실패 메시지와 재실행이 더 다루기 쉽다.
- 컨테이너 rebuild 후에도 같은 스크립트가 같은 경로를 다시 채운다.
- 로그인/대화 state named volume과 스킬 설치 책임이 섞이지 않는다.

구현은 다음 원칙을 따른다.

- `post-create.sh`는 AI CLI 설치 확인 후 `install-ai-skills.sh`를 호출한다.
- `install-ai-skills.sh`는 이미 같은 버전이 설치되어 있으면 아무 작업도 하지 않는다.
- 설치 중 실패하면 어떤 스킬과 어떤 단계에서 실패했는지 명확히 출력한다.
- partial install을 남기지 않도록 임시 디렉터리에 받은 뒤 최종 경로로 교체한다.

## 원본 관리

스킬 원본은 devcontainer bootstrap이 설치할 수 있는 형태로 PAH 패키지에 포함한다. 단, 이것은 대상 프로젝트에 `.harness/skills`로 설치한다는 뜻이 아니다. PAH는 devcontainer 템플릿과 bootstrap 입력물을 제공하고, 실제 사용 위치는 컨테이너 내부다.

하네스 원본:

```text
templates/devcontainer/ai-skills/
├── install-ai-skills.sh
├── skills-manifest.json
├── superpowers/
│   ├── README.md
│   ├── SKILL.md
│   └── metadata.json
└── gstack/
    ├── README.md
    ├── SKILL.md
    └── metadata.json
```

대상 프로젝트 scaffold 결과:

```text
.devcontainer/ai-skills/
├── install-ai-skills.sh
├── skills-manifest.json
├── superpowers/
│   ├── README.md
│   ├── SKILL.md
│   └── metadata.json
└── gstack/
    ├── README.md
    ├── SKILL.md
    └── metadata.json
```

컨테이너 내부 설치 결과:

```text
/home/vscode/.local/share/pah/ai-skills/
├── superpowers/
│   ├── README.md
│   ├── SKILL.md
│   └── metadata.json
└── gstack/
    ├── README.md
    ├── SKILL.md
    └── metadata.json
```

`metadata.json`은 vendored snapshot의 출처와 갱신 기준점을 기록한다.

필수 필드는 다음 의미를 가진다.

| 필드 | 의미 |
| --- | --- |
| `id` | 스킬 ID. 디렉터리 이름과 같아야 한다. |
| `source` | vendored snapshot을 가져온 canonical 원본 URL. |
| `source_ref` | 원본의 commit, tag, release 등 갱신 기준점. |
| `license` | 배포 가능한 라이선스 식별자 또는 함께 포함한 라이선스 파일 경로. |
| `vendored_at` | PAH에 snapshot을 반영한 날짜. |
| `notes` | 갱신이나 설치에 필요한 보충 설명. |

`gstack`의 canonical 원본과 라이선스는 구현 전에 확인해야 한다. 확인 전에는 실제 파일 추가를 보류하고 테스트에서 배포 불가로 처리한다.

## AI별 연결 방식

### Codex

Codex는 `AGENTS.md` managed block을 통해 컨테이너 내부 스킬 경로를 안내받는다.

```text
<!-- pah:devcontainer-ai-skills:start -->
When working inside the PAH devcontainer, read:
- /home/vscode/.local/share/pah/ai-skills/superpowers/SKILL.md
- /home/vscode/.local/share/pah/ai-skills/gstack/SKILL.md
<!-- pah:devcontainer-ai-skills:end -->
```

Codex 전용 native plugin 또는 skill 디렉터리는 1차 구현에서 다루지 않는다.

### Claude

Claude도 `CLAUDE.md` managed block을 통해 같은 컨테이너 내부 스킬 경로를 안내받는다.

Claude Code native skill 디렉터리 설치는 2차 개선으로 남긴다. 1차 구현은 프로젝트 로컬 문서 연결과 컨테이너 내부 공통 경로만 사용한다.

### Cursor

Cursor에는 `gstack`만 연결한다.

```text
.cursor/rules/gstack-skill.mdc
```

이 rule은 긴 스킬 본문을 직접 포함하지 않고 다음을 담는다.

- `gstack`의 짧은 목적
- 컨테이너 내부 canonical path
- 필요할 때 해당 `SKILL.md`를 읽으라는 지시

`superpowers`용 Cursor rule은 만들지 않는다. Cursor가 긴 `superpowers` 절차를 항상 읽어 컨텍스트를 낭비하는 것을 피하기 위해서다.

## Managed block 규칙

Codex와 Claude block marker는 devcontainer AI skills 전용 marker를 사용한다.

```text
<!-- pah:devcontainer-ai-skills:start -->
...
<!-- pah:devcontainer-ai-skills:end -->
```

규칙 도메인의 `pah:<domain>` block과 충돌하지 않도록 별도 marker를 사용한다. 설치기는 block 밖의 사용자 내용을 보존한다. 손상되거나 중복된 block marker가 있으면 설치 전에 실패한다.

## Manifest

대상 프로젝트의 `.harness/manifest.json`은 대상 프로젝트에 설치된 파일만 기록한다. 컨테이너 내부 `/home/vscode/...` 경로는 대상 프로젝트 파일이 아니므로 manifest에 기록하지 않는다.

devcontainer scaffold를 설치한 경우 manifest에는 다음 파일들이 `devcontainer` 컴포넌트 산출물로 포함된다.

```json
{
  "devcontainer": {
    "files": [
      {
        "path": ".devcontainer/ai-skills/install-ai-skills.sh",
        "sha256": "..."
      },
      {
        "path": ".devcontainer/ai-skills/skills-manifest.json",
        "sha256": "..."
      },
      {
        "path": ".devcontainer/ai-skills/superpowers/SKILL.md",
        "sha256": "..."
      },
      {
        "path": ".devcontainer/ai-skills/gstack/SKILL.md",
        "sha256": "..."
      },
      {
        "path": ".cursor/rules/gstack-skill.mdc",
        "sha256": "..."
      }
    ]
  }
}
```

기존 `standards`, `hooks` manifest 형식은 유지한다. 별도의 `skills` manifest 섹션은 만들지 않는다.

## 설치 흐름

1. `templates/devcontainer/ai-skills/`에 bootstrap 스크립트와 스킬 snapshot을 추가한다.
2. `pah install <target> --components devcontainer`가 `.devcontainer/ai-skills/`를 복사한다.
3. devcontainer `post-create.sh`가 `.devcontainer/ai-skills/install-ai-skills.sh`를 실행한다.
4. `install-ai-skills.sh`가 `/home/vscode/.local/share/pah/ai-skills/`에 `superpowers`, `gstack`을 설치한다.
5. `pah install <target> --components rules,hooks`는 기존처럼 규칙과 hooks만 설치한다.
6. `pah install <target> --components devcontainer`는 `AGENTS.md`, `CLAUDE.md`에 devcontainer AI skills managed block을 병합한다.
7. `pah install <target> --components devcontainer`는 `.cursor/rules/gstack-skill.mdc`를 생성한다.

## 검증 흐름

`pah verify`는 manifest에 devcontainer 산출물이 있을 때만 devcontainer AI skills 파일을 검증한다.

검증 항목:

- `.devcontainer/ai-skills/install-ai-skills.sh`가 존재하고 실행 가능하다.
- `.devcontainer/ai-skills/skills-manifest.json`이 존재한다.
- `.devcontainer/ai-skills/<skill-id>/SKILL.md`, `README.md`, `metadata.json`이 존재한다.
- `metadata.json`에 `id`, `source`, `source_ref`, `license`, `vendored_at`이 있다.
- `AGENTS.md`와 `CLAUDE.md`의 `pah:devcontainer-ai-skills` block이 원본 stub과 일치한다.
- `.cursor/rules/gstack-skill.mdc`가 존재하고 `/home/vscode/.local/share/pah/ai-skills/gstack/SKILL.md`를 참조한다.
- `.cursor/rules/superpowers-skill.mdc`는 생성되지 않는다.
- manifest sha256이 실제 scaffold 파일과 일치한다.

컨테이너 내부 설치 결과는 `pah verify`의 기본 범위에 포함하지 않는다. 대신 devcontainer 내부에서 실행하는 smoke command를 별도로 제공한다.

```bash
bash .devcontainer/ai-skills/install-ai-skills.sh
test -f /home/vscode/.local/share/pah/ai-skills/superpowers/SKILL.md
test -f /home/vscode/.local/share/pah/ai-skills/gstack/SKILL.md
```

## 테스트 계획

`tests/test_pah.sh`에 다음 시나리오를 추가한다.

- `pah install <target> --components devcontainer`가 `.devcontainer/ai-skills/`를 생성한다.
- `install-ai-skills.sh`가 실행 가능 권한으로 설치된다.
- `superpowers`, `gstack`의 `SKILL.md`, `README.md`, `metadata.json`이 scaffold에 포함된다.
- `metadata.json` 필수 필드가 누락되면 설치 또는 verify가 실패한다.
- `post-create.sh`가 `install-ai-skills.sh`를 호출한다.
- `AGENTS.md`, `CLAUDE.md`에 devcontainer AI skills managed block이 생성된다.
- `.cursor/rules/gstack-skill.mdc` 연결 파일이 생성된다.
- `.cursor/rules/superpowers-skill.mdc` 연결 파일은 생성되지 않는다.
- `pah verify <target>`가 devcontainer AI skills scaffold 상태를 통과시킨다.
- `pah install <target> --components devcontainer` 재실행 시 managed block이 중복되지 않는다.
- 손상된 `pah:devcontainer-ai-skills` block이 있으면 설치가 실패하고 기존 파일을 보존한다.
- `pah install <target> --components rules,hooks`만 실행하면 `.devcontainer/ai-skills/`가 생기지 않는다.
- npm install 또는 npx 패키지 다운로드만으로는 대상 프로젝트 파일이 생성되지 않는다.

## 구현 순서

1. `templates/devcontainer/ai-skills/` 원본 구조를 추가한다.
2. `superpowers`, `gstack`의 `SKILL.md`, `README.md`, `metadata.json` snapshot을 추가한다.
3. `templates/devcontainer/ai-skills/install-ai-skills.sh`를 추가한다.
4. `templates/devcontainer/commands/post-create.sh`가 `install-ai-skills.sh`를 호출하도록 수정한다.
5. Codex/Claude용 devcontainer AI skills managed block stub을 추가한다.
6. `.cursor/rules/gstack-skill.mdc` 원본 stub을 추가한다.
7. `bin/pah`의 devcontainer 설치 흐름에 AI skills scaffold, managed block, Cursor rule 설치를 포함한다.
8. `pah verify`에 devcontainer AI skills scaffold 검증을 추가한다.
9. `tests/test_pah.sh`에 실패 테스트를 먼저 추가하고 구현을 맞춘다.
10. 사용자 문서 `docs/usage.md`, `docs/reference.md`, `docs/how-it-works.md`에 devcontainer AI skills 동작과 제외 방법을 추가한다.
11. `bash tests/test_pah.sh`와 `git diff --check`를 실행한다.

## 위험과 대응

| 위험 | 대응 |
| --- | --- |
| 스킬과 규칙 도메인의 책임이 섞임 | `skills` 컴포넌트를 만들지 않고 devcontainer scaffold 책임으로 제한한다. |
| 컨테이너 내부 파일을 manifest로 검증하려 함 | manifest는 대상 프로젝트 파일만 기록하고, 컨테이너 내부 설치는 smoke command로 검증한다. |
| rebuild 후 스킬이 사라짐 | `post-create.sh`가 idempotent installer를 다시 실행해 재생성한다. |
| AI 로그인 state와 스킬 파일이 같은 저장소에 섞임 | 로그인/대화 state는 named volume, 스킬은 재생성 가능한 bootstrap 산출물로 분리한다. |
| Cursor가 긴 스킬 문서를 항상 읽어 과도한 컨텍스트를 사용함 | Cursor에는 `gstack`만 연결하고 rule에는 요약과 canonical path만 둔다. |
| 외부 `superpowers`, `gstack` 원본과 drift 발생 | `metadata.json`에 source/ref/license/vendored_at을 기록하고 갱신은 별도 커밋으로 관리한다. |
| 기존 대상 프로젝트에 예상치 못한 파일이 생김 | devcontainer 컴포넌트를 설치할 때만 `.devcontainer/ai-skills/`와 Cursor 연결 파일을 생성한다. |

## 후속 확인 사항

- `gstack`의 canonical 원본과 라이선스를 확인해야 한다.
- `superpowers` snapshot의 출처, ref, 라이선스를 `metadata.json`에 기록해야 한다.
- Codex/Claude native skill 디렉터리까지 설치할지 여부는 2차 개선으로 남긴다.
- devcontainer 내부 smoke command를 문서화할 위치를 정해야 한다.
