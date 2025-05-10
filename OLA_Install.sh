#!/bin/bash
echo "Start OLA install..."
set -e

# Set up working directory
echo "Creating working directory..."
mkdir dmx
cd ~/dmx

# create python venv
echo "🐍 Setting up Python .venv..."
python3 -m venv .venv

# Use virtualenv Python path
export PATH=~/dmx/.venv/bin:$PATH

# Update system
echo "🔄 Updating system..."
sudo apt-get update && sudo apt-get upgrade -y

# Core tools
echo "🛠️ Installing core tools..."
sudo apt-get install -y wget curl supervisor git-core build-essential ccache

# Required dependencies for OLA with Python, uartdmx, and web interface
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
git clone https://github.com/OpenLightingProject/ola.git ola || true
cd ola

# Install Python packages in your venv
echo "🐍 Installing Python dependencies..."
python -m pip install --upgrade pip
python -m pip install gcovr cpplint protobuf numpy

# Bootstrap build system
echo "🔨 Bootstrapping the build system..."
autoreconf -i

# Configure with desired options
echo "⚙️ Configuring OLA build..."
./configure \
  --enable-python-libs \
  --disable-all-plugins \
  --enable-uartdmx

# Optional: set PYTHONPATH if importing OLA modules directly
export PYTHONPATH=$PYTHONPATH:~/dmx/ola/python

# Build & install
echo "🏗️ Building OLA. This make take a long time..."
make -j "$(nproc)"
sudo make install
sudo ldconfig

# Show ccache stats
echo
echo "📊 ccache stats:"
ccache -s

CONFIG_FILE="/boot/firmware/config.txt"
CMDLINE_FILE="/boot/cmdline.txt"

echo "📝 Updating /boot/firmware/config.txt..."
# Remove any existing entries to avoid duplication
sudo sed -i '/^enable_uart=1/d' "$CONFIG_FILE"
sudo sed -i '/^init_uart_clock=16000000/d' "$CONFIG_FILE"
sudo sed -i '/^dtoverlay=pi3-disable-bt/d' "$CONFIG_FILE"
sudo sed -i '/^\[all\]/d' "$CONFIG_FILE"

# Append the new block to the end
echo -e "\n[all]" | sudo tee -a "$CONFIG_FILE" > /dev/null
echo "enable_uart=1" | sudo tee -a "$CONFIG_FILE" > /dev/null
echo "init_uart_clock=16000000" | sudo tee -a "$CONFIG_FILE" > /dev/null
echo "dtoverlay=pi3-disable-bt" | sudo tee -a "$CONFIG_FILE" > /dev/null

# Remove console=serial0,115200 from cmdline.txt (if present)
echo "📝 Updating /boot/cmdline.txt..."
sudo sed -i 's/[ ]*console=serial0,115200[ ]*//g' "$CMDLINE_FILE"

# Download ola.service from GitHub
echo "🔗 Downloading ola.service..."
curl -sSL https://raw.githubusercontent.com/geekyboi/OLA_DiscoPi/refs/heads/main/ola.service -o ola.service

# Copy ola service to startup
echo "🔌 Enabling OLA service on boot..."
sudo cp ola.service /lib/systemd/system/ola.service
sudo systemctl daemon-reload
sudo systemctl enable ola.service
sudo systemctl start ola.service
echo "Confirming OLA service is running..."
systemctl status ola.service


# Copy ola service to startup
echo "🎉 OLA compiled and installed."
echo "🎉 UART settings updated."
echo "🎉 OLA start on power on"
echo "🔌 Please reboot to apply changes."

