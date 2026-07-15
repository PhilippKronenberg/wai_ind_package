# In-sample fit metrics of the WAI and benchmarks against GDP

Regresses GDP growth on each (quarterly-aggregated) series at lags -4 to
0 and reports RMSE, MAE and R-squared, plus Diebold-Mariano p-values of
each series against the WAI.

## Usage

``` r
get_insample_fit_table(
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

A list of wide tables: `RMSE`, `MAE`, `R2`, `PVAL_RMSE`, `PVAL_MAE`.

## Examples

``` r
if (FALSE) { # \dontrun{
fit_tabs <- get_insample_fit_table("mean", "indicators", inputs = insample_inputs)
fit_tabs$RMSE
} # }
```
