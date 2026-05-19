#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
stamp="$(date +%Y%m%d-%H%M%S)"
backup="$HOME/.dotfiles-backup-$stamp"

mkdir -p "$backup"

backup_path() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    mkdir -p "$backup/$(dirname "${path#$HOME/}")"
    mv "$path" "$backup/${path#$HOME/}"
  fi
}

for item in hypr waybar orbit systemd dunst rofi fuzzel gtk-3.0 gtk-4.0 qt6ct wallust fastfetch mpv zathura environment.d; do
  backup_path "$HOME/.config/$item"
done

mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/Pictures"
rsync -a "$repo_root/dotfiles/config/" "$HOME/.config/"
rsync -a "$repo_root/dotfiles/local/bin/" "$HOME/.local/bin/"
if [[ -d "$repo_root/dotfiles/local/share/applications" ]]; then
  rsync -a "$repo_root/dotfiles/local/share/applications/" "$HOME/.local/share/applications/"
fi
rsync -a "$repo_root/dotfiles/Pictures/" "$HOME/Pictures/"
chmod +x "$HOME/.local/bin/"* 2>/dev/null || true

printf 'Existing files backed up to %s\n' "$backup"
