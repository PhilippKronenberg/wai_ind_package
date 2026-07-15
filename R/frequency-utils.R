#' Aggregate weekly series in a dataset to monthly frequency
#'
#' Aggregates every weekly series (frequency 48) in the dataset to
#' monthly sums; series of other frequencies are returned unchanged.
#'
#' @param dat A list with components `flows` and `stocks` (named lists of
#'   `ts` objects).
#'
#' @return A list with components `flows` and `stocks`.
#' @examples
#' data(data_ch_dataset_test)
#' monthly <- week2mon(data_ch_dataset_test)
#' stats::frequency(monthly$flows[[1]])
#' @export
week2mon <- function(dat){

  list("flows" = lapply(dat$flows, function(x) week2mon_helper(x)),
       "stocks" = lapply(dat$stocks, function(x) week2mon_helper(x)))

}


#' @noRd
#' @importFrom stats frequency as.ts aggregate
#' @importFrom zoo as.zoo as.yearmon
week2mon_helper <- function(x){

  if(frequency(x) == 48) as.ts(aggregate(as.zoo(x), as.yearmon, sum)) else x

}


#' Drop all weekly series from a dataset
#'
#' Removes every weekly series (frequency 48) from the dataset, keeping
#' only monthly and quarterly series.
#'
#' @inheritParams week2mon
#'
#' @return A list with components `flows` and `stocks`.
#' @examples
#' data(data_ch_dataset_test)
#' no_weekly <- drop_weekly(data_ch_dataset_test)
#' length(no_weekly$flows)
#' @export
drop_weekly <- function(dat){

  list("flows" = dat$flows[lengths(lapply(dat$flows, function(x) drop_weekly_helper(x))) > 0],
       "stocks" = dat$stocks[lengths(lapply(dat$stocks, function(x) drop_weekly_helper(x))) > 0])
}


#' @noRd
#' @importFrom stats frequency
drop_weekly_helper <- function(x){

  if(frequency(x) == 48) x <- NULL else x
}


#' Remove list elements by name
#'
#' @noRd
remove_elements <- function(lst, names_to_remove) {
  lst[setdiff(names(lst), names_to_remove)]
}


#' Drop the financial market series from a dataset
#'
#' Removes the financial market indicators (FINANSW, INDUSSW, SWISSMI,
#' VIX) from both the flows and stocks components.
#'
#' @inheritParams week2mon
#'
#' @return A list with components `flows` and `stocks`.
#' @examples
#' data(data_ch_dataset_test)
#' no_fin <- drop_financial(data_ch_dataset_test)
#' setdiff(names(data_ch_dataset_test$flows), names(no_fin$flows))
#' @export
drop_financial <- function(dat){
  # Names you want to remove
  financial_variables <- c("FINANSW", "INDUSSW", "SWISSMI", "VIX")

  # Apply to both sublists
  list("flows" = remove_elements(dat$flows, financial_variables),
       "stocks" = remove_elements(dat$stocks, financial_variables))
}


#' Drop the non-total retail trade series from a dataset
#'
#' Removes the sectoral FSO retail trade series (NOGA 0803-0808),
#' keeping only the total retail series.
#'
#' @inheritParams week2mon
#'
#' @return A list with components `flows` and `stocks`.
#' @examples
#' data(data_ch_dataset_test)
#' total_retail_only <- drop_retail(data_ch_dataset_test)
#' length(total_retail_only$flows)
#' @export
drop_retail <- function(dat){
  # Names you want to remove
  non_total_retail <- c("ch.fso.rtt.ind.r.noga0803.sa", "ch.fso.rtt.ind.r.noga0804.sa", "ch.fso.rtt.ind.r.noga0805.sa",
                           "ch.fso.rtt.ind.r.noga0806.sa", "ch.fso.rtt.ind.r.noga0807.sa", "ch.fso.rtt.ind.r.noga0808.sa")

  # Apply to both sublists
  list("flows" = remove_elements(dat$flows, non_total_retail),
       "stocks" = remove_elements(dat$stocks, non_total_retail))
}


#' Convert decimal weekly dates to calendar dates
#'
#' Converts decimal dates on the 48-week grid to `Date` values on the
#' project convention that weeks fall on the 7th, 14th, 21st and 28th of
#' each month.
#'
#' @param x Numeric vector of decimal dates (multiples of 1/48).
#'
#' @return A `Date` vector.
#'
#' @examples
#' dec2week(2020 + (0:3)/48)
#'
#' @importFrom zoo as.yearmon
#' @export
dec2week <- function(x){
  ryear <- floor(x)
  rmon <- as.numeric(format(as.yearmon(x), "%m"))
  rday <- (round((x %% 1) * 48) %% 4 + 1) * 7
  dates <- as.Date(paste0(ryear,"-",sprintf("%02d", rmon),"-",sprintf("%02d", rday)), format = "%Y-%m-%d")
}
