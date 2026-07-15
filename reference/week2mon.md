# Aggregate weekly series in a dataset to monthly frequency

Aggregates every weekly series (frequency 48) in the dataset to monthly
sums; series of other frequencies are returned unchanged.

## Usage

``` r
week2mon(dat)
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
monthly <- week2mon(data_ch_dataset_test)
stats::frequency(monthly$flows[[1]])
#> [1] 12
```
