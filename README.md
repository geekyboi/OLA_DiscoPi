# OLA_DiscoPi
Ola installation for a UART disco.
This script automates the installation of OLA (Open Lighting Architecture) on Raspberry Pi with python enabled.
It's been created to allow uart control of dmx lights with a python based controller

## Installation
```bash
curl -sSL https://raw.githubusercontent.com/geekyboi/OLA_DiscoPi/main/OLA_Install.sh | bash
```

## Notes:
- The script has been tested successfully on a Pi3
- The UART TTL module connected to pins 14/15 for the DMX output
- A reboot is required after running the script to apply changes.


```bash
dmx/.venv/bin/python3 dmx/test.py
```

## OLA
- OLA can be accessed at port 9090
```bash
http://pi.local:9090
```

## License
MIT license
