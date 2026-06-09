# Personal-Agent-Harness 하네스 엔지니어링 분석 보고서

> **문서 유형:** 사람 참고용 분석 문서. `pah install` 대상이 아닙니다.
> **최초 작성일:** 2026-06-02 (v0.2.0, `88f19aa`)
> **재분석일:** 2026-06-09
> **대상 버전:** v0.3.1
>
> 2026-06-02 분석에서 🔴 Critical로 지적했던 항목 중 **enforcement hooks(2-1)**,
> **`pah status` 버전 비교(2-2)**, **`pah update` 서브커맨드(2-5)** 는 v0.3.1에서
> 구현 완료되었습니다. 아래 본문은 v0.3.1 기준으로 갱신했습니다.

---

## 분석 기준 및 참고 자료

| 출처 | 내용 |
|------|------|
| [Anthropic — Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | 하네스 설계 원칙, context 관리, 세션 간 아티팩트 |
| [HumanLayer — Skill Issue: Harness Engineering for Coding Agents](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents) | Advisory vs. Enforcement 구분, CLAUDE.md 한계 |
| [HumanLayer — Writing a good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md) | CLAUDE.md 지침 밀도, 150-200 지침 일관성 한계 |
| [NxCode — Harness Engineering Complete Guide 2026](https://www.nxcode.io/resources/news/harness-engineering-complete-guide-ai-agent-codex-2026) | Registry, manifest, domain 패키지 패턴 |
| [Augment Code — Harness Engineering for AI Coding Agents](https://www.augmentcode.com/guides/harness-engineering-ai-coding-agents) | Rule 선택적 로딩 (always_apply / agent_requested / manual) |
| [O'Reilly — Agent Harness Engineering](https://www.oreilly.com/radar/agent-harness-engineering/) | 하네스 구성요소: 도구, 컨텍스트, 권한, 관찰가능성 |
| [Adnan Masood — Agent Harness Engineering: Rise of the AI Control Plane](https://medium.com/@adnanmasood/agent-harness-engineering-the-rise-of-the-ai-control-plane-938ead884b1d) | 65% 기업 AI 실패 원인: Context Drift, Schema Misalignment |

---

## 1. 현재 잘 되어 있는 부분

### 1-1. Registry 기반 도메인 시스템

`config/rule-domains.txt`의 명시적 레지스트리는 2025-2026 하네스 엔지니어링 모범 사례와 직접 정렬됩니다.

- **자동 탐색 금지**: `standards/*` 디렉토리를 자동 스캔하지 않아 미완성 도메인이 배포되는 사고를 구조적으로 차단
- **ID 유효성 검증**: 소문자 kebab-case, 중복 감지, 빈 항목 거부를 `load_rule_domains`에서 배열 채우기 전 처리
- **순서 결정성**: 레지스트리 순서가 install, manifest, verify 순서를 통제 — 랜덤 결과 없음

```bash
# bin/pah — 정규식 검증 + 중복 검사를 현재 쉘에서 처리
[[ "$domain" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || die "invalid rule domain id: $domain"
case "$seen" in *",$domain,"*) die "duplicate rule domain id: $domain" ;; esac
```

### 1-2. Preflight 검증 — 부분 설치 방지

`preflight_rule_install`이 첫 쓰기 전에 모든 도메인 소스 파일 존재와 블록 구조를 검증합니다. 손상된 레지스트리나 불완전한 도메인 패키지는 대상 디렉토리에 아무것도 쓰지 않고 실패합니다. `tests/test_pah.sh`의 broken-registry, broken-block 시나리오에서 이 보장을 명시적으로 검증합니다.

### 1-3. Managed Block 독립 격리

HTML 주석 마커(`<!-- pah:<domain>:start/end -->`)를 통한 도메인별 블록 독립 갱신은 현재 best practice를 따릅니다.

- 블록 밖의 프로젝트 고유 규칙이 보존됨
- 각 도메인이 서로 독립적으로 갱신 가능
- 손상된 마커를 사전에 감지해 install 거부

### 1-4. Canonical Manifest 재생성 비교 — 강한 무결성 모델

`pah verify`가 현재 설치 상태에서 manifest를 재생성한 뒤 저장된 것과 바이트 단위 비교(`cmp -s`)합니다. SHA-256이 바뀐 standards 파일은 verify 실패로 즉시 드러납니다.

### 1-5. Shell 안전성

- `set -euo pipefail` 전체 적용
- `mktemp`-then-`mv` 원자적 파일 쓰기 패턴
- awk 내부 getline으로 역슬래시 리터럴 보존 (쉘 변수 삽입 우회)
- tmpfile을 대상 파일에 인접하게 생성 → 동일 파일시스템 내 `mv` 보장

### 1-6. AI / 사람 언어 분리

영문 표준만 AI 연결, 한국어 번역은 사람 전용. 이 구분을 preflight(설치 전)와 verify(설치 후) 양쪽에서 독립적으로 강제합니다.

### 1-7. Cursor MDC 규칙 로딩 전략

현재 베스트 프랙티스(Augment Code)는 rule을 세 종류로 구분합니다: always-apply, agent-requested, manual. PAH의 Cursor 규칙은 이를 적절히 반영합니다.

| 규칙 | `alwaysApply` | 이유 |
|------|--------------|------|
| `devcontainer-standards.mdc` | `false` + glob | 도커 파일 작업 시에만 필요 |
| `git-workflow-standards.mdc` | `true` | 커밋 작업은 어떤 맥락에서도 발생 가능 |

### 1-8. 테스트 커버리지 폭

총 15+ 독립 시나리오 — 정상 설치, 중복 설치, 기존 파일 보존, devcontainer 스캐폴드, setup/update 흐름, harness-dev, 손상된 블록 preflight, 손상된 레지스트리, 중복 ID, 잘못된 ID, 빈 레지스트리, 미등록 도메인, KO 참조 거부, 백업 카운트, SHA256 변조, malformed manifest, 알 수 없는 컴포넌트, 역슬래시 이스케이프.

---

## 2. 개선이 필요한 부분

### 2-1. ✅ 해소됨 (v0.3.1): Enforcement Layer 추가

**2026-06-02 현황**: CLAUDE.md/AGENTS.md 블록은 *advisory* 텍스트뿐이라 강제력이 없었습니다.

**2025-2026 업계 관점** (HumanLayer, Claude Code Hooks):

> "CLAUDE.md is text that becomes part of the model's context. A sufficiently confident hallucination, an ambiguous instruction, or a single context-window truncation can override a CLAUDE.md rule. Hooks are deterministic and guarantee the action happens."

**v0.3.1 상태**: 별도 `hooks` 컴포넌트가 추가되어 Claude Code PreToolUse hook과 연결됩니다.

- `pah install . --components rules,hooks` (기본 `init`/`update`가 `rules,hooks` 설치)
- `templates/stubs/hooks/<domain>.hook.sh`를 `.harness/hooks/`로 복사하고 실행 권한 부여
- `.claude/settings.json`의 `hooks.PreToolUse`에 도메인별 matcher 병합 (`install_hooks_component`)
- `pah verify`가 hook 스크립트 존재·실행권한·settings.json 등록을 검증 (`verify_hooks_if_installed`)
- `jq` 부재 시 hooks 설치를 건너뛰고 advisory 모드로 폴백 (경고 출력)

**남은 한계**: enforcement는 Claude Code hooks 런타임에 의존하므로, hooks를 지원하지 않는 에이전트에서는 여전히 advisory로 동작합니다.

---

### 2-2. ✅ 해소됨 (v0.3.1): 버전 드리프트 감지 추가

**2026-06-02 현황**: `pah status`는 `.harness/manifest.json` 존재 여부만 확인했습니다.

**v0.3.1 상태**: `pah status`가 `harness_version`을 출력하고, `--harness-root`로 비교합니다.

- `cmd_status`가 `read_manifest_field`로 manifest의 `harness_version`을 읽어 출력 (`jq` 우선, 없으면 grep/sed 폴백)
- `pah status <target> --harness-root <path>`로 설치 버전 vs 하네스 `VERSION` 비교
- 불일치 시 `update available: installed <x>, harness_root <y>`와 업데이트 명령을 안내

```
# 실제 출력 예시
Personal-Agent-Harness installed: /path/to/project
Manifest: .harness/manifest.json
harness_version: 0.2.0
harness_root version: 0.3.1
update available: installed 0.2.0, harness_root 0.3.1
```

**남은 한계**: `--harness-root` 없이 호출하면 비교는 생략됩니다. 원격(npm registry) 최신 버전을 직접 조회하는 기능은 범위 밖입니다.

---

### 2-3. 🟡 Medium: Managed Block 컨텐츠 무결성 미검증

**현황**: `pah verify`는 `docs/<domain>/<domain>-standards.md` 파일의 SHA-256을 검증하지만, AGENTS.md/CLAUDE.md 내부 블록 컨텐츠는 검증하지 않습니다.

**결과**: 프로젝트 개발자가 managed 블록 내부를 수동 편집해도 verify가 통과됩니다. 블록 내 지침이 outdated된 채로 방치될 수 있습니다.

**개선 방향**: verify 시 소스 블록과 대상 블록을 비교하는 로직 추가, 또는 블록 컨텐츠 체크섬을 manifest에 포함.

---

### 2-4. 🟡 Medium: `install_gitignore_block` 마커 스타일 불일치

**현황**: 에이전트 블록은 HTML 주석 + 정확한 줄 매칭(`$0 == start`)을 사용하지만, gitignore 블록은 쉘 주석 + 정규식 패턴 매칭(`/# pah:managed:start/`)을 사용합니다.

마커 형식이 두 종류가 되면 새 기여자가 규칙을 이해하기 어렵습니다. 기능 오류는 아니지만 일관성이 저하됩니다.

---

### 2-5. ✅ 해소됨 (v0.3.1): `pah update` 서브커맨드 추가

**2026-06-02 현황**: `pah install`, `pah verify`, `pah status`는 있었으나 `pah update`만 없어 CLI 인터페이스가 일관적이지 않았습니다.

**v0.3.1 상태**: `cmd_update`가 추가되어 `pah update <target>`로 install + verify를 실행합니다 (npm 경로에서는 `PAH_SKIP_PULL=1`로 git pull 생략). `npx personal-agent-harness@latest update .`가 표준 업데이트 경로입니다.

---

### 2-6. 🟡 Medium: CI 통합 예시 없음

**현황**: `pah verify`가 드리프트를 감지할 수 있지만 CI/CD에서 자동 실행하는 예시 설정이 없습니다. 하네스가 배포된 프로젝트가 수동 편집으로 drift될 때 자동 감지 방법이 문서화되어 있지 않습니다.

**개선 방향**: `docs/usage.md`에 GitHub Actions 예시 추가.

```yaml
# .github/workflows/harness-verify.yml 예시
- name: Verify harness integrity
  run: npx personal-agent-harness verify .
```

---

### 2-7. 🟢 Low: 새 파일 생성 시 명시적 권한 설정 없음

**현황**: `merge_agent_block`이 새 AGENTS.md/CLAUDE.md를 생성할 때 명시적 `chmod`가 없습니다. `manifest.json`은 `chmod 644`로 명시되어 있지만 agent 파일은 umask 기본값에 의존합니다.

---

### 2-8. 🟢 Low: `pah diff` 커맨드 없음

**현황**: 현재 설치된 블록과 소스 블록의 실제 내용 차이를 확인하려면 dry-run을 실행해야 하는데, dry-run은 CREATE/MERGE 여부만 출력하고 실제 diff는 보여주지 않습니다.

---

### 2-9. 🟢 Low: 설치된 표준 파일에 버전 메타데이터 없음

**현황**: 대상 프로젝트에 복사된 표준 문서는 어느 PAH 버전에서 왔는지 알 수 없습니다. 에이전트가 파일을 읽을 때 최신 여부를 판단할 방법이 없습니다.

**개선 방향**: 파일 상단에 출처 주석 기록을 검토.

```markdown
<!-- Managed by Personal-Agent-Harness v0.2.0. Do not edit manually. -->
```

---

## 3. 종합 평가표

| 영역 | 평가 | 비고 |
|------|------|------|
| Registry 설계 | ✅ 우수 | 명시적, 검증됨, 순서 결정적 |
| Preflight 안전성 | ✅ 강함 | 부분 설치 구조적 차단 |
| Managed block 격리 | ✅ 우수 | 도메인별 독립, 프로젝트 내용 보존 |
| Manifest 무결성 | ✅ 강함 | canonical 재생성 + SHA-256 비교 |
| Shell 안전성 | ✅ 우수 | pipefail, atomic write, backslash 보존 |
| 테스트 커버리지 | ✅ 넓음 | 15+ 시나리오 |
| Cursor MDC 전략 | ✅ 적절 | glob-triggered / alwaysApply 구분 |
| Enforcement layer | ✅ 구현 (v0.3.1) | `hooks` 컴포넌트 + Claude Code PreToolUse |
| 버전 드리프트 감지 | ✅ 구현 (v0.3.1) | `status --harness-root` 비교 |
| CLI 일관성 | ✅ 구현 (v0.3.1) | `pah update` 서브커맨드 추가 |
| Block 컨텐츠 무결성 | ⚠️ 부분 | standards 파일만, block 내용 미검증 |
| CI 통합 | ⚠️ 문서만 | npx verify 예시 있음, 자동 실행 템플릿 없음 |
| 마커 스타일 | ⚠️ 불일치 | gitignore vs agent block |

---

## 4. 개선 우선순위

### 완료 (v0.3.1)

| 항목 | 효과 |
|------|------|
| Enforcement hooks 컴포넌트 추가 (2-1) | Advisory 한계 근본 해소 |
| `pah status` 버전 비교 추가 (2-2) | 운영 가시성 향상 |
| `pah update` 서브커맨드 추가 (2-5) | CLI 일관성 확보 |

### 잔여 (우선순위)

| 순위 | 항목 | 구현 비용 | 효과 |
|------|------|-----------|------|
| 1 | Block 컨텐츠 체크섬 또는 verify 로직 추가 (2-3) | 중간 | 무결성 보장 완성 |
| 2 | CI 자동 실행 워크플로우 템플릿 (2-6) | 낮음 | 드리프트 자동 감지 운영화 |
| 3 | gitignore/agent 마커 스타일 통일 (2-4) | 낮음 | 기여자 이해도 향상 |
| 4 | 설치 파일 버전 메타데이터 (2-9), `pah diff` (2-8), 명시적 chmod (2-7) | 낮음 | 관찰가능성·UX 보강 |
