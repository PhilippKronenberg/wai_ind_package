test_that("run_ar returns the fit and only saves when asked", {
  dat <- make_synth_dat()

  fit <- run_ar(flows = dat$flows, stocks = dat$stocks, target = "gdp",
                date = 2023.5, dataset_used = "synth")
  expect_named(fit, c("nowcast", "nowcast_var"))
  expect_length(fit$nowcast, 1)
  expect_gt(as.numeric(fit$nowcast_var), 0)

  # nothing was written anywhere without output_dir
  expect_false(dir.exists("fits"))

  out_dir <- tempfile(); on.exit(unlink(out_dir, recursive = TRUE))
  run_ar(flows = dat$flows, stocks = dat$stocks, target = "gdp",
         date = 2023.5, dataset_used = "synth", output_dir = out_dir)
  expect_true(file.exists(file.path(out_dir, "synth", "fit_2023.5.Rda")))
})

test_that("retrieve_nowcast and retrieve_nowcast_var dispatch on model type", {
  fit <- list(nowcast = stats::ts(c(0.1, 0.7), start = c(2024, 1), frequency = 4),
              nowcast_var = stats::ts(c(0.02, 0.05), start = c(2024, 1), frequency = 4))
  expect_equal(as.numeric(retrieve_nowcast(fit, "wai")), 0.7)
  expect_equal(as.numeric(retrieve_nowcast_var(fit, "wai")), 0.05)
  expect_identical(retrieve_nowcast(fit, "ar"), fit$nowcast)
  expect_identical(retrieve_nowcast_var(fit, "ar"), fit$nowcast_var)
})
