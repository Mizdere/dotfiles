# Restore Notes

This repo is designed for a fresh Arch install or a similar Arch laptop. It is not a byte-for-byte clone.

## Basic Restore

```bash
git clone https://github.com/Mizdere/dotfiles.git
cd dotfiles
./bootstrap.sh
```

The bootstrap does the following:

- validates pacman exists
- installs official packages from `packages/pacman.txt`
- bootstraps `paru` if missing
- installs AUR packages from `packages/aur.txt`
- backs up current target config paths to `~/.dotfiles-backup-<timestamp>`
- copies dotfiles, local scripts, and picture assets
- builds patched Orbit from source
- enables user services

## Hardware-Specific Checks

After restore, review:

- monitor name/resolution in `~/.config/hypr/hyprland.conf`
- GPU-related env values like `AQ_DRM_DEVICES`
- backlight device in `~/.local/bin/osd_control.py`
- ASUS-specific commands in `keyboard_brightness.sh`
- audio device behavior and Bluetooth availability

## Safer First Test

Before running on a primary machine, inspect the files and run individual scripts:

```bash
./install/00-preflight.sh
./install/10-packages.sh
./install/20-dotfiles.sh
./orbit/build-patched-orbit.sh
./install/30-services.sh
```

## Rollback

`install/20-dotfiles.sh` moves existing target paths into:

```text
~/.dotfiles-backup-<timestamp>
```

Copy files back from that directory if needed.
