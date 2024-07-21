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
export AWM_DIR="$CONFIG_DIR/awesome"

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"

# TODO: https://github.com/Tarrasch/zsh-autoenv
source ~/.zshenv

export ZSH=$DOTS_DIR/.oh-my-zsh

ZSH_THEME="robbyrussell"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"
source $ZSH/oh-my-zsh.sh
