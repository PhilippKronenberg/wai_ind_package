test_that("decimal_date_local follows the day-of-year convention", {
  expect_equal(decimal_date_local(as.Date("2020-01-01")), 2020)
  expect_equal(decimal_date_local(as.Date("2021-12-31")), 2021 + 364 / 365)
})

test_that("is_crisis_period flags the two crisis windows", {
  dates <- as.Date(c("2008-09-15", "2015-06-01", "2020-04-01", "2022-01-01"))
  expect_equal(is_crisis_period(dates), c(TRUE, FALSE, TRUE, FALSE))
})

test_that("daily2weekly averages onto the 48-period grid", {
  daily <- zoo::zoo(rep(2, 96), order.by = seq(as.Date("2022-01-01"), by = "day", length.out = 96))
  weekly <- daily2weekly(daily)
  expect_equal(frequency(weekly), 48)
  expect_true(all(abs(na.omit(as.numeric(weekly)) - 2) < 1e-12))
})

test_that("aggregate_predictor_to_quarterly aggregates by the requested method", {
  df <- data.frame(time = seq(as.Date("2015-01-01"), by = "month", length.out = 12),
                   value = rep(1:4, each = 3))

  by_mean <- aggregate_predictor_to_quarterly(df, method = "mean")
  expect_equal(nrow(by_mean), 4)
  expect_equal(by_mean$value, 1:4)

  by_last <- aggregate_predictor_to_quarterly(df, cut_off_month_pos = 3, method = "last")
  expect_equal(by_last$value, 1:4)

  expect_error(aggregate_predictor_to_quarterly(df, method = "bogus"), "Unknown method")
})

test_that("aggregate_predictor_to_quarterly dispatches on an 'AR'-named argument", {
  AR_df <- data.frame(time = as.Date(c("2020-01-01", "2020-04-01")), value = c(1, 2))
  out <- aggregate_predictor_to_quarterly(AR_df)
  expect_true("yearqtr" %in% names(out))
  expect_identical(out$value, AR_df$value)
})

test_that("get_next_target_vintage finds the first later vintage", {
  expect_equal(get_next_target_vintage(2023.5, c(2023.25, 2023.75, 2024.25)), 2023.75)
  expect_true(is.na(get_next_target_vintage(2025, c(2023.25, 2023.75))))
})
