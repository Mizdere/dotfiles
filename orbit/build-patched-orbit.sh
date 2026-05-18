#!/usr/bin/env bash
set -euo pipefail

version="2.4.13"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workdir="${XDG_CACHE_HOME:-$HOME/.cache}/arch-dotfilescurrent/orbit-build"

rm -rf "$workdir"
mkdir -p "$workdir"

curl -fL "https://github.com/LifeOfATitan/orbit/archive/refs/tags/v${version}.tar.gz" -o "$workdir/orbit.tar.gz"
tar -xzf "$workdir/orbit.tar.gz" -C "$workdir"

src="$workdir/orbit-${version}"
if [[ ! -d "$src" ]]; then
  printf 'Orbit source directory not found after extraction\n' >&2
  exit 1
fi

patch -d "$src" -p1 < "$repo_root/orbit/patch-header-layout.diff"
cargo build --release --manifest-path "$src/Cargo.toml"
install -Dm755 "$src/target/release/orbit" "$HOME/.local/bin/orbit"

printf 'Installed patched Orbit to %s\n' "$HOME/.local/bin/orbit"
