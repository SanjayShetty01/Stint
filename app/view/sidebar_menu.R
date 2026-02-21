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
      text = "Drivers",
      icon = shiny::icon("person"),
      bs4Dash::menuSubItem(
        text = "Rankings",
        tabName = "drivers",
        icon = shiny::icon("trophy")
      ),
      bs4Dash::menuSubItem(
        text = "Progression",
        tabName = "driver_progression",
        icon = shiny::icon("chart-line")
      )
    ),
    bs4Dash::menuItem(
      text = "Constructors",
      icon = shiny::icon("car"),
      bs4Dash::menuSubItem(
        text = "Rankings",
        tabName = "constructors",
        icon = shiny::icon("trophy")
      ),
      bs4Dash::menuSubItem(
        text = "Progression",
        tabName = "constructor_progression",
        icon = shiny::icon("chart-line")
      )
    )
  )
}