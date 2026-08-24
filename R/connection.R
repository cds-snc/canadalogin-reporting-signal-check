#' Athena connection and shared setup for the CanadaLogin Signal Check.
#'
#' This file holds ONLY non-analytical setup: the connection factory, a package
#' check, pure date helpers, and constants for explore.qmd. The data queries
#' themselves are deliberately NOT here - they are written inline in explore.qmd
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
  "ggplot2", "scales", "cowplot", "magick", "dotenv", "ggbrick",
  "glue", "readr", "purrr"
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

# Relying-party registry -----------------------------------------------------

# The relying-party registry: rp.service (one row per service) joined to
# rp.alias (one row per name a source system uses for it). Returns one row per
# alias, keyed on application_name so it joins onto the IBM Verify tables.
# Several aliases map to one service, so aggregate after joining, never before.
# Google Analytics aliases are included; they never match IBM Verify data.
load_relying_parties <- function(con) {
  aliases <- dplyr::tbl(con, dbplyr::in_schema("rp", "alias")) |>
    dplyr::select("alias", "rp_id", "source") |>
    dplyr::collect()

  services <- dplyr::tbl(con, dbplyr::in_schema("rp", "service")) |>
    dplyr::select("rp_id", "service_name_en", "service_name_fr", "operator",
                  "gc_orgid", "is_internal", "launch_date") |>
    dplyr::collect()

  registry <- merge(aliases, services, by = "rp_id", all.x = TRUE)
  out <- data.frame(
    application_name = registry$alias,
    service_name     = registry$service_name_en,
    service_name_fr  = registry$service_name_fr,
    operator         = registry$operator,
    gc_orgid         = as.integer(registry$gc_orgid),
    is_internal      = as.logical(registry$is_internal),
    launch_date      = as.Date(registry$launch_date),
    rp_id            = as.integer(registry$rp_id),
    alias_source     = registry$source,
    stringsAsFactors = FALSE
  )
  out <- out[order(out$launch_date, out$service_name, out$application_name), ]
  rownames(out) <- NULL
  out
}

# Constants ------------------------------------------------------------------

launch_date <- as.Date("2026-04-22")
launch_week_start <- as.Date("2026-04-20")  # Monday of the launch week

# Configuration --------------------------------------------------------------

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
  RAthena::RAthena_options(verbose = FALSE)
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
