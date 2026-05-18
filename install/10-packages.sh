#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

sudo pacman -Syu --needed - < "$repo_root/packages/pacman.txt"

if ! command -v paru >/dev/null 2>&1; then
  tmp="${XDG_CACHE_HOME:-$HOME/.cache}/paru-bootstrap"
  rm -rf "$tmp"
  git clone https://aur.archlinux.org/paru.git "$tmp"
  (cd "$tmp" && makepkg -si --noconfirm)
fi

paru -S --needed - < "$repo_root/packages/aur.txt"

if [[ -s "$repo_root/packages/flatpak.txt" ]] && command -v flatpak >/dev/null 2>&1; then
  while read -r app; do
    [[ -n "$app" ]] || continue
    flatpak install -y flathub "$app"
  done < "$repo_root/packages/flatpak.txt"
fi
