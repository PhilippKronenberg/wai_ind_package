# Harmonized Swiss indicator dataset for the WAI model

The curated, model-ready dataset produced by the data preparation
pipeline in `data-raw/1_data_prep_dataset.R`. Mixed-frequency time
series are harmonized to the project conventions (weekly series use 48
observations per year) and transformed according to the variable
metadata in `data-raw/data_meta.xlsx`.

## Usage

``` r
data_ch_dataset
```

## Format

A list with two components, as expected by
[`hfdfm()`](https://philippkronenberg.github.io/wai_ind_package/reference/hfdfm.md):

- flows:

  Named list of 45 `ts` objects treated as flow variables. The quarterly
  GDP target series is *not* included; the analysis scripts add it at
  runtime from the real-time GDP vintage database that ships with the
  package at
  `system.file("extdata", "realtime_database_GDP.xlsx", package = "waiind")`
  (see
  [`get_real_time_gdp_vintages()`](https://philippkronenberg.github.io/wai_ind_package/reference/get_real_time_gdp_vintages.md)).

- stocks:

  Named list of 7 `ts` objects treated as stock variables.

## Source

Produced from SECO, KOF, FSO, SNB, Datastream and further high-frequency
sources; see `data-raw/README_data_prep_dataset.md` for the per-series
preprocessing choices.
