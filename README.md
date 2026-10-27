# rentership-occupation-analysis

How do occupation and age relate to private renting? Binomial mixed models fitted to 2021 Census data for
neighbourhoods (MSOAs) in England outside London, written up as the blog post
[Who Rents?](https://huggingface.co/blog/prteek/rentership-occupation-analysis) on Hugging Face.

**Blog:** https://huggingface.co/blog/prteek/rentership-occupation-analysis · **Data:** https://huggingface.co/datasets/prteek/census-2021-occupation-tenure-age-msoa

## Layout

```
blog/                   Quarto write-up (R, knitr) -> markdown for the Hugging Face article editor
  index.qmd             the blog post; renders to rentership-occupation-analysis.md, figures to assets/
  _hf-markdown.lua      writes inline maths as \\( ... \\) for the article editor
  thumbnail.png         the article's cover image
data_preparation.qmd    builds data/lab.duckdb from the Nomis CSVs and geography tables in Athena (not rendered)
data/
  msoa_tenure_occupation.csv, msoa_occupation_age.csv   Census 2021 tables RM140 and RM102 from Nomis (tracked)
  lab.duckdb            the database the post reads (not in git; download it from the dataset, below)
  msoa_boundaries.gpkg  MSOA boundaries for the maps (not in git; see Notes)
dataset/README.md       the dataset card
publish.sh              export the tables and publish the dataset, or only its card
renv.lock, renv/        R package versions (renv)
```

## Common tasks

```bash
Rscript -e 'renv::restore()'                                   # once: install the R packages
hf download prteek/census-2021-occupation-tenure-age-msoa lab.duckdb --repo-type dataset --local-dir data

QUARTO_R=/opt/homebrew/bin/Rscript quarto render blog/index.qmd   # blog markdown + assets/ figures (~1 min)
./publish.sh "message" dataset                                 # publish the database and its tables
```

The post re-runs both models from `data/lab.duckdb` on every render (the mixed model fit and the predictions are
cached by knitr in `blog/index_cache/`). It needs no network access: the maps are drawn from
`data/msoa_boundaries.gpkg` without a basemap.

## Notes

- **The write-up is a blog post**, reproducible from the data: dispersion 9.33 for the binomial GLM and 2.08 for the
  mixed model, 3.8% higher odds of renting for 10% more 25–34 year olds, professionals' odds 55% below elementary
  occupations. There are no randomly drawn example rows, so every number in the post is reproducible.
- **MSOA boundaries.** `data/msoa_boundaries.gpkg` holds all 7,264 MSOAs of England and Wales, simplified to 50 m.
  They were taken from the Athena table `geo.dim_msoa` (via an earlier knitr cache) so the post doesn't need AWS.
  To rebuild it, query `select msoa, msoa_polygon_wkt from geo.dim_msoa`, convert with `sf::st_as_sfc(crs = 4326)`,
  simplify with `st_simplify(dTolerance = 50)` in EPSG:27700 and write with `sf::st_write`.
- **No basemap.** CARTO tiles now need an API key (they render with a watermark), so the maps show the
  MSOAs on their own.
- **The data is England only.** `dataset` and `dataset_sample` hold the eight English regions outside London; there
  are no Welsh MSOAs.
- `dataset_sample` in the database is the exact sample the models are fitted on (an unseeded draw); don't redraw it
  without re-checking the post.

## Publishing from CI

A push to `main` that changes the dataset card publishes it (`.github/workflows/publish-dataset-card.yml`, using the
`HF_TOKEN` repository secret). The database is built locally and published by hand.

Data: Office for National Statistics, Census 2021 (RM140, RM102), Open Government Licence v3.0.
