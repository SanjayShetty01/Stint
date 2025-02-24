box::use(shinyWidgets, htmltools)

#' @export
dropdown_ui <- function(id, label, choices, selected = NULL) {
  ns <- shiny::NS(id)
  
  shinyWidgets::dropdown(
    inputId = ns("dropdown"),
    label = label,
    choices = choices,
    selected = selected,
    style = "material-flat",
    status = "danger"
  )|>
    htmltools::tagAppendAttributes(style = "width: inherit;")
}