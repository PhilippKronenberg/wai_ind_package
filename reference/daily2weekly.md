# Aggregate a daily series to the 48-week grid

Averages a daily `zoo` series into the project's 48-periods-per-year
weekly grid.

## Usage

``` r
daily2weekly(x)
```

## Arguments

- x:

  Daily series (`zoo` indexed by `Date`).

## Value

A `ts` with frequency 48; weeks without observations are `NA`.

## Examples

``` r
daily <- zoo::zoo(rnorm(120),
                  order.by = seq(as.Date("2024-01-01"), by = "day", length.out = 120))
weekly <- daily2weekly(daily)
stats::frequency(weekly)
#> [1] 48
```
