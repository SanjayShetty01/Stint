box::use(shinyWidgets, htmltools)

#' @export
button_ui <- function(id, text) {
  shinyWidgets::actionBttn(
    inputId = id,
    label = text,
    style = "material-flat",
    color = "danger"
  ) |>
    htmltools::tagAppendAttributes(style = "width: inherit;")
}