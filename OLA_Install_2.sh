#!/usr/bin/env bash
set -e

printf "\n\n🏁 Start Step 2 OLA configuration....\n"

# Make sure the OLA config directory exists
mkdir -p /home/pi/.ola

# Configure OLA UART plugin
UART_Config="/home/pi/.ola/ola-uartdmx.conf"
if curl -sSL https://raw.githubusercontent.com/geekyboi/OLA_DiscoPi/main/ola-uartdmx.conf -o ola-uartdmx.conf; then
    sudo cp ola-uartdmx.conf "$UART_Config"
    rm ola-uartdmx.conf
else
    echo "❌ Download failed. Uart configuration not updated."
fi

# Configure OLA Universe Creation
UART_Config="/home/pi/.ola/ola-universe.conf"
if curl -sSL https://raw.githubusercontent.com/geekyboi/OLA_DiscoPi/main/ola-universe.conf -o ola-universe.conf; then
    sudo cp ola-universe.conf "$UART_Config"
    rm ola-universe.conf
else
    echo "❌ Download failed. Universe not created."
fi

# Configure OLA Universe Port
UART_Config="/home/pi/.ola/ola-port.conf"
if curl -sSL https://raw.githubusercontent.com/geekyboi/OLA_DiscoPi/main/ola-port.conf -o ola-port.conf; then
    sudo cp ola-port.conf "$UART_Config"
    rm ola-port.conf
else
    echo "❌ Download failed. Port not configured."
fi

# Download ola.service from GitHub
printf "\n\n📥 Downloading ola.service....\n"
if curl -sSL https://raw.githubusercontent.com/geekyboi/OLA_DiscoPi/main/ola.service -o ola.service; then
    # Copy OLA service to startup
    printf "\n\n💡 Enabling OLA service on boot....\n"
    sudo cp ola.service /lib/systemd/system/ola.service
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
