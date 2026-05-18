#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="$HOME/.cache/apply_cached_theme.log"
mkdir -p "$HOME/.cache"

log() { printf '%s | %s\n' "$(date '+%F %T')" "$*" >> "$LOG_FILE"; }

update_vscode_wallust_theme() {
  # Wallust is only used for VS Code; the rest of the desktop keeps using wal.
  if [[ -n "${WALLPAPER:-}" && -f "$WALLPAPER" ]]; then
    if command -v wallust >/dev/null 2>&1; then
      wallust run -q -s "$WALLPAPER" >/dev/null 2>&1 || log "WARN: wallust VS Code theme update failed"
    else
      log "WARN: wallust not found; VS Code theme will not update"
    fi
  fi
}

WAL_LAST_WALLPAPER_FILE="$HOME/.cache/wal/wal"

# 1) Start wallpaper daemon if needed (Arch: awww replaces swww)
if command -v awww-daemon >/dev/null 2>&1; then
  if ! pgrep -x awww-daemon >/dev/null 2>&1; then
    (awww-daemon --quiet >/dev/null 2>&1 &)
    sleep 0.25
  fi
else
  log "WARN: awww-daemon not found; wallpaper will not be restored"
fi

# 2) Set wallpaper from cached path
if [[ -f "$WAL_LAST_WALLPAPER_FILE" ]]; then
  WALLPAPER="$(cat "$WAL_LAST_WALLPAPER_FILE" 2>/dev/null || true)"
else
  WALLPAPER=""
fi

if [[ -n "${WALLPAPER:-}" && -f "$WALLPAPER" ]]; then
  log "Wallpaper: $WALLPAPER"
  if command -v awww >/dev/null 2>&1; then
    awww img "$WALLPAPER" \
      --transition-type simple \
      --transition-step 1 \
      --transition-fps 165 \
      --resize fit \
      >/dev/null 2>&1 || log "WARN: awww img failed"
  else
    log "WARN: awww not found; wallpaper will not be restored"
  fi
else
  log "WARN: No valid cached wallpaper found at $WAL_LAST_WALLPAPER_FILE"
fi

# 3) Restore previous wal palette instantly (no regeneration)
if command -v wal >/dev/null 2>&1; then
  wal -R -q || log "WARN: wal -R failed"
else
  log "WARN: wal not found"
fi

# 4) Generate Wallust files watched by the VS Code Wallust theme extension
update_vscode_wallust_theme

# 5) Apply Hyprland border colors (your existing script)
if [[ -x "$HOME/.local/bin/update_hypr_border_color.sh" ]]; then
  "$HOME/.local/bin/update_hypr_border_color.sh" >/dev/null 2>&1 || log "WARN: update_hypr_border_color.sh failed"
fi

# 6) Kitty live apply (matches your change_wallpaper behavior)
if [[ -f "$HOME/.cache/wal/colors-kitty.conf" ]]; then
  sed -i '/^background /d' "$HOME/.cache/wal/colors-kitty.conf" || true
  kitty @ set-colors --all "$HOME/.cache/wal/colors-kitty.conf" >/dev/null 2>&1 || true
  kitty @ set-colors --all --configured background=#000000 >/dev/null 2>&1 || true
  printf "\033]11;#000000\007" || true
fi

# 7) Keyboard RGB sync (OpenRGB) using wal palette
if [[ -x "$HOME/.local/bin/wal-to-openrgb" ]]; then
  "$HOME/.local/bin/wal-to-openrgb" >/dev/null 2>&1 || log "WARN: wal-to-openrgb failed"
fi

log "Done"
