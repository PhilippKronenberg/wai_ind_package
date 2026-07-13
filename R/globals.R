# Non-standard-evaluation column names and load()-created objects used in
# package code; declared to silence R CMD check "no visible binding" notes.
utils::globalVariables(c(
  # load()-created objects
  "mod",
  # tidy column names used across the analytics functions
  "name", "value", "Series", "quarter", "month", "monthly_mean",
  "gdp_lag", "Lag", "Correlation", "Frequency", "GDP_yoy", "GDP_qoq",
  "series_start", "series_value", "date", "data", "cor_lags", "metrics",
  "RMSE", "MAE", "R2", "P_DM_RMSE", "P_DM_MAE", "PValue", "Stars",
  "Value", "Annotated", "Period", "model", "lag_number", "lag_label",
  "target_vintage", "GDP_type", "error", "RMSE_WAI", "MAE_WAI",
  "rel_RMSE", "rel_MAE", "p_dm_rmse", "p_dm_mae", "Stars_RMSE",
  "Stars_MAE", "RMSE_annotated", "MAE_annotated", "RMSE_relative",
  "MAE_relative", "level_value", "yearqtr", "y", "Peak", "Trough",
  "start_quarter", "end_quarter", "details", "observation_date",
  "Measure", "full_stats", "result",
  # magrittr placeholder and grouping column referenced via split(.$method)
  ".", "method",
  # names bound at runtime by list2env(inputs, environment()) in the
  # in-sample table builders (see get_combined_cor_table etc.)
  "tab_wai_yoy", "wwa_gr_df", "wwa_gr_df_qoq", "fcurve_gr_df", "tab_kss",
  "tab_snb", "tab_baro", "tab_gr", "tab_gr_lv", "result_wai",
  "result_wai_no_sv", "result_wai_only_monthly_no_sv", "result_wai_no_hf",
  "result_wai_no_financial", "x_hist_gr_yoy", "x_hist_gr_ann"
))
