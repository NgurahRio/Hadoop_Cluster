#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(hostname)" != "master" ]; then
  echo "Script ini sebaiknya dijalankan di master. Host sekarang: $(hostname)"
fi

echo "===== Install Prometheus dari apt Ubuntu ====="
sudo apt update
sudo apt install -y prometheus

echo
echo "===== Pasang konfigurasi Prometheus Hadoop ====="
"$SCRIPT_DIR/prometheus/generate_prometheus_config.sh" "$SCRIPT_DIR/prometheus/prometheus.yml"
sudo cp "$SCRIPT_DIR/prometheus/prometheus.yml" /etc/prometheus/prometheus.yml
sudo systemctl enable --now prometheus
sudo systemctl restart prometheus

echo
echo "===== Install Grafana dari repository resmi Grafana ====="
sudo apt install -y apt-transport-https software-properties-common wget gpg
sudo mkdir -p /etc/apt/keyrings
sudo wget -q -O /etc/apt/keyrings/grafana.asc https://apt.grafana.com/gpg-full.key
printf 'deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main
' | sudo tee /etc/apt/sources.list.d/grafana.list >/dev/null
sudo apt update
sudo apt install -y grafana

echo
echo "===== Provision datasource dan dashboard Grafana ====="
sudo mkdir -p /etc/grafana/provisioning/datasources
sudo mkdir -p /etc/grafana/provisioning/dashboards
sudo mkdir -p /var/lib/grafana/dashboards

sudo tee /etc/grafana/provisioning/datasources/prometheus.yml >/dev/null <<'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    uid: Prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: true
EOF

sudo tee /etc/grafana/provisioning/dashboards/dashboards.yml >/dev/null <<'EOF'
apiVersion: 1

providers:
  - name: Hadoop Cluster
    orgId: 1
    folder: Hadoop
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /var/lib/grafana/dashboards
EOF

sudo cp "$SCRIPT_DIR/grafana/dashboards/hadoop-cluster-overview.json" /var/lib/grafana/dashboards/hadoop-cluster-overview.json
sudo chown -R grafana:grafana /var/lib/grafana/dashboards

sudo systemctl enable --now grafana-server
sudo systemctl restart grafana-server

echo
echo "===== Status service ====="
systemctl --no-pager --full status prometheus || true
systemctl --no-pager --full status grafana-server || true

echo
echo "===== URL ====="
echo "Prometheus: http://192.168.33.92:9090"
echo "Grafana   : http://192.168.33.92:3000"
echo "Login     : admin / admin"
