
case $- in
    *i*) ;;
      *) return;;
esac

export PATH="$HOME/miniconda3/bin:$PATH"
export TERM=xterm-color
unset MAILCHECK

HISTCONTROL=ignoreboth

shopt -s histappend

HISTFILESIZE=50
shopt -s checkwinsize

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
# - Navigation -
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"

alias cdb="cd ~/.bashrc"
alias cdz="cd ~/.zshrc"
alias cddot="cd ~/repos/.dotfiles/"
alias cdi3="cd ~/.config/i3/config"
alias cdn="cd ~/.config/nvim/"

# - Nvim To File ----
alias gob="nvim ~/.bashrc"
alias goz="nvim ~/.zshrc"
alias gos="nvim ~/.config/skhd/skhdrc"
alias gok="nvim ~/.config/kitty/kitty.conf"
alias goy="nvim ~/.config/yabai/yabairc"
alias godot="nvim ~/repos/.dotfiles/"
alias goi3="nvim ~/.config/i3/config"
alias gon="nvim ~/.config/nvim/"

# - Source --------
alias sb="source ~/.bashrc"
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

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
. /c/Users/Flynn/miniconda3/etc/profile.d/conda.sh
