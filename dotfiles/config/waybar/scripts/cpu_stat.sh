#!/usr/bin/env bash
set -euo pipefail

state="${XDG_RUNTIME_DIR:-/tmp}/waybar-cpu-stat.prev"
read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
idle_all=$((idle + iowait))
non_idle=$((user + nice + system + irq + softirq + steal))
total=$((idle_all + non_idle))

usage=0
if [[ -f "$state" ]]; then
  read -r prev_total prev_idle < "$state" || true
  total_delta=$((total - ${prev_total:-total}))
  idle_delta=$((idle_all - ${prev_idle:-idle_all}))
  if (( total_delta > 0 )); then
    usage=$(((100 * (total_delta - idle_delta) + total_delta / 2) / total_delta))
  fi
fi
printf '%s %s\n' "$total" "$idle_all" > "$state"

temp="?"
if command -v sensors >/dev/null 2>&1; then
  temp="$(sensors 2>/dev/null | awk '/Package id 0:/ {gsub(/[+°C]/,"",$4); printf "%.0f", $4; exit}')"
fi

if [[ -n "$temp" && "$temp" != "?" ]]; then
  printf 'CPU %s%% %s°C\n' "$usage" "$temp"
else
  printf 'CPU %s%%\n' "$usage"
fi
