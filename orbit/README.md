# Patched Orbit

This setup uses [Orbit](https://github.com/LifeOfATitan/orbit) as the WiFi/Bluetooth/VPN dropdown opened from Waybar.

Local changes are intentionally stored as a source patch instead of committing the compiled binary:

- remove the Orbit logo/title from the header
- move `WiFi / Bluetooth / VPN` tabs above the WiFi/Bluetooth toggle row
- right-align the WiFi/Bluetooth toggle row

Build and install the patched binary:

```bash
./orbit/build-patched-orbit.sh
```

The binary is installed to:

```text
~/.local/bin/orbit
```

The user service uses that local binary.
