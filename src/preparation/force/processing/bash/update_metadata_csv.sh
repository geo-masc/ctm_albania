#!/bin/bash

docker run \
--rm \
-v /mnt/HD1/input/BRDcube/Level1/aux:/mnt/HD1/input/BRDcube/Level1/aux \
--volumes-from gcloud-config \
gcr.io/google.com/cloudsdktool/google-cloud-cli:stable bq query --format=csv \
--use_legacy_sql=false \
-n 1000000 \
"SELECT 
  GRANULE_ID,
  PRODUCT_ID,
  DATATAKE_IDENTIFIER,
  MGRS_TILE,
  FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E6SZ', SENSING_TIME) AS SENSING_TIME,
  TOTAL_SIZE,
  CLOUD_COVER,
  '' AS GEOMETRIC_QUALITY_FLAG,
  FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E6SZ', GENERATION_TIME) AS GENERATION_TIME,
  NORTH_LAT,
  SOUTH_LAT,
  WEST_LON,
  EAST_LON,
  CONCAT(
  'gs://gcp-public-data-sentinel-2/tiles/',
  SUBSTR(mgrs_tile, 0, 2), '/', -- UTM zone
  SUBSTR(mgrs_tile, 3, 1), '/', -- Latitude band
  SUBSTR(mgrs_tile, 4, 2), '/', -- Grid square
  product_id, '.SAFE'
  ) AS BASE_URL
FROM 
  \`bigquery-public-data\`.cloud_storage_geo_index.sentinel_2_index
WHERE
  NORTH_LAT <= 43.0
  AND SOUTH_LAT >= 39.0
  AND WEST_LON >= 19.0
  AND EAST_LON <= 22.0
  AND GRANULE_ID LIKE 'L1C_%'
  AND SENSING_TIME BETWEEN TIMESTAMP('2019-01-01') AND TIMESTAMP('2030-12-31')
ORDER BY
  SENSING_TIME ASC;" \
> /home/schwieder/projects/ctm_albania/src/force/processing/meta/metadata_sentinel2.csv