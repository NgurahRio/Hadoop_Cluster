# Hadoop Cluster Monitoring

Monitoring ini memakai Node Exporter di setiap node, Prometheus sebagai collector, dan Grafana sebagai dashboard.

## Target Node

Prometheus dikonfigurasi untuk membaca metrik dari:

| Node | Role | Endpoint |
| --- | --- | --- |
| master | master | `master:9100` |
| worker1 | worker | `worker1:9100` |
| worker2 | worker | `worker2:9100` |
| worker3 | worker | `worker3:9100` |
| worker4 | worker | `worker4:9100` |
| worker5 | worker | `worker5:9100` |

Pastikan semua hostname di atas bisa di-resolve dari mesin yang menjalankan Prometheus. Docker Compose di folder ini sudah diberi `extra_hosts` sesuai IP cluster saat ini.

## Jalankan Node Exporter di Setiap Node

Node Exporter harus hidup di `master` dan semua worker pada port `9100`. Di Ubuntu/Debian, cara paling mudah adalah memakai paket `prometheus-node-exporter`:

```bash
sudo apt update
sudo apt install -y prometheus-node-exporter
sudo systemctl enable --now prometheus-node-exporter
sudo systemctl status prometheus-node-exporter
```

Untuk menginstal lewat SSH dari master ke seluruh node, jalankan:

```bash
./node_exporter/install_node_exporter_cluster.sh
```

Script ini membaca daftar worker dari `configs/runtime/workers` dan otomatis menambahkan `master`, jadi kalau jumlah worker berubah cukup update file workers Hadoop.

Untuk memperbarui target Prometheus setelah daftar worker berubah, jalankan:

```bash
./prometheus/generate_prometheus_config.sh
sudo cp prometheus/prometheus.yml /etc/prometheus/prometheus.yml
sudo systemctl restart prometheus
```

Untuk mengecek endpoint semua node dari master:

```bash
./node_exporter/check_node_exporter.sh
```


## Setup Tanpa Docker di Master

Karena Docker belum terpasang di master, gunakan setup native berikut dari master:

```bash
cd /home/riyo/research-hadoop/monitoring
./install_monitoring_native.sh
```

Script ini akan:

- menginstal Prometheus dari apt Ubuntu,
- memasang konfigurasi `prometheus/prometheus.yml`,
- menambahkan repository resmi Grafana,
- menginstal Grafana,
- memasang datasource Prometheus dan dashboard Hadoop otomatis.

Setelah selesai, cek service:

```bash
./check_monitoring.sh
```

URL:

- Prometheus: http://192.168.33.92:9090
- Grafana: http://192.168.33.92:3000

Login Grafana default:

- User: `admin`
- Password: `admin`

Dashboard ada di folder Grafana `Hadoop` dengan nama `Hadoop Cluster Overview`.

## Jalankan Prometheus dan Grafana

Dari folder `monitoring`:

```bash
docker compose up -d
```

URL:

- Prometheus: http://192.168.33.92:9090
- Grafana: http://192.168.33.92:3000

Login Grafana default:

- User: `admin`
- Password: `admin`

Dashboard otomatis muncul di folder Grafana `Hadoop` dengan nama `Hadoop Cluster Overview`.

## Alur Monitoring Sebelum dan Sesudah Job

1. Pastikan Node Exporter hidup di semua node:

```bash
./node_exporter/check_node_exporter.sh
```

2. Ambil snapshot sebelum menjalankan job Hadoop:

```bash
./snapshot_metrics.sh before
```

3. Jalankan job MapReduce atau proses data kamu.

4. Ambil snapshot setelah job selesai:

```bash
./snapshot_metrics.sh after
```

Saat label `after` dipakai, terminal otomatis menampilkan ringkasan perubahan dari snapshot `before` terakhir ke snapshot `after` terbaru. Untuk menampilkan ulang ringkasan secara manual:

```bash
./summarize_snapshots.sh
```

File CSV dan tampilan rapi TXT akan tersimpan di `monitoring/snapshots/`. File TXT lebih mudah dibaca karena menampilkan RAM dan disk sebagai terpakai/total plus persen. Kolom CSV mencakup status node, CPU terpakai, RAM terpakai, disk root terpakai, load average, network receive/transmit, dan latency scrape Prometheus.

Di Grafana, atur time range ke waktu sebelum sampai sesudah proses data agar grafik CPU, RAM, network, load, disk, dan scrape latency terlihat dalam satu timeline.

## Metrik Dashboard

Dashboard menampilkan:

- Node hidup/mati dari metric `up`
- CPU usage per node
- RAM usage per node
- Disk usage root filesystem
- Network receive/transmit
- Load average
- Scrape latency dari Prometheus ke setiap node

Jika node tampil mati, cek:

```bash
curl http://worker1:9100/metrics
```

Ganti `worker1` dengan node yang bermasalah.
