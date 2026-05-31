#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/nodes.sh
source "${SCRIPT_DIR}/../lib/nodes.sh"
load_monitoring_nodes

for node in "${NODES[@]}"; do
  echo -n "${node}: "
  if curl -fsS --max-time 3 "http://${node}:9100/metrics" >/dev/null; then
    echo "UP"
  else
    echo "DOWN"
  fi
done
