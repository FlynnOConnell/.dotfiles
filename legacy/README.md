# legacy

Configs from before omarchy, kept for reference. Nothing here is installed by
any current install script. Paths mirror where they used to live in the repo.

| Path | What it was |
|---|---|
| `kickstart.nvim/` | old neovim config (kickstart-based), replaced by `../nvim` (omarchy's LazyVim + my plugins) |
| `install-i3.conf.yaml` | old linux desktop dotbot profile; paths not updated, read it, don't run it |
| `dots/.config/i3`, `polybar`, `picom`, `rofi`, `dunst`, `nitrogen`, `xmenu`, `autostart` | i3 / X11 desktop |
| `dots/.xinitrc`, `dots/.xprofile` | X11 session startup |
| `dots/.config/gtk-2.0`, `gtk-3.0`, `dots/.icons` | GTK theme and Catppuccin cursors (omarchy themes these now) |
| `dots/.config/kitty` | kitty config (omarchy ships its own terminal configs) |
| `dots/.config/sketchybar`, `yabai`, `skhd` | macOS desktop |
| `dots/.config/bottom`, `neofetch` | replaced by btop and fastfetch |
| `dots/.config/keybinds`, `dots/.local/share/applications/keybinds.desktop`, `keybinds.md` | i3 / komorebi keybind reference and its launcher |
| `dots/.config/cheatsheets/{awesome,i3}.txt` | cheatsheets for retired window managers |
| `dots/.local/bin/` | old personal scripts (tmux sessionizer, extract, fzf-preview, kb, ...) |
| `dots/.wallpapers/` | wallpaper that was linked to `~/.wallpapers` |

Vendored third-party binaries (uv, rg, glow, act, micromamba, keymapp), pip
entrypoint shims and broken symlinks that used to sit in `dots/.local/bin` were
deleted; they're in git history before the omarchy move if ever needed. On
omarchy: ripgrep ships with omarchy, uv is installed by its own installer in
`~/.local/bin`, and keymapp is `zsa-keymapp-bin` in `install-omarchy.sh`.
