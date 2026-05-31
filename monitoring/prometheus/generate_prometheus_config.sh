#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/nodes.sh
source "${SCRIPT_DIR}/../lib/nodes.sh"
load_monitoring_nodes

OUT="${1:-${SCRIPT_DIR}/prometheus.yml}"

{
  cat <<'EOF'
global:
  scrape_interval: 5s
  evaluation_interval: 5s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'hadoop-nodes'
    metrics_path: /metrics
    static_configs:
EOF

  for node in "${NODES[@]}"; do
    role="worker"
    if [ "${node}" = "${MASTER_NODE}" ]; then
      role="master"
    fi

    cat <<EOF
      - targets: ['${node}:9100']
        labels:
          node: '${node}'
          role: '${role}'

EOF
  done
} > "${OUT}"

echo "Prometheus config generated: ${OUT}"
