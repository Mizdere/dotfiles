#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Backgrounds"
INDEX_FILE="$HOME/.wallpaper_index"
LOCK_FILE="/tmp/change_wallpaper.lock"

# Prevent running multiple times at once
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    exit 1
fi

# Get sorted list of wallpapers
mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \) | sort)
if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Read current index
if [[ -f "$INDEX_FILE" ]]; then
    INDEX=$(<"$INDEX_FILE")
else
    INDEX=0
fi

# Loop to beginning if needed
if (( INDEX >= ${#WALLPAPERS[@]} )); then
    INDEX=0
fi

# Set wallpaper with smooth transition
swww img "${WALLPAPERS[$INDEX]}" \
  --transition-type simple \
  --transition-duration 0.6 \
  --resize fit

# Generate pywal theme
wal -i "${WALLPAPERS[$INDEX]}" -q

# Sync Firefox
pywalfox update

# Apply GTK colors if wal-gtk exists
if command -v wal-gtk &>/dev/null; then
    wal-gtk -i "${WALLPAPERS[$INDEX]}"
    wal-gtk apply
fi

# === THEME THUNAR ===

# Get colors
FG_COLOR=$(grep "^foreground=" ~/.cache/wal/colors.sh | cut -d"'" -f2)
BG_COLOR=$(grep "^background" ~/.cache/wal/colors-kitty.conf | awk '{print $2}')

# Write GTK override using Kitty's background
mkdir -p ~/.config/gtk-3.0
cat > ~/.config/gtk-3.0/gtk.css <<EOL
.thunar .standard-view .view,
.thunar .sidebar .view,
.thunar toolbar,
.thunar statusbar,
.thunar menubar {
    background-color: $BG_COLOR;
    color: $FG_COLOR;
}

.thunar .view:selected,
.thunar .sidebar .view:selected {
    background-color: rgba(255, 255, 255, 0.1);
    border-radius: 4px;
    padding: 2px;
}
EOL

# === RANDOM ICON RECOLORING ===

# Pick a random accent color from color2–color7
ICON_COLOR=$(jq -r '.colors | to_entries[] | select(.key | test("color[2-7]")) | .value' ~/.cache/wal/colors.json | shuf -n 1)

ICON_DIR="$HOME/.icons/Pywal-Papirus"
BASE_DIR="/usr/share/icons/Papirus"

# Always start fresh from original Papirus to avoid layering changes
rm -rf "$ICON_DIR"
cp -r "$BASE_DIR" "$ICON_DIR"

# Recolor all SVGs containing Papirus folder blue (#5294e2)
find "$ICON_DIR" -type f -name "*.svg" -exec sed -i "s/#5294e2/$ICON_COLOR/g" {} +

# Refresh icon cache
gtk-update-icon-cache -f "$ICON_DIR" &>/dev/null

# Apply modified icon theme
gsettings set org.gnome.desktop.interface icon-theme 'Pywal-Papirus'


# Restart Thunar ONLY if running
if pgrep -x thunar >/dev/null; then
    pkill thunar
    sleep 0.5
    hyprctl dispatch exec "[workspace 1 silent] thunar"
fi

# Save next wallpaper index
echo $((INDEX + 1)) > "$INDEX_FILE"
