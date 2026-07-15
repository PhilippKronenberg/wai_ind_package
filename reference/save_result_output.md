# Save a result object to the results directory

Save a result object to the results directory

## Usage

``` r
save_result_output(object, filename, results_dir)
```

## Arguments

- object:

  Object to save (stored under its own name).

- filename:

  File name (without directory).

- results_dir:

  Directory to write into (e.g. `wai_sample_config()$results_dir`).

## Value

Invisibly, the full path written.

## Examples

``` r
dir <- tempfile(); dir.create(dir)
results_example <- data.frame(x = 1:3)
save_result_output(results_example, "results_example.rda", results_dir = dir)
load(file.path(dir, "results_example.rda"))
```
