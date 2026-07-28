# Harness Maintainer Dev Container

Dev container for **Personal-Agent-Harness repository development** (bash tests, optional package-layout checks, and GitHub tag releases).

This is **not** the target-project scaffold under `templates/devcontainer/`. That template is installed on other projects via `pah install --components devcontainer`.

Authoritative standard: `standards/devcontainer/devcontainer-standards.md`

## Purpose

| Workflow | Command |
|----------|---------|
| Harness tests | `bash tests/test_pah.sh` |
| Package-layout check (optional) | `npm pack --dry-run` |
| GitHub (PR, issues) | `gh auth login` then `gh pr create`, etc. |
| Manual demo | `bin/pah init /tmp/pah-demo` |

Solves WSL + Windows npm path conflicts by providing Linux npm inside the container.

## Prerequisites

- Docker (Docker Desktop on Windows with WSL2 backend, or native Linux Docker)
- Cursor or VS Code with Dev Containers extension

## Open the workspace

| Workspace root | Dev container detected? |
|----------------|-------------------------|
| `Personal-Agent-Harness/` (this repo) | Yes |
| Parent monorepo (e.g. `gw-personal/`) | No — open this folder directly |

Use **Reopen in Container** from the command palette.

## First-time setup

1. `initializeCommand.sh` writes `.devcontainer/.env` with workspace paths and the pinned Codex CLI version.
2. Ensure the host has `~/.gitconfig` with at least `user.name` and `user.email`; the maintainer Compose file mounts it read-only.
3. Rebuild the container if you change the Codex CLI version in `.env`.
4. Run `gh auth login` once. The named `pah-gh-config` volume preserves the login across rebuilds.

## GitHub CLI

Installed via devcontainer feature `ghcr.io/devcontainers/features/github-cli:1` (pinned in `devcontainer.json`).

Authenticate once per `pah-gh-config` volume:

```bash
gh auth login
gh auth status
```

## AI CLI versions

Claude Code is installed by the official devcontainer Feature
`ghcr.io/anthropics/devcontainer-features/claude-code:1.0`.

Codex CLI is pinned in `.devcontainer/.env` (from `.env.example`):

- `CODEX_CLI_VERSION`

Update intentionally after validating with `claude --version` / `codex --version` post-rebuild.

## AI state volumes

Claude Code and Codex CLI state persist across **Rebuild Container** via Docker named volumes (host paths are not shared):

| Volume | Mount | Persists |
|--------|-------|----------|
| `pah-claude-config` | `/home/vscode/.claude` | Login, sessions, plugins |
| `pah-claude-json` | `/home/vscode/.ai-state/claude` | Claude `.claude.json` file state |
| `pah-codex-config` | `/home/vscode/.codex` | Login, sessions, plugins, `config.toml` |
| `pah-cursor-skills` | `/home/vscode/.cursor/skills` | Cursor-installed skills |
| `pah-cursor-plugins` | `/home/vscode/.cursor/plugins` | Cursor marketplace plugins |
| `pah-bun-home` | `/home/vscode/.bun` | Pinned Bun runtime and cache used by gstack |
| `pah-gh-config` | `/home/vscode/.config/gh` | GitHub CLI authentication and settings |

On first container create, named volumes may mount as `root`. Both create and start lifecycle paths run `ensure-ai-volume-permissions.sh`; start repairs permissions before any skill setup.

Reset all AI state (login + superpowers + sessions):

```bash
docker volume rm pah-claude-config pah-claude-json pah-codex-config pah-cursor-skills pah-cursor-plugins pah-bun-home pah-gh-config
```

Then **Rebuild Container** to recreate empty volumes and rerun `post-create.sh`.

Fix permissions only (keep login/sessions):

```bash
bash .devcontainer/commands/ensure-ai-volume-permissions.sh
```

## AI skills (superpowers · gstack · browse)

Installed and repaired automatically by `.devcontainer/commands/ensure-ai-skills.sh`
on container create and start. Defaults and optional repo refs live in
`.devcontainer/versions.env`.

| Tool | Source |
|------|--------|
| Claude Code | `superpowers@superpowers-marketplace` |
| Codex CLI | Skills symlink (`~/.agents/skills/superpowers` → `~/.codex/superpowers/skills`); plugin `superpowers@openai-curated` when marketplace is ready |
| gstack/browse | `GSTACK_REPO` cloned to `~/.codex/gstack`, configured for Claude, Codex, and Cursor with Bun |

On first `post-create`, the Codex marketplace may not be initialized yet. The install script clones [obra/superpowers](https://github.com/obra/superpowers) into the `pah-codex-config` volume and symlinks skills (reliable). Plugin install is attempted when `openai-curated` is available.

Codex subagent skills also enable `multi_agent = true` in `~/.codex/config.toml`.

The browser health check uses `chromium` and warns without failing the whole
container when browse is not healthy.

Manual reinstall or update:

```bash
bash .devcontainer/commands/ensure-ai-skills.sh
claude plugin update superpowers
codex plugin marketplace upgrade openai-curated
```

Verify:

```bash
claude plugin list | grep superpowers
ls -la ~/.agents/skills/superpowers    # Codex skills symlink
codex plugin list | grep superpowers   # optional plugin path
test -d ~/.codex/gstack
```

## Firewall

`post-start.sh` runs `ensure-ai-skills.sh` first, then `init-firewall.sh`. The
firewall is idempotent and allows loopback, established connections, DNS,
GitHub, npm, Anthropic, OpenAI, Bun, and Playwright/Chromium download endpoints.
If `iptables` or `ipset` is unavailable, it prints `WARN:` and leaves networking
unchanged.

## Git identity and GitHub HTTPS authentication

The maintainer Compose file binds host `~/.gitconfig` to the container read-only for `user.name` and `user.email`. Create it on the host before opening the container:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

`post-create.sh` runs `commands/ensure-git-auth.sh`, which writes GitHub and Gist credential helpers to the separate XDG file `~/.config/git/config`:

```text
!gh auth git-credential
```

Authenticate and verify HTTPS Git access:

```bash
gh auth login
gh auth status
git config --file "$HOME/.config/git/config" --get credential.https://github.com.helper
git ls-remote https://github.com/gjwoo1996/Personal-Agent-Harness.git HEAD
```

The host file remains read-only; do not run `gh auth setup-git` against it. The `pah-gh-config` volume keeps the `gh` token across rebuilds. This personal-WSL setup is not a shared-machine credential model; SSH agent and `~/.ssh` mounts are out of scope.

## Exceptions from distributed template

| Item | This devcontainer | Target `templates/devcontainer/` |
|------|-------------------|----------------------------------|
| Audience | Harness maintainers | Applied projects |
| Distributed through the GitHub package | No | Yes (`pah install`) |
| AI CLIs | Claude Feature + pinned Codex | Claude Feature + pinned Codex |
| AI state volumes | Named volumes for Claude, Codex, Cursor, Bun, and gh | Named volumes for Claude, Codex, Cursor, Bun, and gh |
| Host `.gitconfig` | Read-only bind, default-on | Commented personal-WSL example |
| Superpowers/gstack | Auto-repaired in `post-create.sh` and `post-start.sh` | Not included by default |
| Firewall | Default-on after AI setup | Opt-in example only |

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `EACCES: permission denied, mkdir '/home/vscode/.claude/plugins'` | Named volume mounted as `root` on first create | Run `bash .devcontainer/commands/ensure-ai-volume-permissions.sh` or Rebuild Container |
| `invalid spec: ..::cached` | `containerWorkspaceFolder` missing in `.devcontainer/.env` | Reopen in Container (runs `initializeCommand`) or run `bash .devcontainer/commands/initializeCommand.sh` manually |
| `javascript-node:1-24-bookworm: not found` | Wrong image tag (legacy `1-24` prefix) | Use `24-bookworm` (see Dockerfile) |
| gstack or browse missing | Bun, clone, or browser setup failed temporarily | Run `bash .devcontainer/commands/ensure-ai-skills.sh` |

## Verification

```bash
bash .devcontainer/commands/initializeCommand.sh
docker compose -f .devcontainer/docker-compose.dev.yml config
whoami                    # vscode
node --version            # v24.x
gh --version              # 2.93.0
gh auth status
git config --file "$HOME/.config/git/config" --get credential.https://github.com.helper
claude plugin list | grep superpowers
codex plugin list | grep superpowers
bash .devcontainer/commands/ensure-ai-skills.sh
bash tests/test_pah.sh
npm pack
```

After changing volume or superpowers settings, rebuild twice and confirm plugin lines still show installed without reinstalling.
