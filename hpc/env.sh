#!/usr/bin/env bash
# hpc locations - single source of truth, sourced by hpc/hpc.sh
#
# picks a site file from hpc/sites/ and exports a generic set of HPC_* vars.
# override anything by exporting it before this runs (e.g. in ~/.bashrc.local).
#
# adding a cluster: drop a file in sites/<name>.sh that sets the HPC_* vars
# below, and add a detection line to _hpc_detect_site.

_hpc_env_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# which cluster are we on? explicit HPC_SITE wins, else sniff the filesystem.
_hpc_detect_site() {
    [ -n "${HPC_SITE:-}" ] && { echo "$HPC_SITE"; return; }
    [ -d /biohpc ] && { echo biohpc; return; }
    [ -d /lustre/fs8/mbo ] && { echo rockefeller; return; }
    echo generic
}

export HPC_SITE="$(_hpc_detect_site)"
unset -f _hpc_detect_site

# ---- defaults every site inherits -------------------------------------------
# tools install per-user with no root; a site with a shared software tree
# overrides HPC_BIN to put that first on PATH.
export HPC_BIN="${HPC_BIN:-$HOME/.local/bin}"

# HPC_HOME_SMALL=1 means home is quota- or inode-capped, so hpc.sh moves the
# heavy XDG dirs off it (see the XDG block there). sites set this.
export HPC_HOME_SMALL="${HPC_HOME_SMALL:-0}"

# ---- site file --------------------------------------------------------------
if [ -r "$_hpc_env_dir/sites/$HPC_SITE.sh" ]; then
    . "$_hpc_env_dir/sites/$HPC_SITE.sh"
fi
unset _hpc_env_dir

# ---- fallbacks for anything the site did not set ----------------------------
_hpc_u="${USER:-$(id -un)}"
export HPC_SCRATCH="${HPC_SCRATCH:-$HOME}"
export HPC_DATA="${HPC_DATA:-$HOME}"
export HPC_USER="${HPC_USER:-$HPC_SCRATCH/$_hpc_u}"
unset _hpc_u

# ---- uv ---------------------------------------------------------------------
# cluster homes are small and inode-capped, and a venv full of small files is
# the fastest way to blow through both. keep the cache and managed pythons on
# the same filesystem as your venvs so installs hardlink instead of copying;
# uv falls back to copy on its own when a venv lands elsewhere.
export UV_LINK_MODE="${UV_LINK_MODE:-hardlink}"
export UV_CACHE_DIR="${UV_CACHE_DIR:-$HPC_USER/.uv/cache}"
export UV_PYTHON_INSTALL_DIR="${UV_PYTHON_INSTALL_DIR:-$HPC_USER/.uv/python}"
