#!/bin/bash

echo "===== COMBINE WORDCOUNT : 3 WORKER ====="

INPUT=/skenario-worker/3worker
OUTPUT=/results/combine-3worker
WORKERS=3

echo
echo "Removing old output..."
hdfs dfs -rm -r -f $OUTPUT

echo
echo "Running CombineWordCount..."

hadoop jar \
~/research-hadoop/mapreduce/combinewordcount/CombineWordCount.jar \
CombineWordCount \
$INPUT \
$OUTPUT \
$WORKERS

echo
echo "===== OUTPUT RESULT ====="

hdfs dfs -cat $OUTPUT/part-r-00000 | head