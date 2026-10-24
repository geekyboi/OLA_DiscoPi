# OLA_DiscoPi
Ola installation for a UART disco.
This script installs OLA (Open Lighting Architecture) on a Raspberry Pi with Python enabled.
It's been created to allow UART control of DMX lights with a Python based controller.

It uses the OLA package from Raspberry Pi OS, so there's nothing to compile and it only takes a few minutes.

## Installation
Run this as your normal user (not with `sudo`) on a fresh Raspberry Pi OS card:
```bash
curl -sSL https://raw.githubusercontent.com/geekyboi/OLA_DiscoPi/main/install.sh | bash
```
Then reboot. To install a fixed version instead of the latest `main`, use a tag:
```bash
curl -sSL https://raw.githubusercontent.com/geekyboi/OLA_DiscoPi/v1.0/install.sh | OLA_DISCOPI_REF=v1.0 bash
```
You can also clone the repo and run `./install.sh`, which uses the config files in the clone.

## What it sets up
- `ola` and `ola-python` from apt, with every plugin except UART DMX turned off
- Universe 1 "Main" (LTP merge) patched to `/dev/ttyAMA0` on GPIO 14/15
- OLA config in `/etc/ola`, with olad running as the `olad` user from `ola.service`
- `ola.service` switches on wired (GPIO 17) and wireless (GPIO 27) DMX at boot
- The UART enabled in `config.txt` for the Pi 3, 4 and 5, and the serial console removed
- A Python venv in `~/dmx/.venv` that can import the `ola` module

## Notes:
- Supported on the Pi 3 and Pi 5
- The UART TTL module connects to pins 14/15 for the DMX output
- A reboot is required after running the script to apply changes.
- If the Pi had OLA built from source before, start from a fresh card. The old libraries in `/usr/local` can clash with the packaged ones.

## Running the show engine
```bash
cd disco
~/dmx/.venv/bin/python main.py
```

## OLA
- OLA can be accessed at port 9090
```bash
http://pi.local:9090
```

## License
MIT license
