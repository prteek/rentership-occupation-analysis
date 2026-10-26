#!/usr/bin/env bash
# Publish the Hugging Face dataset prteek/census-2021-occupation-tenure-age-msoa
# (locally: `hf auth login` as prteek; in CI: HF_TOKEN):
#   dataset       export every table of data/lab.duckdb to data/<table>.parquet, upload them with lab.duckdb and the card
#   dataset-card  only the card (CI: data/lab.duckdb is not in git, so the data itself is published by hand)
# Usage: huggingface/publish.sh [message] [dataset|dataset-card]   (default: dataset)
# Needs the duckdb CLI for `dataset`. Set HF_CLI=hf to use an installed hf CLI instead of `uvx hf`.
set -euo pipefail
cd "$(dirname "$0")/.."
msg="${1:-Update}"
shift || true
if [ $# -gt 0 ]; then targets=("$@"); else targets=(dataset); fi
read -r -a hf <<< "${HF_CLI:-uvx --from huggingface_hub hf}"
repo=prteek/census-2021-occupation-tenure-age-msoa
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

# table -> sort order of the exported Parquet file (the raw Nomis tables keep their original row order)
declare -a tables=(
  "dim_region:region" "dim_lad:lad" "geo_mapping:region, lad, msoa, lsoa"
  "msoa_tenure_occupation:" "msoa_occupation_age:"
  "occupation_by_tenure:msoa, tenure, occupation" "occupation_by_age_long:msoa, age, occupation"
  "occupation_by_age:msoa, occupation" "dataset:msoa, tenure, occupation"
  "dataset_filtered:msoa, occupation" "dataset_sample:msoa, occupation"
)

for t in "${targets[@]}"; do
  case "$t" in
    dataset)
      mkdir -p "$stage/dataset/data"
      sql=""
      for spec in "${tables[@]}"; do
        name=${spec%%:*}; order=${spec#*:}
        sql+="COPY (FROM $name${order:+ ORDER BY $order}) TO '$stage/dataset/data/$name.parquet';"
      done
      duckdb -init /dev/null -readonly data/lab.duckdb "$sql"
      cp data/lab.duckdb "$stage/dataset/lab.duckdb"
      cp huggingface/dataset/README.md "$stage/dataset/README.md"
      "${hf[@]}" upload "$repo" "$stage/dataset" . --repo-type dataset --commit-message "$msg" ;;
    dataset-card)
      "${hf[@]}" upload "$repo" huggingface/dataset/README.md README.md --repo-type dataset --commit-message "$msg" ;;
    *)
      echo "unknown target: $t" >&2; exit 1 ;;
  esac
done
