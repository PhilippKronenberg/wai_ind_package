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

test_that("numeric vintage pickers respect their bounds", {
  vint <- make_synth_vintages()
  expect_equal(get_latest_numeric_vintage(vint, upper_bound = 2023.9), 2023.75)
  expect_equal(get_latest_numeric_vintage(vint, lower_bound = 2024, upper_bound = 2025), 2024.25)
  expect_error(get_latest_numeric_vintage(vint, upper_bound = 2020), "No valid vintages")

  # the next vintage extending the data beyond what 2023.25 covers
  expect_equal(get_next_extending_numeric_vintage(vint, as.Date("2023-06-30")), 2023.75)

  expect_equal(get_next_target_vintage(2023.5, c(2023.25, 2023.75, 2024.25)), 2023.75)
  expect_true(is.na(get_next_target_vintage(2025, c(2023.25, 2023.75))))
})

test_that("latest_fit_file honors the cutoff", {
  dir <- tempfile(); dir.create(dir); on.exit(unlink(dir, recursive = TRUE))
  mod <- list()
  for (d in c("2019.979", "2020.5", "2021.25")) {
    save(mod, file = file.path(dir, paste0("fit_", d, ".Rda")))
  }
  expect_match(latest_fit_file(dir, cutoff_decimal = 2020.9), "fit_2020.5.Rda")
  expect_match(latest_fit_file(dir, cutoff_decimal = 2022), "fit_2021.25.Rda")
  expect_error(latest_fit_file(dir, cutoff_decimal = 2019), "No fit file")
})

test_that("the shipped GDP vintage database reads and is well-formed", {
  # readxl warns about date cells in the header row it reads as numeric;
  # that is expected for this spreadsheet layout.
  vintages <- suppressWarnings(get_real_time_gdp_vintages("quarterly"))
  expect_s3_class(vintages$time, "Date")
  expect_gt(ncol(vintages), 50)
  vintage_names <- suppressWarnings(as.numeric(names(vintages)[-1]))
  expect_false(anyNA(vintage_names))
  expect_true(all(diff(vintage_names) > 0))
})
