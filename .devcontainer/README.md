# Harness Maintainer Dev Container

Dev container for **Personal-Agent-Harness repository development** (bash tests, npm pack/publish).

This is **not** the target-project scaffold under `templates/devcontainer/`. That template is installed on other projects via `pah install --components devcontainer`.

Authoritative standard: `standards/devcontainer/devcontainer-standards.md`

## Purpose

| Workflow | Command |
|----------|---------|
| Harness tests | `bash tests/test_pah.sh` |
| npm tarball check | `npm pack` |
| npm publish | `npm login` then `npm publish` |
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

1. `initializeCommand.sh` writes `.devcontainer/.env` with workspace paths and pinned AI CLI versions.
2. Rebuild the container if you change AI CLI versions in `.env`.
3. Run `npm login` inside the container before the first `npm publish`.

## AI CLI versions

Pinned in `.devcontainer/.env` (from `.env.example`):

- `CLAUDE_CODE_VERSION`
- `CODEX_CLI_VERSION`

Update intentionally after validating with `claude --version` / `codex --version` post-rebuild.

## AI state volumes

Claude Code and Codex CLI state persist across **Rebuild Container** via Docker named volumes (host paths are not shared):

| Volume | Mount | Persists |
|--------|-------|----------|
| `pah-claude-config` | `/home/vscode/.claude` | Login, sessions, plugins |
| `pah-codex-config` | `/home/vscode/.codex` | Login, sessions, plugins, `config.toml` |

On first container create, named volumes may mount as `root`. `post-create.sh` runs `ensure-ai-volume-permissions.sh` before any AI CLI setup.

Reset all AI state (login + superpowers + sessions):

```bash
docker volume rm pah-claude-config pah-codex-config
```

Then **Rebuild Container** to recreate empty volumes and rerun `post-create.sh`.

Fix permissions only (keep login/sessions):

```bash
bash .devcontainer/commands/ensure-ai-volume-permissions.sh
```

## Superpowers (Claude Code · Codex CLI)

Installed automatically on container create by `.devcontainer/commands/install-superpowers.sh` (idempotent — skips if already present in the volume).

| Tool | Source |
|------|--------|
| Claude Code | `superpowers@superpowers-marketplace` |
| Codex CLI | Skills symlink (`~/.agents/skills/superpowers` → `~/.codex/superpowers/skills`); plugin `superpowers@openai-curated` when marketplace is ready |

On first `post-create`, the Codex marketplace may not be initialized yet. The install script clones [obra/superpowers](https://github.com/obra/superpowers) into the `pah-codex-config` volume and symlinks skills (reliable). Plugin install is attempted when `openai-curated` is available.

Codex subagent skills also enable `multi_agent = true` in `~/.codex/config.toml`.

Manual reinstall or update:

```bash
bash .devcontainer/commands/install-superpowers.sh
claude plugin update superpowers
codex plugin marketplace upgrade openai-curated
```

Verify:

```bash
claude plugin list | grep superpowers
ls -la ~/.agents/skills/superpowers    # Codex skills symlink
codex plugin list | grep superpowers   # optional plugin path
```

## npm credentials

**Default:** `npm login` inside the container. Credentials live in `~/.npmrc` and are lost on full image rebuild.

**Optional (personal machine):** bind-mount host `~/.npmrc` read-only in `docker-compose.dev.yml`:

```yaml
volumes:
  - ${localEnv:HOME}/.npmrc:/home/vscode/.npmrc:ro
```

Do not commit real tokens. Do not use host mounts on shared machines.

## Exceptions from distributed template

| Item | This devcontainer | Target `templates/devcontainer/` |
|------|-------------------|----------------------------------|
| Audience | Harness maintainers | Applied projects |
| Distributed via npm | No | Yes (`pah install`) |
| AI CLIs | Included (pinned) | Included (pinned) |
| AI state volumes | Named volumes (`pah-claude-config`, `pah-codex-config`) | Project chooses per standard |
| Superpowers | Auto-installed in `post-create.sh` | Not included by default |

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `EACCES: permission denied, mkdir '/home/vscode/.claude/plugins'` | Named volume mounted as `root` on first create | Run `bash .devcontainer/commands/ensure-ai-volume-permissions.sh` or Rebuild Container |
| `invalid spec: ..::cached` | `containerWorkspaceFolder` missing in `.devcontainer/.env` | Reopen in Container (runs `initializeCommand`) or run `bash .devcontainer/commands/initializeCommand.sh` manually |
| `javascript-node:1-24-bookworm: not found` | Wrong image tag (legacy `1-24` prefix) | Use `24-bookworm` (see Dockerfile) |

## Verification

```bash
bash .devcontainer/commands/initializeCommand.sh
docker compose -f .devcontainer/docker-compose.dev.yml config
whoami                    # vscode
node --version            # v24.x
claude plugin list | grep superpowers
codex plugin list | grep superpowers
bash tests/test_pah.sh
npm pack
```

After changing volume or superpowers settings, rebuild twice and confirm plugin lines still show installed without reinstalling.
