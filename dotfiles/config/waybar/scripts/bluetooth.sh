#!/usr/bin/env bash
set -euo pipefail

# Waybar custom module (return-type: json)

json_escape() {
  local s=${1:-}
  s=${s//\\/\\\\}
  s=${s//"/\\"}
  s=${s//$'\n'/\\n}
  printf '%s' "$s"
}

powered="$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/{print $2; exit}' || true)"
if [[ "$powered" != "yes" ]]; then
  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
    "$(json_escape "󰕒")" \
    "$(json_escape "Bluetooth: off\nClick: manage devices")" \
    "$(json_escape "off")"
  exit 0
fi

connected_lines="$(bluetoothctl devices Connected 2>/dev/null || true)"
connected_count="$(printf '%s\n' "$connected_lines" | sed '/^$/d' | wc -l | tr -d ' ')"

icon="󰕒"
cls="on"
tooltip="Bluetooth: on"
if [[ "${connected_count:-0}" -gt 0 ]]; then
  icon="󰕒"
  cls="connected"
  tooltip+="\n"
  tooltip+="$(printf '%s\n' "$connected_lines" | awk '{ $1=""; $2=""; sub(/^  +/,"",$0); print "Connected: " $0 }')"
fi

tooltip+="\nClick: manage devices"

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
  "$(json_escape "$icon")" \
  "$(json_escape "$tooltip")" \
  "$(json_escape "$cls")"
