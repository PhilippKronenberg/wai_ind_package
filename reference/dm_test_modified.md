# Modified Diebold-Mariano test

Diebold-Mariano test of equal predictive accuracy with the
Harvey-Leybourne-Newbold (1997) small-sample correction.

## Usage

``` r
dm_test_modified(e1, e2, h = 1, power = 2, alternative = "greater")
```

## Arguments

- e1, e2:

  Numeric vectors of forecast errors of the two models.

- h:

  Forecast horizon.

- power:

  Loss function power (2 = squared error, 1 = absolute).

- alternative:

  One of `"greater"`, `"less"`, `"two.sided"`.

## Value

The p-value.

## Examples

``` r
set.seed(1)
dm_test_modified(rnorm(40) + 0.3, rnorm(40))
#> [1] 0.396157
```
