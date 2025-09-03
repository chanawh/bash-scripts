#!/bin/bash
set -e

TABLE_NAME="country_wise_latest"

# Create the table if it does not exist
clickhouse-client --query="
CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
  Country_Region String,
  Confirmed UInt32,
  Deaths UInt32,
  Recovered UInt32,
  Active UInt32,
  New_case UInt32,
  New_death UInt32,
  New_recovered UInt32,
  Deaths_per_1M Float32,
  Recovered_per_1M Float32,
  Deaths_per_Confirmed Float32,
  Confirmed_1_week_change Int32,
  One_week_percent Float32,
  WHO_Region String
) ENGINE = MergeTree() ORDER BY Country_Region;
"

# Load data if table is empty
if [[ $(clickhouse-client --query "SELECT count() FROM ${TABLE_NAME}") -eq 0 ]]; then
    echo "Loading data into ${TABLE_NAME}..."
    clickhouse-client --query="INSERT INTO ${TABLE_NAME} FORMAT CSVWithNames" < /docker-entrypoint-initdb.d/country_wise_latest_clean.csv
else
    echo "${TABLE_NAME} already has data."
fi

