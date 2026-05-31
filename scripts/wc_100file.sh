#!/bin/bash

echo "===== COMBINE WORDCOUNT : 5 WORKER ====="

INPUT=/skenario-smallfiles/100files
OUTPUT=/results/combine-smallfiles/100files
WORKERS=5

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