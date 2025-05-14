#!/bin/bash

sleep 0.3

if pgrep -x thunar >/dev/null; then
    pkill thunar
    # Launch Thunar connected to current Hyprland session
    XDG_CURRENT_DESKTOP=Hyprland \
    XDG_SESSION_TYPE=wayland \
    GTK_THEME=oomox-wal \
    nohup thunar >/dev/null 2>&1 &
fi
