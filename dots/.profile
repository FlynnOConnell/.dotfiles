echo "Sourcing aliases..."

alias copy='xclip -sel clip'
alias key='cat ~/repos/.dotfiles/scripts/shortcuts.txt'

# - Lists ----
alias lsa='ls -la'

alias VIM="nvim"
alias PERSONAL=$XDG_CONFIG_HOME/personal
alias sudoedit='function _sudoedit(){sudo -e "$1";};_sudoedit'

# - Navigation -
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias cdz="cd ~/.zshrc"
alias cdt="cd ~/.config/tmux/tmux.conf"
alias cdr="cd ~/.config/tmux/tmux.conf"
alias cddot="cd ~/repos/.dotfiles/"
alias cdi3="cd ~/.config/i3/config"
alias cdn="cd ~/.config/nvim/"
alias cdnr="cd ~/.config/nvim/lua/flynnvim/remap.lua"
alias cdnw="cd ~/.config/nvim/lua/flynnvim/maps.lua"
alias cdnp="cd ~/.config/nvim/lua/flynnvim/packer.lua"
alias cdns="cd ~/.config/nvim/lua/flynnvim/set.lua"
alias cdna="cd ~/.config/nvim/after/plugin"

# - Nvim To File ----
alias goa="nvim ~/.aliases"
alias goe="nvim ~/.exports"
alias goz="nvim ~/.zshrc"
alias got="nvim ~/.config/tmux/tmux.conf"
alias gos="nvim ~/.config/skhd/skhdrc"
alias gok="nvim ~/.config/kitty/kitty.conf"
alias goy="nvim ~/.config/yabai/yabairc"
alias god="nvim ~/repos/.dotfiles/"
alias goi3="nvim ~/.config/i3/config"
alias gon="nvim ~/.config/nvim/"
alias gonr="nvim ~/.config/nvim/lua/myvim/remap.lua"
alias gonp="nvim ~/.config/nvim/lua/myvim/packer.lua"
alias gona="nvim ~/.config/nvim/after/plugin"

# - Source --------
alias sz="source ~/.zshrc"
alias st="tmux source ~/.config/tmux/tmux.conf"
alias sy="yabai --restart-service"
alias ss="skhd --reload"

# - Git ---------
alias gs="git status"
alias ga="git add"
alias gb="git branch"
alias gc="git commit"
alias gd="git diff"

# - Other ---------
alias hf='history | fzf -e'
