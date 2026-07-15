# Drop all weekly series from a dataset

Removes every weekly series (frequency 48) from the dataset, keeping
only monthly and quarterly series.

## Usage

``` r
drop_weekly(dat)
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
no_weekly <- drop_weekly(data_ch_dataset_test)
length(no_weekly$flows)
#> [1] 4
```
