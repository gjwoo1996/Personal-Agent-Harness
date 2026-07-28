#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.config/git"
git config --file "$HOME/.config/git/config" \
  credential.https://github.com.helper '!gh auth git-credential'
git config --file "$HOME/.config/git/config" \
  credential.https://gist.github.com.helper '!gh auth git-credential'
