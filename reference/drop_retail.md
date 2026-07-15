# Drop the non-total retail trade series from a dataset

Removes the sectoral FSO retail trade series (NOGA 0803-0808), keeping
only the total retail series.

## Usage

``` r
drop_retail(dat)
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
total_retail_only <- drop_retail(data_ch_dataset_test)
length(total_retail_only$flows)
#> [1] 28
```
