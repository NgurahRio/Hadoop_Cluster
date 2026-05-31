#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"
LABEL="${1:-snapshot}"
OUTPUT_DIR="${OUTPUT_DIR:-${SCRIPT_DIR}/snapshots}"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="${OUTPUT_DIR}/${TS}-${LABEL}.csv"

mkdir -p "${OUTPUT_DIR}"

python3 - "$PROMETHEUS_URL" "$OUT" <<'PYCODE'
import csv
import json
import sys
import urllib.parse
import urllib.request

base_url = sys.argv[1].rstrip("/")
out_path = sys.argv[2]

queries = {
    "up": 'up{job="hadoop-nodes"}',
    "cpu_used_pct": '100 * (1 - avg by (node) (rate(node_cpu_seconds_total{job="hadoop-nodes",mode="idle"}[1m])))',
    "ram_used_pct": '100 * (1 - (node_memory_MemAvailable_bytes{job="hadoop-nodes"} / node_memory_MemTotal_bytes{job="hadoop-nodes"}))',
    "ram_used_gib": '(node_memory_MemTotal_bytes{job="hadoop-nodes"} - node_memory_MemAvailable_bytes{job="hadoop-nodes"}) / 1024 / 1024 / 1024',
    "ram_total_gib": 'node_memory_MemTotal_bytes{job="hadoop-nodes"} / 1024 / 1024 / 1024',
    "disk_root_used_pct": '100 * (1 - (node_filesystem_avail_bytes{job="hadoop-nodes",mountpoint="/",fstype!~"tmpfs|overlay|squashfs"} / node_filesystem_size_bytes{job="hadoop-nodes",mountpoint="/",fstype!~"tmpfs|overlay|squashfs"}))',
    "disk_root_used_gib": '(node_filesystem_size_bytes{job="hadoop-nodes",mountpoint="/",fstype!~"tmpfs|overlay|squashfs"} - node_filesystem_avail_bytes{job="hadoop-nodes",mountpoint="/",fstype!~"tmpfs|overlay|squashfs"}) / 1024 / 1024 / 1024',
    "disk_root_total_gib": 'node_filesystem_size_bytes{job="hadoop-nodes",mountpoint="/",fstype!~"tmpfs|overlay|squashfs"} / 1024 / 1024 / 1024',
    "load_1m": 'node_load1{job="hadoop-nodes"}',
    "network_rx_mbps": 'sum by (node) (rate(node_network_receive_bytes_total{job="hadoop-nodes",device!~"lo|docker.*|veth.*|br.*"}[1m])) * 8 / 1000 / 1000',
    "network_tx_mbps": 'sum by (node) (rate(node_network_transmit_bytes_total{job="hadoop-nodes",device!~"lo|docker.*|veth.*|br.*"}[1m])) * 8 / 1000 / 1000',
    "scrape_latency_seconds": 'scrape_duration_seconds{job="hadoop-nodes"}',
}

rows = {}

def prometheus_query(expr):
    params = urllib.parse.urlencode({"query": expr})
    with urllib.request.urlopen(f"{base_url}/api/v1/query?{params}", timeout=5) as response:
        payload = json.load(response)
    if payload.get("status") != "success":
        raise RuntimeError(payload)
    return payload["data"]["result"]

for metric_name, expr in queries.items():
    for item in prometheus_query(expr):
        node = item.get("metric", {}).get("node") or item.get("metric", {}).get("instance", "unknown")
        value = float(item["value"][1])
        rows.setdefault(node, {})[metric_name] = value

fieldnames = ["node", *queries.keys()]
with open(out_path, "w", newline="", encoding="utf-8") as handle:
    writer = csv.DictWriter(handle, fieldnames=fieldnames)
    writer.writeheader()
    for node in sorted(rows):
        row = {"node": node}
        for key in queries:
            value = rows[node].get(key, "")
            row[key] = "" if value == "" else round(value, 4)
        writer.writerow(row)

print(out_path)
PYCODE

echo "Snapshot tersimpan: ${OUT}"

if [ -x "${SCRIPT_DIR}/format_snapshot.sh" ]; then
  "${SCRIPT_DIR}/format_snapshot.sh" "${OUT}"
fi

if [ "${LABEL}" = "after" ] && [ -x "${SCRIPT_DIR}/summarize_snapshots.sh" ]; then
  "${SCRIPT_DIR}/summarize_snapshots.sh" "" "${OUT}"
fi
