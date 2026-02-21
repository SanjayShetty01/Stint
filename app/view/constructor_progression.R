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
constructor_progression_ui <- function(id) {
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
          inputId = ns("constructor_select"),
          label = shiny::HTML("<span style='color:#ff851b; font-size:16px;'>&#9679;</span> Select Constructor"),
          choices = NULL,
          options = list(placeholder = "Select Constructor...")
        )
      ),
      shiny::column(
        width = 4,
        shiny::div(class = "compare-dropdown",
          shiny::selectizeInput(
            inputId = ns("compare_constructor_select"),
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
constructor_progression_server <- function(id) {
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
                                   selected = years[1],
                                   server = TRUE)
    })

    # Update constructor dropdowns when year changes
    shiny::observeEvent(input$year_select, {
      shiny::req(input$year_select)
      constructors <- db_utils$get_constructors_by_year(input$year_select, conn)
      
      # Reset selections to empty
      shiny::updateSelectizeInput(session, "constructor_select",
                                   choices = constructors,
                                   selected = "",
                                   server = TRUE)
      shiny::updateSelectizeInput(session, "compare_constructor_select",
                                   choices = constructors,
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
      c1 <- input$constructor_select
      year <- input$year_select
      if (is.null(c1) || c1 == "" || is.null(year) || year == "") return()

      data <- db_utils$get_constructor_season_progression(c1, year, conn)
      if (is.null(data) || nrow(data) == 0) {
        progression_data(NULL)
        compare_data(NULL)
        return()
      }
      progression_data(data)

      c2 <- input$compare_constructor_select
      if (!is.null(c2) && c2 != "") {
        c_data <- db_utils$get_constructor_season_progression(c2, year, conn)
        compare_data(c_data)
      } else {
        compare_data(NULL)
      }
    }

    # First click: validate then fetch
    shiny::observeEvent(input$visualize_btn, {
      if (is.null(input$constructor_select) || input$constructor_select == "") {
        shinyalert::shinyalert("Missing Selection", "Please select a constructor to visualize.", type = "error")
        progression_data(NULL)
        compare_data(NULL)
        return()
      }
      has_visualized(TRUE)
      fetch_data()
    })

    # Auto-update on dropdown change (after first Visualize)
    shiny::observeEvent(list(input$constructor_select, input$compare_constructor_select), {
      if (!has_visualized()) return()
      fetch_data()
    })

    # Render UI for chart only if data exists
    output$chart_ui <- shiny::renderUI({
      data <- progression_data()
      if (is.null(data) || nrow(data) == 0) return(NULL)

      c1 <- input$constructor_select
      c2 <- input$compare_constructor_select
      year <- input$year_select

      title <- paste(c1, "-", year, "Season")
      if (!is.null(c2) && c2 != "") {
        title <- paste(c1, "vs", c2, "-", year, "Season")
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
          name = input$constructor_select,
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
            name = input$compare_constructor_select,
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
