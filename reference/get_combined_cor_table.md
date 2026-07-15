# Cross correlations of the WAI and benchmarks with GDP

Computes lagged correlations of the WAI (and either the benchmark
indicators or the WAI model variants) with GDP growth, for YoY and QoQ
frequencies, at lags -4 to 0.

## Usage

``` r
get_combined_cor_table(
  method = c("mean", "last", "last_month"),
  analysis_set = c("wai_versions", "indicators"),
  inputs
)
```

## Arguments

- method:

  Quarterly aggregation method: `"mean"`, `"last"`, or `"last_month"`.

- analysis_set:

  `"wai_versions"` to compare WAI model variants, or `"indicators"` to
  compare against the benchmark indicators.

- inputs:

  Named list of the input data objects (formerly free variables in the
  calling script). Always required: `tab_gr`, `tab_gr_lv`,
  `x_hist_gr_yoy`, `x_hist_gr_ann`. For `analysis_set = "indicators"`
  additionally: `tab_wai_yoy`, `wwa_gr_df`, `wwa_gr_df_qoq`,
  `fcurve_gr_df`, `tab_kss`, `tab_snb`, `tab_baro`. For
  `"wai_versions"`: `result_wai`, `result_wai_no_sv`,
  `result_wai_only_monthly_no_sv`, `result_wai_no_hf`,
  `result_wai_no_financial`.

## Value

A data frame of correlations by `Frequency`, `Series` and lag.

## Examples

``` r
if (FALSE) { # \dontrun{
# inputs is the bundle of data objects built by analysis/5_plots scripts:
cor_tab <- get_combined_cor_table("mean", "indicators", inputs = insample_inputs)
} # }
```
