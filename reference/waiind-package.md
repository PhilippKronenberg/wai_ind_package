# waiind: A High-Frequency GDP Indicator for Switzerland

Estimates the Weekly Activity Index (WAI): a weekly GDP indicator for
Switzerland derived from a Bayesian mixed-frequency dynamic factor model
([`hfdfm()`](https://philippkronenberg.github.io/wai_ind_package/reference/hfdfm.md))
that combines conventional macroeconomic indicators with alternative
high-frequency data (mobility, transactions, search trends, and similar
series) at weekly, monthly and quarterly frequencies.

## Model in brief

The model extracts a single dynamic factor, constrained by an
identification restriction that fixes its loading on GDP to one, so the
factor is directly interpretable as weekly GDP growth rather than a
generic activity index. Three features let it combine heterogeneous,
incomplete high-frequency data with official GDP figures:

- **Data augmentation** treats missing and mixed-frequency observations
  as latent states, so series can enter with different starting dates,
  publication lags and frequencies (weekly, monthly, quarterly).

- **Stochastic volatility** in the factor state equation lets the
  variance of common shocks vary over time, so crisis-period swings
  (e.g. the COVID-19 pandemic) are not mechanically smoothed away.

- **Quasi-differencing** (Chib & Greenberg, 1994) removes serial
  correlation in the measurement errors, preventing persistent
  idiosyncratic noise in individual indicators from contaminating the
  common factor.

Estimation is by Gibbs sampling using the precision sampler of Chan and
Jeliazkov (2009), with temporal aggregation of flow variables following
the geometric-mean approximation of Mariano and Murasawa (2003).

## Getting started

The package ships the curated indicator datasets
[data_ch_dataset](https://philippkronenberg.github.io/wai_ind_package/reference/data_ch_dataset.md)
and
[data_ch_dataset_test](https://philippkronenberg.github.io/wai_ind_package/reference/data_ch_dataset_test.md),
plus the real-time GDP vintage database (in `inst/extdata/`), so a small
nowcast can be estimated out of the box - see
[`vignette("waiind")`](https://philippkronenberg.github.io/wai_ind_package/articles/waiind.md)
for a worked walkthrough, or the example in
[`hfdfm()`](https://philippkronenberg.github.io/wai_ind_package/reference/hfdfm.md)
for the minimal version.

## References

Kronenberg, P. (2026). A high-frequency GDP indicator for Switzerland.
*Swiss Journal of Economics and Statistics*, 162, 10.
[doi:10.1186/s41937-026-00157-w](https://doi.org/10.1186/s41937-026-00157-w)

Eckert, F., Kronenberg, P., Mikosch, H., & Neuwirth, S. (2025). Tracking
economic activity with alternative high-frequency data. *Journal of
Applied Econometrics*, 40(3), 270-290. (The mixed-frequency dynamic
factor model underlying `waiind`; this package estimates the
single-factor, GDP-identified special case used in the WAI.)

A reference list of the related business-cycle-indicator literature is
kept in `analysis/benchmarks/literature.md` of the source repository.

## See also

Useful links:

- <https://github.com/PhilippKronenberg/wai_ind_package>

- <https://philippkronenberg.github.io/wai_ind_package/>

- Report bugs at
  <https://github.com/PhilippKronenberg/wai_ind_package/issues>

## Author

**Maintainer**: Philipp Kronenberg
<PhilippKronenberg@users.noreply.github.com>
