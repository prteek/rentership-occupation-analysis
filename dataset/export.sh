#!/usr/bin/env bash
# Export every table of data/lab.duckdb to $STAGE/data/<table>.parquet (run by `hf publish dataset`). Needs the
# duckdb CLI.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${STAGE:?set STAGE to the folder to write to}"

# table -> sort order of the exported Parquet file (the raw Nomis tables keep their original row order)
tables=(
  "dim_region:region" "dim_lad:lad" "geo_mapping:region, lad, msoa, lsoa"
  "msoa_tenure_occupation:" "msoa_occupation_age:"
  "occupation_by_tenure:msoa, tenure, occupation" "occupation_by_age_long:msoa, age, occupation"
  "occupation_by_age:msoa, occupation" "dataset:msoa, tenure, occupation"
  "dataset_filtered:msoa, occupation" "dataset_sample:msoa, occupation"
)

mkdir -p "$STAGE/data"
sql=""
for spec in "${tables[@]}"; do
  name=${spec%%:*}; order=${spec#*:}
  sql+="COPY (FROM $name${order:+ ORDER BY $order}) TO '$STAGE/data/$name.parquet';"
done
duckdb -init /dev/null -readonly data/lab.duckdb "$sql"
