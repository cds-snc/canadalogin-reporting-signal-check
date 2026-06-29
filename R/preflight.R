#' Preflight data-source validation for the CanadaLogin Signal Check.
#'
#' Defines run_preflight_safety_check(): a once-per-cycle gate meant to run near
#' the top of explore.qmd, before authoring a report. It confirms the data
#' sources are ready for the current cycle, prints a numbered checklist of every
#' assumption (passed or failed), and stops (halting the workbook) naming the
#' checks that did not hold.
#'
#' Source R/connection.R first: this relies on monday_of() and launch_date, and
#' reuses an already-open Athena connection passed in as `con` (it does not open
#' its own). Keyed to `today`, so it is for the live workbook, never a frozen
#' report render. Expects the tidyverse data verbs (dplyr/dbplyr/tidyr) and glue
#' to be attached by the caller, as explore.qmd does.
#'
#' Checks:
#'   1. Registry complete - every relying party in the data lake is in
#'      relying_parties.csv with all fields filled. New parties are auto-appended
#'      (launch_date inferred from first appearance, the rest left blank); the
#'      run then fails until someone fills in the blanks.
#'   2. Reporting period complete - IBM Verify data runs through the most recent
#'      complete Sunday, with no missing days in the two-week period.
#'   3. Call centre current - allowing the feed's full-week lag, the Sun-Sat week
#'      before the most recent complete one is loaded in weekly_activity_report,
#'      with at least one (sparse) weekly_topic_dump entry inside that week.

run_preflight_safety_check <- function(con,
                                       csv_path = "data/relying_parties.csv",
                                       today = Sys.Date()) {

  # Helpers --------------------------------------------------------------------

  # A registry field counts as unfilled if it is NA or whitespace-only.
  is_blank <- function(x) is.na(x) | trimws(as.character(x)) == ""

  # Render a date as "Sun Jun 28" (abbreviated weekday, short month). Robust to
  # the non-finite max() an empty table yields, which reads as "no data".
  format_date <- function(d) {
    labels <- rep("no data", length(d))
    finite <- is.finite(as.numeric(d))
    labels[finite] <- format(as.Date(d[finite], origin = "1970-01-01"),
                             "%a %b %d")
    labels
  }

  # Accumulate check results so we can print one numbered checklist and name the
  # failing checks at the end, rather than stopping at the first problem. The
  # check number is passed in explicitly (not derived from position) so it is
  # easy to grep and stays stable if checks are reordered.
  checks <- list()
  record_check <- function(number, title, passed, details = character()) {
    checks[[length(checks) + 1L]] <<- list(
      number = number, title = as.character(title), passed = passed,
      details = as.character(details)
    )
  }

  # Date anchors ---------------------------------------------------------------

  # Reporting period: the two Mon-Sun weeks ending on the most recent Sunday.
  most_recent_sunday <- monday_of(today) - 1L

  # Call-centre weeks run Sun-Sat. Find the most recent complete Saturday (step
  # back a week if today is itself a Saturday), then allow the feed's full-week
  # lag: this week's data lands mid-next-week, so we only expect the feed loaded
  # through the Saturday a week earlier.
  days_since_saturday <- (as.integer(format(today, "%u")) - 6L) %% 7L
  if (days_since_saturday == 0L) days_since_saturday <- 7L
  most_recent_saturday <- today - days_since_saturday
  expected_call_week_end <- most_recent_saturday - 7L

  # Check 1 - relying-party registry is complete -------------------------------

  relying_parties_registry <- readr::read_csv(
    csv_path,
    col_types = readr::cols(
      .default = readr::col_character(),
      is_internal = readr::col_logical()
    )
  )

  # The data lake's relying parties are the application_name values in
  # app_login_counts, first appearance taken as an inferred launch date.
  data_lake_parties <- tbl(con, in_schema("ibm_verify", "app_login_counts")) |>
    group_by(application_name) |>
    summarise(first_seen = min(from_date, na.rm = TRUE), .groups = "drop") |>
    collect() |>
    mutate(first_seen = as.Date(first_seen))

  new_parties <- data_lake_parties |>
    anti_join(relying_parties_registry, by = "application_name")

  # Auto-append each newcomer as a blank registry row (launch_date inferred);
  # the completeness check below then fails until a human fills the rest.
  if (nrow(new_parties) > 0) {
    new_registry_rows <- data.frame(
      application_name = new_parties$application_name,
      service_name = NA_character_,
      operator = NA_character_,
      is_internal = NA,
      launch_date = format(new_parties$first_seen),
      stringsAsFactors = FALSE
    )
    relying_parties_registry <- bind_rows(relying_parties_registry,
                                          new_registry_rows)
    readr::write_csv(relying_parties_registry, csv_path, na = "")
  }

  # One problem line per registry row that still has a blank required field.
  required_fields <- c("service_name", "operator", "is_internal", "launch_date")
  registry_problems <- relying_parties_registry |>
    mutate(across(everything(), as.character)) |>
    pivot_longer(all_of(required_fields), names_to = "field",
                 values_to = "value") |>
    filter(is_blank(value)) |>
    group_by(application_name) |>
    summarise(blank_fields = glue_collapse(field, sep = ", "),
              .groups = "drop") |>
    mutate(
      newly_added = application_name %in% new_parties$application_name,
      problem = glue(
        "fill in [{blank_fields}] for '{application_name}'",
        "{if_else(newly_added, ' (newly added; launch_date inferred)', '')}"
      )
    ) |>
    pull(problem)

  record_check(
    1,
    "Registry complete - every relying party is registered and filled in",
    passed = length(registry_problems) == 0,
    details = if (length(registry_problems) == 0) {
      glue("{nrow(relying_parties_registry)} relying parties, all fields present")
    } else {
      registry_problems
    }
  )

  # Check 2 - the reporting period is complete ---------------------------------

  reporting_period_end <- most_recent_sunday
  reporting_period_start <- reporting_period_end - 13L

  days_with_data <- tbl(con, in_schema("ibm_verify", "auth_total_logins")) |>
    filter(from_date >= as.Date(reporting_period_start),
           from_date <= as.Date(reporting_period_end)) |>
    transmute(day = as.Date(from_date)) |>
    distinct() |>
    collect() |>
    pull(day)

  # Apr 20-21 are legitimately pre-launch empties; only expect days from launch.
  expected_days <- seq(reporting_period_start, reporting_period_end, by = "day")
  expected_days <- expected_days[expected_days >= launch_date]
  missing_days <- expected_days[!expected_days %in% days_with_data]
  latest_day_with_data <- if (length(days_with_data) > 0) {
    max(days_with_data)
  } else {
    NA
  }

  record_check(
    2,
    glue("Reporting period complete ",
         "({format_date(reporting_period_start)} to ",
         "{format_date(reporting_period_end)})"),
    passed = length(missing_days) == 0,
    details = if (length(missing_days) == 0) {
      glue("IBM Verify data runs through {format_date(reporting_period_end)}")
    } else {
      c(
        glue("Expected IBM Verify data through ",
             "{format_date(reporting_period_end)}, ",
             "found through {format_date(latest_day_with_data)}"),
        glue("missing day(s): ",
             "{glue_collapse(format_date(missing_days), sep = ', ')}")
      )
    }
  )

  # Check 3 - the call centre feed is current (allowing its 1-week lag) ---------

  # weekly_activity_report stores its dates as strings; tiny table, so collect
  # and parse in R (per the data catalog).
  call_centre_weeks <- tbl(
    con, in_schema("call_centre", "weekly_activity_report")
  ) |>
    collect() |>
    mutate(across(c(date_range_start, date_range_end), as.Date))
  latest_loaded_week_end <- suppressWarnings(
    max(call_centre_weeks$date_range_end, na.rm = TRUE)
  )

  call_centre_problems <- character()
  topic_dump_detail <- NULL

  if (!is.finite(latest_loaded_week_end) ||
        latest_loaded_week_end < expected_call_week_end) {
    call_centre_problems <- glue(
      "weekly_activity_report: expected data through ",
      "{format_date(expected_call_week_end)}, ",
      "found {format_date(latest_loaded_week_end)}"
    )
  } else {
    # weekly_topic_dump is sparse (rows only on days with calls), so don't
    # require it to reach a given date: just confirm at least one entry falls
    # inside the most recent week present in weekly_activity_report.
    latest_loaded_week <- call_centre_weeks |>
      slice_max(date_range_end, n = 1, with_ties = FALSE)
    week_start <- latest_loaded_week$date_range_start
    week_end <- latest_loaded_week$date_range_end

    topic_entry_count <- tbl(
      con, in_schema("call_centre", "weekly_topic_dump")
    ) |>
      filter(call_date >= as.Date(week_start),
             call_date <= as.Date(week_end)) |>
      summarise(n = n()) |>
      pull(n) |>
      as.integer()

    if (topic_entry_count < 1L) {
      call_centre_problems <- glue(
        "weekly_topic_dump: no entries within the latest loaded week ",
        "({format_date(week_start)} to {format_date(week_end)})"
      )
    } else {
      topic_dump_detail <- glue(
        "{topic_entry_count} topic-dump ",
        "{if (topic_entry_count == 1L) 'entry' else 'entries'} ",
        "in the latest week ",
        "({format_date(week_start)} to {format_date(week_end)})"
      )
    }
  }

  record_check(
    3,
    glue("Call centre current, allowing its 1-week lag ",
         "(through {format_date(expected_call_week_end)})"),
    passed = length(call_centre_problems) == 0,
    details = if (length(call_centre_problems) == 0) {
      c(glue("activity report through {format_date(latest_loaded_week_end)}"),
        topic_dump_detail)
    } else {
      call_centre_problems
    }
  )

  # Print the numbered checklist and decide the verdict ------------------------

  for (check in checks) {
    mark <- if (check$passed) "✅" else "❌"
    message(glue("{mark} Check {check$number}: {check$title}"))
    for (detail in check$details) message(glue("     {detail}"))
  }

  failed_checks <- purrr::keep(checks, \(check) !check$passed)
  if (length(failed_checks) > 0) {
    failed_numbers <- purrr::map_int(failed_checks, "number")
    stop(
      glue("Preflight safety check failed: check ",
           "{glue_collapse(failed_numbers, sep = ', ', last = ' and ')} ",
           "did not hold (see the checklist above)."),
      call. = FALSE
    )
  }

  invisible(TRUE)
}
