#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$repo_root/appimages/appimages.txt"

while IFS='|' read -r name target url; do
  [[ -n "${name:-}" ]] || continue
  [[ "$name" != \#* ]] || continue

  target="${target/#\~/$HOME}"
  mkdir -p "$(dirname "$target")"

  if [[ -z "${url:-}" ]]; then
    printf 'manual: %s -> %s (no stable URL recorded)\n' "$name" "$target"
    continue
  fi

  printf 'installing: %s -> %s\n' "$name" "$target"
  curl -fL "$url" -o "$target"
  chmod +x "$target"
done < "$manifest"
