echo "Reading .zshrc file..."
export LC_ALL="en_US.utf-8"

export VISUAL="nvim"
export EDITOR="$VISUAL"
export MICRO_TRUECOLOR="1"
export GIT_EDITOR='nvim'

export DOTS_DIR="$HOME/repos/.dotfiles/"
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
export NVIM_DIR="$HOME/repos/.dotfiles/dots/.config/nvim"

export PATH="$PATH:$HOME/.local/bin:"
export PATH="$PATH:$HOME/.cargo/bin/"
export PATH="$PATH:$HOME/.local/share/pnpm/"
export PATH="$PATH:$HOME/.local/opt/"
export PATH="$PATH:$HOME/bin/"
export PATH="$PATH:/opt/local/bin"

# REMOTE PATHS
export PATH="$PATH:/v-data4/foconnell/.local/"
export PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"
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

ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
ZSH_THEME="steeef"

fpath+=${ZDOTDIR:-~}/.zsh_functions

source $ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

plugins=(
	zsh-autosuggestions
	colored-man-pages
	colorize
	git ssh-agent
)

# Source Oh My Zsh and custom configurations
source "$ZSH/oh-my-zsh.sh"

# ---------------------------------------------------------------------------------
# Node/NPM ------------------------------------------------------------------------
# ---------------------------------------------------------------------------------

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
export FZF_DEFAULT_OPTS='--bind=ctrl-u:up,ctrl-d:down'

source ~/.aliases
source ~/.zshenv

# ----------------------------------------------------------------------------------
# Keybinds -------------------------------------------------------------------------
# ----------------------------------------------------------------------------------

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

bindkey -s ^f "tmux-sessionizer ~/repos/work ~/repos/personal ~/repos ~/\n"
bindkey -s ^h "tms\n"

# ----------------------------------------------------------------------------------
# conda/mamba ----------------------------------------------------------------------
# ----------------------------------------------------------------------------------

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/rbo/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/rbo/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/rbo/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/rbo/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


echo "Keybind: cntrl-f - Tmux Sessionizer"


# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba init' !!
export MAMBA_EXE='/home/flynn/repos/.dotfiles/dots/.local/bin/micromamba';
export MAMBA_ROOT_PREFIX='/home/flynn/micromamba';
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
export PATH=$PATH:"/mnt/c/Users/RBO/Program Files/MATLAB/R2023b/bin/"
export PATH=$PATH:"c/Users/RBO/Program Files/MATLAB/R2023b/bin/"
export PATH=$PATH:"C://Program Files//MATLAB//R2023b//bin//"

export MATLAB_ROOT="/mnt/c/Program Files/MATLAB/R2023b"
export PATH=$MATLAB_ROOT/bin:$PATH


