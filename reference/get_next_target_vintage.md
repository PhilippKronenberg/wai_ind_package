# First target vintage after a prediction vintage

First target vintage after a prediction vintage

## Usage

``` r
get_next_target_vintage(pred_vintage, target_vintages)
```

## Arguments

- pred_vintage:

  Numeric decimal date of the prediction vintage.

- target_vintages:

  Numeric vector of available target vintages.

## Value

The smallest target vintage strictly after `pred_vintage`, or `NA` if
none exists.

## Examples

``` r
get_next_target_vintage(2020.5, c(2020.25, 2020.75, 2021))
#> [1] 2020.75
```
