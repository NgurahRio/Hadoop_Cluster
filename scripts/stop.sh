#!/bin/bash

echo "===== STOPPING HISTORY SERVER ====="
mapred --daemon stop historyserver

echo
echo "===== STOPPING YARN ====="
stop-yarn.sh

echo
echo "===== STOPPING HDFS ====="
stop-dfs.sh

echo
echo "===== HADOOP SERVICES AFTER STOP ====="
jps