#!/usr/bin/env bash
set -uo pipefail

WALLPAPER="${1:-}"
LOG_FILE="$HOME/.cache/apply_theme.log"
LATEST_WALLPAPER_FILE="$HOME/.cache/current_wallpaper"
mkdir -p "$HOME/.cache"

log() { printf '%s | %s\n' "$(date '+%F %T')" "$*" >> "$LOG_FILE"; }

update_vscode_wallust_theme() {
  # Wallust is only used for VS Code; the rest of the desktop keeps using wal.
  if command -v wallust >/dev/null 2>&1; then
    wallust run -q -s "$WALLPAPER" >/dev/null 2>&1 || log "WARN: wallust VS Code theme update failed"
  else
    log "WARN: wallust not found; VS Code theme will not update"
  fi
}

update_sddm_login_background() {
  # Keep SDDM login background in sync with the current wallpaper.
  # SilentSDDM can only load images from its `backgrounds/` dir, so we keep a
  # stable cache in /var/cache/sddm and symlink `current.jpg` to it.

  local theme_bg_dir="/usr/share/sddm/themes/silent/backgrounds"
  local theme_bg_link="$theme_bg_dir/current.jpg"
  local cache_dir="/var/cache/sddm/wallpaper"
  local cache_img="$cache_dir/current.jpg"
  local cache_hash="$cache_dir/source.sha256"

  if [[ "$(cat "$LATEST_WALLPAPER_FILE" 2>/dev/null || true)" != "$WALLPAPER" ]]; then
    log "SDDM sync skipped; newer wallpaper selected"
    return 0
  fi

  if [[ ! -d "$theme_bg_dir" ]]; then
    log "WARN: SilentSDDM backgrounds dir not found; skipping SDDM update"
    return 0
  fi

  sudo mkdir -p "$cache_dir" >/dev/null 2>&1 || true
  sudo chmod 755 "$cache_dir" >/dev/null 2>&1 || true

  local new_hash old_hash
  new_hash="$(sha256sum "$WALLPAPER" 2>/dev/null | cut -d' ' -f1 || true)"
  old_hash="$(sudo cat "$cache_hash" 2>/dev/null || true)"

  if [[ -n "$new_hash" && "$new_hash" == "$old_hash" && -f "$cache_img" ]]; then
    # Still ensure the theme points at the cached image.
    if [[ "$(readlink -f "$theme_bg_link" 2>/dev/null || true)" != "$cache_img" ]]; then
      sudo rm -f "$theme_bg_link" >/dev/null 2>&1 || true
      sudo ln -s "$cache_img" "$theme_bg_link" >/dev/null 2>&1 || true
    fi
    return 0
  fi

  # Convert (png/webp/etc) into a predictable jpg for SDDM.
  if command -v magick >/dev/null 2>&1; then
    sudo magick "$WALLPAPER" -auto-orient -strip -quality 92 "$cache_img.tmp" >/dev/null 2>&1 || {
      log "WARN: failed to convert wallpaper to SDDM jpg"
      return 0
    }
    if [[ "$(cat "$LATEST_WALLPAPER_FILE" 2>/dev/null || true)" != "$WALLPAPER" ]]; then
      sudo rm -f "$cache_img.tmp" >/dev/null 2>&1 || true
      log "SDDM sync skipped after conversion; newer wallpaper selected"
      return 0
    fi
    sudo mv -f "$cache_img.tmp" "$cache_img" >/dev/null 2>&1 || true
  else
    # Fallback: only works if the wallpaper is already a jpg.
    if [[ "${WALLPAPER,,}" != *.jpg && "${WALLPAPER,,}" != *.jpeg ]]; then
      log "WARN: ImageMagick not found and wallpaper is not jpg; skipping SDDM update"
      return 0
    fi
    sudo cp -f "$WALLPAPER" "$cache_img.tmp" >/dev/null 2>&1 || {
      log "WARN: failed to copy wallpaper to SDDM jpg"
      return 0
    }
    if [[ "$(cat "$LATEST_WALLPAPER_FILE" 2>/dev/null || true)" != "$WALLPAPER" ]]; then
      sudo rm -f "$cache_img.tmp" >/dev/null 2>&1 || true
      log "SDDM sync skipped after copy; newer wallpaper selected"
      return 0
    fi
    sudo mv -f "$cache_img.tmp" "$cache_img" >/dev/null 2>&1 || true
  fi

  if [[ -n "$new_hash" ]]; then
    sudo bash -lc "umask 022; printf '%s\n' '$new_hash' > '$cache_hash'" >/dev/null 2>&1 || true
  fi

  sudo chmod 644 "$cache_img" "$cache_hash" >/dev/null 2>&1 || true

  # Point theme background at the cached image.
  if [[ "$(cat "$LATEST_WALLPAPER_FILE" 2>/dev/null || true)" != "$WALLPAPER" ]]; then
    log "SDDM sync skipped before link; newer wallpaper selected"
    return 0
  fi
  sudo rm -f "$theme_bg_link" >/dev/null 2>&1 || true
  sudo ln -s "$cache_img" "$theme_bg_link" >/dev/null 2>&1 || true
}

if [[ -z "${WALLPAPER}" || ! -f "$WALLPAPER" ]]; then
  log "ERROR: invalid wallpaper: $WALLPAPER"
  exit 1
fi

printf '%s\n' "$WALLPAPER" > "$LATEST_WALLPAPER_FILE" 2>/dev/null || true

# --- Ensure wallpaper daemon (Arch: awww replaces swww) ---
if command -v awww-daemon >/dev/null 2>&1; then
  if ! pgrep -x awww-daemon >/dev/null 2>&1; then
    (awww-daemon --quiet >/dev/null 2>&1 &)
    sleep 0.20
  fi
else
  log "WARN: awww-daemon not found; wallpaper will not change"
fi

# --- Set wallpaper ---
if command -v awww >/dev/null 2>&1; then
  # awww's 'simple' ignores --transition-duration; use step+fps instead.
  # Approx duration ~= 255 / (step * fps). With step=1,fps=165 => ~1.55s.
  awww img "$WALLPAPER" \
    --transition-type simple \
    --transition-step 1 \
    --transition-fps 165 \
    --resize fit \
    >/dev/null 2>&1 || {
      # Retry once in case the daemon needed extra time.
      sleep 0.20
      awww img "$WALLPAPER" --transition-type simple --transition-step 1 --transition-fps 165 --resize fit >/dev/null 2>&1 \
        || log "WARN: awww img failed"
    }
else
  log "WARN: awww not found; wallpaper will not change"
fi

# --- Update SDDM login background (static image) without blocking wallpaper changes ---
( update_sddm_login_background || true ) >/dev/null 2>&1 &

# --- WAL: always prefer colorz; fallback only for THIS run ---
log "Applying wal backend=colorz wallpaper=$WALLPAPER"
if ! wal -q --backend colorz -i "$WALLPAPER" >/dev/null 2>&1; then
  log "WARN: wal backend=colorz failed; falling back to default backend for this run"
  wal -q -i "$WALLPAPER" >/dev/null 2>&1 || log "ERROR: wal fallback failed"
fi

# --- Wallust: generate only the VS Code theme input files ---
update_vscode_wallust_theme

# Save last wallpaper path for boot restore
printf '%s\n' "$WALLPAPER" > "$HOME/.cache/wal/wal" 2>/dev/null || true

# --- MUST APPLY (run synchronously so it works from keybind) ---

# Border update (log errors)
if [[ -x "$HOME/.local/bin/update_hypr_border_color.sh" ]]; then
  "$HOME/.local/bin/update_hypr_border_color.sh" >> "$LOG_FILE" 2>&1 || log "WARN: border update failed"
else
  log "WARN: missing update_hypr_border_color.sh"
fi

# Keyboard update (log errors)
if [[ -x "$HOME/.local/bin/wal-to-openrgb" ]]; then
  "$HOME/.local/bin/wal-to-openrgb" >> "$LOG_FILE" 2>&1 || log "WARN: wal-to-openrgb failed"
else
  log "WARN: missing wal-to-openrgb"
fi

# --- Optional extras (don’t block the keybind) ---
nohup bash -lc '
  if command -v pywalfox >/dev/null 2>&1; then
    for _ in 1 2 3 4 5; do
      pywalfox update >/dev/null 2>&1 && break
      sleep 0.2
    done
  fi

  if [[ -n "${KITTY_LISTEN_ON:-}" && -f "$HOME/.cache/wal/colors-kitty.conf" ]]; then
    sed -i "/^background /d" "$HOME/.cache/wal/colors-kitty.conf" || true
    kitty @ set-colors --all "$HOME/.cache/wal/colors-kitty.conf" >/dev/null 2>&1 || true
    kitty @ set-colors --all --configured background=#000000 >/dev/null 2>&1 || true
    printf "\033]11;#000000\007" >/dev/null 2>&1 || true
  fi
' >/dev/null 2>&1 &

log "Done"
