# Harness maintainer devcontainer: Node 24 + pinned Codex CLI.
# Target-project scaffold lives in templates/devcontainer/ (installed via pah).
FROM mcr.microsoft.com/devcontainers/javascript-node:24-bookworm

ENV BUN_INSTALL=/home/vscode/.bun
ENV PATH=${BUN_INSTALL}/bin:${PATH}

# Align with devcontainer standard: vscode user + /home/vscode workspace path.
USER root
RUN usermod -l vscode -d /home/vscode -m node \
    && groupmod -n vscode node \
    && find /etc/sudoers.d -type f -exec sed -i 's/\bnode\b/vscode/g' {} + 2>/dev/null || true

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl jq chromium \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p \
      /home/vscode/.codex \
      /home/vscode/.cursor/skills \
      /home/vscode/.cursor/plugins \
    && chown -R vscode:vscode /home/vscode/.codex /home/vscode/.cursor \
    && printf '%s\n' \
      'export BUN_INSTALL=/home/vscode/.bun' \
      'case ":$PATH:" in *":$BUN_INSTALL/bin:"*) ;; *) export PATH="$BUN_INSTALL/bin:$PATH" ;; esac' \
      > /etc/profile.d/pah-bun.sh

ARG CODEX_CLI_VERSION

RUN npm install -g \
    "@openai/codex@${CODEX_CLI_VERSION}" \
    && codex --version

USER vscode
