#!/bin/bash
set -e

echo "Installing kubectl (official binary)..."
KUBECTL_VERSION=$(curl -Ls https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo "kubectl version:"
kubectl version --client

echo
echo "Installing Minikube (official binary)..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

echo "minikube version:"
minikube version

echo
echo "Done! Start your cluster with: minikube start"
