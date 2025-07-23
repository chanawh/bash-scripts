#!/bin/bash

set -e

echo "=== Step 0: Remove old Docker versions ==="
sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine || true

echo "=== Step 1: Install required packages ==="
sudo dnf install -y curl wget conntrack dnf-plugins-core

echo "=== Step 2: Set up Docker CE repository ==="
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

echo "=== Step 3: Install Docker Engine ==="
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== Step 4: Start and enable Docker ==="
sudo systemctl start docker
sudo systemctl enable docker

echo "=== Step 5: Verify Docker status ==="
sudo systemctl status docker --no-pager

echo "=== Step 6: Download and install Minikube ==="
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm -f minikube-linux-amd64

echo "=== Step 7: Add current user to docker group (if not root) ==="
if [ "$EUID" -ne 0 ]; then
  sudo usermod -aG docker $USER
  echo "You may need to log out and back in for group changes to take effect."
fi
echo "=== Step 8: Start Minikube with Docker driver ==="
# Use --force if DRV_AS_ROOT warning appears
minikube start --driver=docker --force

echo "=== Step 9: Install kubectl ==="
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

echo "=== Step 10: Verify Kubernetes node status ==="
kubectl get nodes
