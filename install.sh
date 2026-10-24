#!/usr/bin/env bash
# One-step OLA install for a UART DMX Disco Pi (Pi 3 or Pi 5).
# Uses the OLA package from Raspberry Pi OS instead of building from source.
set -e

# Run as your normal user: the script uses sudo itself where it needs root
if [ "$(id -u)" -eq 0 ]; then
  echo "❌ Please run this as your normal user, not with sudo or as root."
  exit 1
fi

# Which version of this repo to fetch config from when run via curl | bash.
# Set OLA_DISCOPI_REF to a tag (e.g. v1.0) to install a fixed version.
REF="${OLA_DISCOPI_REF:-main}"
RAW_URL="https://raw.githubusercontent.com/geekyboi/OLA_DiscoPi/$REF"
OLA_CONF_DIR="/etc/ola"
DMX_DIR="$HOME/dmx"

printf "\n\n🏁 Start OLA install....\n"

# Use the repo files next to this script if there are any, otherwise download them
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
if [ -f "$SCRIPT_PATH" ] && [ -f "$(dirname "$SCRIPT_PATH")/ola.service" ]; then
  SRC_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
else
  SRC_DIR="$(mktemp -d)"
  trap 'rm -rf "$SRC_DIR"' EXIT
  printf "\n\n📥 Downloading config files (%s)....\n" "$REF"
  for f in ola.service ola-uartdmx.conf ola-universe.conf ola-port.conf; do
    curl -fsSL "$RAW_URL/$f" -o "$SRC_DIR/$f"
  done
fi

# A previous build from source leaves libraries in /usr/local that override the packaged ones
if [ -e /usr/local/bin/olad ]; then
  echo "⚠️  Found an OLA built from source in /usr/local. Its libraries can clash"
  echo "    with the packaged OLA, so a fresh SD card is the safest starting point."
fi

# Install OLA and its Python bindings from apt
printf "\n\n📦 Installing OLA....\n"
sudo apt-get update
sudo apt-get install -y ola ola-python python3-venv

# We run olad from our own ola.service, so stop the package's init script
sudo systemctl disable --now olad 2>/dev/null || true
sudo systemctl mask olad

# Configure OLA: UART plugin, universe 1 "Main" patched to /dev/ttyAMA0
printf "\n\n⚙️ Configuring OLA....\n"
for f in ola-uartdmx.conf ola-universe.conf ola-port.conf; do
  sudo install -o olad -g olad -m 664 "$SRC_DIR/$f" "$OLA_CONF_DIR/$f"
done

# Turn off every other plugin so nothing else grabs the serial port or USB devices
for plugin in artnet dummy e131 espnet ftdidmx gpio karate kinet milinst opendmx \
              openpixelcontrol osc pathport renard sandnet shownet spi stageprofi \
              usbdmx usbserial; do
  conf="$OLA_CONF_DIR/ola-$plugin.conf"
  if sudo test -f "$conf"; then
    sudo sed -i 's/^enabled = .*/enabled = false/' "$conf"
  else
    echo "enabled = false" | sudo tee "$conf" > /dev/null
  fi
done
sudo chown -R olad:olad "$OLA_CONF_DIR"

# Configure UART for DMX output
# Bookworm and later keep the boot files in /boot/firmware, older releases in /boot
if [ -f /boot/firmware/config.txt ]; then
  BOOT_DIR="/boot/firmware"
else
  BOOT_DIR="/boot"
fi
CONFIG_FILE="$BOOT_DIR/config.txt"
CMDLINE_FILE="$BOOT_DIR/cmdline.txt"

printf "\n\n🧹 Cleaning old UART entries in %s....\n" "$CONFIG_FILE"
sudo sed -i '/^# >>> OLA_DiscoPi/,/^# <<< OLA_DiscoPi/d' "$CONFIG_FILE"
sudo sed -i '/^enable_uart=/d' "$CONFIG_FILE"
sudo sed -i '/^init_uart_clock=/d' "$CONFIG_FILE"
sudo sed -i '/^dtoverlay=pi3-disable-bt/d' "$CONFIG_FILE"
echo "📝 Adding new entries config.txt..."
{
  echo ""
  echo "# >>> OLA_DiscoPi UART DMX (managed by install.sh)"
  echo "[all]"
  echo "enable_uart=1"
  echo "# Pi 3/4: give the full PL011 UART (ttyAMA0) to GPIO 14/15 by disabling Bluetooth"
  echo "[pi3]"
  echo "dtoverlay=disable-bt"
  echo "init_uart_clock=16000000"
  echo "[pi4]"
  echo "dtoverlay=disable-bt"
  echo "# Pi 5: Bluetooth has its own UART, so just enable UART0 (ttyAMA0) on GPIO 14/15"
  echo "[pi5]"
  echo "dtparam=uart0=on"
  echo "[all]"
  echo "# <<< OLA_DiscoPi"
} | sudo tee -a "$CONFIG_FILE" > /dev/null

# Bluetooth no longer has a UART on the Pi 3/4, so stop it trying to use one
sudo systemctl disable hciuart 2>/dev/null || true

# Remove the serial console so it doesn't write over the DMX output
printf "\n\n📝 Modifying %s....\n" "$CMDLINE_FILE"
sudo sed -i -E 's/[ ]*console=(serial0|ttyAMA0|ttyS0),[0-9]+[ ]*/ /g' "$CMDLINE_FILE"
sudo sed -i 's/  */ /g' "$CMDLINE_FILE"
sudo sed -i 's/^ *//;s/ *$//' "$CMDLINE_FILE"

# Python venv for the show engine. It can see the system ola-python package.
printf "\n\n🐍 Creating Python virtual environment in %s....\n" "$DMX_DIR/.venv"
mkdir -p "$DMX_DIR"
python3 -m venv --system-site-packages "$DMX_DIR/.venv"

# Enable OLA on boot
printf "\n\n💡 Enabling OLA service on boot....\n"
sudo install -m 644 "$SRC_DIR/ola.service" /etc/systemd/system/ola.service
sudo systemctl daemon-reload
sudo systemctl enable ola.service

# Completed
printf "\n\n🥳 OLA installed. Reboot to switch on the UART, then open http://%s.local:9090\n" "$(hostname)"
# Read the answer from the terminal, since stdin is the script itself under curl | bash
choice=""
if (exec < /dev/tty) 2>/dev/null; then
  read -r -p "🪄 Reboot now? [y/N] " choice < /dev/tty
fi
if [[ "$choice" =~ ^[Yy]$ ]]; then
  sudo reboot
fi
