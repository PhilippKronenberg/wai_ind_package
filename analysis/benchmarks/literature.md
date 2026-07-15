# Benchmark and methodology literature

The PDF copies of these papers were removed from the repository
(issue #11); this list preserves the references. Most are available
from the publisher or institution named.

## Methodology / WAI background

- **Kronenberg, P. (2026)** — *A high-frequency GDP indicator for
  Switzerland*, Swiss Journal of Economics and Statistics, 162:10.
  https://doi.org/10.1186/s41937-026-00157-w. The primary methodology
  and application paper for this package: derives the WAI as a single,
  GDP-identified factor from the model below, with full in-sample and
  real-time out-of-sample evaluation against the benchmarks listed
  under "Swiss business-cycle indicator benchmarks".
- **Eckert, F., Kronenberg, P., Mikosch, H., & Neuwirth, S. (2025)** —
  *Tracking economic activity with alternative high-frequency data*,
  Journal of Applied Econometrics, 40(3), 270-290. The underlying
  (multi-factor) Bayesian mixed-frequency dynamic factor model that
  `hfdfm()` implements as a single-factor special case.
- Eckert, Kronenberg, Mikosch, Neuwirth — *Weekly Activity Index (WWA)*,
  SECO technical note and press material, 2021
  (`2021_4_13_technische_notiz_WWA_gb.pdf`, `2021_4_13_MM_wwa_gb.pdf`).
  Available from SECO (seco.admin.ch).
- SECO — *Die Wöchentliche Wirtschaftsaktivität (WWA)*, Diskussionspapier
  (`seco_diskussionspapier_wwa.pdf`).
- SECO — *Konjunkturtendenzen*, Exkurs on the WWA, issue 2020/4
  (`KT_2020_4_Exkurs_WWA_en.pdf`).
- SECO — *BIP-Flash Machbarkeitsstudie*, May 2024
  (`2024_05_BIP-Flash-Machbarkeitsstudie.pdf`).
- SECO — *Einfliessende Indikatoren* (WWA input indicator list)
  (`einfliessende_Indikatoren_en.pdf`).
- SECO — *Methodik* note (`methodik.pdf`).

## Model derivation references (cited in Kronenberg 2026, Sect. 2)

- Chan, J. C., & Jeliazkov, I. (2009) — *Efficient simulation and
  integrated likelihood estimation in state space models*, International
  Journal of Mathematical Modelling and Numerical Optimisation, 1(1-2),
  101-120. Precision sampler used for the factor, stochastic volatility,
  and augmented-data Gibbs blocks.
- Chib, S., & Greenberg, E. (1994) — *Bayes inference in regression
  models with ARMA(p,q) errors*, Journal of Econometrics, 64(1-2),
  183-206. Quasi-differencing approach used to remove serial correlation
  in the measurement errors.
- Mariano, R. S., & Murasawa, Y. (2003) — *A new coincident index of
  business cycles based on monthly and quarterly series*, Journal of
  Applied Econometrics, 18(4), 427-443. Geometric-mean temporal
  aggregation scheme for flow variables (the distributed lag matrices
  `L0, ..., Ls`).
- Bai, J., & Wang, P. (2015) — *Identification and Bayesian estimation
  of dynamic factor models*, Journal of Business & Economic Statistics,
  33(2), 221-240. Factor loading normalization used for identification.
- Kim, S., Shepherd, N., & Chib, S. (1998) — *Stochastic volatility:
  Likelihood inference and comparison with ARCH models*, Review of
  Economic Studies, 65(3), 361-393. Mixture-of-normals approximation
  used to linearize the stochastic volatility measurement equation.
- Primiceri, G. E. (2005) — *Time varying structural vector
  autoregressions and monetary policy*, Review of Economic Studies,
  72(3), 821-852.
- Indergand, R., & Leist, S. (2014) — *A Real-Time Data Set for
  Switzerland*, Swiss Journal of Economics and Statistics, 150(4),
  331-352. Source of the real-time GDP vintages read by
  `get_real_time_gdp_vintages()`.

## Swiss business-cycle indicator benchmarks

- Glocker, C. and Kaniovski, S. (2018) — *Evaluation of Swiss Business
  Cycle Indicators*, WIFO
  (`2018_WIFO_Glocker_Kaniovski_Evaluation_of Swiss_Business_Cycle_Indicators.pdf`).
- Glocker, C. and Wegmüller, P. (2019) — *30 Indikatoren auf einen
  Schlag*, Die Volkswirtschaft
  (`2019_Die_VW_Glocker_und_Wegmueller_30 Indikatoren_auf_einen_Schlag.pdf`).
- Wegmüller, P. and Glocker, C. (2024) — *Capturing Swiss Economic
  Confidence* (`Wegmueller and Glocker (2024) - Capturing Swiss Economic Confidence.pdf`).
- Abberger, K. et al. (2014) — *The KOF Economic Barometer*
  (`Abberger et al (2014) - The KOF Economic Barometer.pdf`). KOF, ETH Zurich.
- Abberger, K. et al. (2018) — *Using rule-based updating procedures to
  improve the performance*
  (`Abberger et al (2018) - Using rule-based updating procedures to improve the performance.pdf`).
- Indergand, R. and Leist, S. (2014) — *A Real-Time Data Set for
  Switzerland* (`Indergand and Leist (2014) - A Real-Time Data Set for Switzerlanda.pdf`).
- Siliverstovs, B. (2011) — *The Real-Time Predictive Content*
  (`Siliverstovs (2011) - The Real-Time Predictive Content.pdf`).

## Official statistics documentation

- FSO — national accounts documentation (`be-e-04-VGR-02.pdf`).
- SNB — Quartalsbulletin 2018/1 (`quartbul_2018_1_komplett.en.pdf`).
