box::use(shiny, highcharter, shinyalert, shinycssloaders)
box::use(
  app/logic/db_utils
)

# Color palette for comparison
COLORS <- list(
  primary = "#ff851b",
  compare = "#39CCCC"
)

#' @export
driver_progression_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::fluidPage(
    shinyalert::useShinyalert(),
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
        width = 4,
        offset = 2,
        shiny::selectizeInput(
          inputId = ns("driver_select"),
          label = shiny::HTML("<span style='color:#ff851b; font-size:16px;'>&#9679;</span> Select Driver"),
          choices = NULL,
          options = list(placeholder = "Select Driver...")
        )
      ),
      shiny::column(
        width = 4,
        shiny::div(class = "compare-dropdown",
          shiny::selectizeInput(
            inputId = ns("compare_driver_select"),
            label = shiny::HTML("<span style='color:#39CCCC; font-size:16px;'>&#9679;</span> Compare With (optional)"),
            choices = NULL,
            options = list(placeholder = "Select to compare...",
                           dropdownParent = "body")
          )
        )
      )
    ),
    shiny::br(),
    shiny::fluidRow(
      shiny::column(
        width = 12,
        align = "center",
        shiny::actionButton(
          inputId = ns("visualize_btn"),
          label = "Visualize \u26A1",
          class = "btn-warning btn-lg",
          width = "200px"
        )
      )
    ),
    shiny::br(),
    shiny::fluidRow(
      shiny::column(
        width = 12,
        shinycssloaders::withSpinner(
          shiny::uiOutput(ns("chart_ui")),
          type = 7,
          color = "#ff851b"
        )
      )
    )
  )
}

#' @export
driver_progression_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    conn <- db_utils$db_connect()

    shiny::onStop(function() {
      DBI::dbDisconnect(conn)
    })

    # Populate Year Dropdown
    shiny::observe({
      years <- db_utils$get_available_years(conn)
      shiny::updateSelectizeInput(session, "year_select",
                                   choices = years,
                                   selected = years[1], # Default to latest (first because DESC)
                                   server = TRUE)
    })

    # Update driver dropdowns when year changes
    shiny::observeEvent(input$year_select, {
      shiny::req(input$year_select)
      drivers <- db_utils$get_drivers_by_year(input$year_select, conn)
      
      # Reset selections to empty
      shiny::updateSelectizeInput(session, "driver_select",
                                   choices = drivers,
                                   selected = "",
                                   server = TRUE)
      shiny::updateSelectizeInput(session, "compare_driver_select",
                                   choices = drivers,
                                   selected = "",
                                   server = TRUE)
      # Reset visualization state
      has_visualized(FALSE)
      progression_data(NULL)
      compare_data(NULL)
    })

    # Reactive values
    progression_data <- shiny::reactiveVal(NULL)
    compare_data <- shiny::reactiveVal(NULL)
    has_visualized <- shiny::reactiveVal(FALSE)

    # Helper: fetch and store data for current inputs
    fetch_data <- function() {
      d1 <- input$driver_select
      year <- input$year_select
      if (is.null(d1) || d1 == "" || is.null(year) || year == "") return()

      data <- db_utils$get_driver_season_progression(d1, year, conn)
      if (is.null(data) || nrow(data) == 0) {
        progression_data(NULL)
        compare_data(NULL)
        return()
      }
      progression_data(data)

      d2 <- input$compare_driver_select
      if (!is.null(d2) && d2 != "") {
        c_data <- db_utils$get_driver_season_progression(d2, year, conn)
        compare_data(c_data)
      } else {
        compare_data(NULL)
      }
    }

    # First click: validate then fetch
    shiny::observeEvent(input$visualize_btn, {
      if (is.null(input$driver_select) || input$driver_select == "") {
        shinyalert::shinyalert("Missing Selection", "Please select a driver to visualize.", type = "error")
        progression_data(NULL)
        compare_data(NULL)
        return()
      }
      has_visualized(TRUE)
      fetch_data()
    })

    # Auto-update on dropdown change (after first Visualize)
    shiny::observeEvent(list(input$driver_select, input$compare_driver_select), {
      if (!has_visualized()) return()
      fetch_data()
    })

    # Render UI for chart only if data exists
    output$chart_ui <- shiny::renderUI({
      data <- progression_data()
      if (is.null(data) || nrow(data) == 0) return(NULL)

      d1 <- input$driver_select
      d2 <- input$compare_driver_select
      year <- input$year_select

      title <- paste(d1, "-", year, "Season")
      if (!is.null(d2) && d2 != "") {
        title <- paste(d1, "vs", d2, "-", year, "Season")
      }

      shiny::tagList(
        shiny::h2(title),
        shiny::br(),
        highcharter::highchartOutput(ns("progression_chart"), height = "500px")
      )
    })

    output$progression_chart <- highcharter::renderHighchart({
      data <- progression_data()
      shiny::req(nrow(data) > 0)

      hc <- highcharter::highchart() |>
        highcharter::hc_chart(
          type = "areaspline",
          animation = list(duration = 2000, easing = "easeOutQuart"),
          style = list(fontFamily = "Inter, sans-serif")
        ) |>
        highcharter::hc_title(text = NULL) |>
        highcharter::hc_xAxis(
          categories = data$race_name,
          title = list(text = "Race", style = list(fontWeight = "bold")),
          labels = list(
            rotation = -45,
            style = list(fontSize = "11px")
          ),
          crosshair = TRUE
        ) |>
        highcharter::hc_yAxis(
          title = list(text = "Cumulative Points", style = list(fontWeight = "bold")),
          gridLineColor = "#e0e0e0"
        ) |>
        highcharter::hc_add_series(
          data = data$points,
          name = input$driver_select,
          color = COLORS$primary,
          fillColor = list(
            linearGradient = list(x1 = 0, y1 = 0, x2 = 0, y2 = 1),
            stops = list(
              list(0, "rgba(255,133,27,0.45)"),
              list(1, "rgba(255,133,27,0.02)")
            )
          ),
          lineWidth = 3,
          marker = list(
            enabled = TRUE, radius = 5, symbol = "circle",
            fillColor = COLORS$primary, lineColor = "#fff", lineWidth = 2
          ),
          animation = list(duration = 2500)
        )

      # Add comparison series if selected
      cmp <- compare_data()
      if (!is.null(cmp) && nrow(cmp) > 0) {
        hc <- hc |>
          highcharter::hc_add_series(
            data = cmp$points,
            name = input$compare_driver_select,
            color = COLORS$compare,
            fillColor = list(
              linearGradient = list(x1 = 0, y1 = 0, x2 = 0, y2 = 1),
              stops = list(
                list(0, "rgba(57,204,204,0.30)"),
              list(1, "rgba(57,204,204,0.02)")
              )
            ),
            lineWidth = 3,
            marker = list(
              enabled = TRUE, radius = 5, symbol = "diamond",
              fillColor = COLORS$compare, lineColor = "#fff", lineWidth = 2
            ),
            animation = list(duration = 2500)
          )
      }

      hc |>
        highcharter::hc_tooltip(
          shared = TRUE,
          useHTML = TRUE,
          backgroundColor = "rgba(30,30,30,0.9)",
          style = list(color = "#fff"),
          borderRadius = 8,
          borderWidth = 0
        ) |>
        highcharter::hc_plotOptions(
          areaspline = list(
            animation = list(duration = 2500, easing = "easeOutQuart")
          )
        ) |>
        highcharter::hc_legend(
          enabled = TRUE,
          itemStyle = list(fontWeight = "bold")
        ) |>
        highcharter::hc_credits(enabled = FALSE)
    })

  })
}
