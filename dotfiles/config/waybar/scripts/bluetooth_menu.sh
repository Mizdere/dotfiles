#!/usr/bin/env bash
set -euo pipefail

if ! command -v fuzzel >/dev/null 2>&1; then
  notify-send "Waybar Bluetooth" "fuzzel not installed" 2>/dev/null || true
  exit 1
fi

powered="$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/{print $2; exit}')"
powered=${powered:-no}

choices=$(mktemp)
trap 'rm -f "$choices"' EXIT

{
  printf "open bluetooth manager\n"
  printf "toggle bluetooth (%s)\n" "$powered"
  printf "--- paired devices ---\n"

  bluetoothctl paired-devices 2>/dev/null | while read -r _ mac name_rest; do
    [[ -n "${mac:-}" ]] || continue
    name="$name_rest"
    connected="$(bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/Connected:/{print $2; exit}')"
    if [[ "$connected" == "yes" ]]; then
      printf "%s [connected]\t%s\n" "$name" "$mac"
    else
      printf "%s\t%s\n" "$name" "$mac"
    fi
  done
} >"$choices"

sel="$(cat "$choices" | fuzzel --dmenu --prompt="bt> " 2>/dev/null || true)"
[[ -n "$sel" ]] || exit 0

case "$sel" in
  "open bluetooth manager")
    (blueman-manager >/dev/null 2>&1 &)
    exit 0
    ;;
  toggle\ bluetooth\ (*)
    if [[ "$powered" == "yes" ]]; then
      bluetoothctl power off >/dev/null
    else
      bluetoothctl power on >/dev/null
    fi
    exit 0
    ;;
  "--- paired devices ---")
    exit 0
    ;;
  *)
    mac="${sel##*$'\t'}"
    [[ -n "$mac" ]] || exit 0
    connected="$(bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/Connected:/{print $2; exit}')"
    if [[ "$connected" == "yes" ]]; then
      bluetoothctl disconnect "$mac" >/dev/null || true
    else
      bluetoothctl connect "$mac" >/dev/null || true
    fi
    ;;
esac
