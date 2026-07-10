# -----------------------------------------------------------------------------
# analytics_functions.R
# -----------------------------------------------------------------------------
# Purpose:
# This file contains the shared helper functions used by the analytics plotting
# workflow. It centralizes package loading, sample/output initialization,
# plotting utilities, correlation and error-table helpers, and vintage
# aggregation functions that are reused by the data, in-sample, and
# out-of-sample scripts.
#
# How to use:
# Source this file before running any of the other analytics scripts. It does
# not create output by itself; instead it provides the common functions needed
# by the analysis entrypoints.
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Setup Helpers
# -----------------------------------------------------------------------------
# These functions load packages and initialize the sample-specific paths and
# output folders used across the analytics workflow.

load_analytics_packages <- function() {
  Sys.setlocale("LC_TIME", "English")
  library(ggplot2)
  library(tibble)
  library(tidyr)
  library(dplyr)
  has_ggsci <<- requireNamespace("ggsci", quietly = TRUE)
  library(scales)
  library(forecast)
  library(zoo)
  library(ggpubr)
  library(readxl)
  library(lubridate)
  library(ISOweek)
  library(purrr)
}

initialize_plots_insample_context <- function(sample_config = NULL) {
  if (is.null(sample_config) && exists("sample_config", inherits = FALSE)) {
    sample_config <- get("sample_config", inherits = FALSE)
  }
  
  if (is.null(sample_config)) {
    sample_config <- list(
      sample_id = "sample_2025Q4",
      sample_end_date = as.Date("2026-03-07"),
      output_root = file.path("outputs", "plots_insample", "sample_2025Q4"),
      fit_root = "fits",
      fit_rt_dir = file.path("fits", "full_RT")
    )
  }
  
  sample_config$sample_end_date <- as.Date(sample_config$sample_end_date)
  sample_end_date <- sample_config$sample_end_date
  sample_id <- sample_config$sample_id
  output_root <- sample_config$output_root
  figures_dir <- file.path(output_root, "figures")
  tables_dir <- file.path(output_root, "tables")
  results_dir <- file.path(output_root, "results")
  
  dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
  
  decimal_date_local <- function(x) {
    x <- as.Date(x)
    as.numeric(format(x, "%Y")) +
      (as.numeric(format(x, "%m")) - 1) / 12 +
      as.numeric(format(x, "%d")) / 365
  }
  
  sample_end_decimal <- round(decimal_date_local(sample_end_date), 3)
  sample_end_fit_decimal <- round(as.numeric(format(sample_end_date, "%Y")) + 47 / 48, 3)
  
  list2env(
    list(
      sample_config = sample_config,
      sample_end_date = sample_end_date,
      sample_id = sample_id,
      output_root = output_root,
      figures_dir = figures_dir,
      tables_dir = tables_dir,
      results_dir = results_dir,
      sample_end_decimal = sample_end_decimal,
      sample_end_fit_decimal = sample_end_fit_decimal
    ),
    envir = parent.frame()
  )
  
  invisible(sample_config)
}


# -----------------------------------------------------------------------------
# File and Date Utilities
# -----------------------------------------------------------------------------
# These helper functions standardize date handling, sample filtering, and
# output-file selection for the rest of the workflow.

decimal_date <- function(x) {
  x <- as.Date(x)
  as.numeric(format(x, "%Y")) +
    (as.numeric(format(x, "%m")) - 1) / 12 +
    as.numeric(format(x, "%d")) / 365
}

latest_fit_file <- function(folder, cutoff_decimal = sample_end_fit_decimal) {
  files <- list.files(folder, pattern = "^fit_[0-9.]+\\.Rda$", full.names = TRUE)
  if (length(files) == 0) {
    stop(sprintf("No fit files found in '%s'.", folder))
  }
  file_decimals <- suppressWarnings(as.numeric(gsub("^fit_|\\.Rda$", "", basename(files))))
  valid_idx <- which(!is.na(file_decimals) & file_decimals <= cutoff_decimal)
  if (length(valid_idx) == 0) {
    stop(sprintf("No fit file found in '%s' up to cutoff %.3f.", folder, cutoff_decimal))
  }
  files[valid_idx[which.max(file_decimals[valid_idx])]]
}

write_table_output <- function(filename, contents) {
  writeLines(contents, file.path(tables_dir, filename))
}

save_result_output <- function(object, filename) {
  save(list = deparse(substitute(object)), file = file.path(results_dir, filename))
}

output_figure_path <- function(filename) {
  file.path(figures_dir, filename)
}

filter_to_sample <- function(df, time_col = "time", start_date = as.Date("1990-01-01"), end_date = sample_end_date) {
  df[df[[time_col]] >= start_date & df[[time_col]] <= end_date, , drop = FALSE]
}

get_latest_numeric_vintage <- function(df, lower_bound = -Inf, upper_bound = sample_end_decimal) {
  vintages <- suppressWarnings(as.numeric(names(df)[-1]))
  vintages <- vintages[!is.na(vintages) & vintages >= lower_bound & vintages <= upper_bound]
  if (length(vintages) == 0) {
    stop("No valid vintages found for the configured sample.")
  }
  max(vintages)
}

get_next_extending_numeric_vintage <- function(df, reference_date, lower_bound = -Inf) {
  reference_decimal <- round(decimal_date_local(reference_date), 3)
  vintage_names <- names(df)[-1]
  vintages <- suppressWarnings(as.numeric(vintage_names))
  valid_idx <- which(!is.na(vintages) & vintages >= lower_bound)

  if (length(valid_idx) == 0) {
    stop("No valid vintages found for the configured sample.")
  }

  vintages <- vintages[valid_idx]
  vintage_names <- vintage_names[valid_idx]

  earlier_idx <- which(vintages <= reference_decimal)
  if (length(earlier_idx) == 0) {
    stop("No GDP vintage is available on or before the requested reference_date.")
  }

  base_idx <- earlier_idx[which.max(vintages[earlier_idx])]
  base_series <- df[[vintage_names[base_idx]]]
  base_last_obs <- suppressWarnings(max(df$time[!is.na(base_series)], na.rm = TRUE))

  if (!is.finite(base_last_obs)) {
    stop("The latest GDP vintage available at the requested reference_date contains no observations.")
  }

  later_order <- order(vintages)
  later_idx <- later_order[vintages[later_order] > vintages[base_idx]]

  for (idx in later_idx) {
    candidate_series <- df[[vintage_names[idx]]]
    candidate_last_obs <- suppressWarnings(max(df$time[!is.na(candidate_series)], na.rm = TRUE))

    if (is.finite(candidate_last_obs) && candidate_last_obs > base_last_obs) {
      return(vintages[idx])
    }
  }

  stop("No later GDP vintage extends the series beyond the latest vintage available at the requested reference_date.")
}

is_crisis_period <- function(date_vec) {
  crisis_dates <- data.frame(
    start = as.Date(c("2008-07-07", "2020-01-01")),
    end = as.Date(c("2009-09-28", "2021-12-28"))
  )
  vapply(as.Date(date_vec), function(d) any(d >= crisis_dates$start & d <= crisis_dates$end), logical(1))
}

decimal_date_local <- function(x) {
  x <- as.Date(x)
  as.numeric(format(x, "%Y")) +
    (as.numeric(format(x, "%j")) - 1) / 365
}

# -----------------------------------------------------------------------------
# Plotting and Correlation Helpers
# -----------------------------------------------------------------------------
# These functions rescale indicators, align comparison series, and generate the
# correlation structures used later in the heatmap and summary outputs.

rescale_to_gdp <- function(indicator_df, gdp_hist_df,
                           ref_start = as.Date("2005-01-01"),
                           ref_end   = as.Date("2025-12-31")) {
  
  # GDP moments (over reference window)
  gdp_ref <- gdp_hist_df %>%
    filter(value >= ref_start, value <= ref_end) %>%
    pull(y)
  
  mu_gdp <- mean(gdp_ref, na.rm = TRUE)
  sd_gdp <- sd(gdp_ref,  na.rm = TRUE)
  
  # Indicator moments (over reference window)
  ind_ref <- indicator_df %>%
    filter(time >= ref_start, time <= ref_end) %>%
    pull(value)
  
  mu_ind <- mean(ind_ref, na.rm = TRUE)
  sd_ind <- sd(ind_ref,  na.rm = TRUE)
  
  # safeguard
  if (is.na(sd_ind) || sd_ind == 0) {
    return(indicator_df %>% mutate(value = (value - mu_ind) + mu_gdp))
  }
  
  indicator_df %>%
    mutate(value = (value - mu_ind) / sd_ind * sd_gdp + mu_gdp)
}

build_wai_qoq_mean_series <- function(level_df) {
  level_df %>%
    select(time, value) %>%
    mutate(quarter = floor_date(time, unit = "quarter")) %>%
    group_by(quarter) %>%
    summarise(level_value = mean(value, na.rm = TRUE), .groups = "drop") %>%
    arrange(quarter) %>%
    mutate(value = ((level_value / lag(level_value))^4 - 1) * 100) %>%
    transmute(time = quarter, value = value) %>%
    filter(!is.na(value))
}

prepare_wai_qoq_series <- function(wai_result, method) {
  if (method == "mean") {
    return(build_wai_qoq_mean_series(wai_result$tab_gr_lv))
  }
  wai_result$tab_gr_qoq
}

plot_comparison <- function(tab_wai, comparison_df, comparison_label,
                            crises, hist_tab_gdp,
                            plot_title = NULL,
                            ylim_fixed = NULL) {
  x_start <- as.Date("2005-01-01")
  x_end <- sample_end_date

  tab_wai <- tab_wai %>%
    filter(time >= x_start, time <= x_end)

  tab_wai <- tab_wai %>%
    mutate(Series = factor("WAI", levels = c("WAI")))
  
  comparison_df <- comparison_df %>%
    filter(time >= x_start, time <= x_end) %>%
    mutate(Series = factor(comparison_label, levels = c(comparison_label)))

  hist_tab_gdp <- hist_tab_gdp %>%
    filter(value >= x_start, value <= x_end)
  
  plot_df <- bind_rows(tab_wai, comparison_df)
  
  color_values <- setNames(c("red", "blue"), c("WAI", comparison_label))
  
  p <- ggplot() +
    geom_line(data = plot_df, aes(x = time, y = value, color = Series)) +
    scale_x_date(date_breaks = "2 years", date_labels = "%Y", limits = c(x_start, x_end)) +
    ylab(NULL) +
    xlab(NULL) +
    geom_line(data = hist_tab_gdp, aes(y = y, x = value, group = y),
              color = "black") +
    geom_rect(data = crises,
              aes(xmin = Peak, xmax = Trough, ymin = -Inf, ymax = Inf),
              fill = "grey80", alpha = 0.2) +
    scale_color_manual(values = color_values) +
    theme_minimal() +
    theme(axis.text.x = element_text(),
          legend.title = element_blank(),
          legend.position = "bottom",
          plot.title = element_text(hjust = 0.5)) +
    labs(title = plot_title)
  
  # Apply fixed limits ONLY if requested
  if (!is.null(ylim_fixed)) {
    p <- p + coord_cartesian(ylim = ylim_fixed)
  }
  
  return(p)
}

get_combined_cor_table <- function(method = c("mean", "last", "last_month"),
                                   analysis_set = c("wai_versions", "indicators")) {
  method <- match.arg(method)
  analysis_set <- match.arg(analysis_set)
  
  # Helper to aggregate one dataset
  aggregate_to_quarter <- function(df) {
    if (method == "mean") {
      df %>%
        mutate(quarter = floor_date(time, unit = "quarter")) %>%
        group_by(Series, quarter) %>%
        summarise(value = mean(value, na.rm = TRUE), .groups = "drop")
    } else if (method == "last") {
      df %>%
        mutate(quarter = floor_date(time, unit = "quarter")) %>%
        group_by(Series, quarter) %>%
        slice_max(order_by = time, with_ties = FALSE) %>%
        ungroup() %>%
        select(Series, quarter, value)
    } else if (method == "last_month") {
      df %>%
        mutate(month = floor_date(time, unit = "month")) %>%
        group_by(Series, month) %>%
        summarise(monthly_mean = mean(value, na.rm = TRUE), .groups = "drop") %>%  # monthly average
        mutate(quarter = floor_date(month, unit = "quarter")) %>%
        group_by(Series, quarter) %>%
        slice_max(order_by = month, with_ties = FALSE) %>%  # last month in quarter
        ungroup() %>%
        rename(value = monthly_mean) %>%
        select(Series, quarter, value)
    }
  }
  
  # --- YOY Analysis ---
  if (analysis_set == "indicators") {
    plot_df_yoy <- bind_rows(
      tab_wai_yoy   %>% mutate(Series = "WAI"),
      wwa_gr_df     %>% mutate(Series = "SECO-WWA"),
      fcurve_gr_df  %>% mutate(Series = "F-CURVE"),
      tab_kss       %>% mutate(Series = "SECO-SEC"),
      tab_snb       %>% mutate(Series = "SNB-BCI"),
      tab_baro      %>% mutate(Series = "KOF-BARO")
    )
  } else {
    plot_df_yoy <- bind_rows(
      result_wai$tab_wai_yoy   %>% mutate(Series = "WAI"),
      result_wai_no_sv$tab_wai_yoy   %>% mutate(Series = "WAI-SV"),
      result_wai_only_monthly_no_sv$tab_wai_yoy     %>% mutate(Series = "WAI-(SV+HF)"),
      result_wai_no_hf$tab_wai_yoy     %>% mutate(Series = "WAI-HF"),
      result_wai_no_financial$tab_wai_yoy  %>% mutate(Series = "WAI-FIN")#,
      #result_wai_only_total_retail$tab_wai_yoy       %>% mutate(Series = "WAI-Retail")
    )
  }
  
  
  quarterly_df_yoy <- aggregate_to_quarter(plot_df_yoy)
  
  GDP_yoy_tab <- tibble(
    date = seq.Date(as.Date("1991-01-01"), by = "3 months", length.out = length(x_hist_gr_yoy)),
    GDP_yoy = as.numeric(x_hist_gr_yoy)
  )
  
  series_start_dates_yoy <- quarterly_df_yoy %>%
    group_by(Series) %>%
    summarise(series_start = max(min(quarter), min(GDP_yoy_tab$date)), .groups = "drop")
  
  aligned_start_yoy <- max(series_start_dates_yoy$series_start)
  
  quarterly_df_yoy_aligned <- quarterly_df_yoy %>%
    inner_join(series_start_dates_yoy, by = "Series") %>%
    #filter(quarter >= series_start) %>%
    select(-series_start)
  
  GDP_yoy_tab_aligned <- GDP_yoy_tab #%>%
    #filter(date >= aligned_start_yoy)
  
  joined_df_yoy <- quarterly_df_yoy_aligned %>%
    rename(date = quarter, series_value = value) %>%
    inner_join(GDP_yoy_tab_aligned, by = "date")
  
  print_evaluation_periods(
    joined_df_yoy,
    series_col = "Series",
    date_col = "date",
    context_label = paste("In-sample fit table,", analysis_set, "YoY"),
    frequency_label = "YoY",
    method_label = method
  )

  lags <- -4:0
  cor_lag_results_yoy <- joined_df_yoy %>%
    group_by(Series) %>%
    arrange(date) %>%
    nest() %>%
    mutate(cor_lags = map(data, ~ {
      df <- .
      map_dfr(lags, function(l) {
        df_lag <- df %>%
          mutate(gdp_lag = lead(GDP_yoy, n = -l))
        tibble(
          Lag = l,
          Correlation = cor(df_lag$series_value, df_lag$gdp_lag, use = "complete.obs")
        )
      })
    })) %>%
    select(-data) %>%
    unnest(cor_lags)
  
  cor_lag_results_yoy_wide <- cor_lag_results_yoy %>%
    pivot_wider(names_from = Lag, values_from = Correlation, names_prefix = "Lag_") %>%
    mutate(Frequency = "YoY") %>%
    select(Frequency, everything())
  
  # --- QOQ Analysis ---
  base_wai_result <- list(
    tab_gr_qoq = tab_gr %>% select(time, name, value),
    tab_gr_lv = tab_gr_lv
  )
  tab_gr_qoq <- prepare_wai_qoq_series(base_wai_result, method)
  
  if (analysis_set == "indicators") {
    plot_df_qoq <- bind_rows(
      tab_gr_qoq      %>% mutate(Series = "WAI"),
      wwa_gr_df_qoq   %>% mutate(Series = "SECO-WWA"),
      fcurve_gr_df    %>% mutate(Series = "F-CURVE"),
      tab_kss         %>% mutate(Series = "SECO-SEC"),
      tab_snb         %>% mutate(Series = "SNB-BCI"),
      tab_baro        %>% mutate(Series = "KOF-BARO")
    )
  } else {
    plot_df_qoq <- bind_rows(
      prepare_wai_qoq_series(result_wai, method) %>% mutate(Series = "WAI"),
      prepare_wai_qoq_series(result_wai_no_sv, method) %>% mutate(Series = "WAI-SV"),
      prepare_wai_qoq_series(result_wai_only_monthly_no_sv, method) %>% mutate(Series = "WAI-(SV+HF)"),
      prepare_wai_qoq_series(result_wai_no_hf, method) %>% mutate(Series = "WAI-HF"),
      prepare_wai_qoq_series(result_wai_no_financial, method) %>% mutate(Series = "WAI-FIN")#,
      #prepare_wai_qoq_series(result_wai_only_total_retail, method) %>% mutate(Series = "WAI-Retail")
    )
  }
 
  quarterly_df_qoq <- aggregate_to_quarter(plot_df_qoq)
  
  GDP_qoq_tab <- tibble(
    date = seq.Date(as.Date("1990-01-01"), by = "3 months", length.out = length(x_hist_gr_ann)),
    GDP_qoq = as.numeric(x_hist_gr_ann)
  )
  
  series_start_dates_qoq <- quarterly_df_qoq %>%
    group_by(Series) %>%
    summarise(series_start = max(min(quarter), min(GDP_qoq_tab$date)), .groups = "drop")
  
  aligned_start_qoq <- max(series_start_dates_qoq$series_start)
  
  quarterly_df_qoq_aligned <- quarterly_df_qoq %>%
    inner_join(series_start_dates_qoq, by = "Series") %>%
    #filter(quarter >= series_start) %>%
    select(-series_start)
  
  GDP_tab_aligned <- GDP_qoq_tab #%>%
    #filter(date >= aligned_start_qoq)
  
  joined_df_qoq <- quarterly_df_qoq_aligned %>%
    rename(date = quarter, series_value = value) %>%
    inner_join(GDP_tab_aligned, by = "date")
  
  print_evaluation_periods(
    joined_df_qoq,
    series_col = "Series",
    date_col = "date",
    context_label = paste("In-sample fit table,", analysis_set, "QoQ"),
    frequency_label = "QoQ",
    method_label = method
  )

  cor_lag_results_qoq <- joined_df_qoq %>%
    group_by(Series) %>%
    arrange(date) %>%
    nest() %>%
    mutate(cor_lags = map(data, ~ {
      df <- .
      map_dfr(lags, function(l) {
        df_lag <- df %>%
          mutate(gdp_lag = lead(GDP_qoq, n = -l))
        tibble(
          Lag = l,
          Correlation = cor(df_lag$series_value, df_lag$gdp_lag, use = "complete.obs")
        )
      })
    })) %>%
    select(-data) %>%
    unnest(cor_lags) %>%
    ungroup()
  
  cor_lag_results_qoq_wide <- cor_lag_results_qoq %>%
    pivot_wider(names_from = Lag, values_from = Correlation, names_prefix = "Lag_") %>%
    mutate(Frequency = "QoQ") %>%
    select(Frequency, everything())
  
  desired_order <- if (analysis_set == "indicators") {
    c("WAI", "SECO-WWA", "F-CURVE", "SECO-SEC", "SNB-BCI", "KOF-BARO")
  } else {
    c("WAI", "WAI-SV", "WAI-(SV+HF)", "WAI-HF", "WAI-FIN")#, "WAI-Retail")
  }
  
  cor_lag_results_yoy_wide <- cor_lag_results_yoy_wide %>%
    arrange(factor(Series, levels = desired_order))
  
  cor_lag_results_qoq_wide <- cor_lag_results_qoq_wide %>%
    arrange(factor(Series, levels = desired_order))
  
  # --- Combine ---
  combined_cor_table <- bind_rows(cor_lag_results_yoy_wide, cor_lag_results_qoq_wide)
  
  return(combined_cor_table)
}

render_correlation_heatmap <- function(cor_tables, series_order, output_file) {
  method_labels <- c(
    mean = "Mean",
    last = "Last",
    lastmonth = "Last Month",
    last_month = "Last Month"
  )
  

  # Store all plots
  all_plots <- list()
  
  # Loop through each table and frequency
  for (method in names(cor_tables)) {
    for (freq in c("YoY", "QoQ")) {
      
      # Subset table
      df <- cor_tables[[method]] %>%
        filter(Frequency == freq) %>%
        select(-Frequency)
      
      # Pivot longer
      cor_table <- df %>%
        pivot_longer(cols = starts_with("Lag_"), names_to = "Lag", values_to = "Correlation")
      
      # Factor levels
      lag_levels <- paste0("Lag_", -4:0, "_", method)
      cor_table$Lag <- factor(cor_table$Lag, levels = lag_levels)
      cor_table$Series <- factor(cor_table$Series, levels = rev(series_order))
      
      # Factor levels for Lag
      cor_table$Lag <- gsub(paste0("_", method), "", cor_table$Lag)
      cor_table$Lag <- gsub("Lag_", "", cor_table$Lag)
      cor_table$Lag <- factor(cor_table$Lag, levels = as.character(-4:0))
      
      # Set factor levels for Series
      cor_table$Series <- factor(cor_table$Series, levels = rev(series_order))
      
      # Create plot
      p <- ggplot(cor_table, aes(x = Lag, y = Series, fill = Correlation)) +
        geom_tile(color = "white") +
        geom_text(aes(label = round(Correlation, 2)), color = "black", size = 5) +
        scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0,
                             limits = c(-1, 1), oob = squish) +
        theme_minimal() +
        theme(
          axis.text.x = element_text(size = 10),
          axis.text.y = element_text(size = 10),
          axis.title.y = element_blank(),
          legend.title = element_text(size = 10),
          legend.text = element_text(size = 8)
        ) +
        labs(
          title = paste("Correlation Heatmap with GDP -", freq, "(", method, ")"),
          x = "Lag", y = NULL, fill = "Corr"
        )
      
      # Save plot in list
      all_plots[[paste(freq, method, sep = "_")]] <- p
    }
  }
  
  # Arrange and display all 6 plots in a 2x3 grid
  heatmap_plot <- ggarrange(
    plotlist = all_plots,
    ncol = 2,
    nrow = 3,
    common.legend = TRUE,
    legend = "right"
  )
  
  print(heatmap_plot)
  ggsave(output_figure_path(output_file), heatmap_plot, width = 33, height = 44, units = "cm")

  invisible(heatmap_plot)
}

suffix_cols <- function(df, suffix) {
  df %>%
    rename_with(~ paste0(., "_", suffix), .cols = starts_with("Lag_"))
}


# -----------------------------------------------------------------------------
# In-Sample Evaluation Helpers
# -----------------------------------------------------------------------------
# These functions compute in-sample fit metrics, significance tests, and
# reshaped tables that are later written to LaTeX output.

dm_test_modified <- function(e1, e2, h = 1, power = 2, alternative = "greater") {
  d <- (abs(e1)^power - abs(e2)^power)  # loss differential
  d <- na.omit(d)
  n <- length(d)
  d_bar <- mean(d)
  gamma_0 <- var(d)
  
  # t-statistic (standard)
  DM_stat <- d_bar / sqrt(gamma_0 / n)
  
  # Harvey-Leybourne-Newbold correction (1997)
  HLN_factor <- sqrt((n + 1 - 2 * h + h * (h - 1) / n) / n)
  DM_modified <- DM_stat / HLN_factor
  
  # One-sided p-value
  pval <- switch(alternative,
                 "greater" = 1 - pnorm(DM_modified),
                 "less"    = pnorm(DM_modified),
                 "two.sided" = 2 * min(pnorm(DM_modified), 1 - pnorm(DM_modified)))
  
  return(pval)
}
get_insample_fit_table <- function(method = c("mean", "last", "last_month"),
                                   analysis_set = c("wai_versions", "indicators")) {
  method <- match.arg(method)
  analysis_set <- match.arg(analysis_set)
  
  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(purrr)
  library(broom)
  library(Metrics)
  library(forecast)
  
  # --- Store WAI prediction errors for p-value comparisons
  wai_error_store <- list()
  
  aggregate_to_quarter <- function(df) {
    if (method == "mean") {
      df %>%
        mutate(quarter = floor_date(time, unit = "quarter")) %>%
        group_by(Series, quarter) %>%
        summarise(value = mean(value, na.rm = TRUE), .groups = "drop")
    } else if (method == "last") {
      df %>%
        mutate(quarter = floor_date(time, unit = "quarter")) %>%
        group_by(Series, quarter) %>%
        slice_max(order_by = time, with_ties = FALSE) %>%
        ungroup() %>%
        select(Series, quarter, value)
    } else if (method == "last_month") {
      df %>%
        mutate(month = floor_date(time, unit = "month")) %>%
        group_by(Series, month) %>%
        summarise(monthly_mean = mean(value, na.rm = TRUE), .groups = "drop") %>%
        mutate(quarter = floor_date(month, unit = "quarter")) %>%
        group_by(Series, quarter) %>%
        slice_max(order_by = month, with_ties = FALSE) %>%
        ungroup() %>%
        rename(value = monthly_mean) %>%
        select(Series, quarter, value)
    }
  }
  
  # Build the in-sample comparison panel for either the WAI variants or the
  # benchmark indicators.
  if (analysis_set == "indicators") {
    plot_df_yoy <- bind_rows(
      tab_wai_yoy %>% mutate(Series = "WAI"),
      wwa_gr_df %>% mutate(Series = "SECO-WWA"),
      fcurve_gr_df %>% mutate(Series = "F-CURVE"),
      tab_kss %>% mutate(Series = "SECO-SEC"),
      tab_snb %>% mutate(Series = "SNB-BCI"),
      tab_baro %>% mutate(Series = "KOF-BARO")
    )
  } else {
    plot_df_yoy <- bind_rows(
      result_wai$tab_wai_yoy %>% mutate(Series = "WAI"),
      result_wai_no_sv$tab_wai_yoy %>% mutate(Series = "WAI-SV"),
      result_wai_only_monthly_no_sv$tab_wai_yoy %>% mutate(Series = "WAI-(SV+HF)"),
      result_wai_no_hf$tab_wai_yoy %>% mutate(Series = "WAI-HF"),
      result_wai_no_financial$tab_wai_yoy %>% mutate(Series = "WAI-FIN")#,
      #result_wai_only_total_retail$tab_wai_yoy %>% mutate(Series = "WAI-Retail")
    )
  }
  
  
  quarterly_df_yoy <- aggregate_to_quarter(plot_df_yoy)
  
  GDP_yoy_tab <- tibble(
    date = seq.Date(as.Date("1991-01-01"), by = "3 months", length.out = length(x_hist_gr_yoy)),
    GDP_yoy = as.numeric(x_hist_gr_yoy)
  )
  
  series_start_dates_yoy <- quarterly_df_yoy %>%
    group_by(Series) %>%
    summarise(series_start = max(min(quarter), min(GDP_yoy_tab$date)), .groups = "drop")
  
  aligned_start_yoy <- max(series_start_dates_yoy$series_start)
  
  quarterly_df_yoy_aligned <- quarterly_df_yoy %>%
    inner_join(series_start_dates_yoy, by = "Series") %>%
    #filter(quarter >= series_start) %>%
    select(-series_start)
  
  GDP_yoy_tab_aligned <- GDP_yoy_tab #%>%
    #filter(date >= aligned_start_yoy)
  
  joined_df_yoy <- quarterly_df_yoy_aligned %>%
    rename(date = quarter, series_value = value) %>%
    inner_join(GDP_yoy_tab_aligned, by = "date")
  
  base_wai_result <- list(
    tab_gr_qoq = tab_gr %>% select(time, name, value),
    tab_gr_lv = tab_gr_lv
  )
  tab_gr_qoq <- prepare_wai_qoq_series(base_wai_result, method)
  
  if (analysis_set == "indicators") {
    plot_df_qoq <- bind_rows(
      tab_gr_qoq %>% mutate(Series = "WAI"),
      wwa_gr_df_qoq %>% mutate(Series = "SECO-WWA"),
      fcurve_gr_df %>% mutate(Series = "F-CURVE"),
      tab_kss %>% mutate(Series = "SECO-SEC"),
      tab_snb %>% mutate(Series = "SNB-BCI"),
      tab_baro %>% mutate(Series = "KOF-BARO")
    )
  } else {
    plot_df_qoq <- bind_rows(
      prepare_wai_qoq_series(result_wai, method) %>% mutate(Series = "WAI"),
      prepare_wai_qoq_series(result_wai_no_sv, method) %>% mutate(Series = "WAI-SV"),
      prepare_wai_qoq_series(result_wai_only_monthly_no_sv, method) %>% mutate(Series = "WAI-(SV+HF)"),
      prepare_wai_qoq_series(result_wai_no_hf, method) %>% mutate(Series = "WAI-HF"),
      prepare_wai_qoq_series(result_wai_no_financial, method) %>% mutate(Series = "WAI-FIN")#,
      #prepare_wai_qoq_series(result_wai_only_total_retail, method) %>% mutate(Series = "WAI-Retail")
    )
  }
  
  quarterly_df_qoq <- aggregate_to_quarter(plot_df_qoq)
  
  GDP_qoq_tab <- tibble(
    date = seq.Date(as.Date("1990-01-01"), by = "3 months", length.out = length(x_hist_gr_ann)),
    GDP_qoq = as.numeric(x_hist_gr_ann)
  )
  
  series_start_dates_qoq <- quarterly_df_qoq %>%
    group_by(Series) %>%
    summarise(series_start = max(min(quarter), min(GDP_qoq_tab$date)), .groups = "drop")
  
  aligned_start_qoq <- max(series_start_dates_qoq$series_start)
  
  quarterly_df_qoq_aligned <- quarterly_df_qoq %>%
    inner_join(series_start_dates_qoq, by = "Series") %>%
    #filter(quarter >= series_start) %>%
    select(-series_start)
  
  GDP_tab_aligned <- GDP_qoq_tab #%>%
    #filter(date >= aligned_start_qoq)
  
  joined_df_qoq <- quarterly_df_qoq_aligned %>%
    rename(date = quarter, series_value = value) %>%
    inner_join(GDP_tab_aligned, by = "date")
  
  # Lags
  lags <- -4:0

  compute_metrics <- function(df, target_var, frequency, series_name) {
    map_dfr(lags, function(l) {
      df_lag <- df %>%
        mutate(gdp_lag = lead(.data[[target_var]], n = -l)) %>%
        filter(!is.na(gdp_lag) & !is.na(series_value))
      
      if (nrow(df_lag) >= 12) {
        fit <- lm(gdp_lag ~ series_value, data = df_lag)
        preds <- predict(fit, df_lag)
        errors <- df_lag$gdp_lag - preds
        
        if (series_name == "WAI") {
          if (is.null(wai_error_store[[frequency]])) {
            wai_error_store[[frequency]] <- list()
          }
          wai_error_store[[frequency]][[as.character(l)]] <<- errors
        }
        
        p_dm_rmse <- NA_real_
        p_dm_mae  <- NA_real_
        
        if (series_name != "WAI" && !is.null(wai_error_store[[frequency]][[as.character(l)]])) {
          errors_wai <- wai_error_store[[frequency]][[as.character(l)]]
          n <- min(length(errors), length(errors_wai))
          e1 <- errors[1:n]
          e2 <- errors_wai[1:n]
          
          p_dm_rmse <- tryCatch({
            dm_test_modified(e1, e2, h = 1, power = 2, alternative = "greater")
          }, error = function(e) NA_real_)
          
          p_dm_mae <- tryCatch({
            dm_test_modified(e1, e2, h = 1, power = 1, alternative = "greater")
          }, error = function(e) NA_real_)
        }
        
        tibble(
          Lag = l,
          RMSE = rmse(df_lag$gdp_lag, preds),
          MAE = mae(df_lag$gdp_lag, preds),
          R2 = glance(fit)$r.squared,
          P_DM_RMSE = p_dm_rmse,
          P_DM_MAE = p_dm_mae
        )
      } else {
        tibble(
          Lag = l,
          RMSE = NA_real_, MAE = NA_real_, R2 = NA_real_,
          P_DM_RMSE = NA_real_, P_DM_MAE = NA_real_
        )
      }
    })
  }
  
  # --- Process WAI first ---
  wai_yoy <- joined_df_yoy %>% filter(Series == "WAI")
  other_yoy <- joined_df_yoy %>% filter(Series != "WAI")
  
  wai_qoq <- joined_df_qoq %>% filter(Series == "WAI")
  other_qoq <- joined_df_qoq %>% filter(Series != "WAI")
  
  fit_lag_results_yoy <- bind_rows(
    wai_yoy %>% group_by(Series) %>% nest() %>%
      mutate(metrics = map2(data, Series, ~ compute_metrics(.x, "GDP_yoy", "YoY", .y))) %>%
      select(-data) %>% unnest(metrics),
    other_yoy %>% group_by(Series) %>% nest() %>%
      mutate(metrics = map2(data, Series, ~ compute_metrics(.x, "GDP_yoy", "YoY", .y))) %>%
      select(-data) %>% unnest(metrics)
  )
  
  fit_lag_results_qoq <- bind_rows(
    wai_qoq %>% group_by(Series) %>% nest() %>%
      mutate(metrics = map2(data, Series, ~ compute_metrics(.x, "GDP_qoq", "QoQ", .y))) %>%
      select(-data) %>% unnest(metrics),
    other_qoq %>% group_by(Series) %>% nest() %>%
      mutate(metrics = map2(data, Series, ~ compute_metrics(.x, "GDP_qoq", "QoQ", .y))) %>%
      select(-data) %>% unnest(metrics)
  )
  
  fit_lag_results_yoy_wide <- fit_lag_results_yoy %>%
    pivot_wider(names_from = Lag, values_from = c(RMSE, MAE, R2, P_DM_RMSE, P_DM_MAE), names_glue = "{.value}_Lag_{Lag}") %>%
    mutate(Frequency = "YoY")
  
  fit_lag_results_qoq_wide <- fit_lag_results_qoq %>%
    pivot_wider(names_from = Lag, values_from = c(RMSE, MAE, R2, P_DM_RMSE, P_DM_MAE), names_glue = "{.value}_Lag_{Lag}") %>%
    mutate(Frequency = "QoQ")
  
  combined_table <- bind_rows(fit_lag_results_yoy_wide, fit_lag_results_qoq_wide)
  
  desired_order <- if (analysis_set == "indicators") {
    c("WAI", "SECO-WWA", "F-CURVE", "SECO-SEC", "SNB-BCI", "KOF-BARO")
  } else {
    c("WAI", "WAI-SV", "WAI-(SV+HF)", "WAI-HF", "WAI-FIN")#, "WAI-Retail")
  }
  
  combined_table <- combined_table %>%
    mutate(
      Frequency = factor(Frequency, levels = c("QoQ", "YoY")),
      Series = factor(Series, levels = desired_order)
    ) %>%
    arrange(Frequency, Series)
  
  # Extract output tables
  rmse_table <- combined_table %>% select(Frequency, Series, starts_with("RMSE_Lag_"))
  mae_table  <- combined_table %>% select(Frequency, Series, starts_with("MAE_Lag_"))
  r2_table   <- combined_table %>% select(Frequency, Series, starts_with("R2_Lag_")) %>% mutate(across(where(is.numeric), ~ round(.x, 2))) %>% mutate(across(where(is.numeric), ~ sprintf("%.2f", .)))
  pval_rmse  <- combined_table %>% select(Frequency, Series, starts_with("P_DM_RMSE_Lag_"))
  pval_mae   <- combined_table %>% select(Frequency, Series, starts_with("P_DM_MAE_Lag_"))
  
  return(list(
    RMSE = rmse_table,
    MAE = mae_table,
    R2 = r2_table,
    PVAL_RMSE = pval_rmse,
    PVAL_MAE = pval_mae
  ))
}
calculate_relative_errors <- function(fit_tables) {
  rmse_table <- fit_tables$RMSE %>% ungroup()
  mae_table  <- fit_tables$MAE %>% ungroup()
  
  # Pivot to long format
  rmse_long <- rmse_table %>%
    pivot_longer(cols = starts_with("RMSE_Lag_"), names_to = "Lag", values_to = "RMSE")
  
  mae_long <- mae_table %>%
    pivot_longer(cols = starts_with("MAE_Lag_"), names_to = "Lag", values_to = "MAE")
  
  # Confirm Series column exists
  if (!"Series" %in% names(rmse_long)) stop("Column 'Series' is missing from RMSE table")
  if (!"Series" %in% names(mae_long))  stop("Column 'Series' is missing from MAE table")
  
  # Extract WAI for normalization
  rmse_wai_long <- rmse_long %>%
    filter(Series == "WAI") %>%
    select(Frequency, Lag, RMSE_WAI = RMSE)
  
  mae_wai_long <- mae_long %>%
    filter(Series == "WAI") %>%
    select(Frequency, Lag, MAE_WAI = MAE)
  
  # Join and compute relative values
  rmse_relative <- rmse_long %>%
    left_join(rmse_wai_long, by = c("Frequency", "Lag")) %>%
    mutate(RMSE_relative = RMSE / RMSE_WAI) %>%
    select(Frequency, Series, Lag, RMSE_relative) %>%
    pivot_wider(names_from = Lag, values_from = RMSE_relative, names_prefix = "RMSE_rel_") %>%
    mutate(across(where(is.numeric), ~ round(.x, 2))) %>%
    mutate(across(where(is.numeric), ~ ifelse(is.na(.x), "", .x))) %>%
    mutate(across(where(is.numeric), ~ sprintf("%.2f", .)))
  
  mae_relative <- mae_long %>%
    left_join(mae_wai_long, by = c("Frequency", "Lag")) %>%
    mutate(MAE_relative = MAE / MAE_WAI) %>%
    select(Frequency, Series, Lag, MAE_relative) %>%
    pivot_wider(names_from = Lag, values_from = MAE_relative, names_prefix = "MAE_rel_") %>%
    mutate(across(where(is.numeric), ~ round(.x, 2))) %>%
    mutate(across(where(is.numeric), ~ ifelse(is.na(.x), "", .x))) %>%
    mutate(across(where(is.numeric), ~ sprintf("%.2f", .)))
  
  return(list(RMSE_relative = rmse_relative, MAE_relative = mae_relative))
}
annotate_relative_errors <- function(rel_table, pval_table, metric_prefix) {
  # Remove prefix to get lag names
  rel_long <- rel_table %>%
    pivot_longer(cols = starts_with(metric_prefix),
                 names_to = "Lag",
                 values_to = "Value")
  
  pval_long <- pval_table %>%
    pivot_longer(cols = starts_with(paste0("P_DM_", metric_prefix)),
                 names_to = "Lag",
                 values_to = "PValue")
  
  # Normalize Lag names
  rel_long <- rel_long %>%
    mutate(Lag = gsub(".*Lag_", "", Lag))
  
  pval_long <- pval_long %>%
    mutate(Lag = gsub(".*Lag_", "", Lag))
  
  # Join and annotate
  annotated <- rel_long %>%
    left_join(pval_long, by = c("Frequency", "Series", "Lag")) %>%
    mutate(
      Stars = case_when(
        is.na(PValue)       ~ "",
        PValue < 0.01       ~ "***",
        PValue < 0.05       ~ "**",
        PValue < 0.10       ~ "*",
        TRUE                ~ ""
      ),
      Annotated = paste0(Value, Stars)
    ) %>%
    select(Frequency, Series, Lag, Annotated) %>%
    pivot_wider(names_from = Lag, values_from = Annotated,
                names_prefix = paste0(metric_prefix, "_rel_"))
  
  return(annotated)
}
create_combined_latex_table <- function(combined_tables_list,
                                        caption = "Cross Correlation with GDP for Different Lags and Aggregation Methods",
                                        include_period = FALSE,
                                        measure_label_map = NULL) {
  library(dplyr)
  library(knitr)
  library(kableExtra)

  normalize_table <- function(tbl) {
    lag_cols <- grep(".*_-?[0-9]+$", names(tbl), value = TRUE)
    lag_numbers <- suppressWarnings(as.numeric(sub("^.*_(-?[0-9]+)$", "\\1", lag_cols)))
    lag_cols <- lag_cols[!is.na(lag_numbers)]
    lag_numbers <- lag_numbers[!is.na(lag_numbers)]
    lag_cols <- lag_cols[order(lag_numbers)]
    
    tbl <- tbl %>%
      rename_with(~ paste0("Lag_", sub("^.*_(-?[0-9]+)$", "\\1", .x)), .cols = all_of(lag_cols))
    
    if (include_period && "Period" %in% names(tbl)) {
      tbl %>% select(Period, Frequency, Series, starts_with("Lag_"))
    } else {
      tbl %>% select(Frequency, Series, starts_with("Lag_"))
    }
  }
  
  combined_tables_list <- lapply(combined_tables_list, normalize_table)
  
  if (is.null(measure_label_map)) {
    measure_label_map <- c(
      mean = "\\textbf{Mean}",
      last = "\\textbf{Last}",
      last_month = "\\textbf{Last Month}",
      lastmonth = "\\textbf{Last Month}"
    )
  }
  
  measure_names <- names(combined_tables_list)
  if (is.null(measure_names) || any(measure_names == "")) {
    stop("combined_tables_list must be a named list.")
  }
  
  # 1. Add measure labels
  combined_tables_list <- Map(function(tbl, measure_name) {
    tbl$Measure <- measure_name
    tbl
  }, combined_tables_list, measure_names)
  
  # 2. Reorder columns
  first_table <- combined_tables_list[[1]]
  cols <- c(if (include_period && "Period" %in% names(first_table)) "Period",
            "Frequency", "Measure", "Series", "Lag_-4", "Lag_-3", "Lag_-2", "Lag_-1", "Lag_0")
  combined_tables_list <- lapply(combined_tables_list, function(tbl) tbl[, cols])
  
  # 3. Combine long-format tables
  combined_table2 <- bind_rows(combined_tables_list)
  combined_table2 <- combined_table2[order(combined_table2$Frequency), ]
  
  # 4. Helper: rename lag columns with suffix
  suffix_cols <- function(df, suffix) {
    df %>%
      rename_with(~ paste0(., "_", suffix), .cols = starts_with("Lag_"))
  }
  
  # 5. Split and widen
  df_qoq <- combined_table2 %>%
    filter(Frequency == "QoQ") %>%
    suffix_cols("QoQ")
  
  df_yoy <- combined_table2 %>%
    filter(Frequency == "YoY") %>%
    suffix_cols("YoY")
  
  qoq_drop_cols <- c("Series", "Frequency", "Measure")
  if (include_period && "Period" %in% names(df_qoq)) {
    qoq_drop_cols <- c(qoq_drop_cols, "Period")
  }
  
  combined_wide <- cbind(
    df_yoy,
    df_qoq %>% ungroup() %>% select(-all_of(qoq_drop_cols))
  )
  
  empty_row <- function(label) {
    combined_wide[1, , drop = FALSE] %>%
      mutate(across(everything(), ~NA)) %>%
      mutate(Series = label, Frequency = NA)
  }
  
  get_measure_label <- function(method_name) {
    label <- measure_label_map[[method_name]]
    if (is.null(label) || is.na(label) || label == "") {
      paste0("\\textbf{", method_name, "}")
    } else {
      unname(label)
    }
  }
  
  ordered_measures <- unique(measure_names)
  present_methods <- ordered_measures[ordered_measures %in% unique(combined_wide$Measure)]
  combined_with_labels <- bind_rows(lapply(present_methods, function(method_name) {
    bind_rows(
      empty_row(get_measure_label(method_name)),
      combined_wide %>% filter(Measure == method_name)
    )
  }))
  
  # 8. Clean table
  combined_table_clean <- combined_with_labels %>%
    ungroup() %>%
    select(-any_of(c("Frequency", "Measure"))) %>%
    mutate(across(everything(), as.character)) %>%
    mutate(across(everything(), ~ ifelse(is.na(.), "", .)))
  
  section_labels <- vapply(present_methods, get_measure_label, character(1))
  section_rows <- which(combined_table_clean$Series %in% section_labels)
  add_lines <- list(pos = section_rows - 1, command = rep("\\midrule\n", length(section_rows)))
  
  # 9. Generate LaTeX table
  table_tex <- kable(
    combined_table_clean,
    format = "latex",
    booktabs = TRUE,
    escape = FALSE,
    col.names = if (include_period && "Period" %in% names(combined_table_clean)) {
      c("Period", "Lags", rep(c("-4", "-3", "-2", "-1", "0"), 2))
    } else {
      c("Lags", rep(c("-4", "-3", "-2", "-1", "0"), 2))
    },
    align = if (include_period && "Period" %in% names(combined_table_clean)) "llrrrrrrrrrr" else "lrrrrrrrrrr",
    caption = caption,
    add.to.row = add_lines
  ) %>%
    add_header_above(if (include_period && "Period" %in% names(combined_table_clean)) {
      c(" " = 2, "YoY" = 5, "QoQ" = 5)
    } else {
      c(" " = 1, "YoY" = 5, "QoQ" = 5)
    }) %>%
    kable_styling(latex_options = "hold_position", full_width = TRUE) %>%
    row_spec(section_rows, bold = TRUE) %>%
    column_spec(1, width = "2.3cm") %>%
    column_spec(if (include_period && "Period" %in% names(combined_table_clean)) 2:12 else 2:11, width = "0.9cm")
  
  # Remove auto-added addlinespace
  table_tex <- gsub("\\\\addlinespace\n?", "", table_tex)
  
  return(list(combined_wide = combined_wide, table_tex = table_tex))
}

print_evaluation_periods <- function(data, series_col, date_col, context_label, frequency_label = NULL, method_label = NULL) {
  if (is.null(data) || nrow(data) == 0) {
    return(invisible(NULL))
  }
  
  period_summary <- data %>%
    filter(!is.na(.data[[series_col]]), !is.na(.data[[date_col]])) %>%
    group_by(Series = .data[[series_col]]) %>%
    summarise(
      start_quarter = as.character(as.yearqtr(min(.data[[date_col]], na.rm = TRUE))),
      end_quarter = as.character(as.yearqtr(max(.data[[date_col]], na.rm = TRUE))),
      .groups = "drop"
    )
  
  if (!is.null(frequency_label)) {
    period_summary <- period_summary %>%
      mutate(Frequency = frequency_label, .before = start_quarter)
  }
  
  if (!is.null(method_label)) {
    period_summary <- period_summary %>%
      mutate(Method = method_label, .before = start_quarter)
  }
  
  message("")
  message(paste0("Evaluation periods: ", context_label))
  print(period_summary, row.names = FALSE)
  
  invisible(period_summary)
}
daily2weekly <- function(x){
  
  idx <- plyr::round_any(x = as.numeric(format(time(x), "%Y")) + 
                           (as.numeric(format(time(x), "%m"))-1)/12 + 
                           as.numeric(format(time(x), "%d"))/365,
                         accuracy = 1/48,
                         f = floor)
  
  ts_weekly <- as.ts(aggregate(x = x,
                               by = idx,
                               FUN = mean,
                               na.rm=T))
  ts_weekly[is.nan(ts_weekly)] <- NA
  ts_weekly
  
}
aggregate_predictor_to_quarterly <- function(df, cut_off_month_pos = NULL, method = "cut_off") {
  df_name <- deparse(substitute(df))
  
  # If name contains "AR", return df with time converted to yearqtr
  if (grepl("AR", df_name)) {
    return(
      result <- df %>%
        mutate(yearqtr = as.yearqtr(time))
    )
  }
  if (method == "last_month") {
    result <- df %>%
    mutate(month = as.numeric(format(time, "%m")),
           yearqtr = as.yearqtr(time)) %>%
    group_by(yearqtr) %>%
      filter(month %% 3 == (cut_off_month_pos %% 3)) %>%
    summarise(value = mean(value, na.rm = TRUE), .groups = "drop") %>% 
    ungroup()
    
  } else if (method == "mean") {
    result <- df %>%
      mutate(quarter = floor_date(time, unit = "quarter")) %>%
      group_by(quarter) %>%
      summarise(value = mean(value, na.rm = TRUE), .groups = "drop") %>%
      ungroup() %>%
      rename(time = quarter) %>%
    mutate(yearqtr = as.yearqtr(time))
    
  } else if (method == "last") {
    result <- df %>%
      mutate(month = as.numeric(format(time, "%m")),
             yearqtr = as.yearqtr(time)) %>%
      group_by(yearqtr) %>%
      filter(month %% 3 == (cut_off_month_pos %% 3)) %>%
      slice_max(order_by = time, with_ties = FALSE) %>%  # Select the latest date per yearqtr
      ungroup() %>%
      select(yearqtr, value)
  } else {
    stop("Unknown method. Please choose 'cut_off', 'mean', or 'last'.")
  }
  
  return(result)
}
get_next_target_vintage <- function(pred_vintage, target_vintages) {
  valid_targets <- target_vintages[target_vintages > pred_vintage]
  if (length(valid_targets) == 0) return(NA_real_)
  min(valid_targets)
}

create_error_summary_tables <- function(error_data, model_order, date_col, lag_range = -4:0, include_period = FALSE) {
  library(dplyr)
  library(tidyr)
  library(purrr)
  
  rmse_rel_cols <- paste0("RMSE_rel_", lag_range)
  mae_rel_cols <- paste0("MAE_rel_", lag_range)
  rmse_abs_cols <- paste0("RMSE_", lag_range)
  mae_abs_cols <- paste0("MAE_", lag_range)
  
  aggregated_errors <- error_data %>%
    mutate(
      Period = ifelse(is_crisis_period(.data[[date_col]]), "Crisis Periods", "Non-Crisis Periods")
    ) %>%
    group_by(.data[[date_col]], Period, model, method, lag_number, frequency) %>%
    summarise(error = mean(error, na.rm = TRUE), .groups = "drop")
  
  grouping_vars <- c("method", "lag_number", "frequency")
  if (include_period) grouping_vars <- c(grouping_vars, "Period")
  
  dm_summary <- aggregated_errors %>%
    group_by(across(all_of(grouping_vars))) %>%
    group_map(~ {
      group_data <- .x
      group_keys <- .y
      
      errors_wai <- group_data %>%
        filter(model == "WAI") %>%
        arrange(.data[[date_col]]) %>%
        pull(error)
      
      if (length(errors_wai) == 0) return(NULL)
      
      all_models_stats <- group_data %>%
        group_by(model) %>%
        summarise(
          RMSE = sqrt(mean(error^2, na.rm = TRUE)),
          MAE = mean(abs(error), na.rm = TRUE),
          .groups = "drop"
        )
      
      dm_results <- group_data %>%
        filter(model != "WAI") %>%
        group_by(model) %>%
        arrange(.data[[date_col]], .by_group = TRUE) %>%
        summarise(
          p_dm_rmse = {
            e1 <- error
            n <- min(length(e1), length(errors_wai))
            e1 <- e1[1:n]
            e2 <- errors_wai[1:n]
            tryCatch(dm_test_modified(e1, e2, h = 1, power = 2, alternative = "greater"), error = function(e) NA_real_)
          },
          p_dm_mae = {
            e1 <- error
            n <- min(length(e1), length(errors_wai))
            e1 <- e1[1:n]
            e2 <- errors_wai[1:n]
            tryCatch(dm_test_modified(e1, e2, h = 1, power = 1, alternative = "greater"), error = function(e) NA_real_)
          },
          .groups = "drop"
        )
      
      out <- all_models_stats %>%
        left_join(dm_results, by = "model") %>%
        mutate(
          method = group_keys$method,
          lag_number = group_keys$lag_number,
          frequency = group_keys$frequency
        )
      if (include_period) out$Period <- group_keys$Period
      out
    }) %>%
    bind_rows() %>%
    group_by(across(all_of(grouping_vars))) %>%
    mutate(
      RMSE_WAI = RMSE[model == "WAI"],
      MAE_WAI = MAE[model == "WAI"],
      rel_RMSE = RMSE / RMSE_WAI,
      rel_MAE = MAE / MAE_WAI
    ) %>%
    ungroup() %>%
    mutate(
      Stars_RMSE = case_when(
        is.na(p_dm_rmse) ~ "",
        p_dm_rmse < 0.01 ~ "***",
        p_dm_rmse < 0.05 ~ "**",
        p_dm_rmse < 0.10 ~ "*",
        TRUE ~ ""
      ),
      Stars_MAE = case_when(
        is.na(p_dm_mae) ~ "",
        p_dm_mae < 0.01 ~ "***",
        p_dm_mae < 0.05 ~ "**",
        p_dm_mae < 0.10 ~ "*",
        TRUE ~ ""
      ),
      RMSE_rel_annotated = paste0(formatC(rel_RMSE, format = "f", digits = 2), Stars_RMSE),
      MAE_rel_annotated = paste0(formatC(rel_MAE, format = "f", digits = 2), Stars_MAE),
      RMSE_abs_annotated = paste0(formatC(RMSE, format = "f", digits = 2), Stars_RMSE),
      MAE_abs_annotated = paste0(formatC(MAE, format = "f", digits = 2), Stars_MAE)
    )
  
  build_metric_list <- function(summary_df, annotated_col, lag_prefix, expected_cols) {
    summary_df %>%
      filter(model %in% model_order) %>%
      split(.$method) %>%
      map(~ {
        table_data <- .x %>%
          mutate(
            Frequency = factor(frequency, levels = c("QoQ", "YoY")),
            Series = factor(model, levels = model_order),
            lag_number = ifelse(lag_number > 0, -lag_number, lag_number),
            lag_label = paste0(lag_prefix, lag_number)
          )
        
        if (include_period) {
          table_data <- table_data %>%
            mutate(Period = factor(Period, levels = c("Non-Crisis Periods", "Crisis Periods"))) %>%
            select(Period, Frequency, Series, lag_label, value = all_of(annotated_col)) %>%
            pivot_wider(names_from = lag_label, values_from = value) %>%
            select(Period, Frequency, Series, all_of(expected_cols)) %>%
            arrange(Period, Frequency, Series)
        } else {
          table_data <- table_data %>%
            select(Frequency, Series, lag_label, value = all_of(annotated_col)) %>%
            pivot_wider(names_from = lag_label, values_from = value) %>%
            select(Frequency, Series, all_of(expected_cols)) %>%
            arrange(Frequency, Series)
        }
        
        table_data
      })
  }
  
  list(
    rel_rmse = build_metric_list(dm_summary, "RMSE_rel_annotated", "RMSE_rel_", rmse_rel_cols),
    rel_mae = build_metric_list(dm_summary, "MAE_rel_annotated", "MAE_rel_", mae_rel_cols),
    abs_rmse = build_metric_list(dm_summary, "RMSE_abs_annotated", "RMSE_", rmse_abs_cols),
    abs_mae = build_metric_list(dm_summary, "MAE_abs_annotated", "MAE_", mae_abs_cols),
    summary = dm_summary
  )
}

get_insample_error_details <- function(method = c("mean", "last", "last_month"),
                                       analysis_set = c("wai_versions", "indicators")) {
  method <- match.arg(method)
  analysis_set <- match.arg(analysis_set)
  
  aggregate_to_quarter <- function(df) {
    if (method == "mean") {
      df %>%
        mutate(quarter = floor_date(time, unit = "quarter")) %>%
        group_by(Series, quarter) %>%
        summarise(value = mean(value, na.rm = TRUE), .groups = "drop")
    } else if (method == "last") {
      df %>%
        mutate(quarter = floor_date(time, unit = "quarter")) %>%
        group_by(Series, quarter) %>%
        slice_max(order_by = time, with_ties = FALSE) %>%
        ungroup() %>%
        select(Series, quarter, value)
    } else {
      df %>%
        mutate(month = floor_date(time, unit = "month")) %>%
        group_by(Series, month) %>%
        summarise(monthly_mean = mean(value, na.rm = TRUE), .groups = "drop") %>%
        mutate(quarter = floor_date(month, unit = "quarter")) %>%
        group_by(Series, quarter) %>%
        slice_max(order_by = month, with_ties = FALSE) %>%
        ungroup() %>%
        rename(value = monthly_mean) %>%
        select(Series, quarter, value)
    }
  }
  
  if (analysis_set == "indicators") {
    base_wai_result <- list(
      tab_gr_qoq = tab_gr %>% select(time, name, value),
      tab_gr_lv = tab_gr_lv
    )
    plot_df_yoy <- bind_rows(
      tab_wai_yoy %>% mutate(Series = "WAI"),
      wwa_gr_df %>% mutate(Series = "SECO-WWA"),
      fcurve_gr_df %>% mutate(Series = "F-CURVE"),
      tab_kss %>% mutate(Series = "SECO-SEC"),
      tab_snb %>% mutate(Series = "SNB-BCI"),
      tab_baro %>% mutate(Series = "KOF-BARO")
    )
    
    plot_df_qoq <- bind_rows(
      prepare_wai_qoq_series(base_wai_result, method) %>% mutate(Series = "WAI"),
      wwa_gr_df_qoq %>% mutate(Series = "SECO-WWA"),
      fcurve_gr_df %>% mutate(Series = "F-CURVE"),
      tab_kss %>% mutate(Series = "SECO-SEC"),
      tab_snb %>% mutate(Series = "SNB-BCI"),
      tab_baro %>% mutate(Series = "KOF-BARO")
    )
  } else {
    plot_df_yoy <- bind_rows(
      result_wai$tab_wai_yoy %>% mutate(Series = "WAI"),
      result_wai_no_sv$tab_wai_yoy %>% mutate(Series = "WAI-SV"),
      result_wai_only_monthly_no_sv$tab_wai_yoy %>% mutate(Series = "WAI-(SV+HF)"),
      result_wai_no_hf$tab_wai_yoy %>% mutate(Series = "WAI-HF"),
      result_wai_no_financial$tab_wai_yoy %>% mutate(Series = "WAI-FIN")#,
     # result_wai_only_total_retail$tab_wai_yoy %>% mutate(Series = "WAI-Retail")
    )
    
    plot_df_qoq <- bind_rows(
      prepare_wai_qoq_series(result_wai, method) %>% mutate(Series = "WAI"),
      prepare_wai_qoq_series(result_wai_no_sv, method) %>% mutate(Series = "WAI-SV"),
      prepare_wai_qoq_series(result_wai_only_monthly_no_sv, method) %>% mutate(Series = "WAI-(SV+HF)"),
      prepare_wai_qoq_series(result_wai_no_hf, method) %>% mutate(Series = "WAI-HF"),
      prepare_wai_qoq_series(result_wai_no_financial, method) %>% mutate(Series = "WAI-FIN")#,
      #prepare_wai_qoq_series(result_wai_only_total_retail, method) %>% mutate(Series = "WAI-Retail")
    )
  }
  
  joined_df_yoy <- aggregate_to_quarter(plot_df_yoy) %>%
    rename(date = quarter, series_value = value) %>%
    inner_join(
      tibble(date = seq.Date(as.Date("1991-01-01"), by = "3 months", length.out = length(x_hist_gr_yoy)),
             GDP_yoy = as.numeric(x_hist_gr_yoy)),
      by = "date"
    )
  
  print_evaluation_periods(
    joined_df_yoy,
    series_col = "Series",
    date_col = "date",
    context_label = paste("In-sample error evaluation,", analysis_set, "YoY"),
    frequency_label = "YoY",
    method_label = method
  )
  
  joined_df_qoq <- aggregate_to_quarter(plot_df_qoq) %>%
    rename(date = quarter, series_value = value) %>%
    inner_join(
      tibble(date = seq.Date(as.Date("1990-01-01"), by = "3 months", length.out = length(x_hist_gr_ann)),
             GDP_qoq = as.numeric(x_hist_gr_ann)),
      by = "date"
    )
  
  print_evaluation_periods(
    joined_df_qoq,
    series_col = "Series",
    date_col = "date",
    context_label = paste("In-sample error evaluation,", analysis_set, "QoQ"),
    frequency_label = "QoQ",
    method_label = method
  )
  
  collect_errors <- function(df, target_var, frequency) {
    df %>%
      group_by(Series) %>%
      nest() %>%
      mutate(details = map2(data, Series, ~ {
        map_dfr(-4:0, function(l) {
          df_lag <- .x %>%
            arrange(date) %>%
            mutate(gdp_lag = lead(.data[[target_var]], n = -l)) %>%
            filter(!is.na(gdp_lag) & !is.na(series_value))
          tibble(
            observation_date = df_lag$date,
            error = df_lag$gdp_lag - predict(lm(gdp_lag ~ series_value, data = df_lag), df_lag),
            model = .y,
            method = method,
            lag_number = l,
            frequency = frequency
          )
        })
      })) %>%
      select(details) %>%
      unnest(details)
  }
  
  bind_rows(
    collect_errors(joined_df_yoy, "GDP_yoy", "YoY"),
    collect_errors(joined_df_qoq, "GDP_qoq", "QoQ")
  )
}


# -----------------------------------------------------------------------------
# Out-of-Sample Evaluation Helpers
# -----------------------------------------------------------------------------
# These functions aggregate predictions across vintages and create the relative
# and absolute forecast error summaries used for the OOS tables.

create_rel_error_tables <- function(combined_results, model_order, lag_range = -4:0) {
   library(dplyr)
   library(tidyr)
   library(purrr)
   
   rmse_cols <- paste0("RMSE_rel_", lag_range)
   mae_cols  <- paste0("MAE_rel_", lag_range)
   
   # Step 1: Aggregate errors
   aggregated_errors <- combined_results %>%
     group_by(target_vintage, model, method, lag_number, GDP_type, frequency) %>%
     summarise(
       error = mean(error, na.rm = TRUE),
       .groups = "drop"
     )
   
   # Step 2: Compute summary stats with DM tests
   dm_summary <- aggregated_errors %>%
     group_by(method, lag_number, frequency) %>%
     group_map(~ {
       group_data <- .x
       group_keys <- .y
       
       errors_wai <- group_data %>%
         filter(model == "WAI") %>%
         pull(error)
       
       if (length(errors_wai) == 0) return(NULL)
       
       all_models_stats <- group_data %>%
         group_by(model) %>%
         summarise(
           RMSE = sqrt(mean(error^2, na.rm = TRUE)),
           MAE = mean(abs(error), na.rm = TRUE),
           .groups = "drop"
         )
       
       dm_results <- group_data %>%
         filter(model != "WAI") %>%
         group_by(model) %>%
         summarise(
           p_dm_rmse = {
             e1 <- error
             n <- min(length(e1), length(errors_wai))
             e1 <- e1[1:n]
             e2 <- errors_wai[1:n]
             tryCatch(dm_test_modified(e1, e2, h = 1, power = 2, alternative = "greater"), error = function(e) NA_real_)
           },
           p_dm_mae = {
             e1 <- error
             n <- min(length(e1), length(errors_wai))
             e1 <- e1[1:n]
             e2 <- errors_wai[1:n]
             tryCatch(dm_test_modified(e1, e2, h = 1, power = 1, alternative = "greater"), error = function(e) NA_real_)
           },
           .groups = "drop"
         )
       
       full_stats <- all_models_stats %>%
         left_join(dm_results, by = "model") %>%
         mutate(
           method = group_keys$method,
           lag_number = group_keys$lag_number,
           frequency = group_keys$frequency
         ) %>%
         select(method, model, lag_number, frequency, everything())
     }) %>%
     bind_rows()
   
   # Step 3: Relative RMSE/MAE
   dm_summary <- dm_summary %>%
     group_by(method, lag_number, frequency) %>%
     mutate(
       RMSE_WAI = RMSE[model == "WAI"],
       MAE_WAI = MAE[model == "WAI"],
       rel_RMSE = RMSE / RMSE_WAI,
       rel_MAE = MAE / MAE_WAI
     ) %>%
     mutate(across(where(is.numeric), ~ round(.x, 2))) %>%
     ungroup() %>%
     select(-RMSE_WAI, -MAE_WAI)
   
   # Step 4: Significance stars and annotation
   dm_summary <- dm_summary %>%
     mutate(
       Stars_RMSE = case_when(
         is.na(p_dm_rmse) ~ "",
         p_dm_rmse < 0.01 ~ "***",
         p_dm_rmse < 0.05 ~ "**",
         p_dm_rmse < 0.10 ~ "*",
         TRUE             ~ ""
       ),
       Stars_MAE = case_when(
         is.na(p_dm_mae) ~ "",
         p_dm_mae < 0.01 ~ "***",
         p_dm_mae < 0.05 ~ "**",
         p_dm_mae < 0.10 ~ "*",
         TRUE            ~ ""
       ),
       RMSE_annotated = paste0(formatC(rel_RMSE, format = "f", digits = 2), Stars_RMSE),
       MAE_annotated  = paste0(formatC(rel_MAE,  format = "f", digits = 2), Stars_MAE)
     )
   
   # Step 5: Create RMSE tables
   rel_rmse_list <- dm_summary %>%
     filter(model %in% model_order) %>%
     split(.$method) %>%
     map(~ {
       .x %>%
         mutate(
           Frequency = factor(frequency, levels = c("QoQ", "YoY")),
           Series = factor(model, levels = model_order),
           lag_number = ifelse(lag_number > 0, -lag_number, lag_number),
           lag_label = paste0("RMSE_rel_", lag_number)
         ) %>%
         select(Frequency, Series, lag_label, RMSE_annotated) %>%
         pivot_wider(names_from = lag_label, values_from = RMSE_annotated) %>%
         select(Frequency, Series, all_of(rmse_cols)) %>%
         arrange(Frequency, Series)
     })
   
   # Step 6: Create MAE tables
   rel_mae_list <- dm_summary %>%
     filter(model %in% model_order) %>%
     split(.$method) %>%
     map(~ {
       .x %>%
         mutate(
           Frequency = factor(frequency, levels = c("QoQ", "YoY")),
           Series = factor(model, levels = model_order),
           lag_number = ifelse(lag_number > 0, -lag_number, lag_number),
           lag_label = paste0("MAE_rel_", lag_number)
         ) %>%
         select(Frequency, Series, lag_label, MAE_annotated) %>%
         pivot_wider(names_from = lag_label, values_from = MAE_annotated) %>%
         select(Frequency, Series, all_of(mae_cols)) %>%
         arrange(Frequency, Series)
     })
   
   # Return both lists
   list(rel_rmse = rel_rmse_list, rel_mae = rel_mae_list)
 }
