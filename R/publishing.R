# Published URLs ---------------------------------------------------------------
#
# Every page in the publishing repo sits under an unlisted token
# (r/<token>/<file>.html). This repo is public, so the token is looked up from
# the sibling publishing repo at render time and never written into source.

publishing_base_url <- "https://cds-snc.github.io/canadalogin-signal-check-publishing"

# The publishing repo sits beside this one; renders run from the root or reports/.
publishing_repo_root <- function() {
  for (p in c("../canadalogin-signal-check-publishing",
              "../../canadalogin-signal-check-publishing")) {
    if (dir.exists(file.path(p, "r"))) return(p)
  }
  stop("canadalogin-signal-check-publishing not found beside this repo")
}

# URL of a published file by name, e.g. published_url("support.html").
# Pass utm_source = NULL for a bare URL. Stops if the file is not published
# exactly once.
published_url <- function(file, utm_source = "report_link") {
  hits <- Sys.glob(file.path(publishing_repo_root(), "r", "*", file))
  if (length(hits) != 1L) {
    stop(file, " is published ", length(hits), " times, expected once")
  }
  url <- paste(publishing_base_url, "r", basename(dirname(hits)), file, sep = "/")
  if (is.null(utm_source)) url else paste0(url, "?utm_source=", utm_source)
}
