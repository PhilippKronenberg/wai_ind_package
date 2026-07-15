test_that("wai_sample_config derives dirs and decimals", {
  root <- tempfile(); on.exit(unlink(root, recursive = TRUE))
  cfg <- wai_sample_config(sample_id = "s1",
                           sample_end_date = "2026-03-07",
                           output_root = root)
  expect_true(dir.exists(cfg$figures_dir))
  expect_true(dir.exists(cfg$tables_dir))
  expect_true(dir.exists(cfg$results_dir))
  expect_equal(cfg$sample_end_decimal, round(2026 + 2 / 12 + 7 / 365, 3))
  expect_equal(cfg$sample_end_fit_decimal, round(2026 + 47 / 48, 3))
})

test_that("latest_fit_file honors the cutoff", {
  dir <- tempfile(); dir.create(dir); on.exit(unlink(dir, recursive = TRUE))
  mod <- list()
  for (d in c("2019.979", "2020.5", "2021.25")) {
    save(mod, file = file.path(dir, paste0("fit_", d, ".Rda")))
  }
  expect_match(latest_fit_file(dir, cutoff_decimal = 2020.9), "fit_2020.5.Rda")
  expect_match(latest_fit_file(dir, cutoff_decimal = 2022), "fit_2021.25.Rda")
  expect_error(latest_fit_file(dir, cutoff_decimal = 2019), "No fit file")
})

test_that("write_table_output writes the given contents", {
  dir <- tempfile(); dir.create(dir); on.exit(unlink(dir, recursive = TRUE))
  write_table_output("example.tex", "\\textbf{table}", tables_dir = dir)
  expect_equal(readLines(file.path(dir, "example.tex")), "\\textbf{table}")
})

test_that("save_result_output saves the object under its own name", {
  dir <- tempfile(); dir.create(dir); on.exit(unlink(dir, recursive = TRUE))
  results_example <- data.frame(x = 1:3)
  path <- save_result_output(results_example, "results_example.rda", results_dir = dir)
  expect_true(file.exists(path))

  e <- new.env()
  load(path, envir = e)
  expect_true("results_example" %in% ls(e))
  expect_identical(e$results_example, results_example)
})

test_that("output_figure_path joins the directory and file name", {
  expect_equal(output_figure_path("history.pdf", figures_dir = "outputs/figures"),
               file.path("outputs/figures", "history.pdf"))
})

test_that("filter_to_sample keeps only the requested window", {
  df <- data.frame(time = seq(as.Date("2019-01-01"), by = "quarter", length.out = 12),
                   value = 1:12)
  out <- filter_to_sample(df, end_date = as.Date("2020-12-31"))
  expect_true(all(out$time <= as.Date("2020-12-31")))
  expect_lt(nrow(out), nrow(df))
})

test_that("numeric vintage pickers respect their bounds", {
  vint <- make_synth_vintages()
  expect_equal(get_latest_numeric_vintage(vint, upper_bound = 2023.9), 2023.75)
  expect_equal(get_latest_numeric_vintage(vint, lower_bound = 2024, upper_bound = 2025), 2024.25)
  expect_error(get_latest_numeric_vintage(vint, upper_bound = 2020), "No valid vintages")

  # the next vintage extending the data beyond what 2023.25 covers
  expect_equal(get_next_extending_numeric_vintage(vint, as.Date("2023-06-30")), 2023.75)
})
