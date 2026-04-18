box::use(DBI, RSQLite, glue)


# ============================================================================
# Shared connection pool (one connection per R process)
# ============================================================================

# Module-level connection (created once, reused across all modules)
.state <- new.env(parent = emptyenv())
.state$conn <- NULL
.state$cache <- list()

#' Get or create the shared database connection
#' @return A DBI connection object
#' @export
db_connect <- function() {
  if (is.null(.state$conn) || !DBI::dbIsValid(.state$conn)) {
    mydb_path <- "db/f1_data"
    .state$conn <- DBI::dbConnect(RSQLite::SQLite(), mydb_path)
    # Enable WAL mode for better read concurrency
    DBI::dbExecute(.state$conn, "PRAGMA journal_mode=WAL")
    # Use memory-mapped I/O for faster reads (64MB)
    DBI::dbExecute(.state$conn, "PRAGMA mmap_size=67108864")
    # Increase cache size (8MB worth of pages)
    DBI::dbExecute(.state$conn, "PRAGMA cache_size=-8000")
  }
  return(.state$conn)
}


#' Disconnect the shared database connection (call on app stop)
#' @export
db_disconnect <- function() {
  if (!is.null(.state$conn) && DBI::dbIsValid(.state$conn)) {
    DBI::dbDisconnect(.state$conn)
    .state$conn <- NULL
  }
  .state$cache <- list()
}


# ============================================================================
# Cached helpers (avoid redundant queries for static/semi-static data)
# ============================================================================

#' Get all available season years (cached after first call)
#' @param conn A DBI connection object (optional, uses shared if NULL)
#' @return A numeric vector of years
#' @export
get_available_years <- function(conn = NULL) {
  if (!is.null(.state$cache$years)) return(.state$cache$years)
  if (is.null(conn)) conn <- db_connect()
  result <- DBI::dbGetQuery(conn, "SELECT DISTINCT year FROM seasons ORDER BY year DESC")
  .state$cache$years <- result$year
  return(.state$cache$years)
}


#' Get all unique driver names for a given season (cached per year)
#' @param year Season year
#' @param conn A DBI connection object (optional, uses shared if NULL)
#' @return A character vector of driver names
#' @export
get_drivers_by_year <- function(year, conn = NULL) {
  cache_key <- paste0("drivers_", year)
  if (!is.null(.state$cache[[cache_key]])) return(.state$cache[[cache_key]])
  if (is.null(conn)) conn <- db_connect()

  result <- DBI::dbGetQuery(conn, glue::glue_sql(
    "SELECT DISTINCT d.full_name AS driver_name
     FROM driver_standings ds
     JOIN races r ON ds.raceId = r.raceId
     JOIN drivers d ON ds.driverId = d.driverId
     WHERE r.year = {year}
     ORDER BY driver_name",
    .con = conn
  ))
  .state$cache[[cache_key]] <- result$driver_name
  return(.state$cache[[cache_key]])
}


#' Get all unique constructor names for a given season (cached per year)
#' @param year Season year
#' @param conn A DBI connection object (optional, uses shared if NULL)
#' @return A character vector of constructor names
#' @export
get_constructors_by_year <- function(year, conn = NULL) {
  cache_key <- paste0("constructors_", year)
  if (!is.null(.state$cache[[cache_key]])) return(.state$cache[[cache_key]])
  if (is.null(conn)) conn <- db_connect()

  result <- DBI::dbGetQuery(conn, glue::glue_sql(
    "SELECT DISTINCT c.name AS constructor_name
     FROM constructor_standings cs
     JOIN races r ON cs.raceId = r.raceId
     JOIN constructors c ON cs.constructorId = c.constructorId
     WHERE r.year = {year}
     ORDER BY constructor_name",
    .con = conn
  ))
  .state$cache[[cache_key]] <- result$constructor_name
  return(.state$cache[[cache_key]])
}


# ============================================================================
# Query functions (use indexes and materialized tables)
# ============================================================================

#' Get ranking data from a materialized summary table for a given year
#' @param view_name Original view name (mapped to materialized table internally)
#' @param year Season year to filter by
#' @param conn A DBI connection object (optional, uses shared if NULL)
#' @return A data.frame of ranking data ordered by total_points DESC
#' @export
get_ranking_view <- function(view_name, year, conn = NULL) {
  if (is.null(conn)) conn <- db_connect()

  # Map old view names to materialized tables for faster reads
  mat_table <- switch(view_name,
    "driver_summary_view" = "driver_summary_mat",
    "constructor_summary_view" = "constructor_summary_mat",
    view_name  # fallback to original name
  )

  DBI::dbGetQuery(conn, glue::glue_sql(
    "SELECT * FROM {`mat_table`}
     WHERE year = {year}
     ORDER BY total_points DESC",
    .con = conn
  ))
}


#' Get race-by-race driver points progression for a season
#' @param driver_name Full name of the driver (e.g., "Max Verstappen")
#' @param year Season year
#' @param conn A DBI connection object (optional, uses shared if NULL)
#' @return A data.frame with round, race_name, points, position, wins
#' @export
get_driver_season_progression <- function(driver_name, year, conn = NULL) {
  if (is.null(conn)) conn <- db_connect()

  # Uses the pre-computed full_name column + index instead of
  # string concatenation (forename || ' ' || surname) in WHERE
  DBI::dbGetQuery(conn, glue::glue_sql(
    "SELECT r.round, r.name AS race_name, ds.points, ds.position, ds.wins
     FROM driver_standings ds
     JOIN races r ON ds.raceId = r.raceId
     JOIN drivers d ON ds.driverId = d.driverId
     WHERE d.full_name = {driver_name}
       AND r.year = {year}
     ORDER BY r.round",
    .con = conn
  ))
}


#' Get race-by-race constructor points progression for a season
#' @param constructor_name Name of the constructor (e.g., "Red Bull")
#' @param year Season year
#' @param conn A DBI connection object (optional, uses shared if NULL)
#' @return A data.frame with round, race_name, points, position, wins
#' @export
get_constructor_season_progression <- function(constructor_name, year, conn = NULL) {
  if (is.null(conn)) conn <- db_connect()

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
