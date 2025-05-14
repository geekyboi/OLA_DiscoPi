#!/usr/bin/env bash
set -e

printf "\n\n🏁 Start OLA install..."
printf "This is going to take a while..............."

# Update system
printf "\n\n📬 Updating system..."
sudo apt-get update && sudo apt-get upgrade -y

# Set up working directory
printf "\n\n🗂️ Creating working directory..."
mkdir -p dmx
cd dmx

# create python venv
printf "\n\n🐍 Creating Python virtual enviroment..."
python3 -m venv .venv

# Set virtualenv as Python PATH
DMX_DIR="$(pwd)"
export PATH="$DMX_DIR/.venv/bin:$PATH"
export PYTHONPATH="$PYTHONPATH:$DMX_DIR/.venv/bin/"

# Install Core tools
printf "\n\n🔨 Installing core tools..."
sudo apt-get install -y wget curl supervisor git build-essential ccache make

# Install required dependencies for OLA
printf "\n\n📦 Installing required dependencies for OLA..."
sudo apt-get install -y libcppunit-dev libcppunit-1.15-0 uuid-dev pkg-config \
 libncurses5-dev libtool autoconf automake  g++ libmicrohttpd-dev  \
 libmicrohttpd12 protobuf-compiler libprotobuf-lite32 libprotobuf-dev \
 libprotoc-dev zlib1g-dev bison flex make libftdi-dev libftdi1 libusb-1.0-0-dev \
 liblo-dev libavahi-client-dev doxygen graphviz flake8

# Install Python packages in your venv
printf "\n\n🐍 Installing Python dependencies..."
Python_Venv="$DMX_DIR/.venv/bin/python"
"$DMX_DIR/.venv/bin/python" -m pip cache purge
"$DMX_DIR/.venv/bin/python" -m pip install --upgrade pip
"$DMX_DIR/.venv/bin/python" -m pip install --prefer-binary gcovr cpplint protobuf numpy

# Update shared library cache
printf "\n\n📚 Updating shared libraries..."
sudo ldconfig

# Use ccache for all C/C++ builds
export CC="ccache gcc"
export CXX="ccache g++"

# Download ola
printf "\n\n🔗 Cloning OLA repository..."
[ -d "ola" ] || git clone https://github.com/OpenLightingProject/ola.git ola
cd "$DMX_DIR/ola"

# Bootstrap build system
printf "\n\n🔨 Bootstrapping the build system..."
autoreconf -i

# Configure OLA installation
printf "\n\n⚙️ Configuring OLA build..."
./configure \
  --enable-python-libs \
  --disable-all-plugins \
  --enable-uartdmx

# Build & install OLA
printf "\n\n🏗️ Building OLA. This make take a long time..."
sudo make -j "$(nproc)"
sudo make install
sudo ldconfig

# Show ccache stats
printf "\n\n📊 ccache stats:"
ccache -s

# Configure UART for DMX output
CONFIG_FILE="/boot/firmware/config.txt"
CMDLINE_FILE="/boot/cmdline.txt"

# Update config.txt to enable UART at DMX baud rate
printf "\n\n🧹 Cleaning old UART entries in config.txt..."
sudo sed -i '/^enable_uart=/d' "$CONFIG_FILE"
sudo sed -i '/^init_uart_clock=/d' "$CONFIG_FILE"
sudo sed -i '/^dtoverlay=pi3-disable-bt/d' "$CONFIG_FILE"
echo "📝 Adding new entries config.txt..."
{
  echo ""
  echo "[all]"
  echo "enable_uart=1"
  echo "init_uart_clock=16000000"
  echo "dtoverlay=pi3-disable-bt"
} | sudo tee -a "$CONFIG_FILE" > /dev/null

# Remove console=serial0,115200 from cmdline.txt
printf "\n\n📝 Modifying /boot/cmdline.txt..."
sudo sed -i 's/[ ]*console=serial0,115200[ ]*//g' "$CMDLINE_FILE"
# Optional: Clean up double or leading/trailing spaces
sudo sed -i 's/  */ /g' "$CMDLINE_FILE"
sudo sed -i 's/^ *//;s/ *$//' "$CMDLINE_FILE"

# Download ola.service from GitHub
printf "\n\n📥 Downloading ola.service..."
curl -sSL https://raw.githubusercontent.com/geekyboi/OLA_DiscoPi/main/ola.service -o ola.service

# Copy OLA service to startup
printf "\n\n💡 Enabling OLA service on boot..."
sudo cp ola.service /lib/systemd/system/ola.service
sudo rm ola.service
sudo systemctl daemon-reload
sudo systemctl enable ola.service
sudo systemctl start ola.service
echo "Confirming OLA service is running..."
systemctl is-active --quiet ola.service && echo "✅ OLA is running." || echo "❌ OLA failed to start."

# Completed
printf "\n\n🥳 OLA Compiled and Installed."
echo "🎉 UART Settings Updated to enable DMX."
echo "🍾 OLA Service on Start Up Enabled.\n\n\n"
read -r -p "🪄 Reboot now to apply changes? [y/N] " choice 
[[ "$choice" =~ ^[Yy]$ ]] && sudo reboot
