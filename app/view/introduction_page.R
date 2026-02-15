box::use(shiny)
box::use(./components/button_ui)

#' @export
introduction_ui <- function(id) {
  ns <- shiny::NS(id) 
  
  shiny::fluidPage(
    shiny::tags$head(
      shiny::tags$style(shiny::HTML("
        .intro-container {
          max-width: 800px;
          margin: auto;
          padding: 20px;
          text-align: center;
        }
        .intro-title {
          font-size: 36px;
          font-weight: bold;
          color: #ff851b;
        }
        .intro-subtitle {
          font-size: 24px;
          color: #555;
          margin-bottom: 20px;
        }
        .intro-text {
          font-size: 18px;
          line-height: 1.6;
          color: #333;
        }
      "))
    ),
    
    shiny::div(class = "intro-container",
               shiny::div(class = "intro-title", 
                          "🏎️️ F1 Time Capsule"),
               shiny::div(class = "intro-subtitle", 
                          "Dive into the thrilling world of Formula 1"),
               
               shiny::p(class = "intro-text", 
                        "This dashboard offers a comprehensive overview of the 
                        Formula 1 seasons, showcasing drivers and constructors 
                        rankings along with their progression over time."
               ),
               shiny::p(class = "intro-text", 
                        "Powered by the Ergast API, this app brings you 
                        historical Formula 1 data to explore past seasons, 
                        legendary races, and iconic moments."
               ),
               shiny::p(class = "intro-text", 
                        "Use the sidebar to navigate between different 
                        sections and start your journey through F1 history!"
               ),
               shiny::p(class = "intro-text", 
                        "🏁 Enjoy exploring the world of Formula 1! 🏆")
    ),
    
    shiny::br(),
    shiny::br(),
    
    shiny::fixedRow(
      shiny::column(
        width = 4,
        offset = 4,
          button_ui$button_ui(ns("start_button"), 
                                  "Start Exploring 🏁")
        ))
  )
}

#' @export
introduction_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
  })
}
