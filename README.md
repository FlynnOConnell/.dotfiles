# dotfiles

A set of dotfiles and install scripts with cross-platform support for Linux, Windows, and WSL.

**Goal:** Platform-independent configuration that works seamlessly across Linux (i3wm) and Windows (komorebi) with matching keybindings.

- Uses [dotbot](https://github.com/anishathalye/dotbot) for installation
- Consistent vim-style keybindings (hjkl) across all platforms
- Window manager configs that match between i3 and komorebi

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
- [PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3)
- [komorebi - Tiling Window Manager](https://github.com/LGUG2Z/komorebi)
- [whkd - Hotkey Daemon](https://github.com/LGUG2Z/whkd)

### Windows Installation

1. **Install komorebi and whkd** (using Scoop):
   ```powershell
   scoop bucket add extras
   scoop install komorebi whkd
   ```

2. **Install dotfiles**:
   ```powershell
   cd ~\.dotfiles
   .\install
   ```

3. **Set up automatic startup**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File ~\.dotfiles\scripts\setup-windows-startup.ps1
   ```

4. **Start komorebi**:
   ```powershell
   komorebic start --whkd --bar
   ```

📖 **See:**
- `dots/.config/komorebi/README-WINDOWS.md` - Detailed Windows setup and troubleshooting
- `KEYBINDINGS.md` - Complete keybinding reference for both platforms

### Keybinding Philosophy

Keybindings are designed to match between i3 (Linux) and komorebi (Windows):
- **Windows key** (Super/Mod4) for all window management operations
- **Alt** for application launchers
- **Vim-style hjkl** for directional navigation and movement
- Consistent workspace switching (Win+1-9) across platforms

**Common Keybindings:**
- `Win+H/J/K/L` - Navigate windows (left/down/up/right)
- `Win+Shift+H/J/K/L` - Move windows
- `Win+Q` - Close window
- `Win+1-9` - Switch workspaces
- `Win+Shift+1-9` - Move window to workspace
- `Alt+Space` - Application launcher

Initializing and checking-out the specified submodule versions:
`git submodule update --init --recursive`

Upgrading submodules to latest published version:
`git submodule update --init --remote`

## HPC / servers

Rootless. Configs and tools install under `~/.local` and `~/.config`, so no
`sudo` and no cooperation from a cluster admin is needed.

### Deploy to a cluster

From this machine:

```bash
hpc/deploy.sh flynn@biohpc --tools essentials
```

The remote clones the repo, links the server configs, installs the selected
tools into `~/.local/bin`, and wires the shell. Re-run it any time; it is
idempotent.

If the cluster has no outbound network, push this working copy instead:

```bash
hpc/deploy.sh flynn@biohpc --rsync --tools none
```

Already sitting on the cluster? Run it there directly:

```bash
curl -fsSL https://raw.githubusercontent.com/FlynnOConnell/.dotfiles/master/install-server.sh | DOTFILES_TOOLS=essentials bash
bash ~/.dotfiles/hpc/setup.sh
```

`DOTFILES_TOOLS` accepts `all`, `essentials`, `none`, or a list like `1,3,5`.
Omit it in a real terminal to get the interactive menu.

### What you get

`hpc/hpc.sh` loads automatically from the server `.bashrc` and is safe to
source in batch jobs, so a job sees the same environment as a login shell.

- **locations** — `$HPC_SITE` `$HPC_USER` `$HPC_DATA` `$HPC_SCRATCH`, with
  `cdme` `cddata` `cdscratch` `cdshared` to jump; `hpc-where` prints them plus
  free space
- **transfers** — `hpc-pull` `hpc-push` `hpc-stage`, all `rsync -aP` so an
  interrupted copy resumes. Run large ones from a transfer/DTN node
- **jobs** — `hpc-jobs` `hpc-cancel` `hpc-queues` `hpc-gpus`, and `hpc-gpu` /
  `hpc-cpu` for interactive shells. Defined only for the scheduler actually
  present (SLURM, PBS, or LSF), so nothing is defined on a box without one.
  `cp "$HPC_TEMPLATE" run.sbatch` for a job template
- **uv** — cache and managed pythons redirected onto scratch with hardlink
  installs, because cluster homes are small and inode-capped
- **terminfo** — falls back to `xterm-256color` when the cluster has never
  heard of your terminal's `TERM` (kitty, wezterm, ghostty)
- `hpc-help` lists all of it; `hpc-update` pulls the latest dotfiles

### Adding a cluster

Sites live in `hpc/sites/<name>.sh` and just set `HPC_*` variables. Add a
detection line to `_hpc_detect_site` in `hpc/env.sh`, or force one with
`export HPC_SITE=<name>`. Currently: `biohpc`, `rockefeller`, `generic`.

Per-machine overrides that should not be tracked go in `~/.bashrc.local`.
Setting `HPC_USER` there is the fix if your personal directory is not
auto-detected.

## Inspiration
- [khanelimans dotfiles for Windows 11](https://github.com/khaneliman/dotfiles)
- [This UnixPorn post](https://www.reddit.com/r/unixporn/comments/11wd2jr/gnome_lost_in_space/)
- [raven2cz dotfiles](https://github.com/raven2cz/dotfiles)
