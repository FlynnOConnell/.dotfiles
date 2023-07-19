# dotfiles

A set of dotfiles and install scripts. I have two primary goals:
- Uniquitous platform independent installation (MacOS, Linux, Windows, WSL2)
- No external dependencies, click and go

Linux, macOS, and WSL2 can all be ran with the install script. With windows, this led to too much trouble than it was worth so instead these configs can be applied manually through powershell scripts running the install.bat file. 

## Tools

- [dotbot](https://github.com/anishathalye/dotbot)
- [i3 desktop environment](https://i3wm.org/)
- [kitty terminal emulator](https://sw.kovidgoyal.net/kitty/)
- [zsh shell + oh-my-zsh](https://ohmyz.sh/)
- [tmux + tmux-sessionizer + tpm](https://github.com/tmux/tmux/wiki)
- [neovim + ideavim configs](https://github.com/tmux/tmux/wiki)

Initializing and checking-out the specified submodule versions:
`git submodule update --init --recursive`

Upgrading submodules to latest published version:
`git submodule update --init --remote`

