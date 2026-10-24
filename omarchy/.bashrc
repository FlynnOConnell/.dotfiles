# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

. "$HOME/.local/share/../bin/env"

alias lg='lazygit'

# 1Password shell plugins (gh via `op plugin init gh`)
[[ -f ~/.config/op/plugins.sh ]] && source ~/.config/op/plugins.sh

# ve: fuzzy-pick and activate a uv venv from ~/envs/* or ./.venv
#   ve            pick with fzf
#   ve pml        activate ~/envs/pml directly
#   ve new NAME [PYTHON]   create ~/envs/NAME with uv
#   ve rm NAME    delete ~/envs/NAME
#   ve -          deactivate
VE_HOME=~/envs
ve() {
  case "$1" in
    -) deactivate 2>/dev/null; return ;;
    new)
      [[ -z $2 ]] && { echo "usage: ve new NAME [PYTHON]"; return 1; }
      mkdir -p "$VE_HOME/$2" && uv venv "$VE_HOME/$2/.venv" ${3:+--python "$3"} &&
        source "$VE_HOME/$2/.venv/bin/activate"
      return ;;
    rm)
      [[ -z $2 || ! -d $VE_HOME/$2 ]] && { echo "no env: $2"; return 1; }
      read -rp "delete $VE_HOME/$2? [y/N] " a && [[ $a == y ]] && rm -rf "${VE_HOME:?}/$2"
      return ;;
  esac
  local dir
  if [[ -n $1 ]]; then
    dir=$VE_HOME/$1/.venv
  else
    dir=$({ [[ -d .venv ]] && echo "$PWD/.venv"; command ls -d "$VE_HOME"/*/.venv 2>/dev/null; } |
      sed "s|^$HOME|~|" |
      fzf --height 40% --reverse --prompt "venv> " \
        --preview 'd={}; d=${d/#\~/$HOME}; grep -E "^(version|uv)" "$d/pyvenv.cfg"; echo; command ls "$d"/lib/python*/site-packages | grep -v -E "dist-info|^_|pycache" | head -40')
    [[ -z $dir ]] && return
    dir=${dir/#\~/$HOME}
  fi
  [[ -f $dir/bin/activate ]] || { echo "no venv at $dir"; return 1; }
  source "$dir/bin/activate"
}
_ve_complete() { COMPREPLY=($(compgen -W "new rm - $(command ls "$VE_HOME" 2>/dev/null)" -- "${COMP_WORDS[COMP_CWORD]}")); }
complete -F _ve_complete ve
