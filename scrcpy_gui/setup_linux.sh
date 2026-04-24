#!/bin/bash

# setup_linux.sh - Install dependencies for FrameLink on Linux

echo "🚀 FrameLink Linux Dependency Installer"
echo "----------------------------------------"

# Detect Package Manager
if [ -f /etc/arch-release ]; then
    echo "Detected Arch Linux based system."
    INSTALL_CMD="sudo pacman -S scrcpy android-tools --noconfirm"
elif [ -f /etc/lsb-release ] || [ -f /etc/debian_version ]; then
    echo "Detected Ubuntu/Debian based system."
    INSTALL_CMD="sudo apt update && sudo apt install -y scrcpy adb"
elif [ -f /etc/fedora-release ]; then
    echo "Detected Fedora based system."
    INSTALL_CMD="sudo dnf install -y scrcpy android-tools"
else
    echo "❌ Unknown Linux distribution. Please install 'scrcpy' and 'adb' manually."
    exit 1
fi

echo "Running: $INSTALL_CMD"
eval $INSTALL_CMD

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully!"
    
    # Make the app binary executable if it exists in the current folder
    if [ -f "./frame_link" ]; then
        chmod +x ./frame_link
        echo "✅ App binary 'frame_link' is now executable."
    fi
    
    echo "----------------------------------------"
    echo "🎉 Setup complete! You can now run the app using: ./frame_link"
else
    echo "❌ Installation failed. Please check the errors above."
    exit 1
fi
