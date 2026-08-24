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
#' report render. It attaches the packages it needs, so sourcing this file
#' alone is enough to run the gate.
#'
#' Checks:
#'   1. Registry complete - every application_name in the data lake resolves
#'      through rp.alias, and the service it resolves to has all fields filled.
#'      Read-only: the registry comes from a hand-maintained sheet, so the run
#'      fails with instructions to add the name there.
#'   2. Reporting period complete - IBM Verify data runs through the most recent
#'      complete Sunday, with no missing days in the two-week period.
#'   3. Call centre current - allowing the feed's full-week lag, the Sun-Sat week
#'      before the most recent complete one is loaded in weekly_activity_report,
#'      with at least one (sparse) weekly_topic_dump entry inside that week.
#'   4. Google Analytics current - allowing the export's deliberate two-day lag
#'      (`ga_export_lag_days`), property_traffic runs through today minus that
#'      lag with no gaps. This checks the export is current for its own lag, not
#'      that it covers the reporting period; it never does by the time a report
#'      is written, which is a caveat for the prose rather than a gate.

# Packages -------------------------------------------------------------------

# The gate is often sourced and run on its own, so it attaches what it needs.
suppressPackageStartupMessages({
  library(dplyr)
  library(dbplyr)
  library(tidyr)
  library(glue)
  library(purrr)
  library(readr)
})

run_preflight_safety_check <- function(con,
                                       today = Sys.Date(),
                                       ga_export_lag_days = 2L) {

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

  # The registry comes from a hand-maintained sheet, so this check is
  # read-only: it reports what is missing rather than filling it in.
  registry <- load_relying_parties(con)

  # An application_name that does not resolve through rp.alias would be
  # dropped silently by an inner join, so surface it here.
  data_lake_parties <- tbl(con, in_schema("ibm_verify", "app_login_counts")) |>
    group_by(application_name) |>
    summarise(first_seen = min(from_date, na.rm = TRUE), .groups = "drop") |>
    collect() |>
    mutate(first_seen = as.Date(first_seen))

  unresolved <- data_lake_parties |>
    anti_join(registry, by = "application_name") |>
    mutate(problem = glue(
      "'{application_name}' is in app_login_counts (first seen ",
      "{format_date(first_seen)}) but has no row in rp.alias - add it to the ",
      "relying-parties sheet"
    )) |>
    pull(problem)

  # A service that an alias resolves to, but whose own fields are unfilled.
  required_fields <- c("service_name", "operator", "is_internal", "launch_date")
  incomplete <- registry |>
    filter(application_name %in% data_lake_parties$application_name) |>
    mutate(across(everything(), as.character)) |>
    pivot_longer(all_of(required_fields), names_to = "field",
                 values_to = "value") |>
    filter(is_blank(value)) |>
    group_by(application_name) |>
    summarise(blank_fields = glue_collapse(field, sep = ", "),
              .groups = "drop") |>
    mutate(problem = glue(
      "fill in [{blank_fields}] for '{application_name}' in the ",
      "relying-parties sheet"
    )) |>
    pull(problem)

  registry_problems <- c(unresolved, incomplete)

  in_use <- registry |>
    filter(application_name %in% data_lake_parties$application_name)

  record_check(
    1,
    "Registry complete - every relying party resolves through rp.alias",
    passed = length(registry_problems) == 0,
    details = if (length(registry_problems) == 0) {
      glue("{nrow(in_use)} application names resolving to ",
           "{dplyr::n_distinct(in_use$service_name)} services, all fields present")
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

  # Check 4 - the Google Analytics export is current (allowing its 2-day lag) --

  # What this check does and does not assert. It asserts that the GA export is
  # current *for its own lag*: the pipeline pulls each day two days late on
  # purpose, because GA4 takes 24-48 hours to finish processing a day's events
  # and each day is written once and never re-pulled, so a window read early
  # would stay artificially low forever.
  #
  # It deliberately does NOT require GA to cover the reporting period. It cannot:
  # the period ends on a Sunday and the report is written the next morning, when
  # the export has only reached Saturday, so a coverage requirement would fail
  # every single cycle and train people to wave the gate through. How far GA
  # falls short of the period is a real thing to know, but it is a fact to carry
  # into the writing, not a reason to halt - explore.qmd surfaces it as
  # `ga_short_days` beside the other data-health cards.
  expected_ga_end <- today - ga_export_lag_days

  ga_days_with_data <- tbl(
    con, in_schema("google_analytics", "property_traffic")
  ) |>
    filter(as.Date(date) >= as.Date(reporting_period_start),
           as.Date(date) <= as.Date(expected_ga_end)) |>
    transmute(day = as.Date(date)) |>
    distinct() |>
    collect() |>
    pull(day)

  expected_ga_days <- seq(reporting_period_start, expected_ga_end, by = "day")
  missing_ga_days <- expected_ga_days[!expected_ga_days %in% ga_days_with_data]
  latest_ga_day <- if (length(ga_days_with_data) > 0) {
    max(ga_days_with_data)
  } else {
    NA
  }

  record_check(
    4,
    glue("Google Analytics current, allowing its ",
         "{ga_export_lag_days}-day export lag ",
         "(through {format_date(expected_ga_end)})"),
    passed = length(missing_ga_days) == 0,
    details = if (length(missing_ga_days) == 0) {
      glue("property_traffic runs through {format_date(latest_ga_day)}")
    } else {
      c(
        glue("Expected property_traffic through ",
             "{format_date(expected_ga_end)}, ",
             "found through {format_date(latest_ga_day)}"),
        glue("missing day(s): ",
             "{glue_collapse(format_date(missing_ga_days), sep = ', ')}"),
        # The nightly export lands at 07:00 ET. Run the workbook before that and
        # the newest expected day genuinely is not there yet, which looks
        # identical to a broken pipeline from here.
        "if run before 07:00 ET, the newest day may not have landed yet; re-run"
      )
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
