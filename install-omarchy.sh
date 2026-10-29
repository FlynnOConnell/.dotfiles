#!/usr/bin/env bash
# omarchy desktop: link the configs I've changed from omarchy's defaults, plus
# nvim, and install the apps and web apps I've added on top of omarchy's.
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
#
# --link only links files and enables services: no packages, apps or envs.
# repo-sync runs it after fast-forwarding the repo, so it must never prompt.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/omarchy"
OMARCHY="${OMARCHY_PATH:-/usr/share/omarchy}"
HOST="$(uname -n)"
FRESH=0
LINK_ONLY=0
[[ ${1:-} == --fresh ]] && FRESH=1
[[ ${1:-} == --link ]] && LINK_ONLY=1
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
  .config/omarchy/plugins/fo.herdr
  .config/omarchy/defaults/agent
  .config/git/config
  .config/herdr/config.toml
  .config/starship.toml
  .config/lazygit/config.yml
  .config/swayimg/init.lua
  .config/autostart/com.onepassword.OnePassword.desktop
  .local/share/applications/slack.desktop
  .local/bin/utsw-vpn
  .local/bin/slack-attention
  .local/bin/moonlight-stream
  .local/bin/meeting-record
  .local/bin/cheatsheets
  .local/bin/quick-note
  .local/bin/repo-sync
  .local/bin/suspend-when-locked
  .local/bin/sshfs-mount
  .local/bin/gamesir-x360
  .config/systemd/user/sshfs@.service
  .config/systemd/user/bt-connect@.service
  .config/systemd/user/slack-attention.service
  .config/systemd/user/suspend-when-locked.service
  .config/systemd/user/gamesir-x360.service
  .config/systemd/user/repo-sync.service
  .config/systemd/user/repo-sync.timer
  .config/systemd/user/omarchy-crash-watch.service.d/skip-claude.conf
  .local/lib/crash-watch
  .claude/settings.json
  .claude/CLAUDE.md
)

# configs the app rewrites itself (btop saves its settings on every change): a
# machine gets the repo copy once, then keeps its own, so what the app saves
# never shows up as a dotfiles edit or holds up repo-sync's fast-forward
SEED_FILES=(
  .config/btop/btop.conf
)

# per-machine files, mirrored under omarchy/hosts/<hostname>/. a machine
# without its own copy yet adopts whatever it has live.
HOST_FILES=(
  .config/hypr/monitors.lua
  .config/gtk-3.0/bookmarks  # sshfs-mount adds ~/<host> here, so each machine lists its own peers
)

# extra packages on top of omarchy's; installed only when missing
PACKAGES=(
  swayimg        # image window nvim opens images in (nvim/lua/config/swayimg.lua)
  slack-desktop  # SUPER+SHIFT+M (bindings.lua), watched by slack-attention
  sshfs          # sshfs@<host> mounts another machine's home at ~/<host>
)
PACKAGES_AUR=(
  zsa-keymapp-bin  # ZSA keyboard layout viewer (pulls in zsa-udev)
  globalprotect-openconnect-git  # gpclient, for utsw-vpn (UTSW GlobalProtect over openconnect)
  sioyek-git       # SUPER+SHIFT+R PDF reader (bindings.lua); sioyek left the official repos
)

# apps omarchy has its own installer for, which also sets up what's around the
# package (browser flags, services, the bar widget, drivers). each runs only
# when its package is missing; some ask questions or open the app when done.
OMARCHY_APPS=(
  "google-chrome  install_chrome"                          # SUPER+SHIFT+RETURN's browser
  "1password      omarchy-install-service-1password"
  "tailscale      omarchy-install-service-tailscale"        # the tailnet: sshfs@, Home Assistant, Moonlight
  "voxtype-bin    omarchy-voxtype-install"                  # dictation
  "steam          omarchy-install-gaming-steam"             # SUPER+SHIFT+S (hyprland.lua)
  "xpadneo-dkms   omarchy-install-gaming-xbox-controllers"  # last: it can offer to reboot
)

# mise tools beyond omarchy's agent wrappers: node for nvim's language servers
# (pyright, markdownlint), uv for python envs, nvim's debugger and sciview
MISE_TOOLS=(node uv@latest)

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

seed() { # seed <repo path> <live path>
  local src=$1 dst=$2
  [[ -e $src ]] || return 0
  if [[ -L $dst && $(readlink -f "$dst") == "$(readlink -f "$src")" ]]; then
    cp --remove-destination "$src" "$dst" # linked before SEED_FILES existed
    echo "local $dst"
  elif [[ ! -e $dst || $FRESH == 1 ]]; then
    mkdir -p "$(dirname "$dst")"
    cp --remove-destination "$src" "$dst"
    echo "seed  $dst"
  fi
}

install_chrome() {
  omarchy-install-browser chrome && omarchy-default-browser chrome
}

for f in "${FILES[@]}"; do
  link "$SRC/$f" "$HOME/$f"
done

for f in "${SEED_FILES[@]}"; do
  seed "$SRC/$f" "$HOME/$f"
done

for f in "${HOST_FILES[@]}"; do
  link "$SRC/hosts/$HOST/$f" "$HOME/$f"
done

# web apps (Omarchy menu > Install > Web App) beyond the ones omarchy ships: a
# new one on this machine is adopted into the repo, and every machine gets them
# all. To drop one everywhere, delete its .desktop and icon from omarchy/.local/share/.
APPS=.local/share/applications
ICONS=.local/share/icons/hicolor/256x256/apps
is_webapp() { grep -qs '^Exec=omarchy-launch-webapp ' "$1"; }
for live in "$HOME/$APPS"/*.desktop; do
  if [[ ! -L $live && ! -e $OMARCHY/applications/${live##*/} ]] && is_webapp "$live"; then
    link "$SRC/$APPS/${live##*/}" "$live"
  fi
done
for app in "$SRC/$APPS"/*.desktop; do
  if is_webapp "$app"; then
    link "$app" "$HOME/$APPS/${app##*/}"
    icon=$(sed -n 's/^Icon=//p' "$app")
    link "$SRC/$ICONS/$icon.png" "$HOME/$ICONS/$icon.png"
  fi
done
gtk-update-icon-cache "$HOME/.local/share/icons/hicolor" &>/dev/null || true

# open images with imv's own folder launcher, so arrow keys step through the folder
xdg-mime default imv-dir.desktop image/png image/jpeg image/gif image/bmp image/webp image/tiff

# moonlight: always capture system shortcuts, so SUPER+GRAVE (bindings.lua) can hand SUPER+1 etc.
# to the stream. its conf also holds per-machine pairing, so only this one key is managed.
# restart moonlight to pick it up; it rewrites the key if changed in its settings page.
if command -v moonlight >/dev/null; then
  moonlight_conf="$HOME/.config/Moonlight Game Streaming Project/Moonlight.conf"
  mkdir -p "$(dirname "$moonlight_conf")"
  if grep -q '^capturesyskeys=' "$moonlight_conf" 2>/dev/null; then
    sed -i 's/^capturesyskeys=.*/capturesyskeys=2/' "$moonlight_conf"
  elif grep -q '^\[General\]' "$moonlight_conf" 2>/dev/null; then
    sed -i '/^\[General\]/a capturesyskeys=2' "$moonlight_conf"
  else
    printf '[General]\ncapturesyskeys=2\n' >>"$moonlight_conf"
  fi
fi

# user services this repo owns (sshfs@/bt-connect@ are templates, enabled per
# instance elsewhere). ignore failures: on --fresh the user bus may not be up.
if command -v systemctl >/dev/null; then
  systemctl --user daemon-reload 2>/dev/null || true
  systemctl --user enable --now slack-attention.service 2>/dev/null || true
  # the lab workstations host the shared herdr session and can't be woken from
  # outside the lab, so only the other machines suspend once locked
  if [[ $HOST == pml-w* ]]; then
    systemctl --user disable --now suspend-when-locked.service 2>/dev/null || true
  else
    systemctl --user enable --now suspend-when-locked.service 2>/dev/null || true
  fi
  systemctl --user enable --now gamesir-x360.service 2>/dev/null || true
  systemctl --user enable --now repo-sync.timer 2>/dev/null || true
fi

# private/ used to be a symlink to a separate arctic-lake-private clone; the
# notes now live in the vault repo itself, so a leftover link must go before
# repo-sync can check the directory out.
[[ -L $HOME/repos/arctic-lake/private ]] && rm "$HOME/repos/arctic-lake/private"

link "$REPO/nvim" "$HOME/.config/nvim"
# nvim follows the active omarchy theme; untracked, see nvim/.gitignore
ln -sfn "$HOME/.local/state/omarchy/current/theme/neovim.lua" "$REPO/nvim/lua/plugins/theme.lua"

if (( LINK_ONLY )); then
  exit 0
fi

# sudo and polkit never ask me for a password: the disk password at boot and
# the lock screen are the gates. 1Password keeps its own unlock prompt.
if [[ ! -f /etc/sudoers.d/50-$USER-nopasswd ]]; then
  echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/50-$USER-nopasswd" >/dev/null
  sudo chmod 440 "/etc/sudoers.d/50-$USER-nopasswd"
fi
if [[ ! -f /etc/polkit-1/rules.d/49-$USER-nopasswd.rules ]]; then
  sudo tee "/etc/polkit-1/rules.d/49-$USER-nopasswd.rules" >/dev/null <<POLKIT
polkit.addRule(function(action, subject) {
    if (subject.user == "$USER" && action.id.indexOf("com.1password.") != 0) {
        return polkit.Result.YES;
    }
});
POLKIT
fi

(( ${#PACKAGES[@]} )) && omarchy-pkg-add "${PACKAGES[@]}"
(( ${#PACKAGES_AUR[@]} )) && omarchy-pkg-aur-add "${PACKAGES_AUR[@]}"

for tool in "${MISE_TOOLS[@]}"; do
  grep -qs "^${tool%@*} *=" "$HOME/.config/mise/config.toml" || mise use --global "$tool"
done

# sciview (~/repos/sciview, cloned by bootstrap-omarchy.sh): the debugger app
# behind nvim's viewer, SUPER+M (hyprland.lua) and the bar's fo.sciview widget.
# These are the install steps from its README.
SCIVIEW="$HOME/repos/sciview"
SCIVIEW_ENV="$HOME/envs/sciview/.venv"
if [[ -d $SCIVIEW ]]; then
  if [[ ! -x $SCIVIEW_ENV/bin/sciview ]]; then
    mise exec -- uv venv --allow-existing "$SCIVIEW_ENV" --python 3.12 &&
      mise exec -- uv pip install --python "$SCIVIEW_ENV/bin/python" -e "$SCIVIEW[test]" ||
      echo "sciview's env didn't install; see $SCIVIEW/README.md" >&2
  fi
  link "$SCIVIEW_ENV/bin/sciview" "$HOME/.local/bin/sciview"
  link "$SCIVIEW/omarchy/fo.sciview" "$HOME/.config/omarchy/plugins/fo.sciview"
  link "$SCIVIEW/systemd/sciview.service" "$HOME/.config/systemd/user/sciview.service"
  link "$SCIVIEW/systemd/sciview.socket" "$HOME/.config/systemd/user/sciview.socket"
  systemctl --user daemon-reload 2>/dev/null || true
  systemctl --user enable --now sciview.socket 2>/dev/null || true
fi

# skills and agents are chosen in agents/skills.conf
python3 "$REPO/agents/sync_skills.py"

# last, since these can be long and interactive (logins, prompts, a reboot)
for app in "${OMARCHY_APPS[@]}"; do
  read -r pkg installer <<<"$app"
  pacman -Q "$pkg" &>/dev/null && continue
  $installer || echo "$installer failed; run it again on its own" >&2
done
