# waiind: A High-Frequency GDP Indicator for Switzerland

``` r

library(waiind)
```

## What is the WAI?

The Weekly Activity Index (WAI) is a high-frequency GDP indicator for
Switzerland: a single dynamic factor, extracted from a Bayesian
mixed-frequency dynamic factor model, that is directly interpretable as
the week-on-week growth rate of Swiss real GDP. It is built to combine
two kinds of data:

- **Conventional macroeconomic indicators** — surveys, prices, trade,
  purchasing manager indices — published monthly or quarterly, and
- **Alternative high-frequency data** — payment and transaction volumes,
  mobility indicators, search-trend indices, traffic and flight counts —
  available daily or weekly, often with very short histories and
  irregular publication lags.

Unlike unsupervised approaches that extract a factor from high-frequency
data alone (e.g. principal components), the WAI is *supervised*: an
identification restriction anchors the factor to observed GDP growth, so
it is a direct high-frequency proxy for GDP rather than a generic
activity index that merely correlates with it.

The methodology, full empirical results, and a real-time forecast
evaluation are described in Kronenberg (2026); see
[`?waiind`](https://philippkronenberg.github.io/wai_ind_package/reference/waiind-package.md)
for the full citation and the underlying multi-factor framework of
Eckert, Kronenberg, Mikosch & Neuwirth (2025). This vignette covers the
package’s user-facing workflow only.

## The model, briefly

[`hfdfm()`](https://philippkronenberg.github.io/wai_ind_package/reference/hfdfm.md)
estimates a single latent weekly factor $`f_t`$ whose (distributed-lag,
temporally aggregated) measurement equation links it to every input
series, and whose autoregressive state equation includes **stochastic
volatility** so the variance of common shocks can rise during crises
instead of being smoothed away. Three features make this work with
real-world mixed-frequency data:

- **Data augmentation** treats missing and lower-frequency observations
  as latent states, so a series that starts in 2020 and updates weekly,
  another that starts in 1990 and updates monthly, and quarterly GDP
  itself can all enter the same state-space model.
- **Stochastic volatility** in the factor state equation lets abrupt
  swings (e.g. the COVID-19 pandemic) show up as genuinely higher
  volatility rather than being averaged away.
- **Quasi-differencing** of the measurement equation removes serial
  correlation in each series’ idiosyncratic errors, so persistent
  indicator-specific noise doesn’t get misattributed to the common
  factor.

Identification fixes the factor’s loading on the target series (GDP) to
one and shrinks its measurement error toward zero, so the factor tracks
GDP growth closely by construction — see
[`?hfdfm`](https://philippkronenberg.github.io/wai_ind_package/reference/hfdfm.md)
for the details and references, and
[`vignette("waiind")`](https://philippkronenberg.github.io/wai_ind_package/articles/waiind.md)’s
“Real-time GDP vintages” section below for how the target series itself
is constructed for live use.

## A minimal worked example

The package ships a curated, model-ready dataset,
`data_ch_dataset_test`, so a small demonstration model can be estimated
without any external data. Real analyses use the full indicator set and
a much longer chain (the accompanying paper uses `length_sample = 5000`
after a burn-in of 1000); here we use a tiny subset and a short chain
purely so this vignette builds quickly.

``` r

data(data_ch_dataset_test)

target <- "ch.seco.gdp.real.gdp.ssa"
flows <- lapply(
  data_ch_dataset_test$flows[c(target, "SWISSMI", "traffic_PW")],
  stats::window, start = 2018
)
stocks <- lapply(data_ch_dataset_test$stocks[1:2], stats::window, start = 2018)

set.seed(1)
fit <- hfdfm(
  flows = flows, stocks = stocks, target = target,
  length_sample = 200, burn_in = 50
)
#> preallocating..
#> simulating posterior distribution..
#>   |                                                                              |                                                                      |   0%  |                                                                              |=                                                                     |   1%  |                                                                              |=                                                                     |   2%  |                                                                              |==                                                                    |   2%  |                                                                              |==                                                                    |   3%  |                                                                              |===                                                                   |   4%  |                                                                              |===                                                                   |   5%  |                                                                              |====                                                                  |   5%  |                                                                              |====                                                                  |   6%  |                                                                              |=====                                                                 |   7%  |                                                                              |=====                                                                 |   8%  |                                                                              |======                                                                |   8%  |                                                                              |======                                                                |   9%  |                                                                              |=======                                                               |  10%  |                                                                              |========                                                              |  11%  |                                                                              |========                                                              |  12%  |                                                                              |=========                                                             |  12%  |                                                                              |=========                                                             |  13%  |                                                                              |==========                                                            |  14%  |                                                                              |==========                                                            |  15%  |                                                                              |===========                                                           |  15%  |                                                                              |===========                                                           |  16%  |                                                                              |============                                                          |  17%  |                                                                              |============                                                          |  18%  |                                                                              |=============                                                         |  18%  |                                                                              |=============                                                         |  19%  |                                                                              |==============                                                        |  20%  |                                                                              |===============                                                       |  21%  |                                                                              |===============                                                       |  22%  |                                                                              |================                                                      |  22%  |                                                                              |================                                                      |  23%  |                                                                              |=================                                                     |  24%  |                                                                              |=================                                                     |  25%  |                                                                              |==================                                                    |  25%  |                                                                              |==================                                                    |  26%  |                                                                              |===================                                                   |  27%  |                                                                              |===================                                                   |  28%  |                                                                              |====================                                                  |  28%  |                                                                              |====================                                                  |  29%  |                                                                              |=====================                                                 |  30%  |                                                                              |======================                                                |  31%  |                                                                              |======================                                                |  32%  |                                                                              |=======================                                               |  32%  |                                                                              |=======================                                               |  33%  |                                                                              |========================                                              |  34%  |                                                                              |========================                                              |  35%  |                                                                              |=========================                                             |  35%  |                                                                              |=========================                                             |  36%  |                                                                              |==========================                                            |  37%  |                                                                              |==========================                                            |  38%  |                                                                              |===========================                                           |  38%  |                                                                              |===========================                                           |  39%  |                                                                              |============================                                          |  40%  |                                                                              |=============================                                         |  41%  |                                                                              |=============================                                         |  42%  |                                                                              |==============================                                        |  42%  |                                                                              |==============================                                        |  43%  |                                                                              |===============================                                       |  44%  |                                                                              |===============================                                       |  45%  |                                                                              |================================                                      |  45%  |                                                                              |================================                                      |  46%  |                                                                              |=================================                                     |  47%  |                                                                              |=================================                                     |  48%  |                                                                              |==================================                                    |  48%  |                                                                              |==================================                                    |  49%  |                                                                              |===================================                                   |  50%  |                                                                              |====================================                                  |  51%  |                                                                              |====================================                                  |  52%  |                                                                              |=====================================                                 |  52%  |                                                                              |=====================================                                 |  53%  |                                                                              |======================================                                |  54%  |                                                                              |======================================                                |  55%  |                                                                              |=======================================                               |  55%  |                                                                              |=======================================                               |  56%  |                                                                              |========================================                              |  57%  |                                                                              |========================================                              |  58%  |                                                                              |=========================================                             |  58%  |                                                                              |=========================================                             |  59%  |                                                                              |==========================================                            |  60%  |                                                                              |===========================================                           |  61%  |                                                                              |===========================================                           |  62%  |                                                                              |============================================                          |  62%  |                                                                              |============================================                          |  63%  |                                                                              |=============================================                         |  64%  |                                                                              |=============================================                         |  65%  |                                                                              |==============================================                        |  65%  |                                                                              |==============================================                        |  66%  |                                                                              |===============================================                       |  67%  |                                                                              |===============================================                       |  68%  |                                                                              |================================================                      |  68%  |                                                                              |================================================                      |  69%  |                                                                              |=================================================                     |  70%  |                                                                              |==================================================                    |  71%  |                                                                              |==================================================                    |  72%  |                                                                              |===================================================                   |  72%  |                                                                              |===================================================                   |  73%  |                                                                              |====================================================                  |  74%  |                                                                              |====================================================                  |  75%  |                                                                              |=====================================================                 |  75%  |                                                                              |=====================================================                 |  76%  |                                                                              |======================================================                |  77%  |                                                                              |======================================================                |  78%  |                                                                              |=======================================================               |  78%  |                                                                              |=======================================================               |  79%  |                                                                              |========================================================              |  80%  |                                                                              |=========================================================             |  81%  |                                                                              |=========================================================             |  82%  |                                                                              |==========================================================            |  82%  |                                                                              |==========================================================            |  83%  |                                                                              |===========================================================           |  84%  |                                                                              |===========================================================           |  85%  |                                                                              |============================================================          |  85%  |                                                                              |============================================================          |  86%  |                                                                              |=============================================================         |  87%  |                                                                              |=============================================================         |  88%  |                                                                              |==============================================================        |  88%  |                                                                              |==============================================================        |  89%  |                                                                              |===============================================================       |  90%  |                                                                              |================================================================      |  91%  |                                                                              |================================================================      |  92%  |                                                                              |=================================================================     |  92%  |                                                                              |=================================================================     |  93%  |                                                                              |==================================================================    |  94%  |                                                                              |==================================================================    |  95%  |                                                                              |===================================================================   |  95%  |                                                                              |===================================================================   |  96%  |                                                                              |====================================================================  |  97%  |                                                                              |====================================================================  |  98%  |                                                                              |===================================================================== |  98%  |                                                                              |===================================================================== |  99%  |                                                                              |======================================================================| 100%
#> processing output..

class(fit)
#> [1] "hfdfm"
names(fit)
#>  [1] "factor"         "factor_var"     "index"          "nowcast"       
#>  [5] "nowcast_var"    "target"         "pars"           "data"          
#>  [9] "data_augmented" "inventory"
```

`fit$factor` is the annualized weekly growth rate implied by the model —
the WAI itself — and `fit$nowcast` is that same information aggregated
back up to the target’s own (here quarterly) frequency:

``` r

plot(fit$factor, ylab = "WAI (annualized %, weekly)", xlab = NULL)
```

![](waiind_files/figure-html/plot-factor-1.png)

``` r

fit$nowcast
#>              Qtr1         Qtr2         Qtr3         Qtr4
#> 2018  0.010358258  0.007347781 -0.001407579  0.005268532
#> 2019  0.002011808  0.006503894  0.003023009  0.001999370
#> 2020 -0.010753651 -0.065794476  0.059015689  0.009101004
#> 2021  0.005967472  0.025366943  0.019780739  0.010104565
#> 2022  0.002357652  0.006806208  0.004997186  0.002075334
#> 2023  0.006192212 -0.003620587  0.004556616  0.003672437
#> 2024 -0.001181404  0.007846092  0.002901754  0.005175476
#> 2025  0.007858613  0.001230707 -0.004400680  0.001506296
```

`fit$index` gives the cumulated activity level (rebased to 100 at the
start of the estimation window), and `fit$pars` holds the posterior
means of the model parameters, including the factor loadings
(`fit$pars$lambda`) — the target series’ loading is fixed at 1 by
construction:

``` r

fit$pars$lambda[which(fit$inventory$key == target)]
#> [1] 1
```

## Real-time GDP vintages

The full `data_ch_dataset` deliberately ships *without* a GDP target
series: real analyses inject GDP at runtime from the real-time vintage
database, which ships with the package and needs no configuration:

``` r

vintages <- get_real_time_gdp_vintages("quarterly")
#> New names:
#> • `` -> `...1`
#> • `` -> `...2`
#> • `` -> `...3`
#> • `` -> `...4`
#> • `` -> `...5`
#> • `` -> `...6`
#> • `` -> `...7`
#> • `` -> `...8`
#> • `` -> `...9`
#> • `` -> `...10`
#> • `` -> `...11`
#> • `` -> `...12`
#> • `` -> `...13`
#> • `` -> `...14`
#> • `` -> `...15`
#> • `` -> `...16`
#> • `` -> `...17`
#> • `` -> `...18`
#> • `` -> `...19`
#> • `` -> `...20`
#> • `` -> `...21`
#> • `` -> `...22`
#> • `` -> `...23`
#> • `` -> `...24`
#> • `` -> `...25`
#> • `` -> `...26`
#> • `` -> `...27`
#> • `` -> `...28`
#> • `` -> `...29`
#> • `` -> `...30`
#> • `` -> `...31`
#> • `` -> `...32`
#> • `` -> `...33`
#> • `` -> `...34`
#> • `` -> `...35`
#> • `` -> `...36`
#> • `` -> `...37`
#> • `` -> `...38`
#> • `` -> `...39`
#> • `` -> `...40`
#> • `` -> `...41`
#> • `` -> `...42`
#> • `` -> `...43`
#> • `` -> `...44`
#> • `` -> `...45`
#> • `` -> `...46`
#> • `` -> `...47`
#> • `` -> `...48`
#> • `` -> `...49`
#> • `` -> `...50`
#> • `` -> `...51`
#> • `` -> `...52`
#> • `` -> `...53`
#> • `` -> `...54`
#> • `` -> `...55`
#> • `` -> `...56`
#> • `` -> `...57`
#> • `` -> `...58`
#> • `` -> `...59`
#> • `` -> `...60`
#> • `` -> `...61`
#> • `` -> `...62`
#> • `` -> `...63`
#> • `` -> `...64`
#> • `` -> `...65`
#> • `` -> `...66`
#> • `` -> `...67`
#> • `` -> `...68`
#> • `` -> `...69`
#> • `` -> `...70`
#> • `` -> `...71`
#> • `` -> `...72`
#> • `` -> `...73`
#> • `` -> `...74`
#> • `` -> `...75`
#> • `` -> `...76`
#> • `` -> `...77`
#> • `` -> `...78`
#> • `` -> `...79`
#> • `` -> `...80`
#> • `` -> `...81`
#> • `` -> `...82`
#> • `` -> `...83`
#> • `` -> `...84`
#> • `` -> `...85`
#> • `` -> `...86`
#> • `` -> `...87`
#> • `` -> `...88`
#> • `` -> `...89`
#> • `` -> `...90`
#> • `` -> `...91`
#> • `` -> `...92`
#> • `` -> `...93`
#> • `` -> `...94`
#> • `` -> `...95`
#> • `` -> `...96`
#> • `` -> `...97`
#> • `` -> `...98`
#> • `` -> `...99`
#> • `` -> `...100`
#> • `` -> `...101`
#> • `` -> `...102`
#> • `` -> `...103`
#> • `` -> `...104`
#> • `` -> `...105`
#> Warning: Expecting numeric in BW10 / R10C75: got a date
#> Warning: Expecting numeric in BX10 / R10C76: got a date
#> Warning: Expecting numeric in BY10 / R10C77: got a date
#> Warning: Expecting numeric in BZ10 / R10C78: got a date
#> Warning: Expecting numeric in CA10 / R10C79: got a date
#> Warning: Expecting numeric in CB10 / R10C80: got a date
#> Warning: Expecting numeric in CC10 / R10C81: got a date
#> Warning: Expecting numeric in CD10 / R10C82: got a date
#> Warning: Expecting numeric in CE10 / R10C83: got a date
#> Warning: Expecting numeric in CF10 / R10C84: got a date
#> Warning: Expecting numeric in CG10 / R10C85: got a date
#> Warning: Expecting numeric in CH10 / R10C86: got a date
#> Warning: Expecting numeric in CI10 / R10C87: got a date
#> Warning: Expecting numeric in CJ10 / R10C88: got a date
#> Warning: Expecting numeric in CK10 / R10C89: got a date
#> Warning: Expecting numeric in CL10 / R10C90: got a date
#> Warning: Expecting numeric in CM10 / R10C91: got a date
#> Warning: Expecting numeric in CN10 / R10C92: got a date
#> Warning: Expecting numeric in CO10 / R10C93: got a date
#> Warning: Expecting numeric in CP10 / R10C94: got a date
#> Warning: Expecting numeric in CQ10 / R10C95: got a date
#> Warning: Expecting numeric in CR10 / R10C96: got a date
#> Warning: Expecting numeric in CS10 / R10C97: got a date
#> Warning: Expecting numeric in CT10 / R10C98: got a date
#> Warning: Expecting numeric in CU10 / R10C99: got a date
#> Warning: Expecting numeric in CV10 / R10C100: got a date
#> Warning: Expecting numeric in CW10 / R10C101: got a date
#> Warning: Expecting numeric in CX10 / R10C102: got a date
#> Warning: Expecting numeric in CY10 / R10C103: got a date
#> Warning: Expecting numeric in CZ10 / R10C104: got a date
#> Warning: Expecting numeric in DA10 / R10C105: got a date
#> New names:
#> New names:
#> • `` -> `...1`
#> • `` -> `...2`
#> • `` -> `...3`
#> • `` -> `...4`
#> • `` -> `...5`
#> • `` -> `...6`
#> • `` -> `...7`
#> • `` -> `...8`
#> • `` -> `...9`
#> • `` -> `...10`
#> • `` -> `...11`
#> • `` -> `...12`
#> • `` -> `...13`
#> • `` -> `...14`
#> • `` -> `...15`
#> • `` -> `...16`
#> • `` -> `...17`
#> • `` -> `...18`
#> • `` -> `...19`
#> • `` -> `...20`
#> • `` -> `...21`
#> • `` -> `...22`
#> • `` -> `...23`
#> • `` -> `...24`
#> • `` -> `...25`
#> • `` -> `...26`
#> • `` -> `...27`
#> • `` -> `...28`
#> • `` -> `...29`
#> • `` -> `...30`
#> • `` -> `...31`
#> Warning: Expecting numeric in B10 / R10C2: got a date
#> Warning: Expecting numeric in C10 / R10C3: got a date
#> Warning: Expecting numeric in D10 / R10C4: got a date
#> Warning: Expecting numeric in E10 / R10C5: got a date
#> Warning: Expecting numeric in F10 / R10C6: got a date
#> Warning: Expecting numeric in G10 / R10C7: got a date
#> Warning: Expecting numeric in H10 / R10C8: got a date
#> Warning: Expecting numeric in I10 / R10C9: got a date
#> Warning: Expecting numeric in J10 / R10C10: got a date
#> Warning: Expecting numeric in K10 / R10C11: got a date
#> Warning: Expecting numeric in L10 / R10C12: got a date
#> Warning: Expecting numeric in M10 / R10C13: got a date
#> Warning: Expecting numeric in N10 / R10C14: got a date
#> Warning: Expecting numeric in O10 / R10C15: got a date
#> Warning: Expecting numeric in P10 / R10C16: got a date
#> Warning: Expecting numeric in Q10 / R10C17: got a date
#> Warning: Expecting numeric in R10 / R10C18: got a date
#> Warning: Expecting numeric in S10 / R10C19: got a date
#> Warning: Expecting numeric in T10 / R10C20: got a date
#> Warning: Expecting numeric in U10 / R10C21: got a date
#> Warning: Expecting numeric in V10 / R10C22: got a date
#> Warning: Expecting numeric in W10 / R10C23: got a date
#> Warning: Expecting numeric in X10 / R10C24: got a date
#> Warning: Expecting numeric in Y10 / R10C25: got a date
#> Warning: Expecting numeric in Z10 / R10C26: got a date
#> Warning: Expecting numeric in AA10 / R10C27: got a date
#> Warning: Expecting numeric in AB10 / R10C28: got a date
#> Warning: Expecting numeric in AC10 / R10C29: got a date
#> Warning: Expecting numeric in AD10 / R10C30: got a date
#> Warning: Expecting numeric in AE10 / R10C31: got a date
#> Warning: Expecting numeric in AF10 / R10C32: got a date
#> Warning: Expecting numeric in AG10 / R10C33: got a date
#> Warning: Expecting numeric in AH10 / R10C34: got a date
#> Warning: Expecting numeric in AI10 / R10C35: got a date
#> Warning: Expecting numeric in AJ10 / R10C36: got a date
#> Warning: Expecting numeric in AK10 / R10C37: got a date
#> Warning: Expecting numeric in AL10 / R10C38: got a date
#> Warning: Expecting numeric in AM10 / R10C39: got a date
#> Warning: Expecting numeric in AN10 / R10C40: got a date
#> Warning: Expecting numeric in AO10 / R10C41: got a date
#> Warning: Expecting numeric in AP10 / R10C42: got a date
#> Warning: Expecting numeric in AQ10 / R10C43: got a date
#> Warning: Expecting numeric in AR10 / R10C44: got a date
#> Warning: Expecting numeric in AS10 / R10C45: got a date
#> Warning: Expecting numeric in AT10 / R10C46: got a date
#> Warning: Expecting numeric in AU10 / R10C47: got a date
#> Warning: Expecting numeric in AV10 / R10C48: got a date
#> Warning: Expecting numeric in AW10 / R10C49: got a date
#> Warning: Expecting numeric in AX10 / R10C50: got a date
#> Warning: Expecting numeric in AY10 / R10C51: got a date
#> Warning: Expecting numeric in AZ10 / R10C52: got a date
#> Warning: Expecting numeric in BA10 / R10C53: got a date
#> Warning: Expecting numeric in BB10 / R10C54: got a date
#> Warning: Expecting numeric in BC10 / R10C55: got a date
#> Warning: Expecting numeric in BD10 / R10C56: got a date
#> Warning: Expecting numeric in BE10 / R10C57: got a date
#> Warning: Expecting numeric in BF10 / R10C58: got a date
#> Warning: Expecting numeric in BG10 / R10C59: got a date
#> Warning: Expecting numeric in BH10 / R10C60: got a date
#> Warning: Expecting numeric in BI10 / R10C61: got a date
#> Warning: Expecting numeric in BJ10 / R10C62: got a date
#> Warning: Expecting numeric in BK10 / R10C63: got a date
#> Warning: Expecting numeric in BL10 / R10C64: got a date
#> Warning: Expecting numeric in BM10 / R10C65: got a date
#> Warning: Expecting numeric in BN10 / R10C66: got a date
#> Warning: Expecting numeric in BO10 / R10C67: got a date
#> Warning: Expecting numeric in BP10 / R10C68: got a date
#> Warning: Expecting numeric in BQ10 / R10C69: got a date
#> Warning: Expecting numeric in BR10 / R10C70: got a date
#> Warning: Expecting numeric in BS10 / R10C71: got a date
#> Warning: Expecting numeric in BT10 / R10C72: got a date
#> Warning: Expecting numeric in BU10 / R10C73: got a date
#> Warning: Expecting numeric in BV10 / R10C74: got a date
#> Warning: Expecting numeric in BW10 / R10C75: got a date
#> Warning: Expecting numeric in BX10 / R10C76: got a date
#> Warning: Expecting numeric in BY10 / R10C77: got a date
#> Warning: Expecting numeric in BZ10 / R10C78: got a date
#> Warning: Expecting numeric in CA10 / R10C79: got a date
#> Warning: Expecting numeric in CB10 / R10C80: got a date
#> Warning: Expecting numeric in CC10 / R10C81: got a date
#> Warning: Expecting numeric in CD10 / R10C82: got a date
#> Warning: Expecting numeric in CE10 / R10C83: got a date
#> Warning: Expecting numeric in CF10 / R10C84: got a date
#> Warning: Expecting numeric in CG10 / R10C85: got a date
#> Warning: Expecting numeric in CH10 / R10C86: got a date
#> Warning: Expecting numeric in CI10 / R10C87: got a date
#> Warning: Expecting numeric in CJ10 / R10C88: got a date
#> Warning: Expecting numeric in CK10 / R10C89: got a date
#> Warning: Expecting numeric in CL10 / R10C90: got a date
#> Warning: Expecting numeric in CM10 / R10C91: got a date
#> Warning: Expecting numeric in CN10 / R10C92: got a date
#> Warning: Expecting numeric in CO10 / R10C93: got a date
#> Warning: Expecting numeric in CP10 / R10C94: got a date
#> Warning: Expecting numeric in CQ10 / R10C95: got a date
#> Warning: Expecting numeric in CR10 / R10C96: got a date
#> Warning: Expecting numeric in CS10 / R10C97: got a date
#> Warning: Expecting numeric in CT10 / R10C98: got a date
#> Warning: Expecting numeric in CU10 / R10C99: got a date
#> Warning: Expecting numeric in CV10 / R10C100: got a date
#> Warning: Expecting numeric in CW10 / R10C101: got a date
#> Warning: Expecting numeric in CX10 / R10C102: got a date
#> Warning: Expecting numeric in CY10 / R10C103: got a date
#> Warning: Expecting numeric in CZ10 / R10C104: got a date
#> Warning: Expecting numeric in DA10 / R10C105: got a date
#> New names:
#> • `` -> `...1`
#> • `` -> `...2`
#> • `` -> `...3`
#> • `` -> `...4`
#> • `` -> `...5`
#> • `` -> `...6`
#> • `` -> `...7`
#> • `` -> `...8`
#> • `` -> `...9`
#> • `` -> `...10`
#> • `` -> `...11`
#> • `` -> `...12`
#> • `` -> `...13`
#> • `` -> `...14`
#> • `` -> `...15`
#> • `` -> `...16`
#> • `` -> `...17`
#> • `` -> `...18`
#> • `` -> `...19`
#> • `` -> `...20`
#> • `` -> `...21`
#> • `` -> `...22`
#> • `` -> `...23`
#> • `` -> `...24`
#> • `` -> `...25`
#> • `` -> `...26`
#> • `` -> `...27`
#> • `` -> `...28`
#> • `` -> `...29`
#> • `` -> `...30`
#> • `` -> `...31`
#> • `` -> `...32`
#> • `` -> `...33`
#> • `` -> `...34`
#> • `` -> `...35`
#> • `` -> `...36`
#> • `` -> `...37`
#> • `` -> `...38`
#> • `` -> `...39`
#> • `` -> `...40`
#> • `` -> `...41`
#> • `` -> `...42`
#> • `` -> `...43`
#> • `` -> `...44`
#> • `` -> `...45`
#> • `` -> `...46`
#> • `` -> `...47`
#> • `` -> `...48`
#> • `` -> `...49`
#> • `` -> `...50`
#> • `` -> `...51`
#> • `` -> `...52`
#> • `` -> `...53`
#> • `` -> `...54`
#> • `` -> `...55`
#> • `` -> `...56`
#> • `` -> `...57`
#> • `` -> `...58`
#> • `` -> `...59`
#> • `` -> `...60`
#> • `` -> `...61`
#> • `` -> `...62`
#> • `` -> `...63`
#> • `` -> `...64`
#> • `` -> `...65`
#> • `` -> `...66`
#> • `` -> `...67`
#> • `` -> `...68`
#> • `` -> `...69`
#> • `` -> `...70`
#> • `` -> `...71`
#> • `` -> `...72`
#> • `` -> `...73`
#> • `` -> `...74`
#> • `` -> `...75`
#> • `` -> `...76`
#> • `` -> `...77`
#> • `` -> `...78`
#> • `` -> `...79`
#> • `` -> `...80`
#> • `` -> `...81`
#> • `` -> `...82`
#> • `` -> `...83`
#> • `` -> `...84`
#> • `` -> `...85`
#> • `` -> `...86`
#> • `` -> `...87`
#> • `` -> `...88`
#> • `` -> `...89`
#> • `` -> `...90`
#> • `` -> `...91`
#> • `` -> `...92`
#> • `` -> `...93`
#> • `` -> `...94`
#> • `` -> `...95`
#> • `` -> `...96`
#> • `` -> `...97`
#> • `` -> `...98`
#> • `` -> `...99`
#> • `` -> `...100`
#> • `` -> `...101`
#> • `` -> `...102`
#> • `` -> `...103`
#> • `` -> `...104`
dim(vintages)
#> [1] 144 105
```

[`cut_data_real_time()`](https://philippkronenberg.github.io/wai_ind_package/reference/cut_data_real_time.md)
truncates a dataset to what would have been observable at a given date,
substituting the appropriate GDP vintage for the target series — the
building block for the paper’s real-time out-of-sample evaluation:

``` r

dat_rt <- cut_data_real_time(data_ch_dataset_test, current_date = 2024.5,
                             GDP_gr_vintages = vintages)
tail(time(dat_rt$flows[[target]]))
#>         Qtr1    Qtr2    Qtr3    Qtr4
#> 2022                         2022.75
#> 2023 2023.00 2023.25 2023.50 2023.75
#> 2024 2024.00
```

## Beyond this vignette

The functions used in the accompanying analysis pipeline are exported
but need either the full (non-shipped) indicator set or previously saved
model fits, so they aren’t run here:

``` r

# Estimate the full WAI and optionally save the fit:
fit_full <- run_wai_adj(
  flows = dat$flows, stocks = dat$stocks, target = target,
  date = 2024.5, dataset_used = "full_RT", output_dir = "fits/updated"
)

# AR(1) benchmark, and the Diebold-Mariano test used to compare them:
fit_ar <- run_ar(flows = dat$flows, stocks = dat$stocks, target = target,
                 date = 2024.5, dataset_used = "full_RT")
dm_test_modified(errors_wai, errors_ar)
```

For the in-sample and out-of-sample evaluation tables and plots shown in
the paper (correlation heatmaps, relative RMSE/MAE tables against the
SECO-WEA, F-CURVE, SECO-SEC, SNB-BCI and KOF-BARO benchmarks), see the
`analysis/5_plots/` scripts in the package’s source repository, which
call
[`get_combined_cor_table()`](https://philippkronenberg.github.io/wai_ind_package/reference/get_combined_cor_table.md),
[`get_insample_fit_table()`](https://philippkronenberg.github.io/wai_ind_package/reference/get_insample_fit_table.md),
[`create_rel_error_tables()`](https://philippkronenberg.github.io/wai_ind_package/reference/create_rel_error_tables.md)
and related functions documented under
[`?get_combined_cor_table`](https://philippkronenberg.github.io/wai_ind_package/reference/get_combined_cor_table.md).
