#!/usr/bin/env bash
set -euo pipefail

systemctl --user daemon-reload
systemctl --user enable --now orbit.service
systemctl --user enable --now auto-bluetooth-audio.service || true
