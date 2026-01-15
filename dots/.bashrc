# MBO Bash Profile

# path
export PATH="$HOME/.local/bin:$PATH"

# aliases
alias lg='lazygit'
alias vim='nvim'
alias vi='nvim'
alias g='git'

# ls -> eza (size, icon, name by default)
if command -v eza &> /dev/null; then
    alias ls='eza -l --icons --group-directories-first --no-permissions --no-time --no-user'
    alias lsv='eza -l --icons --group-directories-first'
    alias la='eza -la --icons --group-directories-first --no-permissions --no-time --no-user'
    alias lt='eza -T --icons --group-directories-first'
fi

# cat -> bat
if command -v bat &> /dev/null; then
    alias cat='bat --paging=never'
fi

# navigation
alias ..='cd ..'
alias ...='cd ../..'

# git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias glog='git log --oneline --graph --decorate -20'

# starship prompt
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi

# zoxide (smart cd) - must be after starship
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash --cmd cd)"
fi

# fastfetch + tips on startup
if command -v fastfetch &> /dev/null && [[ $- == *i* ]]; then
    fastfetch
    echo ""
    echo -e "  \033[36mquick reference\033[0m"
    echo -e "  \033[90m  ls           size + icon + name       lsv         detailed list\033[0m"
    echo -e "  \033[90m  lt           tree view                la          list all (hidden)\033[0m"
    echo -e "  \033[90m  cd <name>    smart jump (zoxide)      cd -        go back\033[0m"
    echo -e "  \033[90m  fd <pat>     find files               rg <pat>    search contents\033[0m"
    echo -e "  \033[90m  cat <file>   view with syntax         nvim        editor\033[0m"
    echo -e "  \033[90m  lg           lazygit                  uv run      run python script\033[0m"
    echo ""
fi
