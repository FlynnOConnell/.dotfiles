# dotfiles

A set of dotfiles and install scripts. I have one primary goal:
- Uniquitous platform independent installation (Linux, Windows, WSL)

Linux, macOS, and WSL2 can all be ran with the install script. With windows, this led to too much trouble than it was worth so instead these configs can be applied manually through powershell scripts running the install.bat file.

- [dotbot](https://github.com/anishathalye/dotbot)

## Linux Only
- [i3 desktop environment](https://i3wm.org/)
- [polybar](https://github.com/polybar/polybar)
- [x-settings](https://wiki.archlinux.org/title/Xsettingsd)
- [bottom](https://github.com/ClementTsang/bottom)
- [rofi app manager](https://github.com/davatorium/rofi)
- [picom x11 compositor](https://github.com/yshui/picom)
- [flameshot - screenshot util](https://flameshot.org/)
- [dunst](https://dunst-project.org/)
- [tmux + tmux-sessionizer + tpm](https://github.com/tmux/tmux/wiki)
- [kitty terminal emulator](https://sw.kovidgoyal.net/kitty/)
- [zsh shell + oh-my-zsh](https://ohmyz.sh/)
- [neovim + ideavim configs](https://github.com/tmux/tmux/wiki)
- [neofetch](https://github.com/dylanaraps/neofetch)
  
## Windows Only
- [Powershell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3)
- [komorebi](https://github.com/LGUG2Z/komorebi)
- [wkhd](https://github.com/LGUG2Z/whkd)

Initializing and checking-out the specified submodule versions:
`git submodule update --init --recursive`

Upgrading submodules to latest published version:
`git submodule update --init --remote`

## Inspiration
- [khanelimans dotfiles for Windows 11](https://github.com/khaneliman/dotfiles)
- [This UnixPorn post](https://www.reddit.com/r/unixporn/comments/11wd2jr/gnome_lost_in_space/)
- [raven2cz dotfiles](https://github.com/raven2cz/dotfiles)
