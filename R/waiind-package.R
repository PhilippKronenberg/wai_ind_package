#' waiind: Swiss Weekly Activity Index from a Mixed-Frequency Dynamic Factor Model
#'
#' Estimates a weekly activity index (WAI) for Switzerland and produces
#' weekly GDP nowcasts and backcasts. The core is a Bayesian
#' mixed-frequency dynamic factor model estimated by Markov chain Monte
#' Carlo sampling ([hfdfm()]), complemented by real-time GDP vintage
#' handling ([get_real_time_gdp_vintages()], [cut_data_real_time()]),
#' out-of-sample forecast evaluation ([run_wai_adj()], [run_ar()],
#' [dm_test_modified()]) and the table and plot generators used in the
#' accompanying analysis (see the `analysis/` directory of the source
#' repository).
#'
#' @section Getting started:
#' The package ships the curated indicator datasets [data_ch_dataset] and
#' [data_ch_dataset_test] plus the real-time GDP vintage database (in
#' `inst/extdata/`), so a small nowcast can be estimated out of the box -
#' see the example in [hfdfm()].
#'
#' @references
#' Eckert, F., Kronenberg, P., Mikosch, H. and Neuwirth, S. -
#' *Tracking Economic Activity With Alternative High-Frequency Data*
#' (weekly WWA/WAI methodology; SECO technical note, 2021).
#' A reference list of the related literature is kept in
#' `analysis/benchmarks/literature.md` of the source repository.
#'
#' @keywords internal
"_PACKAGE"
