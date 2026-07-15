# Convert decimal weekly dates to calendar dates

Converts decimal dates on the 48-week grid to `Date` values on the
project convention that weeks fall on the 7th, 14th, 21st and 28th of
each month.

## Usage

``` r
dec2week(x)
```

## Arguments

- x:

  Numeric vector of decimal dates (multiples of 1/48).

## Value

A `Date` vector.

## Examples

``` r
dec2week(2020 + (0:3)/48)
```
