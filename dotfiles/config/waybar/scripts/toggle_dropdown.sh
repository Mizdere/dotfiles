#!/usr/bin/env bash
set -euo pipefail

mode="${1:-volume}"
script="$HOME/.config/waybar/scripts/dropdown_popup.py"
pidfile="${XDG_RUNTIME_DIR:-/tmp}/waybar-${mode}-dropdown.pid"

for other in volume power; do
  [[ "$other" == "$mode" ]] && continue
  other_pidfile="${XDG_RUNTIME_DIR:-/tmp}/waybar-${other}-dropdown.pid"
  [[ -f "$other_pidfile" ]] || continue
  other_pid="$(<"$other_pidfile")"
  if [[ -n "$other_pid" ]] && kill -0 "$other_pid" 2>/dev/null; then
    kill "$other_pid" 2>/dev/null || true
  fi
  rm -f "$other_pidfile"
done

if [[ -f "$pidfile" ]]; then
  pid="$(<"$pidfile")"
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    rm -f "$pidfile"
    exit 0
  fi
fi

LD_PRELOAD=/usr/lib/libgtk4-layer-shell.so "$script" "$mode" >/dev/null 2>&1 &
printf '%s' "$!" >"$pidfile"
