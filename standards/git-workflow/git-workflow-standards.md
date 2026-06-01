# Git Workflow Standards

This is the authoritative git workflow rule document distributed by Personal-Agent-Harness.
AI agents should read this English document before preparing commits or changing git history.

## Status

Priority order:

1. Direct user instruction
2. Project-specific git workflow rules and documented exceptions
3. This document
4. Historical notes or translations

Korean translations are for human reading only. Do not use `*.ko.md` files as AI rule sources.

## Before Creating Commits

- Run `git status --short`.
- Inspect tracked unstaged changes with `git diff`.
- Inspect staged changes with `git diff --staged`.
- Read new files that are candidates for the commit because they do not appear in a normal tracked diff.
- Preserve user-owned and unrelated changes.
- Exclude temporary files, generated files, secrets, and unrelated local files.

## Commit Grouping

- Keep one clear purpose in each commit.
- Split independent feature, fix, refactor, docs, test, configuration, dependency, formatting, and file-move changes when they can stand alone.
- Keep tightly coupled code and tests together when separating them would make the commit misleading or unusable.
- Explain the proposed grouping before committing when multiple commits are needed.

## Commit Messages

Use Conventional Commits by default:

```text
<type>: <summary>

<body>
```

Common types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`.

- Make the summary specific and easy to scan.
- Use the body when the reason, behavioral difference, or verification result is not obvious.
- Prefer explaining why the change exists instead of merely listing edited files.
- Follow a project-specific message language rule when one exists.

## History Safety

Without an explicit user request:

- Do not amend existing commits.
- Do not rebase or squash commits.
- Do not force-push.
- Do not discard changes with destructive commands.
- Do not revert changes that appear to belong to the user.

## After Creating Commits

- Run `git status --short`.
- Report the created commit hashes and summaries.
- Report any remaining changes separately.

## Project Exceptions

Document project-specific differences in `docs/git-workflow/README.md`.

Examples:

- Required commit message language
- Additional commit types such as `infra`
- Branch naming rules
- Pull request and review requirements
- Whether user confirmation is required immediately before creating commits
