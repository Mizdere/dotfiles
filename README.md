# arch-dotfilescurrent

Private Arch/Hyprland system configuration for reproducing this laptop setup as closely as possible on a fresh install.

This repository is intended for personal restoration, not as a generic public rice. It captures the active Hyprland, Waybar, Orbit, OSD, audio, theme, package, and wallpaper setup while excluding browser secrets and volatile application state.

## Restore

Clone and run:

```bash
git clone https://github.com/YOUR_GITHUB_USER/arch-dotfilescurrent.git
cd arch-dotfilescurrent
./bootstrap.sh
```

If GitHub CLI is used later, replace `YOUR_GITHUB_USER` with the real account or use the SSH remote.

## What This Restores

- Hyprland config, keybinds, layer rules, autostart, and portal startup
- Waybar config, styling, stats modules, dropdowns, and scripts
- Audio dropdown with volume slider and output switching
- Battery/power profile dropdown
- Orbit WiFi/Bluetooth/VPN dropdown config and styling
- Patched Orbit source workflow and local binary install
- User services for Orbit and Bluetooth audio handling
- Local scripts under `~/.local/bin`
- GTK/Qt/rofi/fuzzel/dunst/wallust/fastfetch/mpv/zathura supporting configs
- Wallpapers/images under `~/Pictures/anime` and `~/Pictures/Backgrounds`
- Pacman/AUR package manifests
- AppImage manifest

## What Is Intentionally Excluded

- Firefox/browser profiles, history, login databases, and cookies
- SSH/private keys and tokens
- OBS state/logs/scenes
- cache directories and generated Python bytecode
- Pulse cookie and other local auth material
- compiled Orbit binary; it is rebuilt from source with a patch
- large AppImage binaries; they are tracked in `appimages/appimages.txt`

## AppImages

Current AppImage manifest:

```bash
./appimages/install-appimages.sh
```

`alcom.AppImage` was present locally at `~/.local/bin/alcom.AppImage`. No stable direct download URL is recorded yet, so the installer prints it as a manual item.

## Docs

- `docs/SYSTEM-DIAGRAM.md`: how the setup connects
- `docs/RESTORE.md`: detailed restore flow and caveats
- `docs/PACKAGES.md`: package restoration notes
- `docs/APPIMAGES.md`: AppImage notes
- `docs/CREDITS.md`: upstream credits
