#!/bin/bash

echo "===== COMBINE WORDCOUNT : 5 WORKER ====="

INPUT=/skenario-smallfiles/1000files
OUTPUT=/results/combine-smallfiles/1000files
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