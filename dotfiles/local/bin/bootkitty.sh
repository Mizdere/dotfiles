#!/usr/bin/env bash
set -u

LOG="$HOME/.cache/bootkitty.log"
mkdir -p "$HOME/.cache"

echo "$(date) bootkitty script start" >> "$LOG"

# Give Hyprland a moment to settle (this is usually the missing piece)
sleep 1

# Don’t spawn duplicates
if pgrep -fa 'kitty.*--title bootkitty' >/dev/null; then
  echo "$(date) bootkitty already running, skip" >> "$LOG"
  exit 0
fi

# Launch like SUPER+Enter would, but with a unique title
/usr/bin/kitty --title bootkitty \
  -o initial_window_width=900 \
  -o initial_window_height=520 \
  sh -lc 'exec ${SHELL:-/bin/bash} -l' >> "$LOG" 2>&1 &

echo "$(date) bootkitty launch attempted" >> "$LOG"
