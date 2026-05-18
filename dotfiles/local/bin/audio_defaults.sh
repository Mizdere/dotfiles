#!/usr/bin/env bash
set -euo pipefail

card="alsa_card.pci-0000_65_00.6"
sink="alsa_output.pci-0000_65_00.6.analog-stereo"
source="alsa_input.pci-0000_65_00.6.analog-stereo"

for _ in {1..20}; do
  if pactl info >/dev/null 2>&1 && pactl list short sinks | grep -q "^.*$sink"; then
    break
  fi
  sleep 0.25
done

pactl set-card-profile "$card" output:analog-stereo+input:analog-stereo || true
pactl set-default-sink "$sink" || true
pactl set-default-source "$source" || true
pactl set-source-port "$source" analog-input-internal-mic || true
pactl set-sink-mute @DEFAULT_SINK@ 0 || true
pactl set-source-mute @DEFAULT_SOURCE@ 0 || true
pactl set-sink-volume @DEFAULT_SINK@ 60% || true
pactl set-source-volume @DEFAULT_SOURCE@ 100% || true
