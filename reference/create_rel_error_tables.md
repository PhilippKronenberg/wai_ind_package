# Relative out-of-sample error tables across vintages

Aggregates out-of-sample errors per target vintage, computes relative
RMSE/MAE against the WAI with Diebold-Mariano significance stars, and
returns per-method wide tables.

## Usage

``` r
create_rel_error_tables(combined_results, model_order, lag_range = -4:0)
```

## Arguments

- combined_results:

  Long data frame of out-of-sample errors with columns `target_vintage`,
  `model`, `method`, `lag_number`, `GDP_type`, `frequency`, `error`.

- model_order:

  Character vector of models in display order.

- lag_range:

  Integer lags covered.

## Value

A list with `rel_rmse` and `rel_mae` (per-method lists).

## Examples

``` r
if (FALSE) { # \dontrun{
# combined_results is the long out-of-sample error table built by
# analysis/5_plots/analytics_out-of-sample.R:
rel <- create_rel_error_tables(combined_results, model_order = c("WAI", "AR"))
} # }
```
