# Packages

Generated from the current machine:

```bash
pacman -Qqen > packages/pacman.txt
pacman -Qqem > packages/aur.txt
flatpak list --app --columns=application > packages/flatpak.txt
```

Current AUR highlights include:

- `orbit-wifi`
- `paru`
- `hyprshade`
- `quickshell-git`
- `wallust`
- `tamzen-font`

The patched Orbit binary is not committed. The restore process installs Orbit dependencies/packages and then rebuilds Orbit locally from source with `orbit/patch-header-layout.diff`.
