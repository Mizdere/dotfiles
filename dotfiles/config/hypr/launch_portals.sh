#!/usr/bin/env bash
set -u

# Make portal activation see the compositor environment before services start.
for _ in {1..50}; do
  if [[ -n "${WAYLAND_DISPLAY:-}" && -S "${XDG_RUNTIME_DIR:-}/$WAYLAND_DISPLAY" ]]; then
    break
  fi
  sleep 0.1
done

dbus-update-activation-environment --systemd \
  WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE \
  QT_QPA_PLATFORM QT_QPA_PLATFORMTHEME GTK_USE_PORTAL AQ_DRM_DEVICES >/dev/null 2>&1 || true

systemctl --user import-environment \
  WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE \
  QT_QPA_PLATFORM QT_QPA_PLATFORMTHEME GTK_USE_PORTAL AQ_DRM_DEVICES >/dev/null 2>&1 || true
