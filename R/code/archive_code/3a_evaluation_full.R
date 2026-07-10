
rm(list = ls())
cat("\014")

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# Full Sample Model Evaluation (In-Sample and Out-of-Sample) for Swiss Weekly GDP Indicator
# Authors: Florian Eckert, Philipp Kronenberg, Heiner Mikosch, Stefan Neuwirth 
# Last Update: 09/02/2022
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

# PACKAGES AND FUNCTIONS --------------------------------------------------

library(ggplot2)
library(tibble)
library(tidyr)
library(dplyr)
library(zoo)
library(forecast)

source("code/lib/functions_backcast.R")

load("code/Rda/data_ch_dataset.Rda")

# PRELIM ------------------------------------------------------------------

datasets <- c("full", "aggr_weekly","only_monthly")
models <- c("ar", "wai")
start_date <- 2000
end_date <- 2021 + 47/48
date_vec <- seq(start_date, end_date, 1/48)

# 1. GATHER FORECASTS -----------------------------------------------------

# 1.1 GATHER STORED FILES TO LIST
out <- lapply(datasets, function(xd){
  out_dx <- lapply(models, function(xm){
    out_tx <- lapply(date_vec, function(xt){
      #load(paste0("L:/Groups/Economic Forecasting/Internationale Konjunktur/Sonstiges/WAI/fits_nosv/",xm,"/",xd,"/fit_",round(xt,3),".Rda"))
      load(paste0("L:/Groups/Economic Forecasting/Internationale Konjunktur/Sonstiges/WAI/fits/",xm,"/",xd,"/fit_",round(xt,3),".Rda"))
      #load(paste0("L:/Groups/Economic Forecasting/Internationale Konjunktur/Sonstiges/WAI/fits_noserial/",xm,"/",xd,"/fit_",round(xt,3),".Rda"))
      retrieve_nowcast(fit = mod, model = xm)
      #print(c(xd,xm,xt))
      #print(retrieve_nowcast(fit = mod, model = xm))

    }); names(out_tx) <- as.character(round(date_vec,3)); out_tx
  }); names(out_dx) <- models; out_dx
}); names(out) <- datasets

var <- lapply(datasets, function(xd){
  var_dx <- lapply(models, function(xm){
    var_tx <- lapply(date_vec, function(xt){
      #load(paste0("L:/Groups/Economic Forecasting/Internationale Konjunktur/Sonstiges/WAI/fits_nosv/",xm,"/",xd,"/fit_",round(xt,3),".Rda"))
      load(paste0("L:/Groups/Economic Forecasting/Internationale Konjunktur/Sonstiges/WAI/fits/",xm,"/",xd,"/fit_",round(xt,3),".Rda"))
      #load(paste0("L:/Groups/Economic Forecasting/Internationale Konjunktur/Sonstiges/WAI/fits_noserial/",xm,"/",xd,"/fit_",round(xt,3),".Rda"))
      retrieve_nowcast_var(fit = mod, model = xm)
    }); names(var_tx) <- as.character(round(date_vec,3)); var_tx
  }); names(var_dx) <- models; var_dx
}); names(var) <- datasets

# save list for further processing
#save(out, date_vec, file = "code/Rda/results_backcast_fits_20210126.Rda")
save(out, date_vec, file = "code/Rda/results_backcast.Rda")
save(var, date_vec, file = "code/Rda/results_backcast_var.Rda")
#save(out, date_vec, file = "code/Rda/results_backcast_noserial.Rda")
#save(var, date_vec, file = "code/Rda/results_backcast_var_noserial.Rda")
#save(out, date_vec, file = "code/Rda/results_backcast_nosv.Rda")
#save(var, date_vec, file = "code/Rda/results_backcast_var_nosv.Rda")

#load("code/Rda/results_backcast_nosv.Rda")
#load("code/Rda/results_backcast_var_nosv.Rda")
#load("code/Rda/results_backcast_noserial.Rda")
#load("code/Rda/results_backcast_var_noserial.Rda")
#noserial_wai_full <- out$full$wai
load("code/Rda/results_backcast.Rda")
load("code/Rda/results_backcast_var.Rda")
#out$full$wai <- noserial_wai_full

# 1.2 CONVERT LIST TO DATAFRAME
tab <- do.call(rbind, lapply(names(out), function(dx) do.call(rbind, lapply(names(out[[dx]]), function(mx){
  out_ts <- do.call(cbind,out[[dx]][[mx]])
  out_df <- as_tibble(out_ts) %>%
    add_column("period" = time(out_ts)) %>%
    pivot_longer(-period, names_to = "date")
  out_df <- out_df[-which(is.na(out_df$value)),] %>%
    add_column("model" = mx,
               "dataset" = dx)
  out_df$date <- as.numeric(out_df$date)

  return(out_df)

}))))

tab_var <- do.call(rbind, lapply(names(var), function(dx) do.call(rbind, lapply(names(var[[dx]]), function(mx){

  var_ts <- do.call(cbind,var[[dx]][[mx]])
  var_df <- as_tibble(var_ts) %>%
    add_column("period" = time(var_ts)) %>%
    pivot_longer(-period, names_to = "date")
  var_df <- var_df[-which(is.na(var_df$value)),] %>%
    add_column("model" = mx,
               "dataset" = dx)
  var_df$date <- as.numeric(var_df$date)

  return(var_df)

}))))

tab_sd <- tab_var %>% mutate(sd = sqrt(value))
tab$sd <- tab_sd$sd

# use only backtest data until most recent GDP estimate is available
tab <- tab %>% filter(period <= 2021.5) # Only use data including nowcast for 2021 Q3
# tab <- tab %>% filter(period <= 2019.75) # Exclude the COVID-19 pandemic

# use only backtest data starting with 12 weeks of horizon such that equal number of observations for every horizon
tab <- tab %>% filter(period >= 2005.00) # Only use data including nowcast for 2005 Q1

# get GDP realizations in the corresponding quarter
tab$realization <- sapply(tab$period, function(x) window(dat$flows$ch.seco.gdp.real.gdp.ssa,start = x, end = x))

# get scores
tab$logs <- scoringRules::logs(y = tab$realization, family = "normal", mean = tab$value, sd = tab$sd)

# compute SFEs
tab$sqerror <- (tab$value - tab$realization)^2
tab$error <- (tab$value - tab$realization)
# compute forecasting horizon in weeks, assuming GDP is observed in the first week of the third month after the end of the quarter
# e.g. Q4 2019 = 2019.75, observed in 2020.000 + 8/48 (= 2019.979 + 9/48)
tab$observed <- round(tab$period + 1/4 + 8/48, 3)
tab$horizon <- round((tab$observed - tab$date) * 48)
tab$year <- floor(tab$date)
tab$week <- round(tab$date %% 1 * 48 + 1)

# Note the following:
# tab$period: vintage date of GDP realization (quarterly frequency!)
# tab$date: nowcast date (weekly frequency!)
# tab$observed: week when GDP is published (weekly frequency!)
# tab$horizon: number of weeks of nowcast before GDP is published

save(tab, file = "code/Rda/results_tab.Rda")
#save(tab, file = "code/Rda/results_tab_nosv.Rda")
#save(tab, file = "code/Rda/results_tab_fits_20210126.Rda")

# Note: Q1=xxxx.00, Q2=xxxx.25, Q3=xxxx.5, Q4=xxxx.75 , check this by e.g. out$full$wai$'2020.625' belongs to Q2 and is period 2020.25

# create a list of tables for specific time periods for output: for disaggregate inspection
tables_subperiods <- list('2000Q1-2021Q3' = tab %>% filter(period >= 2000 & period <= 2021.5),
                          '2005Q1-2021Q3' = tab %>% filter(period >= 2005 & period <= 2021.5),
                          '2000Q1-2021Q1' = tab %>% filter(period >= 2000 & period <= 2021), # (Full sample Old long)
                          '2000Q1-2020Q2' = tab %>% filter(period >= 2000 & period <= 2020.25), # (Full sample Old long)
                          '2005Q1-2020Q2' = tab %>% filter(period >= 2005 & period <= 2020.25), # (Full sample Old)
                          '2000Q1-2021Q1' = tab %>% filter(period >= 2000 & period <= 2021), # (Full Sample 1)
                          '2005Q1-2021Q1' = tab %>% filter(period >= 2005 & period <= 2021), # (Full Sample 2)
                          '2007Q1-2021Q1' = tab %>% filter(period >= 2007 & period <= 2021), # (Full Sample 3)
                          '2000Q1-2004Q3' = tab %>% filter(period >= 2000 & period <= 2004.5),
                          '2005Q1-2008Q3' = tab %>% filter(period >= 2005 & period <= 2008.5), # (Great Recession)
                          '2008Q4-2009Q3' = tab %>% filter(period >= 2008.75 & period <= 2009.5),
                          '2009Q4-2011Q2' = tab %>% filter(period >= 2009.75 & period <= 2011.25), # (Euro Crisis)
                          '2011Q3-2013Q1' = tab %>% filter(period >= 2011.5 & period <= 2013),
                          '2013Q2-2014Q4' = tab %>% filter(period >= 2013.25 & period <= 2014.75),
                          '2015Q1-2015Q2' = tab %>% filter(period >= 2015 & period <= 2015.25), #  (Swiss Franc Shock)
                          '2015Q3-2018Q2' = tab %>% filter(period >= 2015.5 & period <= 2018.25),
                          '2018Q3-2018Q4' = tab %>% filter(period >= 2018.75 & period <= 2018.75),
                          '2019Q1-2019Q4' = tab %>% filter(period >= 2019 & period <= 2019.75),
                          '2020Q1-2021Q1' = tab %>% filter(period >= 2020 & period <= 2021))

# tab <- tab %>% filter(period >= 2000.00) # Only use data including nowcast for 2000 Q1
# tab <- tab %>% filter(period <= 2021.00) # Only use data including nowcast for 2021 Q1
#tab <- tab %>% filter(period <= 2020.25) # Only use data including nowcast for 2021 Q1
#tab <- tab %>% filter(period >= 2005.00)
#tab <- tab %>% filter(period != 2020.75)

# create a list of tables for specific time periods for output: for split in crisis times and cyclical times
lcrises <- tab$period >= 2008.75 & tab$period <= 2009.5 |
  tab$period >= 2011.5 & tab$period <= 2013 |
  tab$period >= 2015 & tab$period <= 2015.25 |
  tab$period >= 2020 & tab$period <= 2021.5 #|
#tab$period >= 2020.75 & tab$period <= 2021.25
# lcrises <- tab$period >= 2018 & tab$period <= 2019.75

tables_crisisvsnormal <- list('Crisis Periods' = tab[which(lcrises),],
                              'Non-Crisis Periods' = tab[which(!lcrises),])

# 1.3 SAVE TABLES
#save(tables_subperiods,tables_crisisvsnormal, file = "code/Rda/results_evaluation_fits_20210126.Rda")
save(tables_subperiods,tables_crisisvsnormal, file = "code/Rda/results_evaluation.Rda")
#save(tables_subperiods,tables_crisisvsnormal, file = "code/Rda/results_evaluation_nosv.Rda")
#save(tables_subperiods,tables_crisisvsnormal, file = "code/Rda/results_evaluation_no_covid.Rda")
#save(tables_subperiods,tables_crisisvsnormal, file = "code/Rda/results_evaluation_2018to19.Rda")

# 2. GATHER VINTAGES -----------------------------------------------------

datasets <- list("full_RT") #list("full", "aggr_weekly", "only_monthly")
start_date <- 2005
end_date <- 2025 + 47/48
date_vec <- seq(start_date, end_date, 1/48)

wd <- getwd()
dataset_used <- "full_RT"

# gather stored output
out <- lapply(datasets, function(xd){
  out_tx <- lapply(date_vec, function(xt){
     #load(paste0("L:/Groups/Economic Forecasting/Internationale Konjunktur/Sonstiges/WAI/fits_20210126/fits/wai/",xd,"/fit_",round(xt,3),".Rda"))
    #load(paste0("L:/Groups/Economic Forecasting/Internationale Konjunktur/Sonstiges/WAI/fits/wai/",xd,"/fit_",round(xt,3),".Rda"))
    load(paste0(wd,"/fits/updated/",dataset_used,"/fit_",round(date,3),".Rda"))
        ryear <- floor(time(mod$factor))
    rmon <- as.numeric(format(as.yearmon(time(mod$factor)), "%m"))
    if (xd == "full"){
      rday <-  (round((time(mod$factor) %% 1) * frequency(mod$factor)) %% 4 + 1) * 7}
    else {
      rday <- rep(28,length(mod$factor))
    }

    res <- zoo(x = cbind(mod$factor,
                         mod$factor + 1.96 * sqrt(mod$factor_var),
                         mod$factor - 1.96 * sqrt(mod$factor_var)),
               order.by = as.Date(paste0(ryear,"-",sprintf("%02d", rmon),"-",sprintf("%02d", rday)), format = "%Y-%m-%d"))

    tab <- data.frame("mean" = as.numeric(res[,1]),
                      "max" = as.numeric(res[,2]),
                      "min" = as.numeric(res[,3]),
                      "time" = time(res))
    tab <- tab %>% pivot_longer(-c(time,min,max))

    return(tab)

  }); names(out_tx) <- as.character(round(date_vec,3)); out_tx
}); names(out) <- datasets

tab <- do.call(rbind, lapply(names(out), function(dx) do.call(rbind, lapply(names(out[[dx]]), function(mx){

  out_df <- out[[dx]][[mx]] %>%
    add_column("vint" = mx) %>%
    add_column("method" = dx)

  return(out_df)

}))))

tab$periods <- plyr::round_any(x = as.numeric(format(tab$time, "%Y")) +
                                 (as.numeric(format(tab$time, "%m"))-1)/12 +
                                 as.numeric(format(tab$time, "%d"))/365,
                               accuracy = 1/48,
                               f = floor)

# save list for further processing
save(tab, date_vec, file = "code/Rda/factor_vintages_updated.Rda")
#save(tab, date_vec, file = "code/Rda/factor_vintages.Rda")
#save(tab, date_vec, file = "code/Rda/factor_vintages_fits_20210126.Rda")







