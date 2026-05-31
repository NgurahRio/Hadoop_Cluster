#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAPSHOT_DIR="${SNAPSHOT_DIR:-${SCRIPT_DIR}/snapshots}"
BEFORE="${1:-}"
AFTER="${2:-}"

if [ -z "${BEFORE}" ]; then
  BEFORE="$(find "${SNAPSHOT_DIR}" -maxdepth 1 -type f -name '*-before.csv' | sort | tail -n 1)"
fi

if [ -z "${AFTER}" ]; then
  AFTER="$(find "${SNAPSHOT_DIR}" -maxdepth 1 -type f -name '*-after.csv' | sort | tail -n 1)"
fi

if [ -z "${BEFORE}" ] || [ -z "${AFTER}" ]; then
  echo "Belum ada pasangan snapshot before/after."
  echo "Jalankan: ./snapshot_metrics.sh before"
  echo "Lalu setelah job selesai: ./snapshot_metrics.sh after"
  exit 1
fi

python3 - "${BEFORE}" "${AFTER}" <<'PYCODE'
import csv
import sys
from pathlib import Path

before_path = Path(sys.argv[1])
after_path = Path(sys.argv[2])

metrics = [
    ("cpu_used_pct", "CPU %"),
    ("ram_used_pct", "RAM %"),
    ("ram_used_gib", "RAM GiB"),
    ("disk_root_used_pct", "Disk / %"),
    ("load_1m", "Load 1m"),
    ("network_rx_mbps", "RX Mbps"),
    ("network_tx_mbps", "TX Mbps"),
    ("scrape_latency_seconds", "Latency s"),
]

def load(path):
    with path.open(newline="", encoding="utf-8") as handle:
        return {row["node"]: row for row in csv.DictReader(handle)}

def num(value):
    if value in (None, ""):
        return None
    return float(value)

def fmt(value):
    if value is None:
        return "-"
    return f"{value:.2f}"

def delta(before, after):
    if before is None or after is None:
        return None
    return after - before

def arrow(value):
    if value is None:
        return "-"
    if value > 0:
        return f"+{value:.2f}"
    return f"{value:.2f}"

before = load(before_path)
after = load(after_path)
nodes = sorted(set(before) | set(after))

print()
print("===== Ringkasan Monitoring Hadoop =====")
print(f"Before : {before_path}")
print(f"After  : {after_path}")
print()

header = f"{'Node':<10} {'UP':>3} {'CPU %':>9} {'RAM %':>9} {'RAM GiB':>9} {'Disk / %':>9} {'Load':>9} {'RX Mbps':>9} {'TX Mbps':>9} {'Latency':>9}"
print(header)
print("-" * len(header))

for node in nodes:
    b = before.get(node, {})
    a = after.get(node, {})
    up = a.get("up", "-")
    values = []
    for key, _label in metrics:
        values.append(arrow(delta(num(b.get(key)), num(a.get(key)))))
    print(f"{node:<10} {up:>3} {values[0]:>9} {values[1]:>9} {values[2]:>9} {values[3]:>9} {values[4]:>9} {values[5]:>9} {values[6]:>9} {values[7]:>9}")

print()
print("Angka di tabel adalah perubahan after - before. Nilai positif berarti naik setelah proses data.")

# Small highlights for quick reading.
highlights = []
for key, label in metrics:
    best = None
    for node in nodes:
        d = delta(num(before.get(node, {}).get(key)), num(after.get(node, {}).get(key)))
        if d is None:
            continue
        if best is None or abs(d) > abs(best[1]):
            best = (node, d)
    if best is not None:
        highlights.append((label, best[0], best[1]))

if highlights:
    print()
    print("Perubahan terbesar:")
    for label, node, value in highlights:
        print(f"- {label}: {node} ({arrow(value)})")
PYCODE
