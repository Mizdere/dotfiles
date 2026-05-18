#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  up)
    asusctl leds next
    ;;
  down)
    asusctl leds prev
    ;;
  *)
    echo "usage: keyboard_brightness.sh [up|down]" >&2
    exit 2
    ;;
esac

if ! asusctl leds get 2>/dev/null | grep -qi 'Off'; then
  "$HOME/.local/bin/wal-to-openrgb" --force >/dev/null 2>&1 || true
fi
