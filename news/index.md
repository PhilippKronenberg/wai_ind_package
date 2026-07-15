# Changelog

## waiind 0.0.0.9000

First functional version of the package, converting the WAI research
code into a proper R package
([\#9](https://github.com/PhilippKronenberg/wai_ind_package/issues/9)-#19):

### New features

- [`hfdfm()`](https://philippkronenberg.github.io/wai_ind_package/reference/hfdfm.md)
  estimates the Bayesian mixed-frequency dynamic factor model behind the
  Swiss Weekly Activity Index, with exported data-preparation helpers
  [`create_inventory()`](https://philippkronenberg.github.io/wai_ind_package/reference/create_inventory.md)
  and
  [`prepare_data()`](https://philippkronenberg.github.io/wai_ind_package/reference/prepare_data.md)
  ([\#12](https://github.com/PhilippKronenberg/wai_ind_package/issues/12)).
- Backcasting and real-time vintage tooling:
  [`run_wai_adj()`](https://philippkronenberg.github.io/wai_ind_package/reference/run_wai_adj.md),
  [`run_ar()`](https://philippkronenberg.github.io/wai_ind_package/reference/run_ar.md),
  [`cut_data()`](https://philippkronenberg.github.io/wai_ind_package/reference/cut_data.md),
  [`cut_data_real_time()`](https://philippkronenberg.github.io/wai_ind_package/reference/cut_data_real_time.md),
  [`get_real_time_gdp_vintages()`](https://philippkronenberg.github.io/wai_ind_package/reference/get_real_time_gdp_vintages.md)
  (reads the vintage database shipped in `inst/extdata/`), frequency
  converters
  [`week2mon()`](https://philippkronenberg.github.io/wai_ind_package/reference/week2mon.md),
  [`daily2weekly()`](https://philippkronenberg.github.io/wai_ind_package/reference/daily2weekly.md),
  [`dec2week()`](https://philippkronenberg.github.io/wai_ind_package/reference/dec2week.md)
  ([\#13](https://github.com/PhilippKronenberg/wai_ind_package/issues/13),
  [\#11](https://github.com/PhilippKronenberg/wai_ind_package/issues/11)).
- In-sample and out-of-sample evaluation suite:
  [`get_combined_cor_table()`](https://philippkronenberg.github.io/wai_ind_package/reference/get_combined_cor_table.md),
  [`get_insample_fit_table()`](https://philippkronenberg.github.io/wai_ind_package/reference/get_insample_fit_table.md),
  [`get_insample_error_details()`](https://philippkronenberg.github.io/wai_ind_package/reference/get_insample_error_details.md),
  the relative-error/LaTeX table pipeline,
  [`dm_test_modified()`](https://philippkronenberg.github.io/wai_ind_package/reference/dm_test_modified.md),
  and
  [`wai_sample_config()`](https://philippkronenberg.github.io/wai_ind_package/reference/wai_sample_config.md)
  for configuring analytics runs
  ([\#14](https://github.com/PhilippKronenberg/wai_ind_package/issues/14)).
- Shipped datasets `data_ch_dataset` and `data_ch_dataset_test`
  ([\#11](https://github.com/PhilippKronenberg/wai_ind_package/issues/11)).

### Bug fixes (relative to the pre-package scripts)

- [`run_wai_adj()`](https://philippkronenberg.github.io/wai_ind_package/reference/run_wai_adj.md)
  no longer passes a silently ignored `extend` argument to the sampler
  ([\#13](https://github.com/PhilippKronenberg/wai_ind_package/issues/13)).
- [`drop_weekly()`](https://philippkronenberg.github.io/wai_ind_package/reference/drop_weekly.md),
  [`drop_financial()`](https://philippkronenberg.github.io/wai_ind_package/reference/drop_financial.md)
  and
  [`drop_retail()`](https://philippkronenberg.github.io/wai_ind_package/reference/drop_retail.md)
  now operate on their argument instead of a global variable named `dat`
  ([\#13](https://github.com/PhilippKronenberg/wai_ind_package/issues/13)).
- [`save_result_output()`](https://philippkronenberg.github.io/wai_ind_package/reference/save_result_output.md)
  now finds the object to save in the caller’s environment
  ([\#14](https://github.com/PhilippKronenberg/wai_ind_package/issues/14)).

### Breaking changes (relative to the pre-package scripts)

- [`run_ar()`](https://philippkronenberg.github.io/wai_ind_package/reference/run_ar.md)/[`run_wai_adj()`](https://philippkronenberg.github.io/wai_ind_package/reference/run_wai_adj.md)
  return the fit and only write to disk when `output_dir` is given
  ([\#13](https://github.com/PhilippKronenberg/wai_ind_package/issues/13)).
- The in-sample table builders require an explicit `inputs` list instead
  of reading objects from the calling environment; output-path helpers
  take their directory as an argument
  ([\#14](https://github.com/PhilippKronenberg/wai_ind_package/issues/14)).
- `initialize_plots_insample_context()` and `load_analytics_packages()`
  were removed; use
  [`wai_sample_config()`](https://philippkronenberg.github.io/wai_ind_package/reference/wai_sample_config.md)
  and proper imports
  ([\#14](https://github.com/PhilippKronenberg/wai_ind_package/issues/14),
  [\#15](https://github.com/PhilippKronenberg/wai_ind_package/issues/15)).
