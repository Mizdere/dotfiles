#!/usr/bin/env bash
set -euo pipefail

json_escape() {
  local s=${1:-}
  s=${s//\\/\\\\}
  s=${s//"/\\"}
  s=${s//$'\n'/\\n}
  printf '%s' "$s"
}

format_rate() {
  local bytes=${1:-0}
  awk -v b="$bytes" 'BEGIN {
    if (b >= 1048576) printf "%.1fM", b / 1048576;
    else if (b >= 1024) printf "%.0fK", b / 1024;
    else printf "%dB", b;
  }'
}

iface="$(ip route get 1.1.1.1 2>/dev/null | awk '{ for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit } }' || true)"
if [[ -z "$iface" ]]; then
  iface="$(awk -F: '$1 != "lo" { gsub(/ /, "", $1); print $1; exit }' /proc/net/dev)"
fi

rx_file="/sys/class/net/${iface}/statistics/rx_bytes"
tx_file="/sys/class/net/${iface}/statistics/tx_bytes"

if [[ -z "$iface" || ! -r "$rx_file" || ! -r "$tx_file" ]]; then
  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
    "$(json_escape "↓ --K ↑ --K")" \
    "$(json_escape "Network: unavailable\nClick: select network")" \
    "$(json_escape "off")"
  exit 0
fi

rx="$(<"$rx_file")"
tx="$(<"$tx_file")"
now="$(date +%s)"
state="${XDG_RUNTIME_DIR:-/tmp}/waybar-net-stat.prev"

down=0
up=0
if [[ -f "$state" ]]; then
  read -r prev_now prev_rx prev_tx < "$state" || true
  elapsed=$((now - ${prev_now:-now}))
  if (( elapsed > 0 )); then
    down=$(((rx - ${prev_rx:-rx}) / elapsed))
    up=$(((tx - ${prev_tx:-tx}) / elapsed))
    (( down < 0 )) && down=0
    (( up < 0 )) && up=0
  fi
fi

printf '%s %s %s\n' "$now" "$rx" "$tx" > "$state"

down_text="$(format_rate "$down")"
up_text="$(format_rate "$up")"
tooltip="Network: ${iface}\nDownload: ${down_text}/s\nUpload: ${up_text}/s\nLeft click: WiFi controls\nRight click: Bluetooth controls"

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
  "$(json_escape "↓ ${down_text} ↑ ${up_text}")" \
  "$(json_escape "$tooltip")" \
  "$(json_escape "connected")"
