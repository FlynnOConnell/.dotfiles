#!/usr/bin/env bash
# new omarchy machine: log into github, clone dotfiles and notes, install.
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/FlynnOConnell/.dotfiles/master/bootstrap-omarchy.sh)

set -euo pipefail

REPOS="$HOME/repos"
CLONE=(.dotfiles arctic-lake home_hub sciview)

command -v gh >/dev/null || omarchy-pkg-add github-cli
# --git-protocol ssh offers to generate and upload an ssh key
gh auth status >/dev/null 2>&1 || gh auth login --git-protocol ssh --web </dev/tty

export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new"
mkdir -p "$REPOS"
for r in "${CLONE[@]}"; do
  [[ -d $REPOS/$r ]] || gh repo clone "FlynnOConnell/$r" "$REPOS/$r"
done

# per-host files are keyed by hostname, so a name already in hosts/ would
# hand this machine another machine's monitors.lua
HOST="$(uname -n)"
while [[ -d $REPOS/.dotfiles/omarchy/hosts/$HOST ]]; do
  read -rp "omarchy/hosts/$HOST/ already exists. new hostname (empty to reuse it): " name </dev/tty
  [[ -z $name ]] && break
  hostnamectl set-hostname "$name"
  HOST="$name"
done

"$REPOS/.dotfiles/install-omarchy.sh" --fresh
# private fleet-hub layer (ssh aliases, claude/MCP, and hub screen access)
[[ -x "$REPOS/home_hub/install-hub.sh" ]] && "$REPOS/home_hub/install-hub.sh" --fresh
hyprctl reload >/dev/null || true

echo
echo "done. omarchy's replaced defaults are in ~/.dotfiles-backup/"
echo "this machine's monitors.lua is in omarchy/hosts/$(uname -n)/, commit it from ~/repos/.dotfiles"
