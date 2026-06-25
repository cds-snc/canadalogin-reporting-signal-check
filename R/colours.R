#' CDS Colo(u)r Palettes
#'
#' A list of color vectors that makes using CDS color palettes easier.
#'
#' @examples
#' \dontrun{
#'   scale_color_manual(values = cds::colors$missions$dark)
#'   scale_fill_manual(values = cds::colors$primary[c(1,2,7)])
#' }

colors <- list(
  canada = "#26374A",

  missions = list(
    light = c(
      "1 - Easy access to government services" = "#d1e5f3",
      "2 - Human centered client experiences" = "#e1ead5",
      "3 - Effective, efficient, and trustworthy services" = "#f7dfcb",
      "4 - Empowering People to deliver" = "#ebd4d4",
      "5 - Building a strong foundation" = "#efeef5"
    ),

    medium = c(
      "1 - Easy access to government services" = "#a4cce6",
      "2 - Human centered client experiences" = "#c4d4ac",
      "3 - Effective, efficient, and trustworthy services" = "#eebe97",
      "4 - Empowering People to deliver" = "#d6a9a9",
      "5 - Building a strong foundation" = "#bfbbd8"
    ),

    dark = c(
      "1 - Easy access to government services" = "#539acd",
      "2 - Human centered client experiences" = "#8aa95c",
      "3 - Effective, efficient, and trustworthy services" = "#e07f3b",
      "4 - Empowering People to deliver" = "#a02f2c",
      "5 - Building a strong foundation" = "#60559e"
    ),

    full = c(
      "1 - Easy access to government services" = "#339CD2",
      "2 - Human centered client experiences" ="#82AA51",
      "3 - Effective, efficient, and trustworthy services" = "#EF7922",
      "4 - Empowering People to deliver" = "#AE2125",
      "5 - Building a strong foundation" = "#6255A3"
    ),

    original = c(
      "1 - Easy access to government services" = "#41A4FF",
      "2 - Human centered client experiences" = "#9FCC95",
      "3 - Effective, efficient, and trustworthy services" = "#EB895F",
      "4 - Empowering People to deliver" = "#BE6A73",
      "5 - Building a strong foundation" = "#AC95DA"
    )
  ),

  primary = c(
    "#7B58A5ff","#0c497aff","#004f38ff",
    "#83ab53ff","#af2024ff","#ccd7e2ff",
    "#dcdddeff"
    ),

  greyscale = c(
    "#000000", "#666666", "#999999", "#B7B7B7", "#EFEFEF", "#FFFFFF"
  ),

  highlight = c(
    "#C61D23", "#F67121", "#F6BE00"
  ),

  # Brand palette (mirrors _brand.yml) ----------------------------------------
  # _brand.yml is the source of brand truth; these named vectors mirror it for
  # use in ggplot, which cannot read _brand.yml directly. Prefer these for new
  # graphs; the legacy palettes above remain for cases the brand palette does
  # not cover. Grouped by the CDS Brand Guide's usage categories.
  brand = c(
    white  = "#FFFFFF",
    black  = "#000000",
    blue   = "#004986",  # base (digital primary)
    forest = "#115740",  # base (deep green)
    green  = "#89A84F",  # base
    red    = "#AB2328",  # base
    orange = "#E87722",  # action
    yellow = "#F6BE00",  # action
    sky    = "#CCDAE6",  # grounding (pale blue)
    grey   = "#D8D8D8"   # grounding (light grey)
  ),

  # Subsets of `brand` by usage category, handy for scale_*_manual().
  brand_base = c(
    blue = "#004986", forest = "#115740", green = "#89A84F", red = "#AB2328"
  ),

  brand_action = c(
    orange = "#E87722", yellow = "#F6BE00"
  ),

  brand_grounding = c(
    sky = "#CCDAE6", grey = "#D8D8D8"
  )

)