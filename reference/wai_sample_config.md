# Build the sample configuration for an analytics run

Creates (and returns) the configuration object used by the analytics
scripts: the sample identifier and end date, the output directories
(created if missing), and the sample-end cutoffs in decimal time. This
replaces the former `initialize_plots_insample_context()`, which wrote
these values directly into the calling environment.

## Usage

``` r
wai_sample_config(
  sample_id = "sample_2025Q4",
  sample_end_date = as.Date("2026-03-07"),
  output_root = file.path("analysis", "outputs", "plots_insample", sample_id),
  fit_root = "fits",
  fit_rt_dir = file.path(fit_root, "full_RT")
)
```

## Arguments

- sample_id:

  Character label for the run, e.g. `"sample_2025Q4"`.

- sample_end_date:

  Sample end as `Date` (or coercible).

- output_root:

  Directory under which `figures/`, `tables/` and `results/`
  subdirectories are created.

- fit_root:

  Root directory of the saved model fits.

- fit_rt_dir:

  Directory of the real-time fits.

## Value

A list with elements `sample_id`, `sample_end_date`, `output_root`,
`fit_root`, `fit_rt_dir`, `figures_dir`, `tables_dir`, `results_dir`,
`sample_end_decimal` and `sample_end_fit_decimal`.

## Examples

``` r
cfg <- wai_sample_config(
  sample_id = "sample_2025Q4",
  sample_end_date = "2026-03-07",
  output_root = file.path(tempdir(), "plots_insample")
)
cfg$sample_end_decimal
#> [1] 2026.186
```
