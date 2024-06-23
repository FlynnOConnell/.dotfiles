echo "Reading .zshrc file..."
export LC_ALL="en_US.utf-8"

# ----------------------------------------------------------------------------------
# User-Setup -----------------------------------------------------------------------
# ----------------------------------------------------------------------------------

ZSH_THEME="steeef"
setopt NO_BEEP

zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' frequency 13

# Ensure ZSH and ZSH_CUSTOM are properly set with home directory expansion
ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
plugins=(git ssh-agent)

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
	# connect to tmux session named "main" on startup as base
	if command -v tmux &> /dev/null; then
	  # Check if we are already inside a tmux session
	  if [ -z "$TMUX" ]; then
	    # Check if the "main" session already exists
	    if ! tmux has-session -t main &> /dev/null; then
	      # Create a new session named "main"
	      tmux new-session -s main -d
	    fi
	    # Attach to the "main" session
	    tmux attach-session -t main
	  fi
	fi
  elif [[ $(get_os) == "macos" ]]; then
    brew install tmux
	# connect to tmux session named "main" on startup as base
	if command -v tmux &> /dev/null; then
	  # Check if we are already inside a tmux session
	  if [ -z "$TMUX" ]; then
	    # Check if the "main" session already exists
	    if ! tmux has-session -t main &> /dev/null; then
	      # Create a new session named "main"
	      tmux new-session -s main -d
	    fi
	    # Attach to the "main" session
	    tmux attach-session -t main
	  fi
	fi
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
source ~/.zshenv

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/flynn/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/flynn/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/flynn/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/flynn/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

bindkey -s ^f "tmux-sessionizer\n"
bindkey -s ^h "hf\n"

echo "Keybind: cntrl-f - Tmux Sessionizer"
echo "Keybind: cntrl-h -  Command History"
fpath+=${ZDOTDIR:-~}/.zsh_functions

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
