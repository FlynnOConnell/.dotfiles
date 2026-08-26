#!/usr/bin/env bash
# site: biohpc
#
# layout is /biohpc/data<N>/<user>, with the data volume you belong to varying
# per user, so the personal dir is detected rather than hardcoded. if the guess
# is wrong, export HPC_USER before this loads (~/.bashrc.local is a good spot).

export HPC_ROOT="${HPC_ROOT:-/biohpc}"

# newest data volume wins as the generic root; every volume stays reachable.
_bh_u="${USER:-$(id -un)}"
if [ -z "${HPC_DATA:-}" ]; then
    for _d in "$HPC_ROOT"/data*; do
        [ -d "$_d" ] && HPC_DATA="$_d"
    done
    export HPC_DATA="${HPC_DATA:-$HPC_ROOT}"
fi

# personal dir: first /biohpc/data*/<user> that exists. the volumes are group
# writable, so guessing a path that does not exist would silently create clutter
# on shared storage - fall back to $HOME instead, which here is large.
if [ -z "${HPC_USER:-}" ]; then
    for _d in "$HPC_ROOT"/data*/"$_bh_u"; do
        [ -d "$_d" ] && { export HPC_USER="$_d"; break; }
    done
    export HPC_USER="${HPC_USER:-$HOME}"
fi
export HPC_SCRATCH="${HPC_SCRATCH:-$HPC_DATA}"
export HPC_SHARED="${HPC_SHARED:-$HPC_DATA/shared_data}"
export HPC_TRANSFER="${HPC_TRANSFER:-$HPC_DATA/transfer_folder}"
unset _bh_u _d

# no shared software tree here - everything installs under ~/.local (rootless).
export HPC_HOME_SMALL="${HPC_HOME_SMALL:-0}"
