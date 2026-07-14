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
  mk_cor_tab <- function() {
    data.frame(
      Frequency = rep(c("YoY", "QoQ"), each = 2),
      Series = rep(c("WAI", "SECO-WWA"), 2),
      "Lag_-4" = runif(4, -1, 1), "Lag_-3" = runif(4, -1, 1),
      "Lag_-2" = runif(4, -1, 1), "Lag_-1" = runif(4, -1, 1),
      "Lag_0"  = runif(4, -1, 1),
      check.names = FALSE
    )
  }

  out <- create_combined_latex_table(list(mean = mk_cor_tab(), last = mk_cor_tab()))
  expect_type(out$table_tex, "character")
  expect_match(out$table_tex, "\\\\textbf\\{Mean\\}")
  expect_match(out$table_tex, "begin\\{tab")
})

test_that("print_evaluation_periods summarizes start/end quarters per series", {
  df <- data.frame(Series = c("WAI", "WAI", "AR", "AR"),
                   date = as.Date(c("2010-01-01", "2010-10-01", "2011-01-01", "2011-04-01")))

  expect_message(
    res <- print_evaluation_periods(df, "Series", "date", context_label = "example"),
    "Evaluation periods: example"
  )
  expect_equal(sort(res$Series), c("AR", "WAI"))
  expect_true(all(c("start_quarter", "end_quarter") %in% names(res)))
})

test_that("print_evaluation_periods returns NULL invisibly for empty data", {
  expect_null(print_evaluation_periods(data.frame(), "Series", "date", context_label = "x"))
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

test_that("create_rel_error_tables normalizes relative errors to the WAI baseline", {
  set.seed(3)
  combined_results <- expand.grid(
    target_vintage = seq(2020, 2020.75, 0.25),
    model = c("WAI", "AR"),
    method = "mean",
    lag_number = 0,
    GDP_type = "real",
    frequency = "QoQ",
    stringsAsFactors = FALSE
  )
  combined_results$error <- rnorm(nrow(combined_results))

  out <- create_rel_error_tables(combined_results, model_order = c("WAI", "AR"), lag_range = 0)
  expect_named(out, c("rel_rmse", "rel_mae"))
  expect_true("mean" %in% names(out$rel_rmse))

  wai_row <- out$rel_rmse$mean[out$rel_rmse$mean$Series == "WAI", ]
  expect_equal(unname(wai_row[["RMSE_rel_0"]]), "1.00")
})
