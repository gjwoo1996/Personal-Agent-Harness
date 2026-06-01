# Personal-Agent-Harness 하네스 엔지니어링 분석 보고서

> **문서 유형:** 사람 참고용 분석 문서. `pah install` 대상이 아닙니다.
> **작성일:** 2026-06-02
> **대상 버전:** v0.2.0 (`88f19aa`)

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

### 2-1. 🔴 Critical: Enforcement Layer 부재

**현황**: CLAUDE.md/AGENTS.md 블록은 *advisory* 텍스트입니다. AI가 컨텍스트에 포함해 읽지만 강제력이 없습니다.

**2025-2026 업계 관점** (HumanLayer, Claude Code Hooks):

> "CLAUDE.md is text that becomes part of the model's context. A sufficiently confident hallucination, an ambiguous instruction, or a single context-window truncation can override a CLAUDE.md rule. Hooks are deterministic and guarantee the action happens."

현재 PAH는 Anthropic Claude Code hooks 시스템 (PreToolUse, PostToolUse, UserPromptSubmit 등)과 연결되어 있지 않습니다.

- 커밋 전에 `git-workflow-standards.md`를 실제로 읽도록 강제하는 hook 없음
- `.devcontainer/` 파일 수정 시 devcontainer 표준 확인을 강제하는 hook 없음

**개선 방향**: `rules` 컴포넌트 외에 별도 `hooks` 컴포넌트를 추가해 `.claude/settings.json` 스텁을 병합하는 방식을 검토할 수 있습니다.

```bash
# 예시: 향후 pah install . --components rules,hooks
# → .claude/settings.json에 UserPromptSubmit hook 병합
```

---

### 2-2. 🔴 Critical: 버전 드리프트 감지 없음

**현황**: `pah status`는 `.harness/manifest.json` 존재 여부만 확인합니다. manifest에 `harness_version`이 기록되어 있지만 현재 하네스 버전과의 비교는 없습니다.

**결과**: 하네스가 신규 버전으로 업그레이드된 후 프로젝트가 구버전 기준으로 뒤처져도 경고가 없습니다.

**개선 방향**: `pah status`에 버전 비교 로직 추가.

```
# 개선 후 출력 예시
Personal-Agent-Harness installed: /path/to/project
  Installed version: 0.2.0
  Current harness:   0.5.0
  WARNING: Run update.sh to upgrade.
```

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

### 2-5. 🟡 Medium: `pah update` 서브커맨드 없음

**현황**: `update.sh`는 `git pull --ff-only` + `pah install` + `pah verify`를 실행하는 별도 진입 스크립트입니다. `pah install`, `pah verify`, `pah status`가 있는데 `pah update`만 없어 CLI 인터페이스가 일관적이지 않습니다.

---

### 2-6. 🟡 Medium: CI 통합 예시 없음

**현황**: `pah verify`가 드리프트를 감지할 수 있지만 CI/CD에서 자동 실행하는 예시 설정이 없습니다. 하네스가 배포된 프로젝트가 수동 편집으로 drift될 때 자동 감지 방법이 문서화되어 있지 않습니다.

**개선 방향**: `docs/usage.md`에 GitHub Actions 예시 추가.

```yaml
# .github/workflows/harness-verify.yml 예시
- name: Verify harness integrity
  run: ./Personal-Agent-Harness/bin/pah verify .
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
| Enforcement layer | ❌ 없음 | 가장 큰 갭 — advisory only |
| 버전 드리프트 감지 | ❌ 없음 | status가 존재만 확인 |
| Block 컨텐츠 무결성 | ⚠️ 부분 | standards 파일만, block 내용 미검증 |
| CI 통합 | ⚠️ 없음 | verify는 있지만 예시 없음 |
| CLI 일관성 | ⚠️ 부분 | update.sh가 pah 서브커맨드가 아님 |
| 마커 스타일 | ⚠️ 불일치 | gitignore vs agent block |

---

## 4. 개선 우선순위

| 순위 | 항목 | 구현 비용 | 효과 |
|------|------|-----------|------|
| 1 | Enforcement hooks 컴포넌트 추가 (2-1) | 높음 | Advisory 한계 근본 해소 |
| 2 | `pah status`에 버전 비교 추가 (2-2) | 낮음 | 운영 가시성 즉시 향상 |
| 3 | Block 컨텐츠 체크섬 또는 verify 로직 추가 (2-3) | 중간 | 무결성 보장 완성 |
| 4 | `pah update` 서브커맨드 + CI 예시 문서 (2-5, 2-6) | 낮음 | UX와 운영 패턴 정렬 |
