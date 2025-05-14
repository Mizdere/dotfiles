#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Backgrounds"
INDEX_FILE="$HOME/.wallpaper_index"
LOCK_FILE="/tmp/change_wallpaper.lock"

# Prevent concurrent runs
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    exit 1
fi

# Check if Thunar was open beforehand
THUNAR_WAS_RUNNING=false
if pgrep -x thunar >/dev/null; then
    THUNAR_WAS_RUNNING=true
fi

# Get sorted wallpaper list
mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)
if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Read and increment wallpaper index
if [[ -f "$INDEX_FILE" ]]; then
    INDEX=$(<"$INDEX_FILE")
else
    INDEX=0
fi
(( INDEX >= ${#WALLPAPERS[@]} )) && INDEX=0

# Set the wallpaper
swww img "${WALLPAPERS[$INDEX]}" \
  --transition-type simple \
  --transition-duration 0.6 \
  --resize fit

# Generate color scheme
wal --backend colorz -i "${WALLPAPERS[$INDEX]}" -q

# Apply Firefox theme
pywalfox update

# Apply GTK theme if wal-gtk exists
if command -v wal-gtk &>/dev/null; then
    wal-gtk -i "${WALLPAPERS[$INDEX]}"
    wal-gtk apply
fi

# === GTK Styling for Thunar ===
FG_COLOR=$(grep "^foreground=" ~/.cache/wal/colors.sh | cut -d"'" -f2)
BG_COLOR=$(grep "^background" ~/.cache/wal/colors-kitty.conf | awk '{print $2}')

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

# === Icon Recoloring (folders only) ===
ICON_COLOR=$(jq -r '.colors | to_entries[] | select(.key | test("color[2-7]")) | .value' ~/.cache/wal/colors.json | shuf -n 1)
ICON_DIR="$HOME/.icons/Pywal-Papirus"
BASE_DIR="/usr/share/icons/Papirus"

rm -rf "$ICON_DIR"
cp -r "$BASE_DIR" "$ICON_DIR"

find "$ICON_DIR" -type f -path "*/places/*" -name "*.svg" -exec sed -i "s/#5294e2/$ICON_COLOR/g" {} +
gtk-update-icon-cache -f "$ICON_DIR" &>/dev/null
gsettings set org.gnome.desktop.interface icon-theme 'Pywal-Papirus'

# === Restart Thunar only if it was running before ===
if [ "$THUNAR_WAS_RUNNING" = true ]; then
    pkill thunar
    sleep 0.6
    hyprctl dispatch exec "[workspace 1 silent] thunar"
fi

# Save next wallpaper index
echo $((INDEX + 1)) > "$INDEX_FILE"
