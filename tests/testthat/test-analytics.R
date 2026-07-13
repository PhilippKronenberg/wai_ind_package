test_that("dm_test_modified reproduces its documented formula exactly", {
  set.seed(11); e1 <- rnorm(60) + 0.3
  set.seed(12); e2 <- rnorm(60)

  for (pw in c(1, 2)) {
    d <- abs(e1)^pw - abs(e2)^pw
    n <- length(d)
    stat <- (mean(d) / sqrt(var(d) / n)) / sqrt((n - 1) / n) # HLN factor at h = 1
    expect_equal(dm_test_modified(e1, e2, h = 1, power = pw, alternative = "greater"),
                 1 - pnorm(stat), tolerance = 1e-12)
    expect_equal(dm_test_modified(e1, e2, h = 1, power = pw, alternative = "two.sided"),
                 2 * min(pnorm(stat), 1 - pnorm(stat)), tolerance = 1e-12)
  }
})

test_that("dm_test_modified is consistent with forecast::dm.test", {
  # Not identical by construction: this implementation uses the normal
  # approximation and var(); forecast::dm.test uses the t-distribution and
  # an autocovariance-based long-run variance. They must agree closely.
  skip_if_not_installed("forecast")
  set.seed(11); e1 <- rnorm(60) + 0.3
  set.seed(12); e2 <- rnorm(60)

  for (pw in c(1, 2)) {
    ours <- dm_test_modified(e1, e2, h = 1, power = pw, alternative = "greater")
    ref <- forecast::dm.test(e1, e2, alternative = "greater", h = 1, power = pw)
    expect_equal(ours, unname(ref$p.value), tolerance = 2e-2)
  }
})

test_that("in-sample fit tables and relative errors are consistent", {
  inputs <- make_synth_inputs()

  fit_tabs <- suppressMessages(
    get_insample_fit_table("mean", "indicators", inputs = inputs)
  )
  expect_named(fit_tabs, c("RMSE", "MAE", "R2", "PVAL_RMSE", "PVAL_MAE"))
  expect_setequal(as.character(unique(fit_tabs$RMSE$Series)),
                  c("WAI", "SECO-WWA", "F-CURVE", "SECO-SEC", "SNB-BCI", "KOF-BARO"))
  expect_setequal(as.character(unique(fit_tabs$RMSE$Frequency)), c("QoQ", "YoY"))

  rel <- calculate_relative_errors(fit_tabs)
  # WAI normalizes to itself: all relative RMSE entries are 1.00
  wai_rows <- rel$RMSE_relative[rel$RMSE_relative$Series == "WAI", -(1:2)]
  expect_true(all(unlist(wai_rows) == "1.00"))

  ann <- annotate_relative_errors(rel$RMSE_relative, fit_tabs$PVAL_RMSE, "RMSE")
  expect_true(all(grepl("^[0-9.]+\\*{0,3}$", unlist(ann[, -(1:2)]))))
})

test_that("get_insample_fit_table validates its inputs", {
  expect_error(
    get_insample_fit_table("mean", "indicators", inputs = list(tab_gr = 1)),
    "Missing required inputs"
  )
})

test_that("create_combined_latex_table produces LaTeX with method sections", {
  inputs <- make_synth_inputs()
  cor_tab <- suppressMessages(
    get_combined_cor_table("mean", "indicators", inputs = inputs)
  )
  expect_true(all(c("Frequency", "Series", "Lag_0") %in% names(cor_tab)))
  expect_true(all(abs(na.omit(unlist(cor_tab[, -(1:2)]))) <= 1))

  out <- create_combined_latex_table(list(mean = cor_tab, last = cor_tab))
  expect_type(out$table_tex, "character")
  expect_match(out$table_tex, "\\\\textbf\\{Mean\\}")
  expect_match(out$table_tex, "begin\\{tab")
})

test_that("error details feed the crisis summary tables", {
  inputs <- make_synth_inputs()
  details <- suppressMessages(
    get_insample_error_details("mean", "indicators", inputs = inputs)
  )
  expect_setequal(names(details),
                  c("Series", "observation_date", "error", "model", "method", "lag_number", "frequency"))

  tabs <- create_error_summary_tables(
    details,
    model_order = c("WAI", "SECO-WWA", "KOF-BARO"),
    date_col = "observation_date"
  )
  expect_named(tabs, c("rel_rmse", "rel_mae", "abs_rmse", "abs_mae", "summary"))
  expect_true("mean" %in% names(tabs$rel_rmse))
})

test_that("wai_sample_config derives dirs and decimals", {
  root <- tempfile(); on.exit(unlink(root, recursive = TRUE))
  cfg <- wai_sample_config(sample_id = "s1",
                           sample_end_date = "2026-03-07",
                           output_root = root)
  expect_true(dir.exists(cfg$figures_dir))
  expect_true(dir.exists(cfg$tables_dir))
  expect_true(dir.exists(cfg$results_dir))
  expect_equal(cfg$sample_end_decimal, round(2026 + 2 / 12 + 7 / 365, 3))
  expect_equal(cfg$sample_end_fit_decimal, round(2026 + 47 / 48, 3))
})
