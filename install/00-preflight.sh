#!/usr/bin/env bash
set -euo pipefail

if ! command -v pacman >/dev/null 2>&1; then
  printf 'This bootstrap targets Arch Linux/pacman systems.\n' >&2
  exit 1
fi

printf 'Preflight OK: Arch/pacman detected.\n'
