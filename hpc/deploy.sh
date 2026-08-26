#!/usr/bin/env bash
# deploy these dotfiles to a cluster over ssh. no root anywhere.
#
#   hpc/deploy.sh flynn@biohpc
#   hpc/deploy.sh flynn@biohpc --tools essentials
#   hpc/deploy.sh flynn@biohpc --rsync          # cluster has no outbound network
#
# by default the remote clones from github (fast, and `hpc-update` works after).
# --rsync pushes this working copy instead, for clusters that cannot reach
# github - the tool downloads in install-server.sh still need network, so pair
# it with --tools none there.
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/FlynnOConnell/.dotfiles.git}"
REMOTE_ROOT="${REMOTE_ROOT:-\$HOME/.dotfiles}"
TOOLS="none"
MODE="clone"
HOST=""

usage() { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [ $# -gt 0 ]; do
    case "$1" in
        --tools) TOOLS="${2:?--tools needs a value}"; shift 2 ;;
        --rsync) MODE="rsync"; shift ;;
        -h|--help) usage 0 ;;
        -*) echo "unknown option: $1" >&2; usage 1 ;;
        *) HOST="$1"; shift ;;
    esac
done
[ -n "$HOST" ] || usage 1

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> $HOST ($MODE, tools=$TOOLS)"

# desktop-only bulk to leave behind: wallpapers, fonts, icons, the vendored
# binaries in dots/.local/bin (~60 MB, unused by the server config) and ohmyzsh.
EXCLUDES=(.git wallpapers dots/.wallpapers dots/.fonts dots/.icons dots/.local/bin ohmyzsh)

push_worktree() {
    if command -v rsync >/dev/null 2>&1; then
        local args=()
        for e in "${EXCLUDES[@]}"; do args+=(--exclude "$e"); done
        rsync -az --delete --info=stats1 "${args[@]}" "$here/" "$HOST:.dotfiles/"
    else
        # git-bash on windows ships no rsync; tar over ssh needs only ssh + tar.
        # no --delete equivalent, so stale files on the remote survive - fine for
        # a config tree, and a clone-mode deploy cleans up properly.
        echo "    (no local rsync; falling back to tar over ssh)"
        local args=()
        for e in "${EXCLUDES[@]}"; do args+=(--exclude "./$e"); done
        tar czf - -C "$here" "${args[@]}" .             | ssh "$HOST" 'mkdir -p ~/.dotfiles && tar xzf - -C ~/.dotfiles'
    fi
}

# a windows working copy carries CRLF (git autocrlf), and bash on linux chokes
# on the trailing CR - an unterminated quote shows up as "unexpected end of file".
# git-cloned trees are already LF, so this only matters for a worktree push.
# the script goes over stdin: nesting it in an ssh command string mangles the
# CR pattern through two layers of quoting.
strip_crlf() {
    ssh "$HOST" 'bash -s' <<'REMOTE'
cd ~/.dotfiles 2>/dev/null || exit 0
cr=$(printf "\r")
# -I skips binaries, -U stops grep stripping CR before it can match
mapfile -t files < <(grep -rlIU "$cr" . 2>/dev/null)
(( ${#files[@]} )) || { echo "    line endings already LF"; exit 0; }
printf "%s\0" "${files[@]}" | xargs -0 sed -i "s/$cr$//"
echo "    normalised line endings: ${#files[@]} files"
REMOTE
}

if [ "$MODE" = rsync ]; then
    push_worktree
    strip_crlf
else
    ssh "$HOST" "bash -lc '
        set -e
        if [ -d \"$REMOTE_ROOT/.git\" ]; then
            git -C \"$REMOTE_ROOT\" pull --ff-only
        else
            git clone \"$REPO_URL\" \"$REMOTE_ROOT\"
        fi
        # only the submodules the server config actually uses; ohmyzsh is a
        # desktop concern and pulls in a lot for nothing.
        git -C \"$REMOTE_ROOT\" submodule update --init dotbot'"
fi

# link configs + optionally install tools, then wire the hpc environment
ssh "$HOST" "bash -lc '
    set -e
    DOTFILES_TOOLS=$TOOLS bash \$HOME/.dotfiles/install-server.sh
    bash \$HOME/.dotfiles/hpc/setup.sh'"

echo
echo "done. connect with:  ssh $HOST"
echo "then:               hpc-where    hpc-help"
echo
echo "note: the server .bashrc returns early for non-interactive shells, so"
echo "      'ssh $HOST some-command' will not have the hpc helpers. batch jobs"
echo "      should source ~/.dotfiles/hpc/hpc.sh directly (see job.sbatch.template)."
