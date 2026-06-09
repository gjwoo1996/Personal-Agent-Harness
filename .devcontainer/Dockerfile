# Harness maintainer devcontainer: Node 24 for npm publish + pinned AI CLIs.
# Target-project scaffold lives in templates/devcontainer/ (installed via pah).
FROM mcr.microsoft.com/devcontainers/javascript-node:24-bookworm

# Align with devcontainer standard: vscode user + /home/vscode workspace path.
USER root
RUN usermod -l vscode -d /home/vscode -m node \
    && groupmod -n vscode node \
    && find /etc/sudoers.d -type f -exec sed -i 's/\bnode\b/vscode/g' {} + 2>/dev/null || true

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
