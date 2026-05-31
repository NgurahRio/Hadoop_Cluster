#!/bin/bash
set -euo pipefail

CSV_FILE="${1:?Pakai: ./format_snapshot.sh snapshots/file.csv}"
TXT_FILE="${2:-${CSV_FILE%.csv}.txt}"

python3 - "${CSV_FILE}" "${TXT_FILE}" <<'PYCODE'
import csv
import sys
from pathlib import Path

csv_path = Path(sys.argv[1])
txt_path = Path(sys.argv[2])

with csv_path.open(newline="", encoding="utf-8") as handle:
    rows = list(csv.DictReader(handle))

def num(row, key):
    value = row.get(key, "")
    if value in (None, ""):
        return None
    try:
        return float(value)
    except ValueError:
        return None

def pct(value):
    return "-" if value is None else f"{value:.2f}%"

def gib(value):
    return "-" if value is None else f"{value:.2f} GiB"

def small(value, unit=""):
    return "-" if value is None else f"{value:.2f}{unit}"

def used_total(used, total, percent):
    if used is not None and total is not None and percent is not None:
        return f"{used:.2f}/{total:.2f} GiB ({percent:.2f}%)"
    if used is not None and percent is not None:
        return f"{used:.2f} GiB ({percent:.2f}%)"
    if percent is not None:
        return f"{percent:.2f}%"
    return "-"

lines = []
lines.append("RINGKASAN SNAPSHOT MONITORING HADOOP")
lines.append(f"File: {csv_path}")
lines.append("")
lines.append("Keterangan singkat:")
lines.append("- CPU menunjukkan persen pemakaian CPU saat snapshot diambil.")
lines.append("- RAM dan Disk ditampilkan sebagai terpakai/total plus persen.")
lines.append("- RX/TX adalah trafik jaringan dalam Mbps.")
lines.append("- Latency adalah waktu Prometheus mengambil metrik dari node.")
lines.append("")

header = f"{'Node':<10} {'Status':<6} {'CPU':>8} {'RAM Terpakai':>27} {'Disk / Terpakai':>29} {'Load':>8} {'RX':>10} {'TX':>10} {'Latency':>10}"
lines.append(header)
lines.append("-" * len(header))

for row in rows:
    node = row.get("node", "-")
    status = "UP" if row.get("up") in ("1", "1.0") else "DOWN"
    cpu = pct(num(row, "cpu_used_pct"))
    ram = used_total(num(row, "ram_used_gib"), num(row, "ram_total_gib"), num(row, "ram_used_pct"))
    disk = used_total(num(row, "disk_root_used_gib"), num(row, "disk_root_total_gib"), num(row, "disk_root_used_pct"))
    load = small(num(row, "load_1m"))
    rx = small(num(row, "network_rx_mbps"), " Mbps")
    tx = small(num(row, "network_tx_mbps"), " Mbps")
    latency = small(num(row, "scrape_latency_seconds"), " s")
    lines.append(f"{node:<10} {status:<6} {cpu:>8} {ram:>27} {disk:>29} {load:>8} {rx:>10} {tx:>10} {latency:>10}")

lines.append("")
lines.append("Contoh baca: RAM 1.42/11.68 GiB (12.14%) berarti node memakai 1.42 GiB dari total 11.68 GiB RAM.")

txt_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(txt_path)
PYCODE

echo "Tampilan rapi tersimpan: ${TXT_FILE}"
