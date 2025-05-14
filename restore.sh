#!/bin/bash

# Restore script for Mizdere's dotfiles setup
# Reinstalls ricing packages and restores configs

set -e

echo ">> Updating system..."
sudo pacman -Syu --noconfirm

echo ">> Installing essential packages..."
# Read from saved list
while IFS= read -r pkg; do
    echo "Installing $pkg"
    sudo pacman -S --needed --noconfirm "$pkg"
done < "$(dirname "$0")/rice-packages.txt"

echo ">> Restoring config files..."

cp -r hypr ~/.config/
cp -r kitty ~/.config/
cp -r fastfetch ~/.config/
cp -r btop ~/.config/
cp -r neofetch ~/.config/
cp -r wal ~/.config/
cp -r gtk-3.0 ~/.config/
cp .zshrc ~/
cp .bashrc ~/

mkdir -p ~/.local/bin
cp -r bin/* ~/.local/bin/

echo ">> Done! You may want to restart your session or run Hyprland manually."
