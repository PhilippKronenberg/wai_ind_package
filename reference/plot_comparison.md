# Plot the WAI against a comparison indicator and GDP

Plot the WAI against a comparison indicator and GDP

## Usage

``` r
plot_comparison(
  tab_wai,
  comparison_df,
  comparison_label,
  crises,
  hist_tab_gdp,
  sample_end_date,
  plot_title = NULL,
  ylim_fixed = NULL
)
```

## Arguments

- tab_wai:

  WAI data frame (`time`, `value`).

- comparison_df:

  Comparison indicator data frame (`time`, `value`).

- comparison_label:

  Label for the comparison series.

- crises:

  Data frame with `Peak` and `Trough` dates for shading.

- hist_tab_gdp:

  GDP history in the legacy layout (`value` = Date, `y` = GDP value).

- sample_end_date:

  Sample end (`Date`), e.g. `wai_sample_config()$sample_end_date`.

- plot_title:

  Optional plot title.

- ylim_fixed:

  Optional fixed y-axis limits, length-2 numeric.

## Value

A `ggplot` object.

## Examples

``` r
wk <- seq(as.Date("2005-01-07"), by = "week", length.out = 900)
wai <- data.frame(time = wk, value = rnorm(900))
cmp <- data.frame(time = wk, value = rnorm(900))
crises <- data.frame(Peak = as.Date("2008-07-07"), Trough = as.Date("2009-09-28"))
gdp <- data.frame(value = seq(as.Date("2005-01-01"), by = "quarter", length.out = 60),
                  y = rnorm(60))
plot_comparison(wai, cmp, "Benchmark", crises, gdp,
                sample_end_date = as.Date("2021-12-31"))
#> `geom_line()`: Each group consists of only one observation.
#> ℹ Do you need to adjust the group aesthetic?
```
