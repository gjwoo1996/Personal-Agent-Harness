# 규칙 도메인 추가 가이드

> **하네스 저장소 내부 전용:** 이 문서는 대상 프로젝트에 복사되지 않습니다.

> **관련 문서:** [문서 목록](README.md) · [하네스 개발](development.md) · [작동 방식](how-it-works.md)

## Registry

[../config/rule-domains.txt](../config/rule-domains.txt)는 기본 `rules` 설치에 포함할 도메인의 명시적 registry입니다.

- 등록 순서가 install, manifest, verify 순서를 결정합니다.
- 미완성 도메인은 기본 배포 준비가 끝날 때까지 등록하지 않습니다.
- `standards/*` 자동 탐색은 사용하지 않습니다.
- 등록 ID는 소문자 kebab-case여야 하며 중복될 수 없습니다.

## 도메인 패키지

각 `<domain>`은 다음 네 파일을 제공합니다.

```text
standards/<domain>/<domain>-standards.md
standards/<domain>/<domain>-standards.ko.md
templates/stubs/agent-blocks/<domain>.md
templates/stubs/cursor/<domain>-standards.mdc
```

| 역할 | 하네스 원본 | 대상 프로젝트 |
|------|-------------|---------------|
| AI 표준 | `standards/<domain>/<domain>-standards.md` | `docs/<domain>/<domain>-standards.md` |
| 사람용 번역 | `standards/<domain>/<domain>-standards.ko.md` | `docs/<domain>/<domain>-standards.ko.md` |
| Codex / Claude | `templates/stubs/agent-blocks/<domain>.md` | `AGENTS.md`, `CLAUDE.md`의 `pah:<domain>` block |
| Cursor | `templates/stubs/cursor/<domain>-standards.mdc` | `.cursor/rules/<domain>-standards.mdc` |

`agent-blocks/<domain>.md`가 Codex와 Claude용 단일 원본입니다. installer는 이를 `AGENTS.md`와 `CLAUDE.md`에 각각 병합하며, block 밖의 프로젝트 규칙은 보존합니다.

## 새 도메인 추가 절차

1. 중복되지 않는 kebab-case 도메인 ID를 정합니다.
2. 영문 표준 `standards/<domain>/<domain>-standards.md`를 작성합니다.
3. 사람용 번역 `standards/<domain>/<domain>-standards.ko.md`를 작성합니다.
4. `templates/stubs/agent-blocks/<domain>.md`에 `<!-- pah:<domain>:start -->`와 `<!-- pah:<domain>:end -->` block을 작성합니다.
5. `templates/stubs/cursor/<domain>-standards.mdc`를 작성합니다.
6. 기본 배포 준비가 끝나면 `config/rule-domains.txt`에 도메인을 등록합니다.
7. smoke test와 사용자 문서를 갱신합니다.

일반적인 새 도메인은 `bin/pah`를 도메인별로 수동 수정할 필요가 없습니다. registry 반복 처리에 포함되면 install, manifest, verify가 함께 적용됩니다.

## 규칙

- AI stub은 영문 표준만 참조합니다. `*.ko.md`는 사람용입니다.
- managed block ID는 `pah:<domain>`입니다.
- 손상되거나 중복된 block marker는 설치 전에 수정합니다.
- optional devcontainer 스캐폴드, `.gitignore` block, `harness-dev` rule은 registry 밖의 별도 컴포넌트입니다.
- 특정 도메인에 별도 스캐폴드나 CLI 컴포넌트가 필요할 때만 `bin/pah`를 확장합니다.

## 체크리스트

- [ ] 네 개의 도메인 패키지 파일이 있음
- [ ] AI stub이 영문 표준만 참조함
- [ ] agent block marker가 정확히 한 쌍임
- [ ] 기본 배포 준비가 끝난 뒤 registry에 등록함
- [ ] `bash tests/test_pah.sh`를 실행함
- [ ] 사용자 문서에 새 기본 도메인을 반영함

## 하지 않는 것

- `standards/*` 자동 탐색
- 미완성 도메인의 registry 등록
- `*.ko.md`를 AI 규칙 출처로 참조
- `AGENTS.md` 또는 `CLAUDE.md`의 block 밖 내용 덮어쓰기
