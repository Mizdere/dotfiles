#!/usr/bin/env bash
set -euo pipefail

if ! command -v nvidia-smi >/dev/null 2>&1; then
  printf 'GPU --%% --/--G --°C\n'
  exit 0
fi

IFS=, read -r util used total temp < <(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>/dev/null)
util="${util// /}"
used="${used// /}"
total="${total// /}"
temp="${temp// /}"

awk -v util="${util:-0}" -v used="${used:-0}" -v total="${total:-0}" -v temp="${temp:-?}" '
  BEGIN {
    printf "GPU %s%% %.1f/%.1fG %s°C\n", util, used / 1024, total / 1024, temp
  }
'
