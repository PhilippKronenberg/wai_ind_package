

run_ar <- function(flows, stocks, target, date, dataset_used, stochastic_volatility = TRUE){
  
  gdpdta <- flows[[target]]
  
  # Estimate AR Model
  fit <- arima(gdpdta,order = c(1,0,0))
  mod <- list("nowcast" = predict(fit, h = 1)$pred,
              "nowcast_var" = predict(fit, h = 1)$se^2)
  
  #save(mod, file = paste0("L:/Groups/Economic Forecasting/Internationale Konjunktur/Sonstiges/WAI/fits/updated/ar/",dataset_used,"/fit_",round(date,3),".Rda"))
  wd <- getwd()
  save(mod, file = paste0(wd,"/fits/updated/ar/",dataset_used,"/fit_",round(date,3),".Rda"))
  
}


run_wai_adj <- function(flows, stocks, target, date, dataset_used, stochastic_volatility = TRUE){
  
  mod <- hfdfm(flows = flows,
        stocks = stocks,
        target = target,
        burn_in = 1000,
        length_sample = 5000,
        thinning = 1,
        p = 1, # Number of factor lags in factor state equation. 
        q = 1, # Number of factors
        extend = 1,
        plots = FALSE, 
        stochastic_volatility = stochastic_volatility, 
        serial_correlation = TRUE)
  
  mod$factor <- window(mod$factor, end = date)
  mod$factor_var <- window(mod$factor_var, end = date)
  mod$nowcast <- window(mod$nowcast, end = as.numeric(tail(time(flows[[target]]),1)) + 0.25)
  mod$nowcast_var <- window(mod$nowcast_var, end = as.numeric(tail(time(flows[[target]]),1)) + 0.25)
  
  wd <- getwd()
 # save(mod, file = paste0("L:/Groups/Economic Forecasting/Internationale Konjunktur/Sonstiges/WAI/fits/wai/",dataset_used,"/fit_",round(date,3),".Rda"))
  save(mod, file = paste0(wd,"/fits/updated/",dataset_used,"/fit_",round(date,3),".Rda"))
  
}


retrieve_nowcast <- function(fit, model){
  #if(model == "ar") ncst <- forecast(fit,h=1)$mean
  if(model == "ar") ncst <- fit$nowcast
  if(model == "wai") ncst <- tail(fit$nowcast,1)
  
  return(ncst)
  
}

retrieve_nowcast_var <- function(fit, model){
  #if(model == "ar") ncst <- forecast(fit,h=1)$mean
  if(model == "ar") ncst <- fit$nowcast_var
  if(model == "wai") ncst <- tail(fit$nowcast_var,1)
  
  return(ncst)
  
}

week2mon <- function(dat){
  
  list("flows" = lapply(dat$flows, function(x) week2mon_helper(x)),
       "stocks" = lapply(dat$stocks, function(x) week2mon_helper(x)))
  
}


week2mon_helper <- function(x){
  
  if(frequency(x) == 48) as.ts(aggregate(as.zoo(x), as.yearmon, sum)) else x
  
}


drop_weekly <- function(x){
  
  list("flows" = dat$flows[lengths(lapply(dat$flows, function(x) drop_weekly_helper(x))) > 0],
       "stocks" = dat$stocks[lengths(lapply(dat$stocks, function(x) drop_weekly_helper(x))) > 0])
}


drop_weekly_helper <- function(x){
  
  if(frequency(x) == 48) x <- NULL else x
}

# Function to remove elements by name
remove_elements <- function(lst, names_to_remove) {
  lst[setdiff(names(lst), names_to_remove)]
}

drop_financial <- function(x){
# Names you want to remove
financial_variables <- c("FINANSW", "INDUSSW", "SWISSMI", "VIX")

# Apply to both sublists
dat$flows <- remove_elements(dat$flows, financial_variables)
dat$stocks <- remove_elements(dat$stocks, financial_variables)

list("flows" = dat$flows,
     "stocks" = dat$stocks)
}

drop_retail <- function(x){
  # Names you want to remove
  non_total_retail <- c("ch.fso.rtt.ind.r.noga0803.sa", "ch.fso.rtt.ind.r.noga0804.sa", "ch.fso.rtt.ind.r.noga0805.sa",
                           "ch.fso.rtt.ind.r.noga0806.sa", "ch.fso.rtt.ind.r.noga0807.sa", "ch.fso.rtt.ind.r.noga0808.sa")
  
  # Apply to both sublists
  dat$flows <- remove_elements(dat$flows, non_total_retail)
  dat$stocks <- remove_elements(dat$stocks, non_total_retail)
  
  list("flows" = dat$flows,
       "stocks" = dat$stocks)
}



cut_data <- function(dat, current_date){
  
  # cut time series at points in time contingent on the frequency of that specific series
  out <- list("flows" = lapply(dat$flows, function(x) cut_data_helper(x, current_date)),
              "stocks" = lapply(dat$stocks, function(x) cut_data_helper(x, current_date)))
  
  
  # drop time series containing no entries
  out$flows[which(sapply(out$flows, is.null))] <- NULL
  out$stocks[which(sapply(out$stocks, is.null))] <- NULL
  
  # drop time series that are shorter than 20 observations
  out$flows[which(sapply(out$flows, length) < 24)] <- NULL
  out$stocks[which(sapply(out$stocks, length) < 24)] <- NULL
  
  return(out)
  
}


cut_data_helper <- function(x, current_date){
  
  out <- tryCatch({
    
    if(frequency(x) == 48){
      
      # weekly series are observed in the next week
      # e.g. W1 2020 = 2020.000, observed in 2020.000 + 1/48
      suppressWarnings(window(x, end = current_date - 1/48))
      # suppressWarnings(window(x, end = current_date))
      
    } else if((frequency(x) == 12)){
      
      # monthly series are observed in the first week of the next month 
      # e.g. Jan 2020 = 2020.000, observed in 2020.000 + 4/48 (= 2019.979 + 5/48))
      suppressWarnings(window(x, end = current_date - 4/48))
      # suppressWarnings(window(x, end = current_date))
      
    } else {
      
      # quarterly series (= GDP) are observed in the first week of the third month after the end of the quarter
      # e.g. Q4 2019 = 2019.75, observed in 2020.000 + 8/48 (= 2019.979 + 9/48)
      suppressWarnings(window(x, end = current_date - 1/4 - 8/48))
      # suppressWarnings(window(x, end = current_date))
    }
  }, error=function(cond) {
    
    NULL
    
  }) 
}


cut_data_real_time <- function(dat, current_date, GDP_gr_vintages){
  
  # cut time series at points in time contingent on the frequency of that specific series
  out <- list("flows" = lapply(dat$flows, function(x) cut_data_helper_real_time(x, current_date, GDP_gr_vintages)),
              "stocks" = lapply(dat$stocks, function(x) cut_data_helper_real_time(x, current_date, GDP_gr_vintages)))
  
  
  # drop time series containing no entries
  out$flows[which(sapply(out$flows, is.null))] <- NULL
  out$stocks[which(sapply(out$stocks, is.null))] <- NULL
  
  # drop time series that are shorter than 20 observations
  out$flows[which(sapply(out$flows, length) < 24)] <- NULL
  out$stocks[which(sapply(out$stocks, length) < 24)] <- NULL
  
  return(out)
  
}



cut_data_helper_real_time <- function(x, current_date, GDP_gr_vintages){
  
  out <- tryCatch({
    
    if(frequency(x) == 48){
      
      # weekly series are observed in the next week
      # e.g. W1 2020 = 2020.000, observed in 2020.000 + 1/48
      suppressWarnings(window(x, end = current_date - 1/48))
      # suppressWarnings(window(x, end = current_date))
      
    } else if((frequency(x) == 12)){
      
      # monthly series are observed in the first week of the next month 
      # e.g. Jan 2020 = 2020.000, observed in 2020.000 + 4/48 (= 2019.979 + 5/48))
      suppressWarnings(window(x, end = current_date - 4/48))
      # suppressWarnings(window(x, end = current_date))
      
    } else {
      
      na.trim(ts(select_most_recent_GDP_vintage(current_date, GDP_gr_vintages), start = c(1990,1), frequency = 4))
      
      # quarterly series (= GDP) are observed in the first week of the third month after the end of the quarter
      # e.g. Q4 2019 = 2019.75, observed in 2020.000 + 8/48 (= 2019.979 + 9/48)
      #suppressWarnings(window(x, end = current_date - 1/4 - 8/48))
      # suppressWarnings(window(x, end = current_date))
    }
  }, error=function(cond) {
    
    NULL
    
  }) 
}

select_most_recent_GDP_vintage <- function(current_date, GDP_gr_vintages){
  
  vintage_names <- names(GDP_gr_vintages)[-1]
  column_names_numeric <- round(as.numeric(vintage_names), 3)
  
  target_value <- round(current_date, 3)
  
  # Select the newest vintage that is already available at current_date.
  valid_columns <- column_names_numeric[!is.na(column_names_numeric) & column_names_numeric <= target_value]
  
  if (length(valid_columns) > 0) {
    selected_value <- max(valid_columns)
    selected_column_name <- vintage_names[match(selected_value, column_names_numeric)]
    selected_column <- GDP_gr_vintages[[selected_column_name]]
  } else {
    stop("No GDP vintage is available on or before the requested current_date.")
  }
  
  selected_column
}


get_real_time_gdp_vintages <- function(output_type){
  wd <- getwd()
# Define the file path
file_path <- paste0(wd,"/code/realtime_database_GDP.xlsx")

read_sheet_info <- function(sheet_name, file_path) {
  # Read column titles from row 11
  column_titles <- read_excel(file_path, sheet = sheet_name, range = cell_rows(11), col_names = FALSE)
  column_titles <- as.character(unlist(column_titles))
  
  # Read dates as numeric (Excel serial date numbers)
  dates_raw <- read_excel(file_path, sheet = sheet_name, range = cell_rows(10), col_names = FALSE, col_types = "numeric")
  dates_numeric <- as.numeric(unlist(dates_raw))
  
  # Convert Excel serial date numbers to actual dates
  dates_vector <- format(as.Date(dates_numeric, origin = "1899-12-30"), "%d.%m.%Y")
  
  # Read the data starting from row 12
  data <- read_excel(file_path, sheet = sheet_name, skip = 11, col_names = column_titles)
  
  list(
    column_titles = column_titles,
    dates = dates_vector,
    data = data
  )
}

# Usage
gdp_cssa_info <- read_sheet_info("gdp_cssa", file_path)
gdp_info <- read_sheet_info("gdp", file_path)

# Step 1: Find position of "2018q3"
pos_2018q3 <- which(names(gdp_cssa_info$data) == "2018q3")

# Step 2: Select columns from both lists
# Before "2018q3" → from gdp_info$data
columns_before_2018q3 <- names(gdp_cssa_info$data)[1:(pos_2018q3 - 1)]
before_2018q3_from_info <- gdp_info$data[, columns_before_2018q3, drop = FALSE]

# From "2018q3" onward → from gdp_cssa_info$data
columns_from_2018q3 <- names(gdp_cssa_info$data)[pos_2018q3:length(names(gdp_cssa_info$data))]
from_2018q3_from_cssa <- gdp_cssa_info$data[, columns_from_2018q3, drop = FALSE]

# Step 3: Combine both parts
combined_list <- cbind(before_2018q3_from_info, from_2018q3_from_cssa)

GDP_gr_vintages <- combined_list

if (output_type == "quarterly") {
# Apply log difference to each numeric column except 'time'
GDP_gr_vintages[ , -1] <- apply(combined_list[ , -1], 2, function(x) c(NA, diff(log(x))))
} else if (output_type == "annual") {
# Apply year-on-year growth rates to each numeric column except 'time'
GDP_gr_vintages[ , -1] <- apply(combined_list[ , -1], 2, function(x) c(rep(NA, 4), x[5:length(x)] / x[1:(length(x) - 4)] - 1))
}

# Convert time column to Date class
GDP_gr_vintages$time <- as.Date(GDP_gr_vintages$time)

# Filter rows between 1990-01-01 and 2025-12-31
GDP_gr_vintages <- GDP_gr_vintages[GDP_gr_vintages$time >= as.Date("1990-01-01") & 
                                     GDP_gr_vintages$time <= as.Date("2025-12-31"), ]

dates <- as.Date(gdp_info$dates, format = "%d.%m.%Y")

# Calculate continuous time format
date_vec_names <- plyr::round_any(
  x = as.numeric(format(dates, "%Y")) +
    (as.numeric(format(dates, "%m")) - 1) / 12 +
    as.numeric(format(dates, "%d")) / 365,
  accuracy = 1/48,
  f = ceiling
)

# Convert names (excluding 'time') to numeric and round
date_vec_names <- round(as.numeric(date_vec_names), 3)

names(GDP_gr_vintages) <- c("time", date_vec_names) 

return(GDP_gr_vintages)

}


extract_wai_data <- function(file_path) {
  # Load model object
  load(file_path)
  if (exists("mod", inherits = FALSE)) {
    out <- mod
  }
  
  # Setup
  start_date <- 1990
  end_date <- 2025 + 47/48
  date_vec <- seq(start_date, end_date, 1/48)
  
  # Construct dates for irregular ts (7th, 14th, 21st, 28th)
  dates <- dec2week(date_vec)
  
  # Growth rate series
  ryear <- floor(time(out$factor))
  rmon <- as.numeric(format(as.yearmon(time(out$factor)), "%m"))
  rday <- (round((time(out$factor) %% 1) * 48) %% 4 + 1) * 7
  
  res_gr <- zoo(
    x = cbind(out$factor,
              out$factor + 1.96 * sqrt(out$factor_var),
              out$factor - 1.96 * sqrt(out$factor_var)),
    order.by = as.Date(paste0(ryear, "-", sprintf("%02d", rmon), "-", sprintf("%02d", rday)))
  )
  
  tab_gr <- data.frame("mean" = as.numeric(res_gr[,1]),
                       "max" = as.numeric(res_gr[,2]),
                       "min" = as.numeric(res_gr[,3]),
                       "time" = time(res_gr)) %>%
    pivot_longer(-c(time, min, max))
  
  tab_gr_full <- tab_gr
  tab_gr <- tab_gr #%>% filter(time >= as.Date("2005-01-01"))
  tab_gr_qoq <- tab_gr %>% select(time, name, value)
  # Level index series
  gr <- (1 + out$factor/100)^(1/48) - 1
  gr <- window(gr, start = time(out$factor)[[1]], end = time(out$factor)[length(out$factor)])
  
  lev <- 100
  idx <- numeric(length(gr))
  for (jx in 1:length(gr)) {
    idx[jx] <- exp(gr[jx]) * lev
    lev <- idx[jx]
  }
  
  idx_ts <- ts(idx, start = time(out$factor)[1], frequency = frequency(out$factor))
  
  expected_times <- 2019 + (36:47) / 48
  indices <- findInterval(expected_times, time(idx_ts))
  valid_indices <- indices[indices > 0 & indices <= length(idx_ts)]
  idx_ts_2020 <- mean(idx_ts[valid_indices])
  idx_ts <- 100 * idx_ts / idx_ts_2020
  
  # Level bounds
  ryear <- floor(time(idx_ts))
  rmon <- as.numeric(format(as.yearmon(time(idx_ts)), "%m"))
  rday <- (round((time(idx_ts) %% 1) * 48) %% 4 + 1) * 7
  
  merged_max <- merge(zoo(idx_ts, order.by = dates), (1 + res_gr[,2]/100)^(1/48), all = FALSE)
  merged_min <- merge(zoo(idx_ts, order.by = dates), (1 + res_gr[,3]/100)^(1/48), all = FALSE)
  
  lv_max <- ts(merged_max[,1] * merged_max[,2], start = time(out$factor)[1], frequency = frequency(out$factor))
  lv_min <- ts(merged_min[,1] * merged_min[,2], start = time(out$factor)[1], frequency = frequency(out$factor))
  
  res_lv <- zoo(
    x = cbind(idx_ts, lv_max, lv_min),
    order.by = as.Date(paste0(ryear, "-", sprintf("%02d", rmon), "-", sprintf("%02d", rday)))
  )
  
  tab_gr_lv <- data.frame("mean" = as.numeric(res_lv[,1]),
                          "time" = time(res_lv)) %>%
    pivot_longer(-time) #%>%
    #filter(time >= as.Date("2005-01-01"))
  
  # Year-over-year growth
  wai_yoy <- ts(100 * (idx_ts - stats::lag(idx_ts, k = -48)) / stats::lag(idx_ts, k = -48),
                start = c(1991, 1), frequency = 48)
  
  res_wai_yoy <- zoo(
    x = wai_yoy,
    order.by = as.Date(paste0(ryear[-(1:48)], "-", sprintf("%02d", rmon[-(1:48)]), "-", sprintf("%02d", rday[-(1:48)])))
  )
  
  tab_wai_yoy <- data.frame("mean" = as.numeric(res_wai_yoy[,1]),
                            "time" = time(res_wai_yoy)) %>%
    pivot_longer(-time)
  
  tab_wai_yoy_full <- tab_wai_yoy
  tab_wai_yoy <- tab_wai_yoy #%>% filter(time >= as.Date("2005-01-01"))
  
  return(list(
    tab_wai_yoy_full = tab_wai_yoy_full,
    tab_wai_yoy = tab_wai_yoy,
    tab_gr_full = tab_gr_full,
    tab_gr_qoq = tab_gr_qoq,
    tab_gr_lv = tab_gr_lv
  ))
}

# Date in decimal format to date format transformation
dec2week <- function(x){
  ryear <- floor(x)
  rmon <- as.numeric(format(as.yearmon(x), "%m"))
  rday <- (round((x %% 1) * 48) %% 4 + 1) * 7
  dates <- as.Date(paste0(ryear,"-",sprintf("%02d", rmon),"-",sprintf("%02d", rday)), format = "%Y-%m-%d")
}
