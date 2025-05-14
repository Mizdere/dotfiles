#!/bin/bash
# Full restore script for Mizdere's riced Arch setup
# Includes pywal, swww, hyprland, gtk themes, kitty, btop, pywalfox, and keybinds

set -e

# --------- Update System ---------
echo ":: Updating system..."
sudo pacman -Syu --noconfirm

# --------- Install Required Packages ---------
echo ":: Installing packages..."
while IFS= read -r pkg; do
    echo "Installing $pkg..."
    sudo pacman -S --needed --noconfirm "$pkg"
done < "$(dirname "$0")/rice-packages.txt"

# --------- AUR Helper ---------
if ! command -v yay &>/dev/null; then
    echo ":: Installing yay (AUR helper)..."
    git clone https://aur.archlinux.org/yay.git ~/yay
    (cd ~/yay && makepkg -si --noconfirm)
fi

# --------- AUR Tools ---------
yay -S --needed --noconfirm pywalfox wal-gtk grimblast-git

# --------- Restore Configs ---------
echo ":: Restoring configuration files..."
mkdir -p ~/.config
cp -r hypr ~/.config/
cp -r kitty ~/.config/
cp -r fastfetch ~/.config/
cp -r btop ~/.config/
cp -r neofetch ~/.config/
cp -r wal ~/.config/
cp -r gtk-3.0 ~/.config/
cp .zshrc ~/
cp .bashrc ~/ 

# --------- Restore Scripts ---------
echo ":: Restoring local scripts..."
mkdir -p ~/.local/bin
cp -r bin/* ~/.local/bin/
chmod +x ~/.local/bin/*

# --------- Set default wallpaper and generate theme ---------
echo ":: Setting wallpaper and generating pywal theme..."
DEFAULT_WALL=$(find ~/Pictures/Backgrounds -type f \( -iname '*.jpg' -o -iname '*.png' \) | head -n 1)
if [[ -n "$DEFAULT_WALL" ]]; then
    wal --backend colorz -i "$DEFAULT_WALL" -q
    pywalfox update
    if command -v wal-gtk &>/dev/null; then
        wal-gtk -i "$DEFAULT_WALL"
        wal-gtk apply
    fi
fi

# --------- Set GTK Theme ---------
gsettings set org.gnome.desktop.interface icon-theme 'Pywal-Papirus' || true

# --------- Init pywalfox ---------
pywalfox init || true

# --------- Final Notes ---------
echo ":: Restore complete!"
echo "- Restart Hyprland to apply all settings."
echo "- Press SUPER+= to cycle wallpapers via keybind."
echo "- Confirm GTK theme and Firefox (pywalfox) look correct."
