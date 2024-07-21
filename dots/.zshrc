# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
export LANG=en_US.UTF-8
export MANPATH="/usr/local/man:$MANPATH"
export VISUAL="nvim"
export EDITOR="$VISUAL"
export MICRO_TRUECOLOR="1"
export GIT_EDITOR='nvim'

# ROOT
export DOTS_ROOT="$HOME/repos/.dotfiles"
export DOTS_DIR="$DOTS_ROOT/dots"
export CONFIG_DIR="$DOTS_DIR/.config"

# CONFIG
export NVIM_DIR="$CONFIG_DIR/nvim"
export TMUX_DIR="$CONFIG_DIR/tmux"
export LAZYGIT_DIR="$CONFIG_DIR/lazygit"
export AWM_DIR="$CONFIG_DIR/awesome"
export ZSH="$DOTS_DIR/.oh-my-zsh"


# TODO: https://github.com/Tarrasch/zsh-autoenv
# source ~/.zshenv


# ZSH_THEME="robbyrussell"

DISABLE_UNTRACKED_FILES_DIRTY="true"
# source $ZSH/oh-my-zsh.sh


export PATH="$PATH:$HOME/.local/bin:"
export PATH="$PATH:$HOME/.cargo/bin/"
export PATH="$PATH:$HOME/.local/share/pnpm/"
export PATH="$PATH:$HOME/.local/opt/"
export PATH="$PATH:/opt/local/bin"
export PATH=$PATH:"/mnt/c/Users/RBO/Program Files/MATLAB/R2023b/bin/"
export PATH=$PATH:"c/Users/RBO/Program Files/MATLAB/R2023b/bin/"
export PATH=$PATH:"C://Program Files//MATLAB//R2023b//bin//"

export MATLAB_ROOT="/mnt/c/Program Files/MATLAB/R2023b"
export PATH=$MATLAB_ROOT/bin:$PATH

# source ~/bin/antigen.sh

if [[ -f ~/.cargo/env ]]; then
	. ~/.cargo/env
fi

if [[ -f /opt/homebrew/bin/brew ]]; then
	eval "$("/opt/homebrew/bin/brew" shellenv)"
fi

# ----------------------------------------------------------------------------------
# User-Setup -----------------------------------------------------------------------
# ----------------------------------------------------------------------------------

setopt NO_BEEP

zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' frequency 13
zstyle ':completion:*' menu select

ZSH_THEME="steeef"

# fpath+=${ZDOTDIR:-~}/.zsh_functions

# Source Oh My Zsh and custom configurations
source "$ZSH/oh-my-zsh.sh"

# ---------------------------------------------------------------------------------
# Node/NPM ------------------------------------------------------------------------
# ---------------------------------------------------------------------------------

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ---------------------------------------------------------------------------------
# Tmux ----------------------------------------------------------------------------
# ---------------------------------------------------------------------------------

if ! command -v tmux &> /dev/null; then
  echo "tmux not found, installing..."
  if [[ $(get_os) == "linux" ]]; then
    sudo apt-get update && sudo apt-get install -y tmux
  elif [[ $(get_os) == "macos" ]]; then
    brew install tmux
  else
    echo "Unable to install tmux, OS not supported"
  fi
fi

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    git clone https://github.com/tmux-plugins/tpm.git ~/.tmux/plugins/tpm
fi

[ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source ~/.aliases

# ----------------------------------------------------------------------------------
# Keybinds -------------------------------------------------------------------------
# ----------------------------------------------------------------------------------

bindkey -s ^f "tms\n"

# ----------------------------------------------------------------------------------
# conda/mamba ----------------------------------------------------------------------
# ----------------------------------------------------------------------------------

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
#
# __conda_setup="$('/home/foconnell/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
__conda_setup="$('$HOME/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
        . "$HOME/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

echo "Keybind: cntrl-f - Tmux Sessionizer"


# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba init' !!
export MAMBA_EXE="$HOME/.local/bin/micromamba";

export MAMBA_ROOT_PREFIX='$HOME/micromamba';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias micromamba="$MAMBA_EXE"  # Fallback on help from mamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<
#
#
