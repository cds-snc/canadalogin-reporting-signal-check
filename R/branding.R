#' CDS/SNC logo branding for ggplot graphs.
#'
#' add_cds_logo() overlays the CDS/SNC logo in the top-right corner of a plot
#' using cowplot::draw_image, which preserves the logo's aspect ratio
#' automatically. The result is a cowplot drawing that knitr renders (and
#' embed-resources base64-inlines) like any other figure - no external image
#' file ends up referenced by the HTML.
#'
#' Top-right is chosen as a letterhead position: ggplot titles are left-aligned,
#' so the band above the panel on the right is empty and the logo never collides
#' with the data or the axes.
#'
#' The logo is the bilingual CDS/SNC mark; cds_logo_path() randomly returns the
#' English-first or French-first variant on each call, by design - so different
#' graphs in a report may show different languages, and a re-render may flip
#' them. This is cosmetic only and does not affect any data in the report.

suppressPackageStartupMessages({
  library(cowplot)
})

# Randomly pick the English-first or French-first logo on each call, so graphs
# within a report may differ in language by design. Searches upward so it
# resolves from the project root or the reports/ subfolder.
cds_logo_path <- function() {
  variants <- c("EN_Square+CANADA.jpg", "FR_Square+CANADA.jpg")
  for (dir in c("img", "../img")) {
    present <- file.path(dir, variants)
    present <- present[file.exists(present)]
    if (length(present) > 0) return(sample(present, 1))
  }
  stop(
    "CDS logo not found in img/ ",
    "(EN_Square+CANADA.jpg / FR_Square+CANADA.jpg)",
    call. = FALSE
  )
}

# Overlay the logo flush in a corner. `position` is "top-right" (default),
# "bottom-left", or "top-left". `height` is the logo height as a fraction of the
# figure; width is generous so the height is what constrains the (portrait) logo,
# keeping it small and undistorted.
add_cds_logo <- function(
    plot,
    position = c(
      "top-right", "bottom-left",
      "top-left", "bottom-right", "all"
    ),
    height = 0.13) {
  position <- match.arg(position)

  corners <- list(
    "top-right" = list(
      x = 0.995, y = 0.995,
      hjust = 1, vjust = 1, halign = 1, valign = 1
    ),
    "bottom-left" = list(
      x = 0.005, y = 0.005,
      hjust = 0, vjust = 0, halign = 0, valign = 0
    ),
    "top-left" = list(
      x = 0.005, y = 0.995,
      hjust = 0, vjust = 1, halign = 0, valign = 1
    ),
    "bottom-right" = list(
      x = 0.995, y = 0.005,
      hjust = 1, vjust = 0, halign = 1, valign = 0
    )
  )

  if (position == "all") {
    placements <- corners
  } else {
    placements <- corners[position]
  }

  result <- cowplot::ggdraw(plot)
  for (corner in placements) {
    result <- result +
      cowplot::draw_image(
        cds_logo_path(),
        x = corner$x, y = corner$y,
        hjust = corner$hjust, vjust = corner$vjust,
        halign = corner$halign,
        valign = corner$valign,
        width = 0.4, height = height
      )
  }
  result
}
