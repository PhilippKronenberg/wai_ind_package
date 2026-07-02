# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

This repository is an early-stage scaffold for an R package (`wai_ind_package`). It currently contains no R source code, `DESCRIPTION`, or `NAMESPACE` file — only a README, a standard R-package `.gitignore`, and CI workflow configuration. When adding the first package contents, follow standard R package layout (`DESCRIPTION`, `NAMESPACE`, `R/`, `man/`, `tests/testthat/`), since the CI workflow already assumes this structure.

## CI / workflows

- `.github/workflows/r.yml` runs on push/PR to `main`: sets up R (matrix of versions 3.6.3 and 4.1.1) on `macos-latest`, installs dependencies via `remotes::install_deps(dependencies = TRUE)`, and runs `rcmdcheck::rcmdcheck(args = "--no-manual", error_on = "error")`. This means the package must pass `R CMD check` with no errors once a `DESCRIPTION` file exists declaring its dependencies.
- `.github/workflows/claude-code.yml` wires up the Claude Code GitHub Action, triggered by `@claude` mentions in issue/PR comments and reviews, or manual `workflow_dispatch`.

## Common commands (once package code exists)

Standard R package development commands apply:
- Check package: `Rscript -e 'rcmdcheck::rcmdcheck(args = "--no-manual", error_on = "error")'`
- Install dependencies: `Rscript -e 'remotes::install_deps(dependencies = TRUE)'`
- Run tests (if using testthat): `Rscript -e 'devtools::test()'`
- Run a single test file: `Rscript -e 'testthat::test_file("tests/testthat/test-<name>.R")'`
- Build documentation from roxygen comments: `Rscript -e 'devtools::document()'`
- Load package for interactive development: `Rscript -e 'devtools::load_all()'`
