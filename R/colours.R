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
  )

)