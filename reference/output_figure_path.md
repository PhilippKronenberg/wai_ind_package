# Build the full path for a figure output file

Build the full path for a figure output file

## Usage

``` r
output_figure_path(filename, figures_dir)
```

## Arguments

- filename:

  File name (without directory).

- figures_dir:

  Directory the figure belongs in (e.g.
  `wai_sample_config()$figures_dir`).

## Value

The full file path.

## Examples

``` r
output_figure_path("history.pdf", figures_dir = "analysis/outputs/figures")
#> [1] "analysis/outputs/figures/history.pdf"
```
