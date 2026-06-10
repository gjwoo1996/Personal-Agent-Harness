# Harness Development Dev Container Design

**Date:** 2026-06-09  
**Status:** Approved (2026-06-09) — option 2: include AI CLIs  
**Scope:** `.devcontainer/` for Personal-Agent-Harness **repository development** (not the target-project template under `templates/devcontainer/`)

---

## Problem

Harness maintainers need a reproducible Linux environment to:

1. Run `npm pack`, `npm publish`, and `npx` smoke tests for the `personal-agent-harness` package
2. Run `bash tests/test_pah.sh` (bash 3.2+, `jq`)
3. Avoid WSL + Windows npm path conflicts (`/mnt/c/Program Files/nodejs/npm` cannot read WSL `package.json`)

Daily harness work is mostly bash. Node is required only for npm distribution workflows, but that workflow is now a first-class maintainer task.

---

## Goals

| Goal | Success criteria |
|------|------------------|
| Linux npm inside dev environment | `npm pack` and `npm whoami` succeed from repo root |
| Harness tests | `bash tests/test_pah.sh` passes |
| Reproducible onboarding | New machine: Docker + Reopen in Container → ready |
| Dogfooding | Follow `standards/devcontainer/devcontainer-standards.md` where practical |
| Isolation from target template | Do **not** copy `templates/devcontainer/` wholesale; do **not** install via `pah install --components devcontainer` |

## Non-goals (v1)

- GitHub Actions publish automation
- Windows native devcontainer support
- Monorepo-root devcontainer for entire `gw-personal/`
- Bundling AI CLI login state by default
- Auto-running `npm publish` on container create

---

## Approach Comparison

### A. Minimal image-only (`devcontainer.json` + `image`, no Compose)

```json
"image": "mcr.microsoft.com/devcontainers/javascript-node:1-24-bookworm"
```

| Pros | Cons |
|------|------|
| Smallest file set | Deviates from Compose-first standard |
| Fastest to ship | Harder to extend (sidecars, mounts) later |

### B. Compose + Dockerfile with AI CLIs (recommended — **selected**)

Compose `workspace` service, `javascript-node:24-bookworm` base, `jq` via apt, **Claude Code + Codex CLI** pinned in Dockerfile (same pattern as `templates/devcontainer/`).

| Pros | Cons |
|------|------|
| Matches project devcontainer standard | Slower first build than slim image |
| Terminal AI CLIs available inside container | AI CLI versions must be pinned and maintained |
| Dogfoods the distributed devcontainer template | |

### C. Full target-project template (copy `templates/devcontainer/`)

Includes Claude Code + Codex CLI, pinned versions, AI extensions.

| Pros | Cons |
|------|------|
| Maximum parity with distributed template | Overkill for bash-first harness dev |
| | Slower builds, more moving parts |
| | Blurs harness-dev vs target-project roles |

**Recommendation:** **B** — standards-aligned structure with AI CLIs (user selected option 2).

---

## Architecture

```text
Host (WSL2 / Windows + Docker)
  │
  │  Cursor: "Reopen in Container"
  ▼
.devcontainer/docker-compose.dev.yml
  service: workspace
    build: Dockerfile (node:24-bookworm + jq)
    mount: repo → /home/vscode/Personal-Agent-Harness
  │
  ▼
Maintainer workflows
  bash tests/test_pah.sh
  npm pack / npm publish (after npm login)
  bin/pah init /tmp/demo
```

### Base image

```dockerfile
FROM mcr.microsoft.com/devcontainers/javascript-node:24-bookworm
```

Rationale:

- Satisfies `package.json` `engines.node >= 22` (Node 24 LTS)
- Provides `vscode` user and `/home/vscode/` layout per standard
- Avoids separate Node feature installation on `base:ubuntu`

### Tools installed in Dockerfile

| Tool | Method | Purpose |
|------|--------|---------|
| Node 24 + npm | base image | `npm pack`, `npm publish`, `npx` tests |
| `jq` | `apt-get` | `tests/test_pah.sh` |
| `git` | base image (preinstalled) | harness scripts, safe.directory |

### AI CLIs (included per user choice)

| Tool | Method | Pinning |
|------|--------|---------|
| Claude Code CLI | `npm install -g` in Dockerfile | `CLAUDE_CODE_VERSION` build arg |
| Codex CLI | `npm install -g` in Dockerfile | `CODEX_CLI_VERSION` build arg |

VS Code extensions: `anthropic.claude-code`, `openai.chatgpt` (same as target template).

Validated versions at design time (update intentionally):

- `CLAUDE_CODE_VERSION=2.1.169`
- `CODEX_CLI_VERSION=0.138.0`

---

## File Layout

```text
Personal-Agent-Harness/
└── .devcontainer/
    ├── devcontainer.json
    ├── docker-compose.dev.yml
    ├── Dockerfile
    ├── commands/
    │   ├── initializeCommand.sh
    │   ├── post-create.sh
    │   └── post-start.sh
    ├── .env.example
    └── README.md
```

**Not added:**

- Root `.env` / `.env.example` — no app runtime secrets in harness repo
- `.devcontainer/.env` committed — generated locally by `initializeCommand.sh` (gitignored if empty placeholder only)

`templates/devcontainer/` remains the **target-project** scaffold installed via `pah install --components devcontainer`. The new `.devcontainer/` is **harness-maintainer-only** and lives only in this repo.

---

## Component Details

### `devcontainer.json`

```json
{
  "name": "Personal-Agent-Harness (dev)",
  "dockerComposeFile": "docker-compose.dev.yml",
  "service": "workspace",
  "workspaceFolder": "/home/vscode/${localWorkspaceFolderBasename}",
  "remoteUser": "vscode",
  "updateRemoteUserUID": true,
  "initializeCommand": ".devcontainer/commands/initializeCommand.sh",
  "postCreateCommand": ".devcontainer/commands/post-create.sh",
  "postStartCommand": ".devcontainer/commands/post-start.sh",
  "features": {},
  "customizations": {
    "vscode": {
      "extensions": [
        "anthropic.claude-code",
        "openai.chatgpt"
      ]
    }
  },
  "forwardPorts": [],
  "shutdownAction": "stopCompose"
}
```

### `docker-compose.dev.yml`

- Single `workspace` service
- Build context: `.devcontainer/`
- Volume: `..` → `${containerWorkspaceFolder}` (repo root)
- Command: `sleep infinity`

AI CLI build args from `.devcontainer/.env` (same as target template).

### `Dockerfile`

```dockerfile
FROM mcr.microsoft.com/devcontainers/javascript-node:24-bookworm

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl jq \
    && rm -rf /var/lib/apt/lists/*

ARG CLAUDE_CODE_VERSION
ARG CODEX_CLI_VERSION
RUN npm install -g \
    "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
    "@openai/codex@${CODEX_CLI_VERSION}" \
    && claude --version \
    && codex --version

USER vscode
```

### `commands/initializeCommand.sh`

- Idempotent
- Ensures `.devcontainer/.env` exists (copy from `.env.example` if missing)
- `.env.example` contains pinned `CLAUDE_CODE_VERSION` and `CODEX_CLI_VERSION`

### `commands/post-create.sh`

- `set -euo pipefail`
- `git config --global --add safe.directory "$PWD"`
- Print versions: `node`, `npm`, `jq`, `bash`
- Print reminder: run `npm login` before first `npm publish`
- **Do not** auto-run `tests/test_pah.sh` (maintainer choice; documented in README)

### `commands/post-start.sh`

- Lightweight banner only (same pattern as target template)

---

## npm Authentication

npm 2FA cannot be automated. Two supported paths:

### Option 1 — Login inside container (default doc)

```bash
npm login
npm whoami
```

Credentials stored in container home (`~/.npmrc`). Lost on image rebuild unless volume added later.

### Option 2 — Host bind mount (optional, documented)

Add to `docker-compose.dev.yml` **only when maintainer opts in**:

```yaml
volumes:
  - ${localEnv:HOME}/.npmrc:/home/vscode/.npmrc:ro
```

Document security: read-only mount, personal machine only, not for CI.

---

## Workspace Opening

| How workspace is opened | Devcontainer detected? |
|-------------------------|------------------------|
| `Personal-Agent-Harness/` as Cursor root | Yes |
| `gw-personal/` monorepo root | **No** — `.devcontainer` is in subfolder |

**README must state:** For monorepo harness work, open `Personal-Agent-Harness/` folder directly, or use VS Code multi-root / subfolder reopen if supported.

---

## Documentation Updates (implementation phase)

| File | Change |
|------|--------|
| `docs/development.md` | Add "Dev container" section before npm publish; link to `.devcontainer/README.md` |
| `etc/04-남은-작업.md` | Add devcontainer item under P1 or note completion |
| `.gitignore` | Ignore `.devcontainer/.env` if generated |

No change to `pah install` components — harness `.devcontainer` is not distributed to target projects.

---

## Verification Checklist

After implementation:

```bash
docker compose -f .devcontainer/docker-compose.dev.yml config
# Reopen in Container (manual)
whoami          # vscode
pwd             # /home/vscode/Personal-Agent-Harness (or basename)
node --version  # v24.x
npm --version
jq --version
bash tests/test_pah.sh
npm pack
tar -tzf personal-agent-harness-*.tgz | head -20
```

---

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Monorepo users don't see devcontainer | README + `docs/development.md` callout |
| npm login lost on rebuild | Document re-login; optional `.npmrc` mount |
| Drift from `templates/devcontainer/` | Intentional; exceptions documented |
| Docker not installed on host | Document prerequisite; WSL nvm remains fallback |

---

## Implementation Plan (next step)

After spec approval:

1. Create `.devcontainer/` files per layout above
2. Update `docs/development.md`
3. Update `.gitignore` for `.devcontainer/.env`
4. Run compose config + `test_pah.sh` inside container (manual smoke)
5. Do **not** add harness `.devcontainer` to `package.json` `files` or npm tarball
