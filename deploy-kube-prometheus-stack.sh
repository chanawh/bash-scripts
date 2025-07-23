#!/bin/bash

set -e

echo "=== Step 1: Start Minikube ==="
minikube start --driver=docker --force

echo "=== Step 2: Install Helm ==="
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

echo "=== Step 3: Add Prometheus Helm Repo ==="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "=== Step 4: Install kube-prometheus-stack ==="
helm install monitoring prometheus-community/kube-prometheus-stack

echo "=== Step 5: Expose Grafana Service ==="
minikube service monitoring-grafana
