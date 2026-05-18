#!/usr/bin/env bash
set -euo pipefail

if ! command -v fuzzel >/dev/null 2>&1; then
  notify-send "Waybar WiFi" "fuzzel not installed" 2>/dev/null || true
  exit 1
fi

wifi_dev="$(nmcli -t -f DEVICE,TYPE dev status | awk -F: '$2=="wifi"{print $1; exit}')"
if [[ -z "$wifi_dev" ]]; then
  notify-send "Waybar WiFi" "No WiFi device found" 2>/dev/null || true
  exit 1
fi

radio="$(nmcli -t -f WIFI g)"
active_ssid="$(nmcli -t -f IN-USE,SSID dev wifi list ifname "$wifi_dev" 2>/dev/null | awk -F: '$1=="*"{print $2; exit}')"

choices=$(
  printf "toggle wifi (%s)\n" "$radio"
  [[ -n "$active_ssid" ]] && printf "disconnect (%s)\n" "$active_ssid"
  nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list ifname "$wifi_dev" 2>/dev/null \
    | awk -F: 'BEGIN{OFS=""} {ssid=$1; sig=$2; sec=$3; if(ssid=="") next; if(sec=="") sec="open"; print ssid, "\t", sig, "%\t", sec}' \
    | sort -u
)

sel="$(printf "%s" "$choices" | fuzzel --dmenu --prompt="wifi> " 2>/dev/null || true)"
[[ -n "$sel" ]] || exit 0

case "$sel" in
  toggle\ wifi\ (*)
    if [[ "$radio" == "enabled" ]]; then
      nmcli radio wifi off
    else
      nmcli radio wifi on
    fi
    ;;
  disconnect\ (*)
    nmcli dev disconnect "$wifi_dev" || true
    ;;
  *)
    ssid="${sel%%$'\t'*}"
    [[ -n "$ssid" ]] || exit 0
    # Try without password first.
    out="$(nmcli dev wifi connect "$ssid" ifname "$wifi_dev" 2>&1)" || true
    if printf '%s' "$out" | grep -qiE 'secrets were required|password|802-11-wireless-security'; then
      pw="$(printf '' | fuzzel --dmenu --prompt="password> " --password 2>/dev/null || true)"
      [[ -n "$pw" ]] || exit 0
      nmcli dev wifi connect "$ssid" password "$pw" ifname "$wifi_dev" >/dev/null 2>&1 || true
    fi
    ;;
esac
