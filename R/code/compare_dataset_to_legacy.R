project_dir <- "C:/Users/kphilipp/GitHub/wai_ind/"
setwd(project_dir)

load("code/Rda/data_ch_dataset.Rda")
dat_new <- dat
load("code/Rda/data_ch.Rda")
dat_old <- dat

flatten_dat <- function(x) {
  c(x[["flows"]], x[["stocks"]])
}

align_overlap <- function(x_old, x_new) {
  t_old <- time(x_old)
  t_new <- time(x_new)
  overlap <- intersect(t_old, t_new)
  overlap <- overlap[order(overlap)]
  if (!length(overlap)) {
    return(NULL)
  }
  old_vals <- as.numeric(x_old[match(overlap, t_old)])
  new_vals <- as.numeric(x_new[match(overlap, t_new)])
  keep <- !(is.na(old_vals) | is.na(new_vals))
  if (!any(keep)) {
    return(NULL)
  }
  list(
    time = overlap[keep],
    old = old_vals[keep],
    new = new_vals[keep]
  )
}

classify_series <- function(old_vals, new_vals) {
  diff_vals <- new_vals - old_vals
  abs_diff <- abs(diff_vals)
  max_abs_diff <- max(abs_diff)
  mean_abs_diff <- mean(abs_diff)
  rmse <- sqrt(mean(diff_vals^2))
  corr <- if (length(old_vals) > 1) suppressWarnings(stats::cor(old_vals, new_vals)) else NA_real_

  if (max_abs_diff < 1e-12) {
    status <- "identical"
  } else if (!is.na(corr) && corr >= 0.999 && rmse <= 0.05 * stats::sd(old_vals)) {
    status <- "similar"
  } else {
    status <- "different"
  }

  c(
    status = status,
    max_abs_diff = max_abs_diff,
    mean_abs_diff = mean_abs_diff,
    rmse = rmse,
    correlation = corr
  )
}

old_all <- flatten_dat(dat_old)
new_all <- flatten_dat(dat_new)
common <- intersect(names(old_all), names(new_all))

comparison <- lapply(common, function(nm) {
  overlap <- align_overlap(old_all[[nm]], new_all[[nm]])
  if (is.null(overlap)) {
    data.frame(
      series = nm,
      status = "no_overlap",
      overlap_points = 0L,
      overlap_start = as.Date(NA),
      overlap_end = as.Date(NA),
      max_abs_diff = NA_real_,
      mean_abs_diff = NA_real_,
      rmse = NA_real_,
      correlation = NA_real_,
      stringsAsFactors = FALSE
    )
  } else {
    metrics <- classify_series(overlap$old, overlap$new)
    freq <- frequency(old_all[[nm]])
    overlap_dates <- if (freq == 48) {
      year <- floor(overlap$time)
      as.Date(sprintf("%04d-01-01", year)) + round((overlap$time - year) * 365)
    } else if (freq == 12) {
      year <- floor(overlap$time)
      month <- round((overlap$time - year) * 12) + 1
      as.Date(sprintf("%04d-%02d-01", year, month))
    } else if (freq == 4) {
      year <- floor(overlap$time)
      quarter <- round((overlap$time - year) * 4) + 1
      month <- 1 + (quarter - 1) * 3
      as.Date(sprintf("%04d-%02d-01", year, month))
    } else {
      as.Date(NA)
    }
    data.frame(
      series = nm,
      status = unname(metrics["status"]),
      overlap_points = length(overlap$time),
      overlap_start = min(overlap_dates, na.rm = TRUE),
      overlap_end = max(overlap_dates, na.rm = TRUE),
      max_abs_diff = as.numeric(metrics["max_abs_diff"]),
      mean_abs_diff = as.numeric(metrics["mean_abs_diff"]),
      rmse = as.numeric(metrics["rmse"]),
      correlation = as.numeric(metrics["correlation"]),
      stringsAsFactors = FALSE
    )
  }
})

comparison_df <- do.call(rbind, comparison)
comparison_df <- comparison_df[order(comparison_df$status, comparison_df$series), ]

utils::write.csv(comparison_df, "code/out/data_ch_dataset_vs_legacy.csv", row.names = FALSE)

cat("Common series:", length(common), "\n")
print(table(comparison_df$status, useNA = "ifany"))
cat("\nTop deviations:\n")
print(utils::head(comparison_df[order(-comparison_df$max_abs_diff, comparison_df$series), ], 15))
