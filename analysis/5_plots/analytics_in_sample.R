# -----------------------------------------------------------------------------
# analytics_in_sample.R
# -----------------------------------------------------------------------------
# Purpose:
# This file creates the in-sample figures and LaTeX tables for the analytics
# workflow. It uses the shared data objects prepared in analytics_data.R andhttp://127.0.0.1:11314/graphics/plot_zoom_png?width=2115&height=1236
# produces history plots, correlation heatmaps, and in-sample fit summaries.
#
# How to use:
# Run this file directly after sourcing analytics_functions.R, or simply source
# it on its own. If the shared data objects are missing, it will automatically
# source analytics_data.R first.
# -----------------------------------------------------------------------------

source("analysis/5_plots/_setup.R")

#if (!exists("plots_insample_data_ready", inherits = FALSE)) {
  source("analysis/5_plots/analytics_data.R")
#}

# -----------------------------------------------------------------------------
# Plot Style and Crisis Windows
# -----------------------------------------------------------------------------
# Define the shared plotting theme and the crisis shading windows used across
# the in-sample figures.

PlotOptions = list(
  geom_line(),
  theme_minimal(),
  theme(panel.spacing=unit(3, "lines")),
  if (has_ggsci) ggsci::scale_color_npg(),
  #scale_color_brewer(palette = "Blues"),
  guides(col = guide_legend(ncol = 1)),
  theme(plot.title = element_blank(), 
        legend.position = "bottom",
        text = element_text(size = 12),
        legend.title=element_blank(),
        axis.text.y = element_text(size = 12),
        axis.text.x = element_text(size = 12),
        axis.title.x.bottom = element_text(size = 12),
        legend.text=element_text(size=12),
        panel.grid.major.x = element_line(size = 0.2),
        panel.grid.major.y = element_line(size = 0.2),
        panel.grid.minor.x = element_blank(),
        panel.grid.minor.y = element_blank())
)
rec_dates<- matrix(c("Excluding Corona Crisis", "2008-07-07", "2009-09-28", # 2008Q2-2009Q3 (Great Recession)
                     #"Excluding Corona Crisis", "2011-07-07", "2013-03-28", # 2011Q3-2013Q1 (Euro Crisis)
                     #"Excluding Corona Crisis", "2015-01-07", "2015-06-28", # 2015Q1-2015Q2 (Swiss Franc Shock)
                     #"Excluding Corona Crisis", "2018-06-08", "2018-09-28", #
                     "Corona Crisis", "2020-01-01", "2021-12-28"  # 2020Q1-2021Q4 (Corona Crisis)
), ncol=3,byrow=T)
# Create the default crisis-shading table used in the main history figures.
crises <- data.frame("time_periods_crisis" = rec_dates[,1], 
                     Peak = as.Date(rec_dates[,2]),
                     Trough = as.Date(rec_dates[,3]))


# -----------------------------------------------------------------------------
# Full-History WAI Figures
# -----------------------------------------------------------------------------
# Plot the long WAI history, including growth, level, and volatility, together
# with GDP references and crisis shading.
history_full_x_breaks <- as.Date(as.yearmon(seq(from = 1990, to = 2025, by = 5)))
history_full_axis_end <- max(
  tab_gr_full$time,
  hist_tab_gr_full$value,
  tab_gr_lv_full$time,
  hist_tab_gr_lv_full$value,
  tab_gr_vol$time,
  na.rm = TRUE
)

# Stack the three main diagnostics vertically so the long-run dynamics can be
# read as one figure.
a <- ggplot() +
  geom_hline(yintercept=0, col = "grey50") +
  PlotOptions +
  geom_ribbon(data = tab_gr_full, aes(x = time, ymin = min, ymax = max), fill = "lightblue", alpha = 0.5) +
  geom_line(data = tab_gr_full, mapping = aes(x = time, y = value)) +
  coord_cartesian(ylim = c(-30,30)) +
  ylab("Growth Rates (in %, annualized)") +
  xlab(NULL) +
  scale_y_continuous(breaks = seq(-30,30,10)) +
  scale_x_date(limits = c(as.Date("1990-01-01"), history_full_axis_end),
               breaks = history_full_x_breaks,
               date_labels = "%Y") +
  geom_line(data = hist_tab_gr_full, mapping = aes(y = y, x = value, group = y), color = "red") +
  geom_rect(data = crises, aes(xmin=Peak, xmax=Trough, ymin=-Inf, ymax=Inf),
            fill='grey80', alpha = 0.2) +
  theme(axis.text.x = element_blank())
# Plot the normalized WAI level against the GDP level history.
b <- ggplot() +
  geom_hline(yintercept=0, col = "grey50") +
  PlotOptions +
  #geom_ribbon(data = tab_gr_lv, aes(x = time, ymin = min, ymax = max), fill = "lightblue", alpha = 0.5) +  # does not work yet
  geom_line(data = tab_gr_lv_full, mapping = aes(x = time, y = value)) +
  # coord_cartesian(ylim = c(-40,40)) +
  ylab("Index (100 = Q4 2019)") + 
  xlab(NULL) +
  scale_y_continuous(limits = c(min(tab_gr_lv_full$value),max(tab_gr_lv_full$value))) + #breaks = seq(-30,30,10)) +
  scale_x_date(limits = c(as.Date("1990-01-01"), history_full_axis_end),
               breaks = history_full_x_breaks,
               date_labels = "%Y") +
  geom_line(data = hist_tab_gr_lv_full, mapping = aes(y = y, x = value, group = y), color = "red") +
  geom_rect(data = crises, aes(xmin=Peak, xmax=Trough, ymin=-Inf, ymax=Inf), 
            fill='grey80', alpha = 0.2) +
  theme(axis.text.x = element_blank())
# Plot the estimated stochastic volatility as the third diagnostic panel.
c <- ggplot() +
  PlotOptions +
  geom_line(data = tab_gr_vol, aes(x = time, y = vol)) + 
  ylab("Stochastic Volatility") + 
  xlab(NULL) +
  scale_y_continuous(breaks = seq(0,0.2,0.05), limits = c(0,0.15)) +
  scale_x_date(limits = c(as.Date("1990-01-01"), history_full_axis_end),
               breaks = history_full_x_breaks,
               date_labels = "%Y") +
  geom_rect(data = crises, aes(xmin=Peak, xmax=Trough, ymin=-Inf, ymax=Inf), 
            fill='grey80', alpha = 0.2) 
ggarrange(a, b, c, ncol = 1, nrow = 3, heights = c(4,2,2), align = "hv")
ggsave(output_figure_path("history_full_05.pdf", figures_dir), width = 33, height = 25, units = "cm")


# -----------------------------------------------------------------------------
# Crisis Sequence and Corona Figures
# -----------------------------------------------------------------------------
# Create focused visualizations for selected crisis episodes and the Corona
# period using the weekly WAI and GDP history.

time_periods_crisis <- c("2008Q2-2009Q3") #,"2020Q1-Today")
# Map weekly dates to the internal decimal-week format so crisis windows can be
# sliced using the same boundaries as the model output.
tab_gr$periods <- plyr::round_any(x = as.numeric(format(tab_gr$time, "%Y")) + 
                                 (as.numeric(format(tab_gr$time, "%m"))-1)/12 + 
                                 as.numeric(format(tab_gr$time, "%d"))/365,
                               accuracy = 1/48,
                               f = floor)
results_tab_gr <- list()
# Slice the weekly WAI history into comparable crisis windows for faceted plots.
results_tab_gr$'2008Q2-2009Q3' <- tab_gr %>% filter(periods >= 2008 & periods <= 2010.25)
#results_tab_gr$'2011Q3-2013Q1' <- tab_gr %>% filter(periods >= 2011.25 + 5/48 & periods <= 2013.25 + 5/48)
#results_tab_gr$'2015Q1-2015Q2' <- tab_gr %>% filter(periods >= 2014.25 & periods <= 2016.25)
#results_tab_gr$'2018Q3-2018Q4' <- tab_gr %>% filter(periods >= 2017.75 & periods <= 2019.25)
results_tab_gr <- lapply(time_periods_crisis, function(x){
  results_tab_gr[[x]] %>% 
    mutate(time_periods_crisis = x)
})
names(results_tab_gr) <- time_periods_crisis
data_all_tab_gr <- do.call(rbind.data.frame, results_tab_gr)
data_all_tab_gr$time_periods_crisis <- factor(data_all_tab_gr$time_periods_crisis, 
                                           levels=c("2008Q2-2009Q3"),
                                           labels=c("Great Recession"))
# Repeat the same crisis slicing for the historical GDP series so both lines
# align inside the faceted crisis panels.
hist_tab_gr$periods <- plyr::round_any(x = as.numeric(format(hist_tab_gr$value, "%Y")) + 
                                      (as.numeric(format(hist_tab_gr$value, "%m"))-1)/12 + 
                                      as.numeric(format(hist_tab_gr$value, "%d"))/365,
                                    accuracy = 1/48,
                                    f = floor)
results_hist_tab_gr <- list()
results_hist_tab_gr$'2008Q2-2009Q3' <- hist_tab_gr %>% filter(periods >= 2008.25 & periods <= 2010.25)
#results_hist_tab_gr$'2011Q3-2013Q1' <- hist_tab_gr %>% filter(periods >= 2011.25 + 5/48 & periods <= 2013.25 + 5/48)
#results_hist_tab_gr$'2015Q1-2015Q2' <- hist_tab_gr %>% filter(periods >= 2014.25 & periods <= 2016.25)
#results_hist_tab_gr$'2018Q3-2018Q4' <- hist_tab_gr %>% filter(periods >= 2017.75 & periods <= 2019.25)
results_hist_tab_gr <- lapply(time_periods_crisis, function(x){
  results_hist_tab_gr[[x]] %>% 
    mutate(time_periods_crisis = x)
  
})
names(results_hist_tab_gr) <- time_periods_crisis
data_all_hist_tab_gr <- do.call(rbind.data.frame, results_hist_tab_gr)
data_all_hist_tab_gr$time_periods_crisis <- factor(data_all_hist_tab_gr$time_periods_crisis, 
                                                   levels=c("2008Q2-2009Q3"),
                                                   labels=c("Great Recession"))
rec_dates<- matrix(c("2008Q2-2009Q3", "2008-07-07", "2009-09-28"#, # 2008Q4-2009Q3 (Great Recession)
                   #  "2011Q3-2013Q1", "2011-07-07", "2013-03-28", # 2011Q3-2013Q1 (European Sovereign Debt Crisis)
                  #   "2015Q1-2015Q2", "2015-01-07", "2015-06-28", # 2015Q1-2015Q2 (Swiss Franc Shock)
                  #   "2018Q3-2018Q4", "2018-06-07", "2018-9-28" # 2018Q3-2018Q4 (German Car Production Slump)
                     #"2020Q1-2021Q4", "2020-01-01", "2021-12-28"  # 2020Q1-2020Q2 (Corona Crisis)
), ncol=3,byrow=T)
crises <- data.frame("time_periods_crisis" = rec_dates[,1], 
                     Peak = as.Date(rec_dates[,2]),
                     Trough = as.Date(rec_dates[,3]))
crises$time_periods_crisis <- factor(crises$time_periods_crisis,
                                     levels=c("2008Q2-2009Q3"),
                                     labels=c("Great Recession"))
ggplot() +
  PlotOptions +
  geom_hline(yintercept=0, col = "grey50") +
  geom_ribbon(data = data_all_tab_gr, aes(x = time, ymin = min, ymax = max),
              color = NA, fill = "lightblue", alpha = 0.5) +
  geom_line(data = data_all_tab_gr, mapping = aes(x = time, y = value)) +
  facet_wrap(time_periods_crisis ~ ., nrow = 1, scales = "free_x") +
  ylab("Weekly GDP Growth (in %, annualized)") + 
  xlab(NULL) +
  geom_line(data = data_all_hist_tab_gr, mapping = aes(y = y, x = value, group = y),
            color = "red") +
  theme(panel.spacing=unit(0.2, "lines")) +
  scale_x_date(breaks = date_breaks("6 months"), labels = date_format("%b-%y")) +
  theme(axis.text.x = element_text(size = rel(1), angle = 00)) +
  geom_rect(data = crises, aes(xmin=Peak, xmax=Trough, ymin=-Inf, ymax=Inf), 
            fill='grey80', alpha = 0.2)
ggsave(output_figure_path("history_sequence_crisis.pdf", figures_dir), width = 25, height = 12, units = "cm")

# Define policy-event markers used in the dedicated Corona-period chart.
corona_plot_end_date <- as.Date("2022-04-07")
corona_plot_axis_end_date <- as.Date("2022-04-21")
label <- data.frame(time = as.Date(c("2020-02-25","2020-03-16","2020-05-11",
                                     "2020-06-14","2020-10-19","2020-12-22",
                                     "2021-01-04","2021-01-28","2021-03-01",
                                     "2021-04-19","2021-06-26","2021-09-08",
                                     "2022-01-18","2022-04-01")), 
                    value = 80, 
                    label = c(1:14),
                    # Keep the long legend text in a separate column for plotting.
                    legend = sapply(c("1: First Confirmed Corona Case",
                               "2: First Nationwide Lockdown",
                               "3: Reopening of Stores & Schools",
                               "4: Reopening of Borders",
                               "5: Retightening of Social Distancing Rules",
                               "6: Second Nationwide Lockdown",
                               "7: Begin Vaccination Campaign",
                               "8: Free COVID-19 Tests Available",
                               " 9: Reopening of Stores & Public Facilities",
                               "10: Reopening of Outdoor Restaurants",
                               "11: Easing of Social Distancing Measures",
                               "12: COVID-19 Certificate Obligation",
                               "13: Removement of mask and certificate requirement",
                               "14: Abolishment of remaining measures"
                               ), factor))
tab_gr_corona <- tab_gr %>% filter(time >= "2020-01-01")
tab_gr_corona <- tab_gr_corona %>% filter(time <= corona_plot_end_date)
hist_tab_gr_corona <- hist_tab_gr %>% filter(value >= "2020-01-01")
hist_tab_gr_corona <- hist_tab_gr_corona %>% filter(value <= corona_plot_end_date)
ggplot(mapping = aes(x = time, y = value)) +
  geom_vline(data = label, aes(xintercept = time, color = legend), linetype="dotted", size=0.4) +
  geom_hline(yintercept=0, col = "grey50") +
  geom_ribbon(data = tab_gr_corona, aes(ymin = min, ymax = max),
              color = NA, fill = "light blue", alpha = 0.5) +
  geom_line(data = tab_gr_corona, mapping = aes(y = value)) +
  geom_line(data = hist_tab_gr_corona, mapping = aes(y = y, x = value, group = y), color = "red") +
  geom_label(data = label, aes(label = label)) +
  xlab(NULL) + 
  ylab("Weekly GDP Growth (in %, annualized)") + 
  scale_y_continuous(limits = c(-50, 90), breaks = seq(-50, 90, 10)) +
  scale_x_date(breaks = date_breaks("3 month"), limits = c(as.Date("2020-01-01"), corona_plot_axis_end_date), expand = c(0,0), labels = date_format("%b-%y")) +
  scale_color_manual(name = NULL, values = rep("black",nrow(label))) +
  theme_minimal() + 
  theme(plot.title = element_blank(), 
        legend.position = "bottom",
        text = element_text(size = 12),
        legend.title=element_blank(),
        legend.text = element_text(size = 8),
        panel.grid.major.x = element_line(size = 0.2),
        panel.grid.major.y = element_line(size = 0.2),
        panel.grid.minor.x = element_blank(),
        legend.spacing.x = unit(-0.2, "cm"),
        plot.margin = unit(c(0.2,1.8,0.1,0.5), "cm"),
        panel.grid.minor.y = element_blank()) +
  guides(color=guide_legend(ncol=3, override.aes = list(color = "white")))
ggsave(output_figure_path("history_corona_crisis.pdf", figures_dir), width = 20, height = 14, units = "cm")

# Rebuild the crisis windows once more for the GDP-only quarterly history chart.
startdate <- "2005-01-01"
enddate <- as.character(sample_end_date)
rec_dates<- matrix(c("2008Q2-2009Q3", "2008-07-07", "2009-09-28", # 2008Q4-2009Q3 (Great Recession)
                   #  "2011Q3-2013Q1", "2011-07-07", "2013-03-28", # 2011Q3-2013Q1 (European Sovereign Debt Crisis)
                  #   "2015Q1-2015Q2", "2015-01-07", "2015-06-28", # 2015Q1-2015Q2 (Swiss Franc Shock)
                  #   "2018Q3-2018Q4", "2018-06-07", "2018-09-28", # 2018Q3-2018Q4 (German Car Production Slump)
                     "2020Q1-2021Q4", "2020-01-01", "2021-12-28"  # 2020Q1-2021Q4 (Corona Crisis)
), ncol=3,byrow=T)
crises <- data.frame(Peak = as.Date(rec_dates[,2]),
                     Trough = as.Date(rec_dates[,3]))
ggplot() +
  PlotOptions +
  geom_hline(yintercept=0, col = "grey50") +
  geom_line(data = x_hist_gr_ann, mapping = aes(x = as.Date(as.yearqtr(time(x_hist_gr_ann))), y = x_hist_gr_ann)) +
  scale_x_date(minor_breaks = seq(as.Date("1990-01-01"), last(as.Date(as.yearqtr(time(x_hist_gr_ann)))), "3 month"),
               limits = c(as.Date("2005-01-01"), sample_end_date + 1), 
               breaks = as.Date(as.yearmon(seq(from = 2005, to = as.numeric(format(sample_end_date, "%Y")), by = 2))), date_labels = "%Y") +
  scale_y_continuous(limits = c(-30,30), breaks = c(seq(from = -30, to = 30, by = 5))) +
  ylab("Quarterly GDP Growth (in %, annualized)") +
  xlab(NULL) +
  #scale_y_continuous(breaks = seq(-35,5,5)) +
  #geom_hline(yintercept=0, linetype="dotted", color = "black", size = 0.3) +
  geom_rect(data = crises, aes(xmin=Peak, xmax=Trough, ymin=-Inf, ymax=Inf), fill='grey80', alpha = 0.2)
ggsave(output_figure_path("GDP_qoq.pdf", figures_dir), width = 20, height = 10, units = "cm")


# -----------------------------------------------------------------------------
# Indicator Comparison Figures
# -----------------------------------------------------------------------------
# Build the comparison plots between WAI and the benchmark indicators in both
# YoY and QoQ form, plus the comparison across alternative WAI specifications.

library(dplyr)
library(tidyr)
library(zoo)
library(ggplot2)
library(ggpubr)
# Convert the benchmark zoo series into tidy data frames limited to the sample
# window used in the in-sample comparison figures.
tab_kss <- data.frame("mean" = as.numeric(kss_zoo[,1]),
                      "time" = time(kss_zoo)) %>%
  pivot_longer(-c(time))
tab_kss_full <- tab_kss
tab_kss <- tab_kss %>%
  filter(time >= as.Date("2005-01-01"),
         time <= sample_end_date)
tab_snb <- data.frame("mean" = as.numeric(snb_zoo[,1]),
                      "time" = time(snb_zoo)) %>%
  pivot_longer(-c(time))
tab_snb_full <- tab_snb
tab_snb <- tab_snb %>%
  filter(time >= as.Date("2005-01-01"),
         time <= sample_end_date)
baro_zoo <- zoo(baro_zoo, order.by = index(baro_zoo))
tab_baro <- data.frame("mean" = as.numeric(baro_zoo[,1]),
                       "time" = time(baro_zoo)) %>%
  pivot_longer(-c(time))
tab_baro_full <- tab_baro
tab_baro <- tab_baro %>%
  filter(time >= as.Date("2005-01-01"),
         time <= sample_end_date)
# Put each benchmark onto the GDP scale separately for the YoY and QoQ plots.
wwa_gr_df_yoy    <- rescale_to_gdp(wwa_gr_df,    hist_tab_gr_yoy)  # SECO-WEA
fcurve_gr_df_yoy <- rescale_to_gdp(fcurve_gr_df, hist_tab_gr_yoy)  # F-Curve
tab_kss_yoy      <- rescale_to_gdp(tab_kss,      hist_tab_gr_yoy)  # SECO-SEC
tab_snb_yoy      <- rescale_to_gdp(tab_snb,      hist_tab_gr_yoy)  # SNB-BCI
tab_baro_yoy     <- rescale_to_gdp(tab_baro,     hist_tab_gr_yoy)  # KOF-BARO
wwa_gr_df_qoq    <- rescale_to_gdp(wwa_gr_df,    hist_tab_gr)      # SECO-WEA
fcurve_gr_df_qoq <- rescale_to_gdp(fcurve_gr_df, hist_tab_gr)      # F-Curve
tab_kss_qoq      <- rescale_to_gdp(tab_kss,      hist_tab_gr)      # SECO-SEC
tab_snb_qoq      <- rescale_to_gdp(tab_snb,      hist_tab_gr)      # SNB-BCI
tab_baro_qoq     <- rescale_to_gdp(tab_baro,     hist_tab_gr)      # KOF-BARO
# Rescale benchmark indicators to GDP moments so the visual comparison is about
# co-movement rather than raw units.
d_yoy <- plot_comparison(tab_wai_yoy, wwa_gr_df_yoy,    "SECO-WEA", crises, hist_tab_gr_yoy, sample_end_date, "SECO-WEA vs WAI (YoY)")
e_yoy <- plot_comparison(tab_wai_yoy, fcurve_gr_df_yoy, "F-Curve",  crises, hist_tab_gr_yoy, sample_end_date, "F-Curve vs WAI (YoY)")
f_yoy <- plot_comparison(tab_wai_yoy, tab_kss_yoy,      "SECO-SEC", crises, hist_tab_gr_yoy, sample_end_date, "SECO-SEC vs WAI (YoY)")
g_yoy <- plot_comparison(tab_wai_yoy, tab_snb_yoy,      "SNB-BCI",  crises, hist_tab_gr_yoy, sample_end_date, "SNB-BCI vs WAI (YoY)")
h_yoy <- plot_comparison(tab_wai_yoy, tab_baro_yoy,     "KOF-BARO", crises, hist_tab_gr_yoy, sample_end_date, "KOF-BARO vs WAI (YoY)")
col_yoy <- ggarrange(d_yoy, e_yoy, f_yoy, g_yoy, h_yoy,
                     ncol = 1, nrow = 5, align = "hv")
# Build the matching set of QoQ comparison panels with the same layout.
d_qoq <- plot_comparison(tab_gr, wwa_gr_df_qoq,    "SECO-WEA", crises, hist_tab_gr, sample_end_date, "SECO-WEA vs WAI (QoQ)", ylim_fixed = c(-25, 25))
e_qoq <- plot_comparison(tab_gr, fcurve_gr_df_qoq, "F-Curve",  crises, hist_tab_gr, sample_end_date, "F-Curve vs WAI (QoQ)",  ylim_fixed = c(-25, 25))
f_qoq <- plot_comparison(tab_gr, tab_kss_qoq,      "SECO-SEC", crises, hist_tab_gr, sample_end_date, "SECO-SEC vs WAI (QoQ)", ylim_fixed = c(-25, 25))
g_qoq <- plot_comparison(tab_gr, tab_snb_qoq,      "SNB-BCI",  crises, hist_tab_gr, sample_end_date, "SNB-BCI vs WAI (QoQ)",  ylim_fixed = c(-25, 25))
h_qoq <- plot_comparison(tab_gr, tab_baro_qoq,     "KOF-BARO", crises, hist_tab_gr, sample_end_date, "KOF-BARO vs WAI (QoQ)", ylim_fixed = c(-25, 25))
col_qoq <- ggarrange(d_qoq, e_qoq, f_qoq, g_qoq, h_qoq,
                     ncol = 1, nrow = 5, align = "hv")
final_fig <- ggarrange(col_yoy, col_qoq, ncol = 2, nrow = 1, align = "hv")
final_fig
ggsave(output_figure_path("history_comparison_yoy_qoq.pdf", figures_dir),
       final_fig, width = 44, height = 44, units = "cm")

# Load the alternative WAI fits and compare each specification back to the main WAI.
result_wai <- list(
  tab_wai_yoy = tab_wai_yoy,
  tab_gr_qoq = tab_gr,
  tab_gr_lv = tab_gr_lv
)
result_wai_no_sv <- extract_wai_data(file.path(sample_config$fit_root, "updated/full_no_sv/fit_2025.979.Rda"))
result_wai_only_monthly_no_sv <- extract_wai_data(file.path(sample_config$fit_root, "updated/only_monthly_no_sv/fit_2025.979.Rda"))
result_wai_no_hf <- extract_wai_data(file.path(sample_config$fit_root, "updated/only_monthly/fit_2025.979.Rda"))
result_wai_no_financial <- extract_wai_data(file.path(sample_config$fit_root, "updated/no_financial/fit_2025.979.Rda"))
#result_wai_only_total_retail <- extract_wai_data(latest_fit_file(file.path(sample_config$fit_root, "only_total_retail"), sample_end_fit_decimal))
result_wai_no_sv_qoq_scaled <- rescale_to_gdp(result_wai_no_sv$tab_gr_qoq, hist_tab_gr)
result_wai_only_monthly_no_sv_qoq_scaled <- rescale_to_gdp(result_wai_only_monthly_no_sv$tab_gr_qoq, hist_tab_gr)
result_wai_no_hf_qoq_scaled <- rescale_to_gdp(result_wai_no_hf$tab_gr_qoq, hist_tab_gr)
result_wai_no_financial_qoq_scaled <- rescale_to_gdp(result_wai_no_financial$tab_gr_qoq, hist_tab_gr)
kk <- plot_comparison(result_wai$tab_gr_qoq, result_wai_no_sv_qoq_scaled, "WAI-SV", crises, hist_tab_gr, sample_end_date, plot_title = "WAI-SV vs WAI", ylim_fixed = c(-25, 25))
ll <- plot_comparison(result_wai$tab_gr_qoq, result_wai_only_monthly_no_sv_qoq_scaled, "WAI-(SV+HF)", crises, hist_tab_gr, sample_end_date, plot_title = "WAI-(SV+HF) vs WAI", ylim_fixed = c(-25, 25)) # F-Curve has some missing values
mm <- plot_comparison(result_wai$tab_gr_qoq, result_wai_no_hf_qoq_scaled, "WAI-HF", crises, hist_tab_gr, sample_end_date, plot_title = "WAI-HF vs WAI", ylim_fixed = c(-25, 25)) # F-Curve has some missing values
nn <- plot_comparison(result_wai$tab_gr_qoq, result_wai_no_financial_qoq_scaled, "WAI-FIN", crises, hist_tab_gr, sample_end_date, plot_title = "WAI-FIN vs WAI", ylim_fixed = c(-25, 25))
#oo <- plot_comparison(result_wai$tab_gr_qoq, result_wai_only_total_retail$tab_gr_qoq, "WAI-Retail", crises, hist_tab_gr, sample_end_date, plot_title = "WAI-Retail vs WAI", ylim_fixed = c(-25, 25))
comparison_wai_fig <- ggarrange(kk, ll, mm, nn, ncol = 1, nrow = 4, align = "hv")
comparison_wai_fig
ggsave(output_figure_path("history_comparison_wai.pdf", figures_dir), comparison_wai_fig, width = 33, height = 35.2, units = "cm")


# -----------------------------------------------------------------------------
# Correlation Tables and Heatmaps
# -----------------------------------------------------------------------------
# Compute cross-correlation tables for both indicator comparisons and WAI
# variants, then render the corresponding heatmaps.

library(dplyr)
library(tidyr)
library(purrr)
library(lubridate)
# Bundle the data objects the in-sample table builders need (their former
# implicit globals) into an explicit inputs list.
insample_inputs <- mget(c(
  "tab_gr", "tab_gr_lv", "x_hist_gr_yoy", "x_hist_gr_ann",
  "tab_wai_yoy", "wwa_gr_df", "wwa_gr_df_qoq", "fcurve_gr_df",
  "tab_kss", "tab_snb", "tab_baro",
  "result_wai", "result_wai_no_sv", "result_wai_only_monthly_no_sv",
  "result_wai_no_hf", "result_wai_no_financial"
))

methods <- c("mean", "last", "last_month")
combined_tables_list <- lapply(methods, get_combined_cor_table, inputs = insample_inputs)
names(combined_tables_list) <- methods
combined_tables_list_indicators <- lapply(methods, get_combined_cor_table, analysis_set = "indicators", inputs = insample_inputs)
names(combined_tables_list_indicators) <- methods
# Add the aggregation-method labels explicitly so the combined LaTeX table can
# show grouped rows for mean, last, and last-month aggregation.
combined_tables_list2 <- combined_tables_list
combined_tables_list2$mean$Measure <- "mean"
combined_tables_list2$last$Measure <- "last"
combined_tables_list2$last_month$Measure <- "lastmonth"
combined_tables_list2$mean <- combined_tables_list2$mean[, c("Frequency", "Measure", "Series", "Lag_-4", "Lag_-3", "Lag_-2", "Lag_-1", "Lag_0")]
combined_tables_list2$last <- combined_tables_list2$last[, c("Frequency", "Measure", "Series", "Lag_-4", "Lag_-3", "Lag_-2", "Lag_-1", "Lag_0")]
combined_tables_list2$last_month <- combined_tables_list2$last_month[, c("Frequency", "Measure", "Series", "Lag_-4", "Lag_-3", "Lag_-2", "Lag_-1", "Lag_0")]
combined_table2 <- rbind(combined_tables_list2$mean, combined_tables_list2$last, combined_tables_list2$last_month )
combined_table2 <- combined_table2[order(combined_table2$Frequency), ]
library(dplyr)
# Convert the long correlation output into a wide YoY/QoQ comparison table.
df_qoq <- combined_table2 %>%
  filter(Frequency == "QoQ") %>%
  suffix_cols("QoQ")
df_yoy <- combined_table2 %>%
  filter(Frequency == "YoY") %>%
  suffix_cols("YoY")
combined_wide <- cbind(
  df_yoy,
  df_qoq %>% ungroup() %>% select(-Series, -Frequency, -Measure)
)
library(dplyr)
library(knitr)
library(kableExtra)
mean_index <- which(combined_wide$Measure == "mean")[1]
last_index <- which(combined_wide$Measure == "last")[1]
lastmonth_index <- which(combined_wide$Measure == "lastmonth")[1]
empty_row_mean <- combined_wide[1, ] %>%
  mutate(across(everything(), ~NA)) %>%
  mutate(Series = "\\textbf{Mean}", Frequency = NA)
empty_row_last <- combined_wide[1, ] %>%
  mutate(across(everything(), ~NA)) %>%
  mutate(Series = "\\textbf{Last}", Frequency = NA)
empty_row_lastmonth <- combined_wide[1, ] %>%
  mutate(across(everything(), ~NA)) %>%
  mutate(Series = "\\textbf{Last Month}", Frequency = NA)
combined_with_labels <- bind_rows(
  empty_row_mean,
  combined_wide[mean_index:(last_index - 1), ],
  empty_row_last,
  combined_wide[last_index:(lastmonth_index - 1), ],
  empty_row_lastmonth,
  combined_wide[lastmonth_index:nrow(combined_wide), ]
)
combined_table_clean <- combined_with_labels %>%
  ungroup() %>%  # prevent grouped column conflicts
  select(-Frequency, -Measure) %>%
  mutate(across(
    where(is.numeric),
    ~ round(.x, 2)
  )) %>%
  mutate(across(
    where(is.numeric),
    ~ ifelse(is.na(.x), "", .x)
  ))
section_rows <- which(combined_table_clean$Series %in% c("\\textbf{Mean}", "\\textbf{Last}", "\\textbf{Last Month}"))
add_lines <- list(pos = section_rows - 1, command = rep("\\midrule\n", length(section_rows)))
table_tex <- kable(
  combined_table_clean,
  format = "latex",
  booktabs = TRUE,
  escape = FALSE,
  col.names = c("Lags",
                rep(c("-4", "-3", "-2", "-1", "0"), 2)),
  align = "lrrrrrrrrr",
  caption = "Cross Correlation with GDP for Different Lags and Aggregation Methods",
  add.to.row = add_lines
) %>%
  add_header_above(c(" " = 1, "YoY" = 5, "QoQ" = 5)) %>%
  kable_styling(latex_options = "hold_position", full_width = TRUE) %>%
  row_spec(section_rows, bold = TRUE) %>%
  column_spec(1, width = "2.3cm") %>%
  column_spec(2:11, width = "0.9cm")
table_tex <- gsub("\\\\addlinespace\n?", "", table_tex)
# Prepare the heatmap-specific table variants with method suffixes in the column names.
df_mean <- combined_tables_list$mean %>% suffix_cols("mean")
df_last <- combined_tables_list$last %>% suffix_cols("last")
df_lastmonth <- combined_tables_list$last_month %>% suffix_cols("lastmonth")
df_mean_indicators <- combined_tables_list_indicators$mean %>% suffix_cols("mean")
df_last_indicators <- combined_tables_list_indicators$last %>% suffix_cols("last")
df_lastmonth_indicators <- combined_tables_list_indicators$last_month %>% suffix_cols("lastmonth")
library(dplyr)
library(tidyr)
library(ggplot2)
library(ggpubr)
library(scales)
cor_tables_wai <- list(
  mean = df_mean,
  last = df_last,
  lastmonth = df_lastmonth
)
cor_tables_indicators <- list(
  mean = df_mean_indicators,
  last = df_last_indicators,
  lastmonth = df_lastmonth_indicators
)
# Write one heatmap for the benchmark indicators and one for the WAI variants.
render_correlation_heatmap(
  cor_tables = cor_tables_indicators,
  series_order = c("WAI", "SECO-WWA", "F-CURVE", "SECO-SEC", "SNB-BCI", "KOF-BARO"),
  output_file = "correlation_heatmap_indicators.pdf",
  figures_dir = figures_dir
)
# Render the benchmark-indicator and WAI-variant heatmaps separately.
render_correlation_heatmap(
  cor_tables = cor_tables_wai,
  series_order = c("WAI", "WAI-SV", "WAI-(SV+HF)", "WAI-HF", "WAI-FIN"), #, "WAI-Retail"),
  output_file = "correlation_heatmap_WAI.pdf",
  figures_dir = figures_dir
)


# -----------------------------------------------------------------------------
# In-Sample Fit Tables
# -----------------------------------------------------------------------------
# Compute R-squared, relative errors, and absolute error tables for the WAI
# variants and export them as LaTeX files.

methods <- c("mean", "last", "last_month")
library(dplyr)
library(knitr)
library(kableExtra)

# Build the full set of in-sample fit tables for one model family and write
# them with a dedicated output suffix.
build_insample_table_set <- function(analysis_set, file_suffix, caption_subject) {
  insample_fit_tables <- lapply(methods, get_insample_fit_table, analysis_set = analysis_set, inputs = insample_inputs)
  names(insample_fit_tables) <- methods
  
  # Convert raw fit metrics into relative-to-WAI error tables before annotation.
  relative_error_tables <- lapply(insample_fit_tables, calculate_relative_errors)
  
  # Round the absolute metrics before they are written to the LaTeX tables.
  insample_fit_tables <- lapply(insample_fit_tables, function(level1) {
    lapply(level1, function(df) {
      df %>%
        mutate(across(where(is.numeric), ~ sprintf("%.2f", .x)))
    })
  })
  
  annotated_rmse_mean <- annotate_relative_errors(
    rel_table = relative_error_tables$mean$RMSE_relative,
    pval_table = insample_fit_tables$mean$PVAL_RMSE,
    metric_prefix = "RMSE"
  )
  annotated_rmse_last <- annotate_relative_errors(
    rel_table = relative_error_tables$last$RMSE_relative,
    pval_table = insample_fit_tables$last$PVAL_RMSE,
    metric_prefix = "RMSE"
  )
  annotated_rmse_last_month <- annotate_relative_errors(
    rel_table = relative_error_tables$last_month$RMSE_relative,
    pval_table = insample_fit_tables$last_month$PVAL_RMSE,
    metric_prefix = "RMSE"
  )
  
  annotated_mae_mean <- annotate_relative_errors(
    rel_table = relative_error_tables$mean$MAE_relative,
    pval_table = insample_fit_tables$mean$PVAL_MAE,
    metric_prefix = "MAE"
  )
  annotated_mae_last <- annotate_relative_errors(
    rel_table = relative_error_tables$last$MAE_relative,
    pval_table = insample_fit_tables$last$PVAL_MAE,
    metric_prefix = "MAE"
  )
  annotated_mae_last_month <- annotate_relative_errors(
    rel_table = relative_error_tables$last_month$MAE_relative,
    pval_table = insample_fit_tables$last_month$PVAL_MAE,
    metric_prefix = "MAE"
  )
  
  r2_list <- list(
    insample_fit_tables$mean$R2,
    insample_fit_tables$last$R2,
    insample_fit_tables$last_month$R2
  )
  names(r2_list) <- methods
  
  rel_rmse_list <- list(
    annotated_rmse_mean,
    annotated_rmse_last,
    annotated_rmse_last_month
  )
  names(rel_rmse_list) <- methods
  
  rel_mae_list <- list(
    annotated_mae_mean,
    annotated_mae_last,
    annotated_mae_last_month
  )
  names(rel_mae_list) <- methods
  
  abs_rmse_list <- list(
    insample_fit_tables$mean$RMSE,
    insample_fit_tables$last$RMSE,
    insample_fit_tables$last_month$RMSE
  )
  names(abs_rmse_list) <- methods
  
  abs_mae_list <- list(
    insample_fit_tables$mean$MAE,
    insample_fit_tables$last$MAE,
    insample_fit_tables$last_month$MAE
  )
  names(abs_mae_list) <- methods
  
  results_R2 <- create_combined_latex_table(
    r2_list,
    caption = paste("In-sample R-squared by lag and aggregation method for", caption_subject)
  )
  write_table_output(paste0("table_output_R2_", file_suffix, ".tex"), results_R2$table_tex, tables_dir)
  
  results_rmse <- create_combined_latex_table(
    rel_rmse_list,
    caption = paste("In-sample relative RMSE by lag and aggregation method for", caption_subject)
  )
  write_table_output(paste0("table_output_rmse_", file_suffix, ".tex"), results_rmse$table_tex, tables_dir)
  
  results_mae <- create_combined_latex_table(
    rel_mae_list,
    caption = paste("In-sample relative MAE by lag and aggregation method for", caption_subject)
  )
  write_table_output(paste0("table_output_mae_", file_suffix, ".tex"), results_mae$table_tex, tables_dir)
  
  results_abs_rmse <- create_combined_latex_table(
    abs_rmse_list,
    caption = paste("In-sample absolute RMSE by lag and aggregation method for", caption_subject)
  )
  write_table_output(paste0("table_output_abs_rmse_", file_suffix, ".tex"), results_abs_rmse$table_tex, tables_dir)
  
  results_abs_mae <- create_combined_latex_table(
    abs_mae_list,
    caption = paste("In-sample absolute MAE by lag and aggregation method for", caption_subject)
  )
  write_table_output(paste0("table_output_abs_mae_", file_suffix, ".tex"), results_abs_mae$table_tex, tables_dir)
  
  list(
    fit_tables = insample_fit_tables,
    relative_error_tables = relative_error_tables,
    results_R2 = results_R2,
    results_rmse = results_rmse,
    results_mae = results_mae,
    results_abs_rmse = results_abs_rmse,
    results_abs_mae = results_abs_mae
  )
}

# Build the crisis-vs-non-crisis relative RMSE table for the benchmark
# comparison and keep it with the rest of the in-sample analytics outputs.
build_insample_crisis_table <- function() {
  benchmark_model_order <- c("WAI", "SECO-WWA", "F-CURVE", "SECO-SEC", "SNB-BCI", "KOF-BARO")
  crisis_methods <- c("mean", "last", "last_month")
  method_labels <- c(
    mean = "mean",
    last = "last",
    last_month = "last month"
  )
  
  results_by_method <- lapply(crisis_methods, function(method_name) {
    insample_error_details <- get_insample_error_details(method_name, analysis_set = "indicators", inputs = insample_inputs)
    error_tables_insample_total <- create_error_summary_tables(
      insample_error_details,
      benchmark_model_order,
      date_col = "observation_date"
    )
    error_tables_insample_period <- create_error_summary_tables(
      insample_error_details,
      benchmark_model_order,
      date_col = "observation_date",
      include_period = TRUE
    )
    crisis_rmse_tables <- list(
      total = error_tables_insample_total$rel_rmse[[method_name]],
      crisis = error_tables_insample_period$rel_rmse[[method_name]] %>% filter(Period == "Crisis Periods") %>% select(-Period),
      non_crisis = error_tables_insample_period$rel_rmse[[method_name]] %>% filter(Period == "Non-Crisis Periods") %>% select(-Period)
    )
    
    results_rmse_insample_crisis <- create_combined_latex_table(
      crisis_rmse_tables,
      caption = paste("In-sample relative RMSE by lag and sample regime for WAI and benchmark indicators using", method_labels[[method_name]], "aggregation"),
      measure_label_map = c(
        total = "\\textbf{Total}",
        crisis = "\\textbf{Crisis}",
        non_crisis = "\\textbf{Non-Crisis}"
      )
    )
    write_table_output(
      paste0("table_output_rmse_insample_crisis_", method_name, ".tex"),
      results_rmse_insample_crisis$table_tex,
      tables_dir
    )
    
    list(
      error_tables_total = error_tables_insample_total,
      error_tables_period = error_tables_insample_period,
      results_rmse = results_rmse_insample_crisis
    )
  })
  names(results_by_method) <- crisis_methods
  
  results_by_method
}

# Write one complete in-sample table set for the WAI variants, one for the
# benchmark-indicator comparison, and the benchmark-based crisis split table.
insample_results_wai <- build_insample_table_set(
  analysis_set = "wai_versions",
  file_suffix = "WAI",
  caption_subject = "WAI versions"
)

insample_results_benchmarks <- build_insample_table_set(
  analysis_set = "indicators",
  file_suffix = "benchmarks",
  caption_subject = "WAI and benchmark indicators"
)

insample_results_crisis <- build_insample_crisis_table()

