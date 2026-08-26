#!/usr/bin/env bash
# per-user HPC bootstrap. idempotent - re-run any time the shell drifts.
#
#   bash ~/.dotfiles/hpc/setup.sh
#
# wires ~/.bashrc to source hpc/hpc.sh and creates your personal dir. it does
# not install tools; run install-server.sh for those.
set -eu

_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# the dotfiles ship a ~/.bashrc that already sources hpc.sh, and dotbot symlinks
# it into place - grep follows the link, so that case needs no edit at all.
if grep -q 'hpc/hpc.sh' "$HOME/.bashrc" 2>/dev/null; then
    echo "ok: ~/.bashrc already sources hpc.sh"
else
    # only now does appending matter, and appending into a symlink would write
    # into a tracked repo file - make it a real file first.
    if [ -L "$HOME/.bashrc" ]; then
        cp --remove-destination "$(readlink -f "$HOME/.bashrc")" "$HOME/.bashrc"
        echo "unlinked: ~/.bashrc is now a real file"
    fi
    # sourced last, so it wins over any site profile or module-system prompt hook
    printf '
# dotfiles hpc environment
source %s/hpc.sh
' "$_dir" >> "$HOME/.bashrc"
    echo "added: source $_dir/hpc.sh -> ~/.bashrc"
fi

. "$_dir/env.sh"

if [ -n "${HPC_USER:-}" ]; then
    mkdir -p "$HPC_USER" 2>/dev/null \
        && echo "user dir: $HPC_USER" \
        || echo "warn: could not create $HPC_USER - set HPC_USER in ~/.bashrc.local"
fi

echo
echo "site: $HPC_SITE"
echo "done. start a fresh shell:  exec bash"
