box::use(
  shiny, bs4Dash
)

box::use(
  ./view/dash_brand,
  ./view/sidebar_menu,
  ./view/dashboard_body,
  ./view/introduction_page,
  ./view/driver_ranking,
  ./view/constructor_ranking,
  ./view/driver_progression,
  ./view/constructor_progression
)

#' @export
ui <- function(id) {
  ns <- shiny::NS(id)
  header <- bs4Dash::dashboardHeader(title = dash_brand$title)

  sidebar <- bs4Dash::dashboardSidebar(sidebar_menu$sidebar(ns),
                                       minified = F, status = "danger")

  body <- bs4Dash::dashboardBody(dashboard_body$body(ns))


  bs4Dash::dashboardPage(
    header = header,
    sidebar = sidebar,
    body = body,
    fullscreen = T,
    help = NULL
  )

}

#' @export
server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    introduction_page$introduction_server("introduction", session)
    driver_ranking$driver_ranking_server("driver_ranking")
    constructor_ranking$constructor_ranking_server("constructor_ranking")
    driver_progression$driver_progression_server("driver_progression")
    constructor_progression$constructor_progression_server("constructor_progression")
  })
}
