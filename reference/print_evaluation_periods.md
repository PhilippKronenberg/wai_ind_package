# Print the evaluation period per series

Print the evaluation period per series

## Usage

``` r
print_evaluation_periods(
  data,
  series_col,
  date_col,
  context_label,
  frequency_label = NULL,
  method_label = NULL
)
```

## Arguments

- data:

  Data frame with a series and a date column.

- series_col, date_col:

  Column names.

- context_label:

  Label printed above the summary.

- frequency_label, method_label:

  Optional annotation columns.

## Value

Invisibly, the period summary data frame.

## Examples

``` r
df <- data.frame(Series = "WAI",
                 date = seq(as.Date("2010-01-01"), by = "quarter", length.out = 8))
print_evaluation_periods(df, "Series", "date", context_label = "example")
#> 
#> Evaluation periods: example
#> # A tibble: 1 × 3
#>   Series start_quarter end_quarter
#>   <chr>  <chr>         <chr>      
#> 1 WAI    2010 Q1       2011 Q4    
```
