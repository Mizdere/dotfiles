# AppImages

Current local AppImage discovered:

```text
~/.local/bin/alcom.AppImage
```

It is approximately 88 MB. It is intentionally not committed to Git by default because large binaries make dotfile repositories heavy and awkward to diff.

The manifest is tracked in:

```text
appimages/appimages.txt
```

Install recorded AppImages:

```bash
./appimages/install-appimages.sh
```

If a stable direct URL is later found, add it to `appimages/appimages.txt` in this format:

```text
name|~/.local/bin/name.AppImage|https://example.com/download/name.AppImage
```
