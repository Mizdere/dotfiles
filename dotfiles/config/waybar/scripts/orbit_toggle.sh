#!/usr/bin/env bash
set -euo pipefail

orbit="$HOME/.local/bin/orbit"
[[ -x "$orbit" ]] || orbit="$(command -v orbit || true)"
position="${1:-top-right}"
tab="${2:-wifi}"

if [[ -z "$orbit" ]]; then
  notify-send "Waybar Orbit" "orbit is not installed" 2>/dev/null || true
  exit 1
fi

if ! pgrep -u "${USER:-$(id -un)}" -f "$orbit daemon" >/dev/null; then
  "$orbit" daemon >/tmp/orbit-daemon.log 2>&1 &
fi

last_output=""
for _ in {1..20}; do
  if last_output=$("$orbit" toggle --tab "$tab" "$position" 2>&1); then
    exit 0
  fi

  if [[ "$last_output" != *"Daemon is not running"* ]]; then
    printf '%s\n' "$last_output" >&2
    exit 1
  fi

  sleep 0.1
done

printf '%s\n' "${last_output:-Orbit daemon did not become ready}" >&2
exit 1
