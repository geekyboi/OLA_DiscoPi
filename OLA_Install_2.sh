#!/usr/bin/env bash
set -e

# Run as your normal user: the script uses sudo itself where it needs root
if [ "$(id -u)" -eq 0 ]; then
  echo "❌ Please run this as your normal user, not with sudo or as root."
  exit 1
fi

OLA_USER="$USER"
OLA_GROUP="$(id -gn)"
OLA_DIR="$HOME/.ola"

printf "\n\n🏁 Start Step 2 OLA configuration....\n"

# Make sure the OLA config directory exists
mkdir -p "$OLA_DIR"
# Earlier versions of this script left root-owned files here
sudo chown -R "$OLA_USER:$OLA_GROUP" "$OLA_DIR"

# Configure OLA UART plugin
UART_Config="$OLA_DIR/ola-uartdmx.conf"
if curl -sSL https://raw.githubusercontent.com/geekyboi/OLA_DiscoPi/main/ola-uartdmx.conf -o ola-uartdmx.conf; then
    mv ola-uartdmx.conf "$UART_Config"
else
    echo "❌ Download failed. Uart configuration not updated."
fi

# Configure OLA Universe Creation
UART_Config="$OLA_DIR/ola-universe.conf"
if curl -sSL https://raw.githubusercontent.com/geekyboi/OLA_DiscoPi/main/ola-universe.conf -o ola-universe.conf; then
    mv ola-universe.conf "$UART_Config"
else
    echo "❌ Download failed. Universe not created."
fi

# Configure OLA Universe Port
UART_Config="$OLA_DIR/ola-port.conf"
if curl -sSL https://raw.githubusercontent.com/geekyboi/OLA_DiscoPi/main/ola-port.conf -o ola-port.conf; then
    mv ola-port.conf "$UART_Config"
else
    echo "❌ Download failed. Port not configured."
fi

# Download ola.service from GitHub
printf "\n\n📥 Downloading ola.service....\n"
if curl -sSL https://raw.githubusercontent.com/geekyboi/OLA_DiscoPi/main/ola.service -o ola.service; then
    # Copy OLA service to startup
    printf "\n\n💡 Enabling OLA service on boot....\n"
    # Run olad as this user rather than a hard-coded "pi"
    sed -i -e "s|^User=.*|User=$OLA_USER|" \
           -e "s|^Group=.*|Group=$OLA_GROUP|" \
           -e "s|^WorkingDirectory=.*|WorkingDirectory=$HOME|" ola.service
    sudo install -m 644 ola.service /etc/systemd/system/ola.service
    rm ola.service
    sudo systemctl daemon-reload
    sudo systemctl enable ola.service
    sudo systemctl start ola.service
    echo "Confirming OLA service is running..."
    systemctl is-active --quiet ola.service && echo "✅ OLA is running." || echo "❌ OLA failed to start."
else
    echo "❌ Download failed. Service not enabled."
fi

# Completed
printf "\n\n🥳 Step 2 complete OLA configured.\n"
read -r -p "🪄 Reboot now to apply changes? [y/N] " choice 
[[ "$choice" =~ ^[Yy]$ ]] && sudo reboot
