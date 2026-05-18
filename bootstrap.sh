#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$repo_root/install/00-preflight.sh"
"$repo_root/install/10-packages.sh"
"$repo_root/install/20-dotfiles.sh"
"$repo_root/install/40-orbit.sh"
"$repo_root/install/30-services.sh"
"$repo_root/install/50-postinstall.sh"
