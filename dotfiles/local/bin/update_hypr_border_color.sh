#!/usr/bin/env bash
set -euo pipefail

HYPRCTL=/usr/bin/hyprctl

TRANSPARENT="00000000"

# Keep border_size intact for resize_on_border, but make borders invisible.
"$HYPRCTL" keyword general:col.active_border "$TRANSPARENT $TRANSPARENT 45deg" >/dev/null 2>&1 || true
"$HYPRCTL" keyword general:col.inactive_border "$TRANSPARENT" >/dev/null 2>&1 || true

# If your borderless-single helper is running, ask it to re-apply immediately.
# (Wallpaper/theme updates don't necessarily generate Hyprland socket events.)
pkill -USR1 -f "$HOME/.local/bin/hypr-borderless-single" >/dev/null 2>&1 || true
