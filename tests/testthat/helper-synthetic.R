# Shared synthetic fixtures for the test suite.

# A small mixed-frequency dataset in the flows/stocks layout the model expects:
# quarterly target + monthly + weekly flows, one weekly stock.
make_synth_dat <- function(seed = 42) {
  set.seed(seed)
  list(
    flows = list(
      gdp = stats::ts(rnorm(40, 0.4, 0.5), start = c(2014, 1), frequency = 4),
      m1  = stats::ts(rnorm(120), start = c(2014, 1), frequency = 12),
      w1  = stats::ts(rnorm(480), start = c(2014, 1), frequency = 48)
    ),
    stocks = list(
      s1 = stats::ts(rnorm(480), start = c(2014, 1), frequency = 48)
    )
  )
}

# A synthetic vintage table in the layout of get_real_time_gdp_vintages():
# a time column plus one numeric column per (decimal-named) vintage.
make_synth_vintages <- function() {
  df <- data.frame(time = seq(as.Date("2014-01-01"), by = "quarter", length.out = 40))
  df[["2023.25"]] <- c(rnorm(36), rep(NA, 4))
  df[["2023.75"]] <- c(rnorm(38), rep(NA, 2))
  df[["2024.25"]] <- rnorm(40)
  df
}

# The inputs bundle for the in-sample analytics table builders.
make_synth_inputs <- function(seed = 99) {
  set.seed(seed)
  wk <- seq(as.Date("2010-01-07"), as.Date("2024-12-28"), by = "week")
  mkdf <- function() data.frame(time = wk, value = cumsum(rnorm(length(wk), 0, 0.3)))
  list(
    tab_wai_yoy = data.frame(time = wk, name = "mean", value = cumsum(rnorm(length(wk), 0, 0.3))),
    wwa_gr_df = mkdf(), wwa_gr_df_qoq = mkdf(), fcurve_gr_df = mkdf(),
    tab_kss = mkdf(), tab_snb = mkdf(), tab_baro = mkdf(),
    tab_gr = data.frame(time = wk, name = "mean", value = rnorm(length(wk), 0.5, 1)),
    tab_gr_lv = data.frame(time = wk, value = 100 * cumprod(1 + rnorm(length(wk), 0, 0.002))),
    x_hist_gr_yoy = stats::ts(rnorm(100, 1.5, 1), start = c(1991, 1), frequency = 4),
    x_hist_gr_ann = stats::ts(rnorm(104, 0.4, 0.5), start = c(1990, 1), frequency = 4)
  )
}
