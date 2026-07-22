test_that("cut_data applies the publication-lag conventions per frequency", {
  dat <- make_synth_dat()
  current <- 2023.5
  cut <- cut_data(dat, current_date = current)

  # weekly: observed one week later
  expect_lte(as.numeric(tail(time(cut$flows$w1), 1)), current - 1 / 48)
  # monthly: first week of the next month
  expect_lte(as.numeric(tail(time(cut$flows$m1), 1)), current - 4 / 48)
  # quarterly target: ~10 weeks after quarter end
  expect_lte(as.numeric(tail(time(cut$flows$gdp), 1)), current - 1 / 4 - 8 / 48)
  # too-short series are dropped
  expect_true(all(sapply(c(cut$flows, cut$stocks), length) >= 24))
})

test_that("select_most_recent_GDP_vintage picks the newest available vintage", {
  vint <- make_synth_vintages()
  expect_identical(select_most_recent_GDP_vintage(2023.5, vint), vint[["2023.25"]])
  expect_identical(select_most_recent_GDP_vintage(2024.9, vint), vint[["2024.25"]])
  expect_error(select_most_recent_GDP_vintage(2020.0, vint), "No GDP vintage")
})

test_that("cut_data_real_time substitutes the target with the right vintage", {
  dat <- make_synth_dat()
  vint <- make_synth_vintages()
  cut <- cut_data_real_time(dat, current_date = 2023.9, GDP_gr_vintages = vint)

  expect_equal(frequency(cut$flows$gdp), 4)
  expect_equal(as.numeric(cut$flows$gdp),
               as.numeric(zoo::na.trim(stats::ts(vint[["2023.75"]], start = c(1990, 1), frequency = 4))))
})

test_that("the shipped GDP vintage database reads and is well-formed", {
  vintages <- get_real_time_gdp_vintages("quarterly")
  expect_s3_class(vintages$time, "Date")
  expect_gt(ncol(vintages), 50)
  vintage_names <- suppressWarnings(as.numeric(names(vintages)[-1]))
  expect_false(anyNA(vintage_names))
  expect_true(all(diff(vintage_names) > 0))
})
