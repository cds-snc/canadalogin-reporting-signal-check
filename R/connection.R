#' Athena connection and shared setup for the CanadaLogin Signal Check.
#'
#' This file holds ONLY non-analytical setup: the connection factory, a package
#' check, pure date helpers, and constants for inspect.qmd. The data queries
#' themselves are deliberately NOT here - they are written inline in inspect.qmd
#' and repeated verbatim in each report, so every report freezes the exact
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
  "ggplot2", "scales", "cowplot", "magick", "dotenv", "ggbrick"
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

# Search upward for the project-root .env so this works whether sourced from the
# project root (inspect.qmd) or a subdirectory (reports/ renders from reports/).
load_config <- function() {
  for (p in c(".env", "../.env", "../../.env")) {
    if (file.exists(p)) {
      dotenv::load_dot_env(p)
      return(invisible(TRUE))
    }
  }
  invisible(FALSE)
}

# Connection -----------------------------------------------------------------

connect_athena <- function() {
  check_packages()
  load_config()
  # Silence RAthena's per-query "Data scanned: X Bytes" INFO output; it is noise
  # in the rendered workbook and reports. Affects console output only, not results.
  RAthena::RAthena_options(verbose = FALSE)
  DBI::dbConnect(
    RAthena::athena(),
    profile_name   = Sys.getenv("AWS_PROFILE"),
    region_name    = Sys.getenv("AWS_REGION", "ca-central-1"),
    s3_staging_dir = Sys.getenv("ATHENA_S3_STAGING_DIR")
  )
}

# Relying-party registry -----------------------------------------------------

# Maps each application_name to a clean service name, its operating department,
# and whether it is an internal/system app. This is the single place to track
# who runs each relying party; data/relying_parties.csv is hand-maintained.
# Searches upward so it loads from the project root or a subdirectory.
load_relying_parties <- function() {
  for (p in c("data/relying_parties.csv", "../data/relying_parties.csv")) {
    if (file.exists(p)) {
      return(utils::read.csv(p, stringsAsFactors = FALSE))
    }
  }
  stop("relying_parties.csv not found", call. = FALSE)
}

# Date helpers ---------------------------------------------------------------

# The Monday on or before a date
monday_of <- function(d) {
  d <- as.Date(d)
  d - ((as.integer(format(d, "%u")) - 1L))
}
