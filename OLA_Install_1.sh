#!/usr/bin/env bash
set -e

# Run as your normal user: the script uses sudo itself where it needs root
if [ "$(id -u)" -eq 0 ]; then
  echo "❌ Please run this as your normal user, not with sudo or as root."
  exit 1
fi

printf "\n\n🏁 Start Step 1 OLA install....\n"
printf "This is going to take a while................\n"

# Update system
printf "\n\n📬 Updating system....\n"
sudo apt-get update && sudo apt-get upgrade -y

# Set up working directory
printf "\n\n🗂️ Creating working directory....\n"
mkdir -p "$HOME/dmx"
# Earlier versions built OLA with sudo, leaving root-owned files behind
sudo chown -R "$USER:$(id -gn)" "$HOME/dmx"
[ -d "$HOME/.ccache" ] && sudo chown -R "$USER:$(id -gn)" "$HOME/.ccache"
cd "$HOME/dmx"

# create python venv
printf "\n\n🐍 Creating Python virtual enviroment....\n"
python3 -m venv .venv

# Set virtualenv as Python PATH
DMX_DIR="$(pwd)"
export PATH="$DMX_DIR/.venv/bin:$PATH"
export PYTHONPATH="$PYTHONPATH:$DMX_DIR/.venv/bin/"

# Install Core tools
printf "\n\n🔨 Installing core tools....\n"
sudo apt-get install -y wget curl supervisor git build-essential ccache make

# Install required dependencies for OLA
printf "\n\n📦 Installing required dependencies for OLA....\n"
sudo apt-get install -y libcppunit-dev libcppunit-1.15-0 uuid-dev pkg-config \
 libncurses5-dev libtool autoconf automake  g++ libmicrohttpd-dev  \
 libmicrohttpd12 protobuf-compiler libprotobuf-lite32 libprotobuf-dev \
 libprotoc-dev zlib1g-dev bison flex make libftdi-dev libftdi1 libusb-1.0-0-dev \
 liblo-dev libavahi-client-dev doxygen graphviz flake8

# Install Python packages in your venv
printf "\n\n🐍 Installing Python dependencies....\n"
Python_Venv="$DMX_DIR/.venv/bin/python"
"$DMX_DIR/.venv/bin/python" -m pip cache purge
"$DMX_DIR/.venv/bin/python" -m pip install --upgrade pip
"$DMX_DIR/.venv/bin/python" -m pip install --prefer-binary gcovr cpplint protobuf numpy

# Update shared library cache
printf "\n\n📚 Updating shared libraries....\n"
sudo ldconfig

# Use ccache for all C/C++ builds
export CC="ccache gcc"
export CXX="ccache g++"

# Download ola
printf "\n\n🔗 Cloning OLA repository....\n"
[ -d "ola" ] || git clone https://github.com/OpenLightingProject/ola.git ola
cd "$DMX_DIR/ola"

# Bootstrap build system
printf "\n\n🔨 Bootstrapping the build system....\n"
autoreconf -i

# Configure OLA installation
printf "\n\n⚙️ Configuring OLA build....\n"
./configure \
  --enable-python-libs \
  --disable-all-plugins \
  --enable-uartdmx

# Build & install OLA
printf "\n\n🏗️ Building OLA.\n"
make -j "$(nproc)"
sudo make install
sudo ldconfig

# Let this user use the UART and GPIO pins without root
sudo usermod -aG dialout,gpio "$USER"

# Show ccache stats
printf "\n\n📊 ccache stats:.\n"
ccache -s

# Configure UART for DMX output
# Bookworm and later keep the boot files in /boot/firmware, older releases in /boot
if [ -f /boot/firmware/config.txt ]; then
  BOOT_DIR="/boot/firmware"
else
  BOOT_DIR="/boot"
fi
CONFIG_FILE="$BOOT_DIR/config.txt"
CMDLINE_FILE="$BOOT_DIR/cmdline.txt"

# Update config.txt to enable UART at DMX baud rate
printf "\n\n🧹 Cleaning old UART entries in %s....\n" "$CONFIG_FILE"
sudo sed -i '/^# >>> OLA_DiscoPi/,/^# <<< OLA_DiscoPi/d' "$CONFIG_FILE"
sudo sed -i '/^enable_uart=/d' "$CONFIG_FILE"
sudo sed -i '/^init_uart_clock=/d' "$CONFIG_FILE"
sudo sed -i '/^dtoverlay=pi3-disable-bt/d' "$CONFIG_FILE"
echo "📝 Adding new entries config.txt..."
{
  echo ""
  echo "# >>> OLA_DiscoPi UART DMX (managed by OLA_Install_1.sh)"
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
# Optional: Clean up double or leading/trailing spaces
sudo sed -i 's/  */ /g' "$CMDLINE_FILE"
sudo sed -i 's/^ *//;s/ *$//' "$CMDLINE_FILE"

olad -f

# Completed
printf "\n\n🥳 Step 1 complete - OLA Compiled and Installed.\n"
read -r -p "🪄 Reboot now to and follow step 2 [y/N] " choice 
[[ "$choice" =~ ^[Yy]$ ]] && sudo reboot
