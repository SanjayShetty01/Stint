#' @export
sidebar <- function(ns) {
  bs4Dash::sidebarMenu(
    id = ns("sidebar"),
    bs4Dash::menuItem(
      text = "Home",
      tabName = "home",
      icon = shiny::icon("house", lib = "font-awesome")
    ),
    bs4Dash::menuItem(
      text = "Drivers Rankings",
      tabName = "drivers",
      icon = shiny::icon("eye")
    ),
    bs4Dash::menuItem(
      text = "Constructors Rankings",
      tabName = "constructors",
      icon = shiny::icon("eye")
    ),
    bs4Dash::menuItem(
      text = "Driver Ranking Progression",
      tabName = "driver_progression",
      icon = shiny::icon("eye")
    ),
    bs4Dash::menuItem(
      text = "constriuctor Ranking Progression",
      tabName = "constructor_progression",
      icon = shiny::icon("eye")
    )  
    )
}