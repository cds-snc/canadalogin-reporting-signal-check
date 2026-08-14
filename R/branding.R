#' CDS/SNC logo branding for ggplot graphs.
#'
#' add_cds_logo() draws the logo with cowplot::draw_image, which preserves its
#' aspect ratio. The result is a cowplot drawing knitr renders like any other
#' figure, so the HTML ends up referencing no external image file.
#'
#' Top-right by default: ggplot titles are left-aligned, so that band is empty
#' and the logo never collides with the data or axes.
#'
#' cds_logo_path() picks the English- or French-first mark at random each call,
#' by design. Graphs may differ within a report and flip on re-render; this is
#' cosmetic and affects no data.

suppressPackageStartupMessages({
  library(cowplot)
  library(ggplot2)
  library(showtext)
})

# Random EN/FR variant each call, by design (see above). Searches upward so it
# resolves from the project root or from reports/.
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

# Overlay the logo flush in a corner. `height` is a fraction of the figure;
# width is deliberately generous so height is what constrains the logo, keeping
# it small and undistorted.
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

  # Pad the sides the logo sits on so it lands in whitespace, not the panel.
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

# Light bottom-right watermark with the report name and date. `date` takes a
# Date or a preformatted string; `edition` appends "#N" when supplied. Small and
# grey so it stays readable but unobtrusive.
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
#' theme_cds() extends theme_bw() with the brand font so graphs match the
#' document typography in reports/_brand.yml, giving titles the Semibold weight.
#' Loaded from the vendored files on first use and cached for the session; if
#' they cannot be read, graphs fall back to the default sans rather than fail.

# The brand guide calls this "Source Sans Pro"; "Source Sans 3" is the identical
# current release, and the one name _brand.yml, the report CSS and graphs share.
cds_font <- "Source Sans 3"

# Vendored font files, searched upward like cds_logo_path(). TTF, not the WOFF2
# the reports embed: sysfonts cannot read WOFF2, so fonts/ holds both formats.
cds_font_dir <- function() {
  for (dir in c("fonts", "../fonts")) {
    if (file.exists(file.path(dir, "source-sans-3-400-normal.ttf"))) return(dir)
  }
  NULL
}

# Register once per session and turn on showtext, so the font works with knitr's
# default device without per-report chunk options. Idempotent, needs no network.
# Semibold (600) maps to the "bold" face, so bold theme text is not a heavier 700.
register_cds_fonts <- function() {
  if (cds_font %in% sysfonts::font_families()) {
    showtext::showtext_auto()
    return(invisible(TRUE))
  }
  font_dir <- cds_font_dir()
  ok <- tryCatch(
    {
      if (is.null(font_dir)) stop("font files not found", call. = FALSE)
      sysfonts::font_add(
        cds_font,
        regular = file.path(font_dir, "source-sans-3-400-normal.ttf"),
        bold = file.path(font_dir, "source-sans-3-600-normal.ttf")
      )
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

# theme_bw() in the brand typeface, with Semibold titles.
theme_cds <- function(base_size = 11, base_family = cds_font) {
  if (!register_cds_fonts()) base_family <- ""
  theme_bw(base_size = base_size, base_family = base_family) +
    theme(
      plot.title = element_text(face = "bold"),
      plot.subtitle = element_text(colour = "grey30"),
      plot.caption = element_text(colour = "grey40")
    )
}
