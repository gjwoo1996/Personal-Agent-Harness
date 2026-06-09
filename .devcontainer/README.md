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
| AI state volumes | Not configured (use host login or add later) | Project chooses per standard |

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `invalid spec: ..::cached` | `containerWorkspaceFolder` missing in `.devcontainer/.env` | Reopen in Container (runs `initializeCommand`) or run `bash .devcontainer/commands/initializeCommand.sh` manually |
| `javascript-node:1-24-bookworm: not found` | Wrong image tag (legacy `1-24` prefix) | Use `24-bookworm` (see Dockerfile) |

## Verification

```bash
bash .devcontainer/commands/initializeCommand.sh
docker compose -f .devcontainer/docker-compose.dev.yml config
whoami                    # vscode
node --version            # v24.x
bash tests/test_pah.sh
npm pack
```
