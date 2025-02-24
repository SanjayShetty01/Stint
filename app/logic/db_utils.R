box::use(DBI, RSQLite, dplyr)


#' @export
db_connect <- function() {
  mydb_path <- "db/f1_data"
  my_db <- DBI::dbConnect(RSQLite::SQLite(), mydb_path)
  return(my_db)
}


#' @export
get_ranking_view <- function(view_name, year, conn) {
  DBI::dbGetQuery(conn, glue::glue_sql("SELECT * FROM {view_name} 
                                       WHERE year = {year}
                                       ORDER BY total_points DESC",
                                        .con = conn))
}

driver_ranking <- get_view("driver_summary_view", year = 2023, 
                           conn = my_db)

constructor_ranking <- get_view("constructor_summary_view", year = 2023, 
                                conn = my_db)

## Rough work (Ignore)
driver_ranking$driver_name |> unique()

