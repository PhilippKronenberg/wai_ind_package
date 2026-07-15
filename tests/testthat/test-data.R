test_that("shipped datasets have the structure hfdfm() expects", {
  expect_named(data_ch_dataset, c("flows", "stocks"))
  expect_named(data_ch_dataset_test, c("flows", "stocks"))
  # Only the test variant ships the GDP target; the full dataset gets it
  # injected at runtime from the real-time vintage database.
  expect_true("ch.seco.gdp.real.gdp.ssa" %in% names(data_ch_dataset_test$flows))
  expect_true(all(vapply(data_ch_dataset$flows, stats::is.ts, logical(1))))
})

test_that("real-time GDP vintage database ships with the package", {
  path <- system.file("extdata", "realtime_database_GDP.xlsx", package = "waiind")
  expect_true(nzchar(path))
  expect_true(file.exists(path))
})
