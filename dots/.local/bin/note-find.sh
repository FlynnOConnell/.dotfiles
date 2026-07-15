#!/usr/bin/env bash
# Telescope-style fuzzy finder for the arctic-lake vault.
#   enter  -> open in nvim (this terminal)
#   ctrl-o -> Obsidian
#   ctrl-e -> VSCode
#   ctrl-/ -> toggle preview
# Edit which folders are searched in:  ~/.config/note-find/dirs
set -euo pipefail

VAULT="${NOTE_VAULT:-$HOME/repos/arctic-lake}"
CONFIG="${NOTE_FIND_CONFIG:-$HOME/.config/note-find/dirs}"

# First run: seed the folder list. Edit it anytime; changes apply next open.
if [[ ! -f "$CONFIG" ]]; then
  mkdir -p "$(dirname "$CONFIG")"
  cat >"$CONFIG" <<'EOF'
# Folders to search, relative to the vault root — one per line.
# Add/remove a line and re-open the finder; changes apply instantly.
# Use "." on its own line to search the whole vault.
notes
docs
EOF
fi

mapfile -t dirs < <(grep -vE '^[[:space:]]*(#|$)' "$CONFIG" || true)
[[ ${#dirs[@]} -eq 0 ]] && dirs=(.)

cd "$VAULT"

result=$(
  fdfind -e md --no-ignore \
    --exclude .git --exclude .obsidian --exclude .venv \
    . "${dirs[@]}" 2>/dev/null \
  | fzf --prompt='notes> ' \
        --height=100% --layout=reverse --border \
        --preview 'head -n 400 -- {}' \
        --preview-window='right,60%,wrap' \
        --header='enter: nvim   ctrl-o: obsidian   ctrl-e: vscode   ctrl-/: preview' \
        --bind='ctrl-/:toggle-preview' \
        --expect=ctrl-o,ctrl-e
) || exit 0

key=$(sed -n 1p <<<"$result")
file=$(sed -n 2p <<<"$result")
[[ -z "$file" ]] && exit 0

urlencode() {
  local s="$1" out= c i
  for (( i=0; i<${#s}; i++ )); do
    c=${s:i:1}
    case "$c" in
      [a-zA-Z0-9._~/-]) out+="$c" ;;
      *) printf -v c '%%%02X' "'$c"; out+="$c" ;;
    esac
  done
  printf '%s' "$out"
}

case "$key" in
  ctrl-o) setsid xdg-open "obsidian://open?path=$(urlencode "$VAULT/$file")" >/dev/null 2>&1 & ;;
  ctrl-e) setsid code "$VAULT/$file" >/dev/null 2>&1 & ;;
  *)      exec nvim "$file" ;;
esac
