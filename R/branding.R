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
#'
#' By default the plain CDS/SNC square is used; set canada_wordmark = TRUE for the
#' square + Canada wordmark lockup.

suppressPackageStartupMessages({
  library(cowplot)
  library(ggplot2)
  library(showtext)
})

# Randomly pick the English-first or French-first logo on each call, so graphs
# within a report may differ in language by design. Searches upward so it
# resolves from the project root or the reports/ subfolder. canada_wordmark picks
# the square + Canada wordmark lockup; otherwise the plain CDS/SNC square.
cds_logo_path <- function(canada_wordmark = FALSE) {
  variants <- if (canada_wordmark) {
    c("EN_Square+CANADA.jpg", "FR_Square+CANADA.jpg")
  } else {
    c("cds-snc.png", "snc-cds.png")
  }
  for (dir in c("img", "../img")) {
    present <- file.path(dir, variants)
    present <- present[file.exists(present)]
    if (length(present) > 0) return(sample(present, 1))
  }
  stop(
    "CDS logo not found in img/ (", paste(variants, collapse = " / "), ")",
    call. = FALSE
  )
}

# Overlay the logo flush in a corner. `position` is "top-right" (default),
# "bottom-left", or "top-left". `height` is the logo height as a fraction of the
# figure; width is generous so the height is what constrains the logo, keeping it
# small and undistorted. `canada_wordmark` swaps the plain CDS/SNC square for the
# square + Canada wordmark lockup.
add_cds_logo <- function(
    plot,
    position = c(
      "top-right", "bottom-left",
      "top-left", "bottom-right",
      "all"
    ),
    height = 0.13,
    canada_wordmark = FALSE) {
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

  # Add margin on the sides where the logo will sit so it lands in whitespace
  # rather than overlapping the panel. The margin matches the logo height.
  margin_pt <- grid::unit(height * 55, "pt")
  sides <- unique(sub("-.*", "", names(placements)))
  current_margin <- ggplot2::calc_element("plot.margin", plot$theme)
  if (is.null(current_margin)) current_margin <- ggplot2::margin(5.5, 5.5, 5.5, 5.5)
  if ("top" %in% sides) current_margin[1] <- current_margin[1] + margin_pt
  if ("bottom" %in% sides) current_margin[3] <- current_margin[3] + margin_pt
  plot <- plot + ggplot2::theme(plot.margin = current_margin)

  result <- cowplot::ggdraw(plot)
  for (corner in placements) {
    result <- result +
      cowplot::draw_image(
        cds_logo_path(canada_wordmark),
        x = corner$x, y = corner$y,
        hjust = corner$hjust, vjust = corner$vjust,
        halign = corner$halign,
        valign = corner$valign,
        width = 0.4, height = height
      )
  }
  result
}


# Watermark -------------------------------------------------------------------

# Light watermark in the bottom-right corner with the report name and date.
# `date` should be a string like "June 25, 2026" or a Date object (formatted
# automatically). `edition` is the report's serial number; when supplied it is
# appended to the report name (e.g. "CanadaLogin Signal Check #1 // ..."), and
# omitted when NULL. Uses the brand font when available, grey40 at a small size
# so it stays readable but unobtrusive.
add_watermark <- function(plot, date = Sys.Date(), edition = NULL) {
  if (inherits(date, "Date")) date <- format(date, "%B %e, %Y")
  edition_tag <- if (!is.null(edition)) paste0(" #", edition) else ""
  label <- paste0("CanadaLogin Signal Check", edition_tag, " // ", trimws(date))
  font_family <- if (register_cds_fonts()) cds_font else ""
  current_margin <- ggplot2::calc_element("plot.margin", plot$theme)
  if (is.null(current_margin)) current_margin <- ggplot2::margin(5.5, 5.5, 5.5, 5.5)
  current_margin[3] <- current_margin[3] + grid::unit(5, "pt")
  plot <- plot + ggplot2::theme(plot.margin = current_margin)
  cowplot::ggdraw(plot) +
    cowplot::draw_text(
      label,
      x = 0.99, y = 0.01,
      hjust = 1, vjust = 0,
      size = 7,
      colour = "grey65",
      family = font_family
    )
}

# Brand typography ------------------------------------------------------------

#' Brand typeface for ggplot graphs.
#'
#' theme_cds() applies the CDS/CanadaLogin brand font to a ggplot so graphs match
#' the document typography set in reports/_brand.yml. It extends theme_bw() (the
#' house graph style) and changes only the typeface, giving titles the brand's
#' Semibold weight. The font is loaded from Google Fonts on first use via showtext
#' and cached for the session; if it cannot be fetched (e.g. offline) graphs fall
#' back to the default sans font rather than failing the render.

# _brand.yml names the typeface "Source Sans Pro"; Google Fonts now serves the
# identical v3 under "Source Sans 3", which is the name the Google Fonts API (and
# therefore sysfonts) recognises. Same typeface, current name.
cds_font <- "Source Sans 3"

# Load the brand font from Google once per session and enable showtext glyph
# rendering, so the font works with knitr's default graphics device without any
# per-report chunk options. Idempotent; safe offline (warns, returns FALSE). The
# brand's Semibold (600) is mapped to the "bold" face, so the bold elements that
# theme titles use render as Semibold rather than a heavier 700.
register_cds_fonts <- function() {
  if (cds_font %in% sysfonts::font_families()) {
    showtext::showtext_auto()
    return(invisible(TRUE))
  }
  ok <- tryCatch(
    {
      sysfonts::font_add_google(cds_font, cds_font, regular.wt = 400, bold.wt = 600)
      TRUE
    },
    error = function(e) {
      warning(
        "Could not load brand font '", cds_font, "' (", conditionMessage(e),
        "); graphs will use the default sans font.",
        call. = FALSE
      )
      FALSE
    }
  )
  if (ok) {
    showtext::showtext_auto()
    # Match showtext's text sizing to the resolution knitr renders figures at.
    dpi <- knitr::opts_chunk$get("dpi")
    showtext::showtext_opts(dpi = if (is.null(dpi)) 96 else dpi)
  }
  invisible(ok)
}

# theme_bw() in the brand typeface, with Semibold titles. Falls back to the
# default sans font if the brand font could not be loaded.
theme_cds <- function(base_size = 11, base_family = cds_font) {
  if (!register_cds_fonts()) base_family <- ""
  theme_bw(base_size = base_size, base_family = base_family) +
    theme(
      plot.title = element_text(face = "bold"),
      plot.subtitle = element_text(colour = "grey30"),
      plot.caption = element_text(colour = "grey40")
    )
}
