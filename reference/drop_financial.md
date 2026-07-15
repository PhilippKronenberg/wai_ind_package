# Drop the financial market series from a dataset

Removes the financial market indicators (FINANSW, INDUSSW, SWISSMI, VIX)
from both the flows and stocks components.

## Usage

``` r
drop_financial(dat)
```

## Arguments

- dat:

  A list with components `flows` and `stocks` (named lists of `ts`
  objects).

## Value

A list with components `flows` and `stocks`.

## Examples

``` r
data(data_ch_dataset_test)
no_fin <- drop_financial(data_ch_dataset_test)
setdiff(names(data_ch_dataset_test$flows), names(no_fin$flows))
#> [1] "FINANSW" "INDUSSW" "SWISSMI"
```
