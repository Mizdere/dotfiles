#!/usr/bin/env bash
set -euo pipefail

awk '
  /MemTotal:/ { total=$2 }
  /MemAvailable:/ { available=$2 }
  END {
    used=(total-available)/1000000
    total_g=total/1000000
    printf "RAM %.1f/%.1fG\n", used, total_g
  }
' /proc/meminfo
