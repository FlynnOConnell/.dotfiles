echo "Reading .zshrc file..."

bindkey -s ^f "tmux-sessionizer\n"
echo "cntrl-f to open tmux sessionizer"

export PATH="/Users/flynnoconnell/miniconda3/bin:$PATH"
ZSH_THEME="steeef"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ---------------------------------------------------------------------------------
# Helper Functions ----------------------------------------------------------------
# ---------------------------------------------------------------------------------

function myip() {
    ifconfig lo0 | grep 'inet ' | sed -e 's/:/ /' | awk '{print "lo0       : " $2}'
	ifconfig en0 | grep 'inet ' | sed -e 's/:/ /' | awk '{print "en0 (IPv4): " $2 " " $3 " " $4 " " $5 " " $6}'
	ifconfig en0 | grep 'inet6 ' | sed -e 's/ / /' | awk '{print "en0 (IPv6): " $2 " " $3 " " $4 " " $5 " " $6}'
	ifconfig en1 | grep 'inet ' | sed -e 's/:/ /' | awk '{print "en1 (IPv4): " $2 " " $3 " " $4 " " $5 " " $6}'
	ifconfig en1 | grep 'inet6 ' | sed -e 's/ / /' | awk '{print "en1 (IPv6): " $2 " " $3 " " $4 " " $5 " " $6}'
}

get_os() {
  case "$(uname -s)" in
    Linux*)     echo "linux";;
    Darwin*)    echo "macos";;
    CYGWIN*)    echo "windows";;
    MINGW*)     echo "windows";;
    MSYS*)      echo "windows";;
    *)          echo "unknown"
  esac
}

os=$(get_os)

case "$os" in
  "macos")
    __conda_setup="$('/Users/flynnoconnell/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
      eval "$__conda_setup"
    else
      if [ -f "/Users/flynnoconnell/miniconda3/etc/profile.d/conda.sh" ]; then
      else
        export PATH="/Users/flynnoconnell/miniconda3/bin:$PATH"
      fi
    fi
    ;;
  "linux")
    __conda_setup="$('/home/flynn/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
      eval "$__conda_setup"
    else
      if [ -f "/home/flynn/miniconda3/etc/profile.d/conda.sh" ]; then
      else
        export PATH="/home/flynn/miniconda3/bin:$PATH"
      fi
    fi
    ;;
  "windows")
    __conda_setup="$('C:/Users/flynn/miniconda3/Scripts/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
      eval "$__conda_setup"
    else
      if [ -f "C:/Users/flynn/miniconda3/etc/profile.d/conda.sh" ]; then
# . "C:/Users/flynn/miniconda3/etc/profile.d/conda.sh"  # commented out by conda initialize
      else
        export PATH="C:/Users/flynn/miniconda3/Scripts:$PATH"
      fi
    fi
    ;;
esac

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


# ---------------------------------------------------------------------------------
# Path Configuration --------------------------------------------------------------
# ---------------------------------------------------------------------------------
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.cargo/bin:$HOME/.local/anaconda3/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin/:$PATH"

# ---------------------------------------------------------------------------------
# Oh My Zsh Configuration ---------------------------------------------------------
# ---------------------------------------------------------------------------------

zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' frequency 13
source ~/.oh-my-zsh/oh-my-zsh.sh

if [ ! -d "${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions" ]; then
    # Clone zsh-completions
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
fi

fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

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

# ---------------------------------------------------------------------------------
# User Configuration / Aliases ----------------------------------------------------
# ---------------------------------------------------------------------------------
#

[ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"

# - Navigation -
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"

alias cdz="cd ~/.zshrc"
alias cdt="cd ~/.config/tmux/tmux.conf"
alias cddot="cd ~/repos/.dotfiles/"
alias cdr="cd ~/repos"
alias cddotc="cd ~/repos/.dotfiles/.config"
alias cdi3="cd ~/.config/i3/config"
alias cdn="cd ~/.config/nvim/"
alias cdnr="cd ~/.config/nvim/lua/flynnvim/remap.lua"
alias cdnw="cd ~/.config/nvim/lua/flynnvim/maps.lua"
alias cdnp="cd ~/.config/nvim/lua/flynnvim/packer.lua"
alias cdns="cd ~/.config/nvim/lua/flynnvim/set.lua"
alias cdna="cd ~/.config/nvim/after/plugin"

# - Nvim To File ----
alias goz="nvim ~/.zshrc"
alias got="nvim ~/.config/tmux/tmux.conf"
alias gos="nvim ~/.config/skhd/skhdrc"
alias gok="nvim ~/.config/kitty/kitty.conf"
alias goy="nvim ~/.config/yabai/yabairc"
alias godot="nvim ~/repos/.dotfiles/"
alias godotc="nvim ~/repos/.dotfiles/.config"
alias goi3="nvim ~/.config/i3/config"
alias gon="nvim ~/.config/nvim/"
alias gonr="nvim ~/.config/nvim/lua/flynnvim/remap.lua"
alias gonw="nvim ~/.config/nvim/lua/flynnvim/maps.lua"
alias gonp="nvim ~/.config/nvim/lua/flynnvim/packer.lua"
alias gons="nvim ~/.config/nvim/lua/flynnvim/set.lua"
alias gona="nvim ~/.config/nvim/after/plugin"

# - Source --------
alias sz="source ~/.zshrc"
alias st="tmux source ~/.config/tmux/tmux.conf"
alias sy="yabai --restart-service"
alias ss="skhd --reload"

# - List --------
alias ll="ls -lah"
alias l="ls -l"
alias la="ls -la"
alias ls="ls -GFh"

# - Git ---------
alias gs="git status"
alias ga="git add"
alias gb="git branch"
alias gc="git commit"
alias gd="git diff"

alias pushconfig='f() { cd ~/repos/.dotfiles; git add .; echo "Enter commit message: "; read message; git commit -m "$message"; git push; unset -f f; }; f'
alias push='f() { git add .; echo "Enter commit message: "; read message; git commit -m "$message"; git push; unset -f f; }; f'

alias push='f() { git add .; echo "Enter commit message: "; read message; git commit -m "$message"; git push; unset -f f; }; f'




# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if [ -f '/c/Users/Flynn/mambaforge/Scripts/conda.exe' ]; then
    eval "$('/c/Users/Flynn/mambaforge/Scripts/conda.exe' 'shell.zsh' 'hook')"
fi
# <<< conda initialize <<<

