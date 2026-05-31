#!/bin/bash

echo "===== STARTING HISTORY SERVER ====="
mapred --daemon start historyserver

echo
echo "===== STARTING YARN ====="
start-yarn.sh

echo
echo "===== STARTING HDFS ====="
start-dfs.sh

echo
echo "===== HADOOP SERVICES AFTER START ====="
jps