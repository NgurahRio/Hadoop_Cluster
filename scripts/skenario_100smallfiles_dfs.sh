#!/bin/bash

echo "===== UPLOAD DATASET 5 WORKER ====="

LOCAL_PATH=~/research-hadoop/datasets/skenario-smallfiles/5worker/100
HDFS_PATH=/skenario-smallfiles/100files

TOTAL=$(ls $LOCAL_PATH | wc -l)

echo "Local files : $TOTAL"

echo
echo "Uploading to HDFS..."

hdfs dfs -mkdir -p $HDFS_PATH

hdfs dfs -put $LOCAL_PATH/* $HDFS_PATH

echo
echo "Upload finished"

HDFS_TOTAL=$(hdfs dfs -ls $HDFS_PATH | grep "^-" | wc -l)

echo "HDFS files : $HDFS_TOTAL"