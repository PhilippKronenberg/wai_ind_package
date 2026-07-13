test_that("week2mon aggregates weekly series to monthly sums", {
  dat <- make_synth_dat()
  monthly <- week2mon(dat)

  expect_equal(frequency(monthly$flows$w1), 12)
  expect_equal(frequency(monthly$stocks$s1), 12)
  # non-weekly series pass through unchanged
  expect_identical(monthly$flows$gdp, dat$flows$gdp)
  expect_identical(monthly$flows$m1, dat$flows$m1)
  # first month aggregates the first four weekly observations
  expect_equal(as.numeric(monthly$flows$w1[1]), sum(dat$flows$w1[1:4]), tolerance = 1e-12)
})

test_that("drop_weekly removes exactly the weekly series", {
  dat <- make_synth_dat()
  out <- drop_weekly(dat)
  expect_setequal(names(out$flows), c("gdp", "m1"))
  expect_length(out$stocks, 0)
})

test_that("drop_financial and drop_retail operate on their argument", {
  dat <- make_synth_dat()
  dat$flows$FINANSW <- dat$flows$w1
  dat$stocks$VIX <- dat$stocks$s1
  out <- drop_financial(dat)
  expect_false("FINANSW" %in% names(out$flows))
  expect_false("VIX" %in% names(out$stocks))
  expect_true("w1" %in% names(out$flows))

  dat2 <- make_synth_dat()
  dat2$flows[["ch.fso.rtt.ind.r.noga0803.sa"]] <- dat2$flows$w1
  out2 <- drop_retail(dat2)
  expect_false("ch.fso.rtt.ind.r.noga0803.sa" %in% names(out2$flows))
})

test_that("dec2week maps the 48-week grid onto 7/14/21/28 calendar days", {
  d <- dec2week(2020 + (0:47) / 48)
  expect_s3_class(d, "Date")
  expect_true(all(format(d, "%d") %in% c("07", "14", "21", "28")))
  expect_equal(format(d[1], "%Y-%m-%d"), "2020-01-07")
  expect_equal(format(d[48], "%Y-%m-%d"), "2020-12-28")
  # year boundary
  expect_equal(format(dec2week(2021), "%Y-%m-%d"), "2021-01-07")
})

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
