# Rule Domain Registry and Git Workflow Handoff

## Objective

Add a scalable rule-domain registry to Personal-Agent-Harness, split each
installed domain into its own managed agent block, and add `git-workflow` as a
default rule domain.

## Workspace

- Repository: `<PAH_HOME>`
- Feature worktree:
  `<PAH_HOME>/.worktrees/rule-domain-registry`
- Feature branch: `feat/rule-domain-registry`
- Base commit: `7fa76ea`
- Latest commit before this handoff: `b6d3c15`

Continue all implementation and verification work inside the feature worktree.
Do not merge automatically. The user has not selected an integration method.

## Required Project Instructions

Before modifying the harness, read:

- `AGENTS.md`
- `docs/adding-rule-domains.md`
- `docs/development.md`

Run `bash tests/test_pah.sh` after harness changes.

## Implemented Changes

- Added `config/rule-domains.txt` with default domains:
  `devcontainer`, `git-workflow`.
- Split agent stubs into one managed block per domain under
  `templates/stubs/agent-blocks/`.
- Added English and Korean `git-workflow` standards and Cursor rule stub.
- Generalized `bin/pah` install and verify behavior around the registry.
- Added package preflight validation before target writes.
- Added strict managed-block marker checks.
- Added strict canonical manifest regeneration and comparison.
- Added component allowlist and empty component validation.
- Added unique backup directories and first-version-only backup behavior.
- Preserved literal backslashes and destination file modes during block merge.
- Bumped `VERSION` from `0.1.0` to `0.2.0`.
- Updated user and developer documentation for registry-based expansion.
- Expanded `tests/test_pah.sh` with registry, preflight, backup, manifest,
  component parsing, and literal escape regression cases.

## Important Commits

```text
b6d3c15 docs: registry 기반 규칙 도메인 확장 절차 반영
1595492 fix: components 빈 항목 검증 추가
5274ce5 test: registry preflight 경계 조건 보강
b27da88 fix: registry 병합과 manifest 검증을 엄격화
0524978 test: preflight 실패 무변경 조건 추가
8e4b463 test: registry 오류와 manifest 변조 검증 추가
215be64 feat: git workflow 규칙 도메인 추가
d0529e6 test: git workflow 기본 배포 시나리오 추가
b137cb6 fix: registry 설치 전 검증과 백업 안전성 강화
ff8b102 test: registry 설치 안전성 회귀 시나리오 추가
f3cae82 refactor: 규칙 도메인 설치를 registry 기반으로 일반화
a677534 test: 규칙 도메인 registry 전환 기준 추가
bf574f4 docs: 규칙 도메인 registry 구현 계획 추가
```

## Verification Already Completed

These commands passed after the implementation and documentation edits:

```bash
bash -n bin/pah setup.sh update.sh tests/test_pah.sh
bash tests/test_pah.sh
git diff --check
```

The full smoke suite ended with:

```text
All pah tests passed
```

A fresh temporary install was also verified:

```bash
tmp="$(mktemp -d)"
./bin/pah install "$tmp"
python3 -m json.tool "$tmp/.harness/manifest.json" >/dev/null
./bin/pah verify "$tmp"
stat -c '%a %n' \
  "$tmp/AGENTS.md" \
  "$tmp/CLAUDE.md" \
  "$tmp/.harness/manifest.json"
rm -rf "$tmp"
```

Observed modes were `644` for all three files. Documentation relative-link
checks passed as well.

## Multi-Agent Reviews

Several reviews were completed and their findings were fixed:

- Safety review: damaged block deletion, partial install, backup collision,
  and file mode issues.
- Spec review: registry verification structure and missing coverage.
- Quality review: literal backslash corruption, weak manifest checks,
  unknown component handling, preflight artifacts, and backup argument flow.
- Final focused code review by Franklin: approved.

One whole-implementation reviewer was still running when the user requested
this handoff:

```text
Bernoulli: 019e844b-1c78-7481-8d42-8a8a75848edb
```

If the multi-agent tool remains available, wait for that reviewer and address
any concrete findings before final completion.

## Remaining Steps

1. Wait for Bernoulli's final review result if available.
2. Inspect `git status --short` in the feature worktree.
3. Run fresh final verification:

```bash
bash -n bin/pah setup.sh update.sh tests/test_pah.sh
bash tests/test_pah.sh
git diff --check 7fa76ea..HEAD
```

4. Run a fresh temporary install, JSON parse, `pah verify`, and mode check.
5. Re-run the Markdown relative-link checker if documentation changes.
6. Commit this handoff document if the user wants it kept in branch history.
7. Clean up the duplicate untracked plan copy in the main checkout only after
   confirming it is the exact duplicate created during this work:

```text
<PAH_HOME>/docs/superpowers/plans/
2026-06-02-rule-domain-registry-and-git-workflow.md
```

8. Once final verification passes, present the standard integration choices:

```text
Implementation complete. What would you like to do?

1. Merge back to main locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

## Notes

- `.worktrees/` was added to `.git/info/exclude`, not committed.
- The main checkout currently has an untracked `docs/superpowers/` directory
  because the plan was initially created there before being copied and
  committed on the feature branch.
- Do not remove unrelated files from the main checkout.
- The plan document in the feature branch is:
  `docs/superpowers/plans/2026-06-02-rule-domain-registry-and-git-workflow.md`.
