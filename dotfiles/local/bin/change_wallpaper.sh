#!/usr/bin/env bash
set -uo pipefail

DIR="$HOME/Pictures/Backgrounds"
INDEX_FILE="$HOME/.cache/wallpaper_index"
LOG_FILE="$HOME/.cache/change_wallpaper.log"
mkdir -p "$HOME/.cache"

log() { printf '%s | %s\n' "$(date '+%F %T')" "$*" >> "$LOG_FILE"; }

mapfile -t WALLPAPERS < <(find "$DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) | sort)

if [[ "${#WALLPAPERS[@]}" -eq 0 ]]; then
  log "ERROR: no wallpapers found in $DIR"
  exit 1
fi

INDEX=0
if [[ -f "$INDEX_FILE" ]]; then
  INDEX="$(cat "$INDEX_FILE" 2>/dev/null || echo 0)"
fi
# clamp
if ! [[ "$INDEX" =~ ^[0-9]+$ ]]; then INDEX=0; fi
INDEX=$(( INDEX % ${#WALLPAPERS[@]} ))

WALL="${WALLPAPERS[$INDEX]}"
log "Picked index=$INDEX wallpaper=$WALL"

# Apply theme (this is the only heavy work)
"$HOME/.local/bin/apply_theme.sh" "$WALL" >/dev/null 2>&1 || log "ERROR: apply_theme failed"

# Advance index
NEXT=$(( (INDEX + 1) % ${#WALLPAPERS[@]} ))
echo "$NEXT" > "$INDEX_FILE"
log "Done; next index=$NEXT"
