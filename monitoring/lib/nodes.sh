#!/bin/bash

MONITORING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$(cd "${MONITORING_DIR}/.." && pwd)"
WORKERS_FILE="${WORKERS_FILE:-${REPO_DIR}/configs/runtime/workers}"
MASTER_NODE="${MASTER_NODE:-master}"

load_monitoring_nodes() {
  NODES=("${MASTER_NODE}")

  if [ -f "${WORKERS_FILE}" ]; then
    while IFS= read -r line || [ -n "${line}" ]; do
      line="${line%%#*}"
      line="${line#"${line%%[![:space:]]*}"}"
      line="${line%"${line##*[![:space:]]}"}"

      if [ -n "${line}" ]; then
        NODES+=("${line}")
      fi
    done < "${WORKERS_FILE}"
  fi
}
