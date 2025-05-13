#!/usr/bin/env bash
echo "🏁 Start OLA install..."
set -e

# Update system
echo "📬 Updating system..."
sudo apt-get update && sudo apt-get upgrade -y

# Set up working directory
echo "🗂️ Creating working directory..."
mkdir -p dmx
cd dmx

# create python venv
echo "🐍 Creating Python virtual enviroment..."
python3 -m venv .venv

# Set virtualenv as Python PATH
DMX_DIR="$(pwd)"
export PATH="$DMX_DIR/.venv/bin:$PATH"
export PYTHONPATH="$PYTHONPATH:$DMX_DIR/.venv/bin"

# Install Core tools
echo "🔨 Installing core tools..."
sudo apt-get install -y wget curl supervisor git-core build-essential ccache

# Install required dependencies for OLA
echo "📦 Installing required dependencies for OLA..."
sudo apt-get install -y \
  uuid-dev pkg-config libncurses5-dev libtool autoconf automake g++ \
  libmicrohttpd-dev libmicrohttpd12 \
  protobuf-compiler libprotobuf-dev \
  zlib1g-dev bison flex make \
  libftdi-dev libftdi1 libusb-1.0-0-dev \
  python3-dev flake8

# Update shared library cache
echo "📚 Updating shared libraries..."
sudo ldconfig

# Use ccache for all C/C++ builds
export CC="ccache gcc"
export CXX="ccache g++"

# Download ola
echo "🔗 Cloning OLA repository..."
[ -d "ola" ] || git clone https://github.com/OpenLightingProject/ola.git ola
cd ola

# Install Python packages in your venv
echo "🐍 Installing Python dependencies..."
python3 -m pip install --upgrade pip
python3 -m pip install gcovr cpplint protobuf numpy

# Bootstrap build system
echo "🔨 Bootstrapping the build system..."
autoreconf -i

# Configure OLA installation
echo "⚙️ Configuring OLA build..."
./configure \
  --enable-python-libs \
  --disable-all-plugins \
  --enable-uartdmx

# Build & install OLA
echo "🏗️ Building OLA. This make take a long time..."
sudo make -j "$(nproc)"
sudo make install
sudo ldconfig

# Show ccache stats
echo "📊 ccache stats:"
ccache -s

# Configure UART for DMX output
CONFIG_FILE="/boot/firmware/config.txt"
CMDLINE_FILE="/boot/cmdline.txt"

# Update config.txt to enable UART at DMX baud rate
echo "🧹 Cleaning old UART entries in config.txt..."
sudo sed -i '/^enable_uart=/d' "$CONFIG_FILE"
sudo sed -i '/^init_uart_clock=/d' "$CONFIG_FILE"
sudo sed -i '/^dtoverlay=pi3-disable-bt/d' "$CONFIG_FILE"
echo "📝 Add new entries config.txt..."
{
  echo ""
  echo "[all]"
  echo "enable_uart=1"
  echo "init_uart_clock=16000000"
  echo "dtoverlay=pi3-disable-bt"
} | sudo tee -a "$CONFIG_FILE" > /dev/null

# Remove console=serial0,115200 from cmdline.txt
echo "📝 Modifying /boot/cmdline.txt..."
sudo sed -i 's/[ ]*console=serial0,115200[ ]*//g' "$CMDLINE_FILE"
# Optional: Clean up double or leading/trailing spaces
sudo sed -i 's/  */ /g' "$CMDLINE_FILE"
sudo sed -i 's/^ *//;s/ *$//' "$CMDLINE_FILE"

# Download ola.service from GitHub
echo "📥 Downloading ola.service..."
curl -sSL https://raw.githubusercontent.com/geekyboi/OLA_DiscoPi/refs/heads/main/ola.service -o ola.service

# Copy OLA service to startup
echo "💡 Enabling OLA service on boot..."
sudo cp ola.service /lib/systemd/system/ola.service
sudo rm ola.service
sudo systemctl daemon-reload
sudo systemctl enable ola.service
sudo systemctl start ola.service
echo "Confirming OLA service is running..."
systemctl is-active --quiet ola.service && echo "✅ OLA is running." || echo "❌ OLA failed to start."

# Completed
echo "🥳 OLA Compiled and Installed."
echo "🎉 UART Settings Updated to enable DMX."
echo "🍾 OLA Service on Start Up Enabled."
read -p "🪄 Reboot now to apply changes? [y/N] " choice 
[[ "$choice" =~ ^[Yy]$ ]] && sudo reboot
