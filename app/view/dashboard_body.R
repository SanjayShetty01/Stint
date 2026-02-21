box::use(shiny)
box::use(
  ./introduction_page,
  ./driver_ranking,
  ./constructor_ranking,
  ./driver_progression,
  ./constructor_progression
)

#' @export
body <- function(ns) {
  bs4Dash::tabItems(
    bs4Dash::tabItem(
      tabName = "home",
      introduction_page$introduction_ui(ns("introduction"))
    ),
    bs4Dash::tabItem(
      tabName = "drivers",
      driver_ranking$driver_ranking_ui(ns("driver_ranking"))
    ),
    bs4Dash::tabItem(
      tabName = "constructors",
      constructor_ranking$constructor_ranking_ui(ns("constructor_ranking"))
    ),
    bs4Dash::tabItem(
      tabName = "driver_progression",
      driver_progression$driver_progression_ui(ns("driver_progression"))
    ),
    bs4Dash::tabItem(
      tabName = "constructor_progression",
      constructor_progression$constructor_progression_ui(ns("constructor_progression"))
    )
  )
}