sample_configs <- list(
  #list(
  #   sample_id = "sample_2021Q4",
  #   sample_end_date = as.Date("2021-12-31"),
  #   output_root = file.path("outputs", "plots_insample", "sample_2021Q4"),
  #   fit_root = "fits",
  #   fit_rt_dir = file.path("fits", "full_RT")
  # )
  # ,
  list(
    sample_id = "sample_2025Q4",
    sample_end_date = as.Date("2026-03-07"),
    output_root = file.path("outputs", "plots_insample", "sample_2025Q4"),
    fit_root = "fits",
    fit_rt_dir = file.path("fits", "updated","full_RT")
  )
)

for (cfg in sample_configs) {
  message(sprintf("Running plots_analytics.R for %s", cfg$sample_id))
  sample_config <- cfg
  #sys.source("analysis/5_plots/plots_analytics.R", envir = new.env(parent = globalenv()))
}
