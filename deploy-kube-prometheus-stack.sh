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

echo "=== Step 5: Wait for Grafana to be ready ==="
sleep 60  # Adjust based on system speed

echo "=== Step 6: Port-forward Grafana ==="
kubectl port-forward svc/monitoring-grafana 3000:80 &
sleep 10

echo "=== Step 7: Get Grafana admin password ==="
GRAFANA_PWD=$(kubectl get secret monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

echo "=== Step 8: Import custom dashboard ==="
curl -X POST http://admin:$GRAFANA_PWD@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d '{
    "dashboard": {
      "id": null,
      "uid": null,
      "title": "CPU Usage Dashboard",
      "tags": ["custom"],
      "timezone": "browser",
      "schemaVersion": 16,
      "version": 0,
      "refresh": "5s",
      "panels": [{
        "type": "graph",
        "title": "CPU Usage",
        "targets": [{
          "expr": "rate(container_cpu_usage_seconds_total[1m])",
          "legendFormat": "{{container}}",
          "refId": "A"
        }],
        "gridPos": {"x": 0, "y": 0, "w": 24, "h": 8}
      }]
    },
    "overwrite": true
  }'

echo "=== Dashboard imported successfully ==="
