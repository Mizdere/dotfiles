# Packages

- `pacman.txt`: explicitly installed official Arch packages.
- `aur.txt`: explicitly installed foreign/AUR packages.
- `flatpak.txt`: Flatpak application IDs. Currently empty on this system.

Restore official packages:

```bash
sudo pacman -S --needed - < packages/pacman.txt
```

Restore AUR packages after `paru` exists:

```bash
paru -S --needed - < packages/aur.txt
```
