# -----------------------------------------------------------------------------
# plots_analytics.R
# -----------------------------------------------------------------------------
# Purpose:
# This file is the main wrapper for the analytics plotting workflow. It runs
# the shared setup, prepares the common data objects, and then executes the
# in-sample and out-of-sample scripts in sequence.
#
# How to use:
# Source this file when you want to run the full analytics workflow end to end
# for the currently active sample configuration.
# -----------------------------------------------------------------------------

source("analysis/5_plots/_setup.R")


# -----------------------------------------------------------------------------
# Full Workflow Execution
# -----------------------------------------------------------------------------
# Run the data-preparation script first, then the in-sample outputs, and
# finally the out-of-sample outputs.

source("analysis/5_plots/analytics_data.R")
source("analysis/5_plots/analytics_in_sample.R")
source("analysis/5_plots/analytics_out-of-sample.R")
