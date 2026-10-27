# rentership-occupation-analysis

How do occupation and age relate to private renting? Binomial mixed models fitted to 2021 Census data for
neighbourhoods (MSOAs) in England outside London, written up as the paper
[Rentership ~ Occupation, Analysis](https://www.alphaxiv.org/abs/2610.rentership-occupation-analysis) on alphaXiv.

**Data:** https://huggingface.co/datasets/prteek/census-2021-occupation-tenure-age-msoa

## Layout

```
index.qmd               the paper (R, knitr); reads data/lab.duckdb and queries MSOA boundaries from Athena
_quarto.yml             PDF format; renders to _output/rentership-occupation-analysis.pdf
_freeze/                frozen results of the paper's code (tracked)
data_preparation.qmd    builds data/lab.duckdb from the Nomis CSVs and geography tables in Athena (not rendered)
data/
  msoa_tenure_occupation.csv, msoa_occupation_age.csv   Census 2021 tables RM140 and RM102 from Nomis (tracked)
  lab.duckdb            the database the paper reads (not in git; download it from the dataset, below)
huggingface/
  dataset/README.md     the dataset card
  publish.sh            export the tables and publish the dataset, or only its card
renv.lock, renv/        R package versions (renv); _dependencies.R lists render-time packages
references.bib, rentals_2021.png, _wide-tables.lua
```

## Common tasks

```bash
Rscript -e 'renv::restore()'                                   # once: install the R packages
hf download prteek/census-2021-occupation-tenure-age-msoa lab.duckdb --repo-type dataset --local-dir data

QUARTO_R=/opt/homebrew/bin/Rscript quarto render               # paper PDF from the frozen results
huggingface/publish.sh "message" dataset                       # publish the database and its tables
```

Rendering reuses `_freeze/` until a code chunk changes. Re-running the paper needs `data/lab.duckdb` and access to
the Athena tables holding MSOA boundaries (AWS profile `personal`), plus `RETICULATE_PYTHON` pointing at a Python
with `boto3` and `CHROMOTE_CHROME` at a headless Chrome for the map screenshots.

The figures were reworked for the PDF (horizontal occupation plots, taller panels, map markers), so the paper was
re-run here: every number matches the first alphaXiv version, but the randomly chosen example rows in the
exploratory section differ, because those queries are unseeded.

`dataset_sample` in the database is the exact sample the paper was fitted on (an unseeded draw); don't redraw it
without refitting the paper.

## Publishing from CI

A push to `main` that changes the dataset card publishes it (`.github/workflows/publish-dataset-card.yml`, using the
`HF_TOKEN` repository secret). The database is built locally and published by hand.

Data: Office for National Statistics, Census 2021 (RM140, RM102), Open Government Licence v3.0.
