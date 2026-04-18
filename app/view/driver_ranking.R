box::use(shiny, reactable, shinycssloaders)
box::use(
  app/logic/db_utils
)

#' @export
driver_ranking_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::fluidPage(
    shiny::br(),
    shiny::fluidRow(
      shiny::column(
        width = 4,
        offset = 4,
        shiny::selectizeInput(
          inputId = ns("year_select"),
          label = "Select Season",
          choices = NULL,
          options = list(placeholder = "Loading years...")
        )
      )
    ),
    shiny::br(),
    shiny::fluidRow(
      shiny::column(
        width = 12,
        shinycssloaders::withSpinner(
          shiny::tagList(
            shiny::h2(shiny::textOutput(ns("table_title"))),
            shiny::br(),
            reactable::reactableOutput(ns("ranking_table"))
          ),
          type = 7,
          color = "#ff851b"
        )
      )
    )
  )
}

#' @export
driver_ranking_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    conn <- db_utils$db_connect()

    shiny::onStop(function() {
      DBI::dbDisconnect(conn)
    })

    # Populate Year Dropdown
    shiny::observe({
      years <- db_utils$get_available_years(conn)
      shiny::updateSelectizeInput(session, "year_select",
                                   choices = years,
                                   selected = years[1],
                                   server = TRUE)
    })

    ranking_data <- shiny::reactive({
      shiny::req(input$year_select)
      data <- db_utils$get_ranking_view("driver_summary_view",
                                         input$year_select, conn)
      if (nrow(data) > 0) {
        data$rank <- seq_len(nrow(data))
        data <- data[, c("rank", "driver_name", "nationality", "total_races",
                         "total_wins", "dnf", "top_10_finishes", "total_points")]
        names(data) <- c("Rank", "Driver", "Nationality", "Races",
                         "Wins", "DNF", "Top 10", "Points")
      }
      data
    })

    output$table_title <- shiny::renderText({
      paste("Driver Standings -", input$year_select, "Season")
    })

    output$ranking_table <- reactable::renderReactable({
      data <- ranking_data()
      shiny::req(nrow(data) > 0)

      reactable::reactable(
        data,
        highlight = TRUE,
        bordered = TRUE,
        striped = TRUE,
        compact = TRUE,
        defaultPageSize = 25,
        theme = reactable::reactableTheme(
          borderColor = "#e0e0e0",
          stripedColor = "#fef5ed",
          highlightColor = "#fff3e6",
          headerStyle = list(
            backgroundColor = "#ff851b",
            color = "#fff",
            fontWeight = "bold",
            fontSize = "13px",
            borderColor = "#e67514"
          ),
          cellStyle = list(
            fontSize = "13px"
          )
        ),
        columns = list(
          Rank = reactable::colDef(width = 60, align = "center"),
          Driver = reactable::colDef(minWidth = 160),
          Nationality = reactable::colDef(minWidth = 120),
          Races = reactable::colDef(width = 70, align = "center"),
          Wins = reactable::colDef(width = 70, align = "center"),
          DNF = reactable::colDef(width = 60, align = "center"),
          `Top 10` = reactable::colDef(width = 70, align = "center"),
          Points = reactable::colDef(
            width = 80,
            align = "center",
            style = list(fontWeight = "bold")
          )
        )
      )
    })
  })
}
