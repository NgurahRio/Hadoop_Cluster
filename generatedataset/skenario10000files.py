import os
import random

output_folder = "../datasets/skenario-smallfiles/5worker/10000"

jumlah_file = 10000

os.makedirs(output_folder, exist_ok=True)

sentences = [

    "hadoop manages distributed cluster resources",
    "hdfs stores big data efficiently",
    "mapreduce processes data in parallel",
    "yarn controls cluster resource allocation",
    "grafana visualizes cluster monitoring metrics",
    "prometheus collects realtime system metrics",
    "worker nodes process distributed workloads",
    "namenode manages hdfs file metadata",
    "datanode stores distributed data blocks",
    "big data requires scalable systems",

    "cluster monitoring improves system performance",
    "distributed computing increases processing speed",
    "resource management optimizes cluster stability",
    "hadoop supports fault tolerant processing",
    "parallel processing accelerates big data analytics",

    "linux powers distributed server infrastructure",
    "ubuntu provides stable cluster environments",
    "java runs hadoop distributed applications",
    "openjdk supports hadoop runtime execution",
    "monitoring dashboards display cluster activity",

    "resource allocation improves workload balancing",
    "analytics systems process large datasets",
    "cluster nodes communicate through network services",
    "distributed systems require efficient storage",
    "big data platforms analyze massive datasets"

]

for i in range(1, jumlah_file + 1):

    filename = f"{output_folder}/file_{i:04}.txt"

    # setiap file dibuat besar
    selected_sentences = random.choices(sentences, k=500)

    text = "\n".join(selected_sentences)

    with open(filename, "w") as f:

        f.write(text)

print("10000 distributed large text files berhasil dibuat.")