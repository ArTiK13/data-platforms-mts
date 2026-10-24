from pyspark.sql import SparkSession
from pyspark.sql import functions as F

spark = SparkSession.builder.appName("hw4-events").enableHiveSupport().getOrCreate()

with open("/var/lib/spark/application-id", "w") as f:
    f.write(spark.sparkContext.applicationId + "\n")

src = "hdfs://team-08-nn:8020/user/hive/external/hw3/events"
dst = "hdfs://team-08-nn:8020/user/hive/external/hw4/event_stats"

df = spark.read.schema("event_id STRING, user_id STRING, event_type STRING, dt STRING").csv(src)
df = (
    df.withColumn("user_id", F.col("user_id").cast("int"))
    .withColumn("dt", F.to_date("dt"))
    .withColumn("event_type", F.upper("event_type"))
)
df = df.groupBy("dt", "event_type").agg(
    F.count("*").alias("events"),
    F.countDistinct("user_id").alias("users"),
)

spark.sql("CREATE DATABASE IF NOT EXISTS hw4")
(
    df.write.mode("overwrite")
    .format("hive")
    .option("fileFormat", "parquet")
    .option("path", dst)
    .partitionBy("dt")
    .saveAsTable("hw4.event_stats")
)

spark.stop()
