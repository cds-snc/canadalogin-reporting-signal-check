#' Athena connection and shared setup for the CanadaLogin Week in Review.
#'
#' This file holds ONLY non-analytical setup: the connection factory, a package
#' check, pure date helpers, and constants for inspect.qmd. The data queries
#' themselves are deliberately NOT here - they are written inline in inspect.qmd
#' and repeated verbatim in each weekly report, so every report freezes the exact
#' query that produced its numbers.
#'
#' Configuration comes from a gitignored .env at the project root.
#' Authenticate first with: aws sso login --profile <AWS_PROFILE>.
#'
#' Pipeline of use:
#'   1. check_packages()  - fail early with an install hint if deps are missing
#'   2. load .env         - read AWS profile / region / staging dir
#'   3. connect_athena()  - open the RAthena connection

# Packages -------------------------------------------------------------------

required_packages <- c(
  "DBI", "RAthena", "dplyr", "dbplyr", "stringr", "tidyr", "lubridate",
  "ggplot2", "scales", "dotenv"
)

check_packages <- function() {
  missing <- required_packages[
    !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
  ]
  if (length(missing) > 0) {
    stop(
      "Missing R packages: ", paste(missing, collapse = ", "),
      "\nInstall with: install.packages(c(",
      paste0("'", missing, "'", collapse = ", "), "))",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

# Constants ------------------------------------------------------------------

# CanadaLogin launched on this date; time-series graphs start at the launch
# week rather than a fixed trailing window until there is enough history.
launch_date <- as.Date("2026-04-22")
launch_week_start <- as.Date("2026-04-20")  # Monday of the launch week

# Internal / system applications, excluded from public-adoption reporting.
internal_applications <- c(
  "Flow Application",
  "GCS Migration Solution",
  "GC Sign In - Profile Management App"
)

# Configuration --------------------------------------------------------------

load_config <- function(env_path = ".env") {
  if (file.exists(env_path)) dotenv::load_dot_env(env_path)
  invisible(TRUE)
}

# Connection -----------------------------------------------------------------

connect_athena <- function() {
  check_packages()
  load_config()
  DBI::dbConnect(
    RAthena::athena(),
    profile_name   = Sys.getenv("AWS_PROFILE"),
    region_name    = Sys.getenv("AWS_REGION", "ca-central-1"),
    s3_staging_dir = Sys.getenv("ATHENA_S3_STAGING_DIR")
  )
}

# Date helpers ---------------------------------------------------------------

# The Monday on or before a date
monday_of <- function(d) {
  d <- as.Date(d)
  d - ((as.integer(format(d, "%u")) - 1L))
}
