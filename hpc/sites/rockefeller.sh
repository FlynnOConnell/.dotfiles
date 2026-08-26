#!/usr/bin/env bash
# site: rockefeller (MBO lab)
#
# mirrors mbo_server_configs/config/hpc/env.sh. shared software, venvs and repos
# live under $MBO_SOFT, so nothing installs per user here.
# moving filesystems (/lustre/fs8 -> /lustre/fsN)? change MBO_ROOT only.

export MBO_ROOT="${MBO_ROOT:-/lustre/fs8/mbo}"
export MBO_SCRATCH="$MBO_ROOT/scratch"
export MBO_STORE="$MBO_ROOT/store"
export MBO_SOFT="$MBO_SCRATCH/mbo_soft"
export MBO_BIN="$MBO_SOFT/bin"
export MBO_REPOS="$MBO_SOFT/repos"
export MBO_NVIM="$MBO_SOFT/neovim"
export MBO_ENVS="$MBO_SOFT/envs"
export MBO_ENV="$MBO_ENVS/mbo"
export MBO_DATA="$MBO_SCRATCH/mbo_data"
export MBO_LBM="$MBO_DATA/lbm"
export MBO_LSM="$MBO_DATA/lsm"
export MBO_USER="${MBO_USER:-$MBO_SCRATCH/${USER:-$(id -un)}}"

# generic names the rest of the config speaks
export HPC_ROOT="$MBO_ROOT"
export HPC_SCRATCH="$MBO_SCRATCH"
export HPC_DATA="$MBO_DATA"
export HPC_USER="$MBO_USER"
export HPC_SHARED="$MBO_SOFT"

# shared bin first, then user-local
export HPC_BIN="$MBO_BIN:$MBO_NVIM/bin:$HOME/.local/bin"

# home is 40 GB with strict inode limits - move the heavy XDG dirs off it
export HPC_HOME_SMALL=1

alias cdsoft='cd "$MBO_SOFT"'
alias cdrepos='cd "$MBO_REPOS"'
alias cdlbm='cd "$MBO_LBM"'
alias cdlsm='cd "$MBO_LSM"'

# shared venvs
mbo-activate() { . "$MBO_ENVS/${1:-mbo}/bin/activate"; }
mbo-run() {
    [ -z "${1:-}" ] && { echo "usage: mbo-run <command> [args...]"; return 1; }
    local exe="$MBO_ENV/bin/$1"; shift
    [ -x "$exe" ] || { echo "mbo-run: $exe not found in shared venv"; return 1; }
    "$exe" "$@"
}
