import java.io.IOException;
import java.net.InetAddress;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.FileSystem;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;

import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;

import org.apache.hadoop.mapreduce.lib.input.CombineTextInputFormat;
import org.apache.hadoop.mapreduce.lib.input.CombineFileSplit;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class CombineWordCount {

    public static class TokenizerMapper
            extends Mapper<Object, Text, Text, IntWritable> {

        private static final IntWritable one = new IntWritable(1);
        private Text word = new Text();
        private String hostname;

        @Override
        protected void setup(Context context)
                throws IOException, InterruptedException {

            hostname = InetAddress.getLocalHost().getHostName();

            CombineFileSplit split =
                    (CombineFileSplit) context.getInputSplit();

            int jumlahFile = split.getNumPaths();

            context.getCounter("FILES_PER_WORKER", hostname)
                    .increment(jumlahFile);

            System.out.println("===== FILE YANG DIKERJAKAN "
                    + hostname + " =====");

            for (int i = 0; i < jumlahFile; i++) {
                System.out.println(
                        hostname + " mengerjakan: "
                                + split.getPath(i).getName()
                );
            }
        }

        @Override
        public void map(Object key, Text value, Context context)
                throws IOException, InterruptedException {

            String[] words = value.toString().split("\\s+");

            int localWordCount = 0;

            for (String w : words) {

                if (!w.isEmpty()) {

                    localWordCount++;

                    word.set(w);

                    context.write(word, one);
                }
            }

            context.getCounter("WORDS_PER_WORKER", hostname)
                    .increment(localWordCount);

            context.getCounter("RECORDS_PER_WORKER", hostname)
                    .increment(1);
        }
    }

    public static class IntSumReducer
            extends Reducer<Text, IntWritable,
            Text, IntWritable> {

        private IntWritable result = new IntWritable();

        @Override
        public void reduce(Text key,
                           Iterable<IntWritable> values,
                           Context context)
                throws IOException, InterruptedException {

            int sum = 0;

            for (IntWritable val : values) {
                sum += val.get();
            }

            result.set(sum);

            context.write(key, result);
        }
    }

    public static void main(String[] args)
            throws Exception {

        if (args.length < 3) {

            System.err.println(
                    "Usage: CombineWordCount "
                            + "<input> <output> <workerCount>"
            );

            System.exit(1);
        }

        Configuration conf = new Configuration();

        Job job = Job.getInstance(
                conf,
                "combine word count adaptive"
        );

        job.setJarByClass(CombineWordCount.class);

        job.setMapperClass(TokenizerMapper.class);

        job.setCombinerClass(IntSumReducer.class);

        job.setReducerClass(IntSumReducer.class);

        job.setOutputKeyClass(Text.class);

        job.setOutputValueClass(IntWritable.class);

        job.setInputFormatClass(
                CombineTextInputFormat.class
        );

        Path inputPath = new Path(args[0]);

        Path outputPath = new Path(args[1]);

        CombineTextInputFormat.addInputPath(
                job,
                inputPath
        );

        FileSystem fs =
                inputPath.getFileSystem(conf);

        long totalSize = 0;

        int totalFiles = 0;

        for (FileStatus file :
                fs.listStatus(inputPath)) {

            if (file.isFile()) {

                totalSize += file.getLen();

                totalFiles++;
            }
        }

        int workerCount =
                Integer.parseInt(args[2]);

        /*
         * ==========================================
         * FIX:
         * jumlah split diperbanyak supaya
         * semua worker punya peluang dipakai
         * ==========================================
         */

        int targetSplits = workerCount * 2;

        long splitSize =
                Math.max(totalSize / targetSplits, 1);

        System.out.println(
                "================================="
        );

        System.out.println(
                "Total Files        : " + totalFiles
        );

        System.out.println(
                "Total Dataset Size : " + totalSize
        );

        System.out.println(
                "Worker Count       : " + workerCount
        );

        System.out.println(
                "Target Splits      : " + targetSplits
        );

        System.out.println(
                "Calculated Split   : " + splitSize
        );

        System.out.println(
                "================================="
        );

        CombineTextInputFormat
                .setMaxInputSplitSize(
                        job,
                        splitSize
                );

        FileOutputFormat.setOutputPath(
                job,
                outputPath
        );

        boolean success =
                job.waitForCompletion(true);

        System.out.println();

        System.out.println(
                "===== DISTRIBUSI BEBAN "
                        + "KERJA PER WORKER ====="
        );

        for (org.apache.hadoop.mapreduce.Counter counter :
                job.getCounters()
                        .getGroup("WORDS_PER_WORKER")) {

            String worker =
                    counter.getName();

            long totalWords =
                    counter.getValue();

            long totalFilesWorker =

                    job.getCounters()

                            .findCounter(
                                    "FILES_PER_WORKER",
                                    worker
                            )

                            .getValue();

            long totalRecords =

                    job.getCounters()

                            .findCounter(
                                    "RECORDS_PER_WORKER",
                                    worker
                            )

                            .getValue();

            System.out.println(worker);

            System.out.println(
                    "Jumlah File        : "
                            + totalFilesWorker
            );

            System.out.println(
                    "Jumlah Record/Baris: "
                            + totalRecords
            );

            System.out.println(
                    "Jumlah Kata        : "
                            + totalWords
            );

            System.out.println();
        }

        System.exit(success ? 0 : 1);
    }
}