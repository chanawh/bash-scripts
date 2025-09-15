#!/bin/bash
set -e

echo "=== Kompose Installer ==="

# -------------------------------
# Helper function
# -------------------------------
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# -------------------------------
# Install Kompose
# -------------------------------
echo
echo "Checking for existing Kompose..."
if command_exists kompose; then
    echo "Kompose is already installed at $(command -v kompose)"
    kompose version
else
    echo "Installing Kompose (official binary)..."
    # Get latest release version
    KOMPOSE_VERSION=$(curl -s https://api.github.com/repos/kubernetes/kompose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    
    # Download the binary
    curl -LO "https://github.com/kubernetes/kompose/releases/download/${KOMPOSE_VERSION}/kompose-linux-amd64"
    
    # Install
    sudo install -m 0755 kompose-linux-amd64 /usr/local/bin/kompose
    rm kompose-linux-amd64
    
    echo "Kompose installed successfully!"
    kompose version
fi

