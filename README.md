# waiind — Swiss Weekly Activity Index

<!-- badges: start -->
<!-- badges: end -->

`waiind` estimates a **weekly activity index (WAI) for Switzerland** and
produces weekly GDP nowcasts and backcasts. The core is a Bayesian
**mixed-frequency dynamic factor model** estimated by Markov chain Monte
Carlo (Gibbs) sampling, which combines weekly, monthly and quarterly
indicator series into a single weekly activity factor that is coherent
with quarterly real GDP.

The package also provides:

- **real-time GDP vintage handling** — the Swiss real-time GDP vintage
  database ships with the package,
- **out-of-sample forecast evaluation** (expanding-window backcasts, an
  AR(1) benchmark, modified Diebold–Mariano tests),
- the **table and plot generators** used in the accompanying analysis.

> **Note:** the package is named `waiind` rather than `wai_ind_package`
> because R package names may only contain letters, numbers and dots.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("PhilippKronenberg/wai_ind_package")
```

The package requires R >= 4.1.

## Getting started

The curated indicator datasets ship with the package. A small (fast,
demonstration-sized) nowcast:

``` r
library(waiind)

data(data_ch_dataset_test)
target <- "ch.seco.gdp.real.gdp.ssa"   # quarterly real Swiss GDP

# small subset and short chain so this runs in seconds;
# real runs use the full dataset and length_sample = 10000
flows  <- lapply(data_ch_dataset_test$flows[c(target, "SWISSMI")],
                 stats::window, start = 2018)
stocks <- lapply(data_ch_dataset_test$stocks[1:2],
                 stats::window, start = 2018)

set.seed(1)
fit <- hfdfm(flows = flows, stocks = stocks, target = target,
             length_sample = 500, burn_in = 100)

fit$factor    # weekly activity factor (annualized growth)
fit$nowcast   # quarterly GDP nowcast
```

Real-time GDP vintages work out of the box:

``` r
vintages <- get_real_time_gdp_vintages("quarterly")
dat <- cut_data_real_time(data_ch_dataset_test, current_date = 2024.5,
                          GDP_gr_vintages = vintages)
```

## The analysis pipeline

The `analysis/` and `data-raw/` directories contain the scripts of the
full research workflow (run from the repository root; model fits are
written to a git-ignored `fits/` directory):

1. **`data-raw/1_data_prep_dataset.R`** — builds the harmonized
   indicator dataset from the raw sources (documented in
   `data-raw/README_data_prep_dataset.md`); its curated outputs ship as
   the package datasets `data_ch_dataset` / `data_ch_dataset_test`.
2. **`analysis/2_backcast.R`**, **`analysis/real_time_backcast.R`** —
   estimate the model across evaluation dates (pseudo and true real-time)
   via `run_wai_adj()` / `run_ar()`.
3. **`analysis/4_tables.R`** — parameter and metadata tables.
4. **`analysis/5_plots/`** — in-sample and out-of-sample evaluation:
   `plots_analytics.R` orchestrates `analytics_data.R`,
   `analytics_in_sample.R` and `analytics_out-of-sample.R`; the sample
   is configured via `wai_sample_config()` (see `_setup.R`).

## Data

| Object / file | What it is |
|---|---|
| `data_ch_dataset` | Harmonized Swiss indicator dataset (flows/stocks lists of `ts`) |
| `data_ch_dataset_test` | Test variant, includes the GDP target series |
| `inst/extdata/realtime_database_GDP.xlsx` | Real-time GDP vintage database (read by `get_real_time_gdp_vintages()`) |

The full `data_ch_dataset` deliberately ships *without* the GDP target
series — the workflow injects it at runtime from the real-time vintages.

## Development

``` r
devtools::document()   # regenerate NAMESPACE and man/ from roxygen
devtools::test()       # run the testthat suite (~25 s)
devtools::check()      # R CMD check (CI runs this on push/PR to main)
devtools::load_all()   # interactive development
```

## References

The methodology follows Eckert, Kronenberg, Mikosch and Neuwirth's
weekly activity index work (SECO WWA technical note, 2021). A reference
list of the related literature is kept in
[`analysis/benchmarks/literature.md`](analysis/benchmarks/literature.md).

## License

MIT — see `LICENSE`.
