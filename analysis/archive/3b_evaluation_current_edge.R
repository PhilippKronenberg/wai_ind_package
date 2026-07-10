
rm(list = ls())
cat("\014")

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Current Edge Model Evaluation (In-Sample and Out-of-Sample) for Swiss Weekly GDP Indicator
# Authors: Florian Eckert, Philipp Kronenberg, Heiner Mikosch, Stefan Neuwirth 
# Last Update: 09/02/2022
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

# PACKAGES AND FUNCTIONS --------------------------------------------------

library(Matrix)
library(zoo)
library(dplyr)
library(tidyr)
library(ggplot2)

source("code/lib/functions_model.R")
source("code/lib/functions_backcast.R")



# IMPORT DATA -------------------------------------------------------------

load("code/Rda/data_ch.Rda")


## discontinue retail data
#dat$flows[which(grepl(pattern = "rtt", names(dat$flows)))] <- 
#  lapply(dat$flows[which(grepl(pattern = "rtt", names(dat$flows)))], 
#         function(x){window(x, end = 2021)})


cutoff = 2021 + 48/48
#dat = cut_data(dat, current_date = cutoff)


# RUN ESTIMATION ----------------------------------------------------------

# Target variable: sport-adjusted GDP.
out <- hfdfm(flows = dat$flows,
             stocks = dat$stocks,
             target = "ch.seco.gdp.real.gdp.ssa",
             p = 1,
             extend_to = cutoff,
             burn_in = 5000,
             length_sample = 5000,
             thinning = 5,
             plots = T)

#save(out, file = "out_new.Rda")
#load("code/Rda/data_ch.Rda")

aux <- cbind(out$nowcast*100,
             (out$nowcast - 2*sqrt(out$nowcast_var))*100,
             (out$nowcast + 2*sqrt(out$nowcast_var))*100)
plot.ts(window(aux, start = 1990), plot.type="single", col = c(1,2,2))



# PLOT HISTORY ------------------------------------------------------------

library(dplyr)
library(tidyr)
library(ggplot2)
library(zoo)
library(ggpubr)
library(scales)

# construct irregular time series, observations always on the 1., 8., 15. and 22. of each month
ryear <- floor(time(out$factor))
rmon <- as.numeric(format(as.yearmon(time(out$factor)), "%m"))
rday <- (round((time(out$factor) %% 1) * 48) %% 4 + 1) * 7

res <- zoo(x = cbind(out$factor,
                     out$factor + 1.96 * sqrt(out$factor_var),
                     out$factor - 1.96 * sqrt(out$factor_var)),
           order.by = as.Date(paste0(ryear,"-",sprintf("%02d", rmon),"-",sprintf("%02d", rday)), format = "%Y-%m-%d"))

tab <- data.frame("mean" = as.numeric(res[,1]),
                  "max" = as.numeric(res[,2]),
                  "min" = as.numeric(res[,3]),
                  "time" = time(res))
tab <- tab %>% pivot_longer(-c(time,min,max))

# get historical, annualized GDP growth rates 
x_hist <- ((1+dat$flows$ch.seco.gdp.real.gdp.ssa/100)^4-1)*1e+4
hist_tab <- data.frame(xmin =  seq.Date(as.Date("1990-01-01"),
                                        by = "3 months",
                                        length.out = length(x_hist)),
                       xmax =  seq.Date(as.Date("1990-04-01"),
                                        by = "3 months",
                                        length.out = length(x_hist)),
                       y = as.numeric(x_hist)) %>% 
  pivot_longer(-y)

ggplot() +
  geom_hline(yintercept=0, col = "grey50") +
  geom_ribbon(data = tab, aes(x = time, ymin = min, ymax = max), fill = "lightblue", alpha = 0.5) +
  geom_line(data = tab, mapping = aes(x = time, y = value)) +
  coord_cartesian(ylim = c(-30,30)) +
  ylab("Wöchentliches BIP-Wachstum (in %, annualisiert)") + 
  xlab(NULL) +
  scale_y_continuous(breaks = seq(-30,30,10)) +
  geom_line(data = hist_tab, mapping = aes(y = y, x = value, group = y), color = "red") +
  theme_minimal() + 
  theme(plot.title = element_blank(), 
        legend.position = "bottom",
        text = element_text(size = 10),
        legend.title=element_blank(),
        axis.text.y = element_text(size = 10),
        axis.text.x = element_text(size = 10),
        axis.title.x.bottom = element_text(size = 10),
        legend.text=element_text(size=12),
        panel.grid.major.x = element_line(size = 0.2),
        panel.grid.major.y = element_line(size = 0.2),
        panel.grid.minor.x = element_blank(),
        panel.grid.minor.y = element_blank())

ggsave("figures/bltn_full.pdf", width = 20, height = 12, units = "cm")


# PLOT CORONA -------------------------------------------------------------

label <- data.frame(time = as.Date(c("2020-02-25","2020-03-16","2020-05-11",
                                     "2020-06-22","2020-12-21","2021-01-18")), 
                    value = 120, 
                    label = 1:6,
                    legend = c("1: Erster bestätigter Corona-Fall in der Schweiz",
                               "2: Ausrufung «Ausserordentliche Lage»",
                               "3: Lockerung der Notmassnahmen",
                               "4: Ende der «Ausserordentlichen Lage»",
                               "5: Schliessung von Gastronomiebetrieben",
                               "6: Schliessung von Läden, Home-Office-Pflicht"))

tab_corona <- tab %>% filter(time>= "2020-01-01")
hist_tab_corona <- hist_tab %>% filter(value>= "2020-01-01")

# plot only most recent months
ggplot(mapping = aes(x = time, y = value)) +
  geom_vline(data = label, aes(xintercept = time, color = legend), linetype="dotted", size=0.4) +
  geom_hline(yintercept=0, col = "grey50") +
  geom_ribbon(data = tab_corona, aes(ymin = min, ymax = max),
              color = NA, fill = "lightblue", alpha = 0.5) +
  geom_line(data = tab_corona, mapping = aes(y = value)) +
  geom_line(data = hist_tab_corona, mapping = aes(y = y, x = value, group = y), color = "red") +
  geom_label(data = label, aes(label = label)) +
  xlab(NULL) + 
  ylab("Wöchentliches BIP-Wachstum (in %, annualisiert)") + 
  scale_y_continuous(breaks = seq(-120,120,40)) +
  scale_x_date(breaks = date_breaks("1 month"), labels = date_format("%b")) +
  scale_color_manual(name = NULL, values = rep("black",nrow(label))) +
  theme_minimal() + 
  theme(plot.title = element_blank(), 
        legend.position = "bottom",
        text = element_text(size = 10),
        legend.title=element_blank(),
        legend.text = element_text(size = 11),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(size = 0.2),
        panel.grid.minor.x = element_blank(),
        panel.grid.minor.y = element_blank()) +
  guides(color=guide_legend(ncol=2, override.aes = list(color = "white")))

ggsave("figures/bltn_corona.pdf", width = 20, height = 12, units = "cm")






# COMPARISON NO SV --------------------------------------------------------

load("L:/Groups/Economic Forecasting/Internationale Konjunktur/Sonstiges/WAI/fits_nosv/wai/full/fit_2021.5.Rda")
tab_nosv <- data.frame("time" = as.numeric(time(mod$factor)),
                       "mean" = as.numeric(mod$factor),
                       "sd" = sqrt(as.numeric(mod$factor_var)),
                       "spec" = "no_sv")
load("L:/Groups/Economic Forecasting/Internationale Konjunktur/Sonstiges/WAI/fits/wai/full/fit_2021.5.Rda")
tab_sv <- data.frame("time" = as.numeric(time(mod$factor)),
                       "mean" = as.numeric(mod$factor),
                       "sd" = as.numeric(sqrt(mod$factor_var)),
                       "spec" = "sv")

tab <- rbind(tab_nosv,tab_sv) %>% filter(time > 2015)

ggplot(data = tab, aes(x = time, color = spec, fill = spec, group = spec)) +
  geom_hline(yintercept=0, col = "grey50") +
  geom_ribbon(data = tab,  aes(ymin = mean - 2 *sd, ymax = mean + 2*sd), alpha = 0.5) +
  geom_line(data = tab, mapping = aes(x = time, y = mean)) +
  # coord_cartesian(ylim = c(-30,30)) +
  ylab("Weekly GDP Growth (in %, annualized)") + 
  xlab(NULL) +
  scale_y_continuous(breaks = seq(-60,150,30)) +
  theme_minimal() + 
  theme(plot.title = element_blank(), 
        legend.position = "bottom",
        text = element_text(size = 10),
        legend.title=element_blank(),
        axis.text.y = element_text(size = 10),
        axis.text.x = element_text(size = 10),
        axis.title.x.bottom = element_text(size = 10),
        legend.text=element_text(size=12),
        panel.grid.major.x = element_line(size = 0.2),
        panel.grid.major.y = element_line(size = 0.2),
        panel.grid.minor.x = element_blank(),
        panel.grid.minor.y = element_blank())

ggsave("figures/no_sv_vs_sv.pdf", width = 20, height = 10, units = "cm")
