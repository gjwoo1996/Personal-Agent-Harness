# Dev Container Notes

This project uses Personal-Agent-Harness dev container standards.

Authoritative standard:

`docs/devcontainer/devcontainer-standards.md`

Claude Code is installed by the official devcontainer Feature. Codex CLI is
installed in the Dockerfile with `CODEX_CLI_VERSION`.

## AI State Storage

This scaffold uses Docker named volumes for AI CLI state. The volume names are
generated from the workspace basename in `.devcontainer/commands/initializeCommand.sh`
and written to `.devcontainer/.env` as `aiStateVolumePrefix`.

Preserved paths:

- `/home/vscode/.claude`
- `/home/vscode/.claude.json`
- `/home/vscode/.codex`

Claude's `.claude.json` is file state, so the container stores it inside the
`claude-json` named volume and links `/home/vscode/.claude.json` to that file
during `postCreateCommand`.

Security impact: project-specific AI login state remains in Docker named
volumes after the container is rebuilt or removed. To reset it, remove the
project volumes, for example:

```bash
docker volume rm <workspace>-ai-state-claude-config
docker volume rm <workspace>-ai-state-claude-json
docker volume rm <workspace>-ai-state-codex-config
```

## Optional AI Skills

This scaffold does not automatically install superpowers, gstack, or browse
tooling. See `docs/devcontainer/devcontainer-standards.md` for the opt-in
principles and reference implementation guidance.

## Optional Firewall

`commands/init-firewall.sh` is included as an opt-in example. Wire it into
`postStartCommand` only after first-time package and browser downloads are
complete and after adding any project-specific allowed endpoints.

## Exceptions

Document any project-specific deviations here.

- Exception:
- Reason:
- Security and reproducibility impact:
- Required host setup:
- Verification:

## Verification

```bash
docker compose -f .devcontainer/docker-compose.dev.yml config
```

After logging in to Claude or Codex, rebuild the container and confirm the
login state is still available.
