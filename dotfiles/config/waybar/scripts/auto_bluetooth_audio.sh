#!/usr/bin/env bash
set -euo pipefail

switch_to_bluetooth_sink() {
  local sink
  sink="$(pactl list short sinks | awk '/bluez_output/ { print $2; exit }')"
  [[ -n "$sink" ]] || return 0

  pactl set-default-sink "$sink"

  pactl list short sink-inputs | awk '{ print $1 }' | while read -r input; do
    [[ -n "$input" ]] || continue
    pactl move-sink-input "$input" "$sink" >/dev/null 2>&1 || true
  done
}

switch_to_bluetooth_sink

pactl subscribe | while read -r event; do
  case "$event" in
    *"on sink"*)
      sleep 0.5
      switch_to_bluetooth_sink
      ;;
  esac
done
