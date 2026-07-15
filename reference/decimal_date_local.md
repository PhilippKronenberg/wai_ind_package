# Convert dates to decimal years (day-of-year convention)

Converts dates to decimal years as `year + (day_of_year - 1)/365`, the
convention used throughout the WAI vintage handling. Unlike
[`lubridate::decimal_date()`](https://lubridate.tidyverse.org/reference/decimal_date.html),
this does not account for leap years.

## Usage

``` r
decimal_date_local(x)
```

## Arguments

- x:

  `Date` vector (or coercible).

## Value

Numeric vector of decimal years.

## Examples

``` r
decimal_date_local(as.Date("2020-03-07"))
#> [1] 2020.181
```
