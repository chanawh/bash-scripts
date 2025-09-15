#!/bin/bash
set -e
set -x  # Enable debugging: print each command before executing

echo "=== Kubernetes/Minikube Installer ==="

# -------------------------------
# Helper function
# -------------------------------
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# -------------------------------
# Install kubectl
# -------------------------------
echo
echo "Checking for existing kubectl..."
if command_exists kubectl; then
    echo "kubectl is already installed at $(command -v kubectl)"
    kubectl version --client
else
    echo "Installing kubectl (official binary)..."
    KUBECTL_VERSION=$(curl --fail --connect-timeout 10 --max-time 30 -Ls https://dl.k8s.io/release/stable.txt)
    if [ -z "$KUBECTL_VERSION" ]; then
        echo "Failed to fetch latest kubectl version."
        exit 1
    fi
    curl --fail --connect-timeout 10 --max-time 60 -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    sudo install -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    kubectl version --client
fi

# -------------------------------
# Install Minikube
# -------------------------------
echo
echo "Checking for existing Minikube..."
if command_exists minikube; then
    echo "minikube is already installed at $(command -v minikube)"
    minikube version
else
    echo "Installing Minikube (official binary)..."
    curl --fail --connect-timeout 10 --max-time 60 -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    minikube version
fi

# -------------------------------
# Install conntrack
# -------------------------------
echo
echo "Installing conntrack (required by Kubernetes)..."
sudo apt-get update
sudo apt-get install -y conntrack
conntrack --version || echo "conntrack installed"

# -------------------------------
# Install containernetworking-plugins (CNI plugins)
# -------------------------------
echo
echo "Checking for CNI plugins..."
CNI_DIR="/opt/cni/bin"
CNI_VERSION="v1.4.1"
ARCH="amd64"
if [ -d "$CNI_DIR" ] && [ "$(ls -A $CNI_DIR 2>/dev/null)" ]; then
    echo "containernetworking-plugins seem to be installed in $CNI_DIR"
else
    echo "Installing containernetworking-plugins (CNI plugins)..."
    sudo mkdir -p $CNI_DIR
    curl -LO "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-${ARCH}-${CNI_VERSION}.tgz"
    sudo tar -C $CNI_DIR -xzvf "cni-plugins-linux-${ARCH}-${CNI_VERSION}.tgz"
    rm "cni-plugins-linux-${ARCH}-${CNI_VERSION}.tgz"
fi

# -------------------------------
# Install crictl
# -------------------------------
echo
echo "Checking for existing crictl..."
if command_exists crictl; then
    echo "crictl is already installed at $(command -v crictl)"
    crictl --version
else
    echo "Installing crictl..."
    VERSION="v1.34.0"
    TARBALL="crictl-${VERSION}-linux-amd64.tar.gz"
    URL="https://github.com/kubernetes-sigs/cri-tools/releases/download/${VERSION}/${TARBALL}"
    echo "DEBUG: Downloading $URL"
    wget "$URL"
    sudo tar zxvf "$TARBALL" -C /usr/local/bin
    rm -f "$TARBALL"
    crictl --version
fi

# -------------------------------
# Install cri-dockerd
# -------------------------------
echo
echo "Checking for cri-dockerd..."
if ! command_exists cri-dockerd; then
    echo "Installing cri-dockerd..."
    sudo apt-get install -y golang git make
    git clone https://github.com/Mirantis/cri-dockerd.git /tmp/cri-dockerd
    cd /tmp/cri-dockerd
    mkdir -p bin
    go build -o bin/cri-dockerd
    sudo install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/
    sudo cp -a packaging/systemd/* /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable cri-docker.service
    sudo systemctl enable --now cri-docker.socket
    sudo systemctl start cri-docker.service
    cd ~
    rm -rf /tmp/cri-dockerd
    echo "cri-dockerd installed."
else
    echo "cri-dockerd is already installed."
fi

# -------------------------------
# Finish
# -------------------------------
echo
echo "All required tools installed."
echo "Start your cluster with:"
echo "  minikube start --driver=none"
