#!/usr/bin/env bash
# hpc shell environment - locations, PATH, transfer + scheduler helpers.
#
# sourced from ~/.bashrc by hpc/setup.sh. safe in non-interactive shells, so
# batch jobs can source it to get the same environment as a login shell.
#
#   source ~/.dotfiles/hpc/hpc.sh

# re-sourcing is harmless but wasteful (module systems re-run ~/.bashrc)
[ -n "${HPC_SH_LOADED:-}" ] && return 0
export HPC_SH_LOADED=1

_hpc_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$_hpc_dir/env.sh"

# ---- PATH -------------------------------------------------------------------
# HPC_BIN may be a colon list (shared tree first, then user-local). prepend in
# reverse so the leftmost entry ends up first, and never add a dir twice.
_hpc_paths="$HPC_BIN"
while [ -n "$_hpc_paths" ]; do
    _hpc_last="${_hpc_paths##*:}"
    _hpc_paths="${_hpc_paths%:*}"
    [ "$_hpc_last" = "$_hpc_paths" ] && _hpc_paths=""
    [ -d "$_hpc_last" ] || continue
    case ":$PATH:" in *":$_hpc_last:"*) ;; *) PATH="$_hpc_last:$PATH" ;; esac
done
unset _hpc_paths _hpc_last
export PATH

command -v nvim >/dev/null 2>&1 && { export EDITOR=nvim; export VISUAL=nvim; }

# ---- XDG on a small home ----------------------------------------------------
# only when the site flags home as quota/inode capped: plugin trees (lazy.nvim
# is thousands of files) go to your scratch, while cache and state go node-local
# under $TMPDIR so editor startup avoids slow shared-filesystem metadata ops.
if [ "$HPC_HOME_SMALL" = "1" ] && [ -n "$HPC_USER" ]; then
    _hpc_u="${USER:-$(id -un)}"
    export XDG_DATA_HOME="${XDG_DATA_HOME:-$HPC_USER/.local/share}"
    export XDG_STATE_HOME="${XDG_STATE_HOME:-${TMPDIR:-/tmp}/$_hpc_u/state}"
    export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${TMPDIR:-/tmp}/$_hpc_u/cache}"
    mkdir -p "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" 2>/dev/null
    chmod 700 "${TMPDIR:-/tmp}/$_hpc_u" 2>/dev/null
    unset _hpc_u
fi

# ---- terminfo ---------------------------------------------------------------
# kitty/wezterm/ghostty advertise a TERM most clusters have never heard of,
# which breaks colors and arrow keys over ssh.
if [ -n "${TERM:-}" ] && ! infocmp "$TERM" >/dev/null 2>&1; then
    export TERM=xterm-256color
fi

# ---- location jumps ---------------------------------------------------------
alias cdme='cd "$HPC_USER"'
alias cddata='cd "$HPC_DATA"'
alias cdscratch='cd "$HPC_SCRATCH"'
[ -n "${HPC_SHARED:-}" ] && alias cdshared='cd "$HPC_SHARED"'

# where am i, and how much room is left
hpc-where() {
    printf 'site      %s\n' "$HPC_SITE"
    printf 'user dir  %s\n' "${HPC_USER:-<unset>}"
    printf 'data      %s\n' "${HPC_DATA:-<unset>}"
    printf 'scratch   %s\n' "${HPC_SCRATCH:-<unset>}"
    printf 'bin       %s\n' "$HPC_BIN"
    [ -n "${HPC_SCHED:-}" ] && printf 'scheduler %s\n' "$HPC_SCHED"
    echo
    df -h "$HOME" "${HPC_USER:-$HOME}" 2>/dev/null | awk 'NR==1 || !seen[$0]++'
}

# ---- transfers --------------------------------------------------------------
# -aP: archive + partial + progress, so an interrupted copy resumes.
# run anything large from a transfer/DTN node, not a login node.
hpc-pull() {
    [ -z "${1:-}" ] && { echo "usage: hpc-pull <user@host:path> [dest]"; return 1; }
    rsync -aP "$1" "${2:-$HPC_USER}/"
}
hpc-push() {
    [ $# -lt 2 ] && { echo "usage: hpc-push <src> <user@host:path>"; return 1; }
    rsync -aP "$1" "$2"
}
hpc-stage() {
    [ -z "${1:-}" ] && { echo "usage: hpc-stage <path-under-\$HPC_DATA> [dest]"; return 1; }
    rsync -aP "$HPC_DATA/$1" "${2:-$HPC_USER}/"
}

# ---- scheduler --------------------------------------------------------------
# defined only for the scheduler actually present, so the shell stays quiet on a
# box without one.
if command -v sbatch >/dev/null 2>&1; then
    export HPC_SCHED=slurm
    alias hpc-jobs='squeue --me'
    alias hpc-cancel='scancel'
    hpc-queues() { sinfo -o '%20P %5a %10l %6D %6t %N' ; }
    hpc-gpus() {
        sinfo -N --Format=nodelist:20,partition:20,cpusstate:16,freemem:12,gres:24 --sort=#P,N
    }
    # interactive shells. args: [partition] [time] [ngpu]
    hpc-gpu() {
        srun ${1:+--partition="$1"} --gres="gpu:${3:-1}" --cpus-per-task=8 \
             --mem=64G --time="${2:-04:00:00}" --pty bash -l
    }
    hpc-cpu() {
        srun ${1:+--partition="$1"} --cpus-per-task=8 --mem=32G \
             --time="${2:-04:00:00}" --pty bash -l
    }
elif command -v qsub >/dev/null 2>&1; then
    export HPC_SCHED=pbs
    alias hpc-jobs='qstat -u "$USER"'
    alias hpc-cancel='qdel'
    hpc-queues() { qstat -Q; }
    hpc-cpu() { qsub -I -l select=1:ncpus=8:mem=32gb -l walltime="${2:-04:00:00}"; }
    hpc-gpu() { qsub -I -l select=1:ncpus=8:mem=64gb:ngpus="${3:-1}" -l walltime="${2:-04:00:00}"; }
elif command -v bsub >/dev/null 2>&1; then
    export HPC_SCHED=lsf
    alias hpc-jobs='bjobs'
    alias hpc-cancel='bkill'
    hpc-queues() { bqueues; }
fi

# job template path, for `cp "$HPC_TEMPLATE" run.sbatch`
export HPC_TEMPLATE="$_hpc_dir/job.sbatch.template"

# pull the latest dotfiles on this cluster
hpc-update() {
    git -C "${DOTFILES_ROOT:-$HOME/.dotfiles}" pull --ff-only \
        && git -C "${DOTFILES_ROOT:-$HOME/.dotfiles}" submodule update --init --recursive
}

hpc-help() {
    cat <<'HELP'
  locations   cdme  cddata  cdscratch  cdshared      hpc-where
  transfer    hpc-pull <remote> [dest]   hpc-push <src> <remote>
              hpc-stage <path-under-data> [dest]
  jobs        hpc-jobs  hpc-cancel <id>  hpc-queues  hpc-gpus
              hpc-gpu [part] [time] [n]  hpc-cpu [part] [time]
              cp "$HPC_TEMPLATE" run.sbatch
  maintain    hpc-update      (git pull dotfiles)
  env         $HPC_SITE $HPC_USER $HPC_DATA $HPC_SCRATCH $HPC_BIN
HELP
}

unset _hpc_dir

# ---- interactive only -------------------------------------------------------
case $- in *i*) ;; *) return 0 ;; esac

HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend checkwinsize
# type a prefix, then Up/Down walks only the history entries starting with it
bind '"\e[A": history-search-backward' 2>/dev/null
bind '"\e[B": history-search-forward' 2>/dev/null

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---height 40% --layout=reverse --border}"
command -v fd >/dev/null 2>&1 \
    && export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# HPC_SKIP_PROMPT=1 means the caller (our own ~/.bashrc) sets up the prompt
# itself; without it hpc.sh is the entry point, appended to a stock ~/.bashrc,
# and owns the prompt.
if [ -z "${HPC_SKIP_PROMPT:-}" ]; then
    # a module system or site profile may have set its own prompt hook - take over
    PROMPT_COMMAND=""
    command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
    # zoxide must init last, after starship's PROMPT_COMMAND hook
    command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash --cmd cd)"
fi

# a missing optional tool above is not an error
true
