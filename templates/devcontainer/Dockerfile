# The scaffold uses a Node devcontainer image so npm is available while the
# image installs npm-distributed AI CLIs. Claude Code is provided by its
# official devcontainer Feature in devcontainer.json.
FROM mcr.microsoft.com/devcontainers/javascript-node:24-bookworm

USER root
RUN usermod -l vscode -d /home/vscode -m node \
    && groupmod -n vscode node \
    && find /etc/sudoers.d -type f -exec sed -i 's/\bnode\b/vscode/g' {} + 2>/dev/null || true

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl jq \
    && rm -rf /var/lib/apt/lists/*

ARG CODEX_CLI_VERSION

RUN npm install -g \
    "@openai/codex@${CODEX_CLI_VERSION}" \
    && codex --version

USER vscode
