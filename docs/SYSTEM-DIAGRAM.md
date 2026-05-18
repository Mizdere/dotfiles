# System Diagram

```text
Hyprland session
│
├─ ~/.config/hypr/hyprland.conf
│  ├─ monitor/env/window rules/keybinds
│  ├─ blur rules for Orbit and Waybar dropdown layers
│  ├─ starts portal environment setup
│  ├─ starts Waybar
│  ├─ starts patched Orbit daemon
│  ├─ starts OSD watcher
│  ├─ starts audio defaults
│  ├─ starts theme helpers
│  └─ starts selected apps
│
├─ Waybar
│  ├─ ~/.config/waybar/config.jsonc
│  ├─ ~/.config/waybar/style.css
│  └─ ~/.config/waybar/scripts/
│     ├─ cpu_stat.sh / ram_stat.sh / gpu_stat.sh
│     ├─ battery_stat.sh
│     │  └─ click -> toggle_dropdown.sh power
│     ├─ net_stat.sh
│     │  ├─ left click -> orbit_toggle.sh top-right wifi
│     │  └─ right click -> orbit_toggle.sh top-right bluetooth
│     ├─ dropdown_popup.py
│     │  ├─ volume slider
│     │  ├─ audio output switcher using pactl/wpctl
│     │  └─ power profile controls
│     └─ bluetooth/wifi helper menus
│
├─ Orbit
│  ├─ ~/.local/bin/orbit
│  │  └─ rebuilt from upstream Orbit plus header patch
│  ├─ ~/.config/orbit/config.toml
│  ├─ ~/.config/orbit/theme.toml
│  ├─ ~/.config/orbit/style.css
│  └─ ~/.config/systemd/user/orbit.service
│
├─ Audio and Bluetooth
│  ├─ PipeWire / WirePlumber / pipewire-pulse
│  ├─ wpctl for volume control
│  ├─ pactl for sink discovery and stream moving
│  ├─ pavucontrol as advanced fallback UI
│  └─ auto-bluetooth-audio.service
│
├─ OSD
│  └─ ~/.local/bin/osd_control.py --watch
│     ├─ volume OSD
│     ├─ microphone OSD
│     └─ brightness OSD
│
└─ Theme/assets
   ├─ wallust/pywal helpers
   ├─ pywalfox update
   ├─ GTK/Qt configs
   ├─ rofi/fuzzel/dunst configs
   └─ ~/Pictures/anime + ~/Pictures/Backgrounds
```
