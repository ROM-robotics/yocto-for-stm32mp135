#!/bin/sh
# Xprinter setup script for STM32MP13

echo "=== Xprinter Setup for STM32MP13 ==="
echo ""

# Check if CUPS is running
if ! systemctl is-active --quiet cups; then
    echo "Starting CUPS service..."
    systemctl start cups
    systemctl enable cups
fi

# Detect USB printer
USB_PRINTER=$(lsusb | grep -i "printer\|xprinter" | head -1)

if [ -z "$USB_PRINTER" ]; then
    echo "WARNING: No USB printer detected!"
    echo "Please connect your Xprinter and run this script again."
    exit 1
fi

echo "Detected: $USB_PRINTER"
echo ""

# Get USB device
USB_DEVICE=$(lpinfo -v | grep usb | head -1 | awk '{print $2}')

if [ -z "$USB_DEVICE" ]; then
    echo "ERROR: Could not find USB printer device"
    exit 1
fi

echo "USB Device: $USB_DEVICE"
echo ""

# Add printer to CUPS
PRINTER_NAME="Xprinter"
echo "Adding printer to CUPS as '$PRINTER_NAME'..."

lpadmin -p "$PRINTER_NAME" \
    -v "$USB_DEVICE" \
    -P /usr/share/cups/model/xprinter/xprinter-escpos.ppd \
    -E \
    -o printer-is-shared=false

# Set as default printer
lpadmin -d "$PRINTER_NAME"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Printer '$PRINTER_NAME' is now configured and set as default."
echo ""
echo "Test print command:"
echo "  echo 'Hello from STM32MP13!' | lp"
echo ""
echo "Print text file:"
echo "  lp /path/to/file.txt"
echo ""
echo "Check printer status:"
echo "  lpstat -t"
