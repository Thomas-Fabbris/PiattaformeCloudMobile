import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql.functions import udf, col, lit, to_timestamp, date_format, when, lower, trim, regexp_replace, count
from pyspark.sql.types import StringType, BooleanType, ArrayType
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
import re

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

connection_name = "TedX"
database_name = "unibg_tedx_2025"
collection_name = "tedx_data"

#Lettura dati da MongoDB
read_mongo_options = {
    "connectionName": connection_name,
    "database": database_name,
    "collection": collection_name
}

df = glueContext.create_dynamic_frame.from_options(connection_type="mongodb", connection_options = read_mongo_options).toDF()
print(f"Record originali: {df.count()}")

# Controllo dei duplicati in _id
print("Verifica presenza di ID duplicati:")
duplicates = df.groupBy("_id").agg(count("*").alias("count")).filter(col("count") > 1)
duplicates_count = duplicates.count()
print(f"Trovati {duplicates_count} ID duplicati nel dataset")

if duplicates_count > 0:
    df = df.dropDuplicates(["_id"])

# Controllo dell'esistenza dei related video 
df_with_valid_ids_for_reference = df.filter(
    col("_id").isNotNull() & col("_id").cast("string").rlike("^[0-9]+$")
)
valid_ids_list = [row._id for row in df_with_valid_ids_for_reference.select("_id").distinct().collect()]
broadcast_valid_ids = spark.sparkContext.broadcast(set(valid_ids_list))

print(f"Numero totale di record nel dataset: {df.count()}")
print(f"Numero di ID validi: {len(valid_ids_list)}")

# Funzione per validare URL
def is_valid_url_regex(url_string):
    if url_string is None:
        return False
    return bool(re.match(r'^(https?|ftp):\/\/[^\s/$.?#].[^\s]*$', str(url_string)))

# Funzione per verificare se gli ID dei video watch_next sono validi
def validate_related_ids_list_udf_func(id_list_to_check):
    if id_list_to_check is None:
        return True
    if not isinstance(id_list_to_check, list):
        return False
    for video_id in id_list_to_check:
        if str(video_id) not in broadcast_valid_ids.value:
            return False
    return True

# Definizione delle UDF (User Defined Functions)
is_valid_url_udf = udf(is_valid_url_regex, BooleanType())
validate_related_ids_udf = udf(validate_related_ids_list_udf_func, BooleanType())

# Normalizzazione del testo, rimuovendo spazi extra, caratteri di controllo e convertendo in lowercase
def normalize_text_func(text):
    if text is None:
        return None
    text = text.lower()
    text = re.sub(r'[\r\n\t]+', ' ', text)
    text = text.strip()
    return text

normalize_text_udf = udf(normalize_text_func, StringType())

df_transformed = df \
    .withColumn("publishedAt_ts", to_timestamp(col("publishedAt"))) \
    .withColumn("title_normalized", normalize_text_udf(col("title"))) \
    .withColumn("description_normalized", normalize_text_udf(col("description"))) \
    .withColumn("slug_normalized", normalize_text_udf(col("slug"))) \
    .withColumn("speakers_normalized", normalize_text_udf(col("speakers")))

df_transformed = df_transformed \
    .withColumn(
        "publishedAt_formatted",
        when(col("publishedAt_ts").isNotNull(), date_format(col("publishedAt_ts"), "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"))
        .otherwise(lit("1970-01-01T00:00:00.000Z"))
    ) \
    .withColumn("url_is_valid", is_valid_url_udf(col("url"))) \
    .withColumn("related_videos_are_valid", validate_related_ids_udf(col("related_video_ids")))

# Normalizzazione dei tag
def normalize_tags_list(tags_list):
    if tags_list is None:
        return None
    if not isinstance(tags_list, list):
        return tags_list
    return [tag.lower().strip() for tag in tags_list if tag is not None]

normalize_tags_udf = udf(normalize_tags_list, ArrayType(StringType()))

df_with_normalized_tags = df_transformed \
    .withColumn("tags_normalized", normalize_tags_udf(col("tags")))

df_cleaned = df_with_normalized_tags \
    .drop("publishedAt", "publishedAt_ts") \
    .withColumnRenamed("publishedAt_formatted", "publishedAt") \
    .withColumnRenamed("title_normalized", "title") \
    .withColumnRenamed("description_normalized", "description") \
    .withColumnRenamed("slug_normalized", "slug") \
    .withColumnRenamed("speakers_normalized", "speakers") \
    .withColumnRenamed("tags_normalized", "tags")
    
# Filtraggio finale per ID validi, URL validi e related_videos validi
df_valid = df_cleaned.filter(
    (col("_id").isNotNull()) &
    (col("duration").isNotNull()) &
    (col("url_is_valid") == True) &                                      
    (col("related_videos_are_valid") == True)                          
)

df_final_to_write = df_valid.drop("url_is_valid", "related_videos_are_valid")
print(f"Record dopo pulizia: {df_final_to_write.count()}")
print(f"Record scartati: {df.count() - df_final_to_write.count()}")

write_mongo_options = {
   "connectionName": connection_name,
    "database": database_name,
    "collection": "tedx_data_cleaned",
    "mode": "overwrite",
    "ssl": "true",
    "ssl.domain_match": "false"
}

# Scrittura dataset pulito su MongoDB
tedx_dataset_dynamic_frame = DynamicFrame.fromDF(df_final_to_write, glueContext, "final_dynamic_frame")
glueContext.write_dynamic_frame.from_options(
    frame=tedx_dataset_dynamic_frame,
    connection_type="mongodb",
    connection_options=write_mongo_options
)

job.commit()
