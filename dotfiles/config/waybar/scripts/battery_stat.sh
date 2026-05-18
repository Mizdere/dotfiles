#!/usr/bin/env bash
set -euo pipefail

bat="/sys/class/power_supply/BAT1"
capacity="?"
watts="0.0"

gpu_watts() {
  command -v nvidia-smi >/dev/null 2>&1 || return 1
  nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits 2>/dev/null \
    | awk 'NR==1 && $1 ~ /^[0-9.]+$/ { printf "%.1f", $1 }'
}

cpu_watts() {
  local rapl="/sys/class/powercap/intel-rapl:0"
  local energy="$rapl/energy_uj"
  local max_energy="$rapl/max_energy_range_uj"
  local state="${XDG_RUNTIME_DIR:-/tmp}/waybar-cpu-rapl.prev"

  [[ -r "$energy" ]] || return 1

  local now current max prev_time prev_energy elapsed delta
  now="$(date +%s%N)"
  current="$(<"$energy")"
  max="0"
  [[ -r "$max_energy" ]] && max="$(<"$max_energy")"

  if [[ -f "$state" ]]; then
    read -r prev_time prev_energy < "$state" || true
    elapsed="$(awk -v n="$now" -v p="${prev_time:-$now}" 'BEGIN { printf "%.9f", (n - p) / 1000000000 }')"
    delta=$((current - ${prev_energy:-current}))
    if (( delta < 0 && max > 0 )); then
      delta=$((current + max - ${prev_energy:-current}))
    fi
    printf '%s %s\n' "$now" "$current" > "$state"
    awk -v d="$delta" -v e="$elapsed" 'BEGIN { if (e > 0 && d >= 0) printf "%.1f", d / e / 1000000; else printf "0.0" }'
    return 0
  fi

  printf '%s %s\n' "$now" "$current" > "$state"
  printf '0.0'
}

if [[ -r "$bat/capacity" ]]; then
  capacity="$(<"$bat/capacity")"
fi

if [[ -r "$bat/power_now" ]]; then
  power_now="$(<"$bat/power_now")"
  watts="$(awk -v p="$power_now" 'BEGIN { printf "%.1f", p / 1000000 }')"
elif [[ -r "$bat/current_now" && -r "$bat/voltage_now" ]]; then
  current_now="$(<"$bat/current_now")"
  voltage_now="$(<"$bat/voltage_now")"
  watts="$(awk -v c="$current_now" -v v="$voltage_now" 'BEGIN { printf "%.1f", (c * v) / 1000000000000 }')"
fi

if awk -v w="$watts" 'BEGIN { exit !(w <= 0.05) }'; then
  upower_rate="$(upower -i /org/freedesktop/UPower/devices/battery_BAT1 2>/dev/null | awk '/energy-rate:/ { print $2; exit }')"
  if [[ -n "${upower_rate:-}" ]]; then
    watts="$(awk -v w="$upower_rate" 'BEGIN { printf "%.1f", w }')"
  fi
fi

# Fully charged laptops often report battery current as 0 on AC. In that case,
# show live component draw: GPU + CPU package when RAPL is readable.
if awk -v w="$watts" 'BEGIN { exit !(w <= 0.05) }'; then
  gpu="$(gpu_watts || true)"
  cpu="$(cpu_watts || true)"
  watts="$(awk -v g="${gpu:-0}" -v c="${cpu:-0}" 'BEGIN { printf "%.1f", g + c }')"
fi

printf 'BAT %s%% %sW\n' "$capacity" "$watts"
