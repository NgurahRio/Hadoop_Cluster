#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/nodes.sh
source "${SCRIPT_DIR}/../lib/nodes.sh"
load_monitoring_nodes

install_node_exporter() {
  local node="$1"

  echo
  echo "===== Installing Node Exporter on ${node} ====="

  if [ "${node}" = "$(hostname)" ] || [ "${node}" = "${MASTER_NODE}" ]; then
    sudo apt update
    sudo apt install -y prometheus-node-exporter
    sudo systemctl enable --now prometheus-node-exporter
    sudo systemctl status prometheus-node-exporter --no-pager
  else
    ssh "${node}" 'sudo apt update && sudo apt install -y prometheus-node-exporter && sudo systemctl enable --now prometheus-node-exporter && sudo systemctl status prometheus-node-exporter --no-pager'
  fi
}

for node in "${NODES[@]}"; do
  install_node_exporter "${node}"
done

echo
echo "===== Checking metrics endpoint from master ====="
for node in "${NODES[@]}"; do
  echo -n "${node}: "
  if curl -fsS --max-time 3 "http://${node}:9100/metrics" >/dev/null; then
    echo "UP"
  else
    echo "DOWN"
  fi
done
