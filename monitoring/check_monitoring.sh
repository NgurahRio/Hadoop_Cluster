#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/nodes.sh
source "${SCRIPT_DIR}/lib/nodes.sh"
load_monitoring_nodes

URLS=(
  http://localhost:9090/-/ready
  http://localhost:3000/api/health
)

for node in "${NODES[@]}"; do
  URLS=("http://${node}:9100/metrics" "${URLS[@]}")
done

for url in "${URLS[@]}"; do
  printf '%-40s ' "$url"
  if curl -fsS --max-time 3 "$url" >/dev/null; then
    echo "UP"
  else
    echo "DOWN"
  fi
done
