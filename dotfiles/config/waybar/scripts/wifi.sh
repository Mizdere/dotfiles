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

wifi_radio="$(nmcli -t -f WIFI g 2>/dev/null || true)"
wifi_dev="$(nmcli -t -f DEVICE,TYPE dev status 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}')"

ssid=""
signal=""
ip=""
if [[ -n "$wifi_dev" && "$wifi_radio" == "enabled" ]]; then
  ssid="$(nmcli -t -f IN-USE,SSID dev wifi list ifname "$wifi_dev" 2>/dev/null | awk -F: '$1=="*"{print $2; exit}')"
  signal="$(nmcli -t -f IN-USE,SIGNAL dev wifi list ifname "$wifi_dev" 2>/dev/null | awk -F: '$1=="*"{print $2; exit}')"
  ip="$(nmcli -t -f IP4.ADDRESS dev show "$wifi_dev" 2>/dev/null | awk -F: 'NR==1{print $2}' | cut -d/ -f1)"
fi

icon="󰇚"
cls="off"
tooltip="WiFi: off\nClick: select network"

if [[ "$wifi_radio" == "enabled" ]]; then
  icon="󰇚"
  cls="disconnected"
  tooltip="WiFi: not connected\nClick: select network"

  if [[ -n "$ssid" ]]; then
    sig=${signal:-0}
    icon="󰇚"
    cls="connected"
    tooltip="WiFi: ${ssid} (${signal:-?}%)"
    [[ -n "$ip" ]] && tooltip+="\nIP: $ip"
    tooltip+="\nClick: select network"
  fi
fi

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
  "$(json_escape "$icon")" \
  "$(json_escape "$tooltip")" \
  "$(json_escape "$cls")"
