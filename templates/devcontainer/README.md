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
- `/home/vscode/.cursor/skills`
- `/home/vscode/.cursor/plugins`
- `/home/vscode/.bun`
- `/home/vscode/.config/gh`

Claude's `.claude.json` is file state, so the container stores it inside the
`claude-json` named volume and links `/home/vscode/.claude.json` to that file
during `postCreateCommand`.

Security impact: project-specific AI login state remains in Docker named
volumes after the container is rebuilt or removed. To reset it, remove the
project volumes, for example:

```bash
docker volume rm <workspace>-ai-state-claude-config <workspace>-ai-state-claude-json <workspace>-ai-state-codex-config <workspace>-ai-state-cursor-skills <workspace>-ai-state-cursor-plugins <workspace>-ai-state-bun-home <workspace>-ai-state-gh-config
```

`post-create.sh` and `post-start.sh` run `ensure-ai-volume-permissions.sh` so first-mount root ownership is repaired idempotently.

The Cursor and Bun volumes preserve state only. This scaffold does not install
Cursor skills, plugins, superpowers, or gstack automatically.

## Git identity and GitHub HTTPS authentication

The `gh-config` volume preserves `gh auth login` across rebuilds.
`ensure-git-auth.sh` writes the GitHub and Gist credential helper to
`~/.config/git/config` without modifying host configuration.

For a personal WSL environment:

1. Ensure host `~/.gitconfig` contains `user.name` and `user.email`.
2. Uncomment the read-only `.gitconfig` bind in `docker-compose.dev.yml`.
3. Rebuild, then run `gh auth login` and `gh auth status` in the container.

Verify:

```bash
git config --global --get user.name
git config --file "$HOME/.config/git/config" --get credential.https://github.com.helper
gh auth status
```

Do not enable a personal credential bind on shared machines or CI. SSH agent
and `~/.ssh` forwarding are outside this template's default scope.

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

Normal Dev Container startup runs `initializeCommand` automatically:

```bash
devcontainer up --workspace-folder .
```

When rendering Compose directly, generate `.devcontainer/.env` first:

```bash
bash .devcontainer/commands/initializeCommand.sh
docker compose -f .devcontainer/docker-compose.dev.yml config
```

After logging in to Claude or Codex, rebuild the container and confirm the
login state is still available. After `gh auth login`, also confirm
`gh auth status` survives a rebuild.
