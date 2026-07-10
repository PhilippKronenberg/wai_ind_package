# Placeholder smoke test until the ported functions get real tests (issue #17).
test_that("core model functions are defined", {
  expect_true(is.function(waiind:::hfdfm))
  expect_true(is.function(waiind:::run_sampling))
  expect_true(is.function(waiind:::cut_data))
  expect_true(is.function(waiind:::get_real_time_gdp_vintages))
  expect_true(is.function(waiind:::get_combined_cor_table))
})
