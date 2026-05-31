#!/bin/bash
echo
echo "===== HADOOP WEB UI ====="
echo "HDFS UI   : http://192.168.33.92:9870"
echo "YARN UI   : http://192.168.33.92:8088"
echo "HISTORY   : http://192.168.33.92:19888"

echo
echo "===== DATANODE STATUS ====="

hdfs dfsadmin -report | grep -E "Live datanodes|Hostname"