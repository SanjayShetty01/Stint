box::use(DBI, RSQLite, glue)


#' Connect to the F1 SQLite database
#' @return A DBI connection object
#' @export
db_connect <- function() {
  mydb_path <- "db/f1_data"
  my_db <- DBI::dbConnect(RSQLite::SQLite(), mydb_path)
  return(my_db)
}


#' Get ranking data from a summary view for a given year
#' @param view_name Name of the database view (e.g., "driver_summary_view")
#' @param year Season year to filter by
#' @param conn A DBI connection object
#' @return A data.frame of ranking data ordered by total_points DESC
#' @export
get_ranking_view <- function(view_name, year, conn) {
  DBI::dbGetQuery(conn, glue::glue_sql("SELECT * FROM {view_name}
                                        WHERE year = {year}
                                        ORDER BY total_points DESC",
                                        .con = conn))
}


#' Get all available season years
#' @param conn A DBI connection object
#' @return A numeric vector of years
#' @export
get_available_years <- function(conn) {
  result <- DBI::dbGetQuery(conn, "SELECT DISTINCT year FROM seasons ORDER BY year DESC")
  result$year
}


#' Get all unique driver names for a given season
#' @param year Season year
#' @param conn A DBI connection object
#' @return A character vector of driver names
#' @export
get_drivers_by_year <- function(year, conn) {
  result <- DBI::dbGetQuery(conn, glue::glue_sql(
    "SELECT DISTINCT d.forename || ' ' || d.surname AS driver_name
     FROM driver_standings ds
     JOIN races r ON ds.raceId = r.raceId
     JOIN drivers d ON ds.driverId = d.driverId
     WHERE r.year = {year}
     ORDER BY driver_name",
    .con = conn
  ))
  result$driver_name
}


#' Get all unique constructor names for a given season
#' @param year Season year
#' @param conn A DBI connection object
#' @return A character vector of constructor names
#' @export
get_constructors_by_year <- function(year, conn) {
  result <- DBI::dbGetQuery(conn, glue::glue_sql(
    "SELECT DISTINCT c.name AS constructor_name
     FROM constructor_standings cs
     JOIN races r ON cs.raceId = r.raceId
     JOIN constructors c ON cs.constructorId = c.constructorId
     WHERE r.year = {year}
     ORDER BY constructor_name",
    .con = conn
  ))
  result$constructor_name
}


#' Get race-by-race driver points progression for a season
#' @param driver_name Full name of the driver (e.g., "Max Verstappen")
#' @param year Season year
#' @param conn A DBI connection object
#' @return A data.frame with round, race_name, points, position, wins
#' @export
get_driver_season_progression <- function(driver_name, year, conn) {
  DBI::dbGetQuery(conn, glue::glue_sql(
    "SELECT r.round, r.name AS race_name, ds.points, ds.position, ds.wins
     FROM driver_standings ds
     JOIN races r ON ds.raceId = r.raceId
     JOIN drivers d ON ds.driverId = d.driverId
     WHERE d.forename || ' ' || d.surname = {driver_name}
       AND r.year = {year}
     ORDER BY r.round",
    .con = conn
  ))
}


#' Get race-by-race constructor points progression for a season
#' @param constructor_name Name of the constructor (e.g., "Red Bull")
#' @param year Season year
#' @param conn A DBI connection object
#' @return A data.frame with round, race_name, points, position, wins
#' @export
get_constructor_season_progression <- function(constructor_name, year, conn) {
  DBI::dbGetQuery(conn, glue::glue_sql(
    "SELECT r.round, r.name AS race_name, cs.points, cs.position, cs.wins
     FROM constructor_standings cs
     JOIN races r ON cs.raceId = r.raceId
     JOIN constructors c ON cs.constructorId = c.constructorId
     WHERE c.name = {constructor_name}
       AND r.year = {year}
     ORDER BY r.round",
    .con = conn
  ))
}
