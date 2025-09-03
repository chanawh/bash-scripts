#!/bin/bash

# Simple Docker install script for Ubuntu

set -e

echo "Updating package index..."
sudo apt-get update

echo "Installing packages to allow apt to use a repository over HTTPS..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg

echo "Adding Docker’s official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "Adding Docker repository to APT sources..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Updating package index again..."
sudo apt-get update

echo "Installing Docker Engine, CLI, containerd, Buildx, and Compose plugin..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Docker installation complete!"
echo "Verifying Docker version:"
sudo docker --version

echo ""
echo "To use Docker as a non-root user, run:"
echo "  sudo usermod -aG docker \$USER"
echo "Then log out and back in for this to take effect."
