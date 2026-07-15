# Flag dates falling into the crisis periods

Marks dates inside the financial crisis (2008-07-07 to 2009-09-28) or
the Covid-19 crisis (2020-01-01 to 2021-12-28).

## Usage

``` r
is_crisis_period(date_vec)
```

## Arguments

- date_vec:

  `Date` vector (or coercible).

## Value

Logical vector.

## Examples

``` r
is_crisis_period(as.Date(c("2015-01-01", "2020-06-01")))
#> [1] FALSE  TRUE
```
