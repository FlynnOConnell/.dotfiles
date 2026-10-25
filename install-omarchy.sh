#!/usr/bin/env bash
# omarchy desktop: link the configs I've changed from omarchy's defaults, plus nvim.
#
# The live machine is the source of truth. Omarchy (and its UI) sometimes
# rewrites a config by replacing the file, which turns our symlink back into a
# regular file. When that happens the live copy is adopted into the repo first,
# then relinked, so nothing is lost and `git diff` shows what changed.
#
# Everything omarchy ships that isn't listed here is left as omarchy's default.
#
# --fresh is for a new machine, where the live files are omarchy's defaults:
# they're moved to ~/.dotfiles-backup/ instead of adopted over the repo copies.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/omarchy"
HOST="$(uname -n)"
FRESH=0
[[ ${1:-} == --fresh ]] && FRESH=1
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# paths relative to $HOME, mirrored under omarchy/
FILES=(
  .bashrc
  .config/hypr/autostart.lua
  .config/hypr/bindings.lua
  .config/hypr/hyprland.lua
  .config/hypr/input.lua
  .config/omarchy/shell.json
  .config/omarchy/extensions/omarchy-menu.jsonc
  .config/omarchy/defaults/agent
  .config/git/config
  .config/herdr/config.toml
  .config/starship.toml
  .config/lazygit/config.yml
  .config/btop/btop.conf
  .local/bin/utsw-vpn
  .config/systemd/user/sshfs@.service
  .config/systemd/user/bt-connect@.service
  .claude/settings.json
  .claude/CLAUDE.md
)

# per-machine files, mirrored under omarchy/hosts/<hostname>/. a machine
# without its own copy yet adopts whatever it has live.
HOST_FILES=(
  .config/hypr/monitors.lua
)

# extra packages on top of omarchy's; installed only when missing
PACKAGES=()
PACKAGES_AUR=(
  zsa-keymapp-bin  # ZSA keyboard layout viewer (pulls in zsa-udev)
)

link() { # link <repo path> <live path>
  local src=$1 dst=$2
  if [[ -L $dst && $(readlink -f "$dst") == "$(readlink -f "$src")" ]]; then
    return
  fi
  if [[ ! -e $src && ! -e $dst ]]; then
    return
  fi
  if [[ -e $dst && ! -L $dst && $FRESH == 1 && -e $src ]]; then
    mkdir -p "$(dirname "$BACKUP/${dst#$HOME/}")"
    mv "$dst" "$BACKUP/${dst#$HOME/}"
    echo "backup $dst -> $BACKUP"
  elif [[ -e $dst && ! -L $dst ]]; then
    if [[ -d $dst ]]; then
      echo "skip $dst: is a real directory, move it aside first" >&2
      return
    fi
    if ! cmp -s "$dst" "$src"; then
      echo "adopt $dst -> ${src#$REPO/}"
      mkdir -p "$(dirname "$src")"
      cp -a "$dst" "$src"
    fi
  fi
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  echo "link  $dst"
}

for f in "${FILES[@]}"; do
  link "$SRC/$f" "$HOME/$f"
done

for f in "${HOST_FILES[@]}"; do
  link "$SRC/hosts/$HOST/$f" "$HOME/$f"
done

# open images with imv's own folder launcher, so arrow keys step through the folder
xdg-mime default imv-dir.desktop image/png image/jpeg image/gif image/bmp image/webp image/tiff

link "$REPO/nvim" "$HOME/.config/nvim"
# nvim follows the active omarchy theme; untracked, see nvim/.gitignore
ln -sfn "$HOME/.local/state/omarchy/current/theme/neovim.lua" "$REPO/nvim/lua/plugins/theme.lua"

(( ${#PACKAGES[@]} )) && omarchy-pkg-add "${PACKAGES[@]}"
(( ${#PACKAGES_AUR[@]} )) && omarchy-pkg-aur-add "${PACKAGES_AUR[@]}"

# skills and agents are chosen in agents/skills.conf
python3 "$REPO/agents/sync_skills.py"
