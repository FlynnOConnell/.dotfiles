# Exports
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export VISUAL="nvim"
export EDITOR="$VISUAL"
export MICRO_TRUECOLOR="1"
export GIT_EDITOR='nvim'

# Paths
export DOTS_DIR="$HOME/repos/.dotfiles/"
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
export NVIM_DIR="$HOME/repos/.dotfiles/dots/.config/nvim"
export PATH="$PATH:/opt/:/opt/local/bin:/opt/local/sbin:$HOME/.local/share/pnpm:$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.local/opt/:$HOME/bin/:/v-data4/foconnell/.local/"

export CLICOLOR=1
export LSCOLORS=gxFxCxDxBxegedabagaced

# Load cargo environment
if [[ -f ~/.cargo/env ]]; then
	. ~/.cargo/env
fi

# Brew environment
if [[ -f /opt/homebrew/bin/brew ]]; then
	eval "$("/opt/homebrew/bin/brew" shellenv)"
fi

