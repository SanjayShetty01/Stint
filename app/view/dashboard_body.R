box::use(shiny)
box::use(
  ./introduction_page
)

body  <- function(ns) {
  bs4Dash::tabItems(
    bs4Dash::tabItem(
      tabName = "home",
      introduction_page$introduction_ui(ns("introduction"))
    ),
    bs4Dash::tabItem(
      tabName = "drivers",
      shiny::h1("Drivers Rankings")
    ),
    bs4Dash::tabItem(
      tabName = "constructors",
      shiny::h1("Constructors Rankings")
    ),
    bs4Dash::tabItem(
      tabName = "driver_progression",
      shiny::h1("Driver Ranking Progression")
    ),
    bs4Dash::tabItem(
      tabName = "constructor_progression",
      shiny::h1("Constructor Ranking Progression")
    )
  )
}