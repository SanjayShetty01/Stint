#!/usr/bin/env Rscript
# Stint Data Pipeline
# Loads local F1 data CSVs into the SQLite database.

box::use(DBI)
box::use(RSQLite)

# Local data paths
ZIP_PATH <- "data_processor_r/raw_data/f1_data.zip"
DB_PATH <- "db/f1_data"
TEMP_DIR <- "data_processor_r/temp"

# List of CSV files to load into the database
CSV_TABLES <- c(
  "circuits",
  "constructors",
  "constructor_results",
  "constructor_standings",
  "drivers",
  "driver_standings",
  "lap_times",
  "pit_stops",
  "qualifying",
  "races",
  "results",
  "seasons",
  "sprint_results",
  "status"
)


#' Extract the local CSV dataset
extract_local_data <- function(zip_file = ZIP_PATH, dest_dir = TEMP_DIR) {
  if (!file.exists(zip_file)) stop("Zip file not found: ", zip_file)
  if (!dir.exists(dest_dir)) dir.create(dest_dir, recursive = TRUE)

  message("Extracting CSV files from: ", zip_file)
  utils::unzip(zip_file, exdir = dest_dir)
  message("Extraction complete.")
}


#' Drop all existing tables and views in the database
drop_all_tables <- function(db_path = DB_PATH) {
  con <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit(DBI::dbDisconnect(con))
  
  # Drop Views
  views <- DBI::dbGetQuery(con, "SELECT name FROM sqlite_master WHERE type = 'view'")
  if (nrow(views) > 0) {
    for (v in views$name) {
      message("  Dropping view: ", v)
      DBI::dbExecute(con, paste0("DROP VIEW IF EXISTS ", v))
    }
  }

  # Drop Tables
  tables <- DBI::dbGetQuery(con, "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'")
  if (nrow(tables) > 0) {
    for (t in tables$name) {
      message("  Dropping table: ", t)
      DBI::dbExecute(con, paste0("DROP TABLE IF EXISTS ", t))
    }
  }
}


#' Load all CSV files into the SQLite database
load_csvs_to_db <- function(csv_dir = TEMP_DIR, db_path = DB_PATH) {
  con <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit(DBI::dbDisconnect(con))

  for (table_name in CSV_TABLES) {
    # Check for both .csv and capital .CSV extensions just in case
    csv_file <- file.path(csv_dir, paste0(table_name, ".csv"))
    if (!file.exists(csv_file)) {
       csv_file <- file.path(csv_dir, paste0(table_name, ".CSV"))
    }
    
    if (!file.exists(csv_file)) {
      message("  Skipping: ", table_name, " (file not found)")
      next
    }
    
    message("  Loading: ", table_name)
    data <- utils::read.csv(csv_file, stringsAsFactors = FALSE)
    DBI::dbWriteTable(con, table_name, data, overwrite = TRUE)
  }

  message("All CSV files loaded.")
}


#' Create summary views in the database
create_views <- function(db_path = DB_PATH) {
  con <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit(DBI::dbDisconnect(con))

  message("Creating driver_summary_view...")
  DBI::dbExecute(con, "DROP VIEW IF EXISTS driver_summary_view")
  DBI::dbExecute(con, "
    CREATE VIEW driver_summary_view AS
    SELECT
      d.driverId,
      d.forename || ' ' || d.surname AS driver_name,
      d.nationality,
      r.year,
      COUNT(DISTINCT res.raceId) AS total_races,
      SUM(CASE WHEN res.position = '1' THEN 1 ELSE 0 END) AS total_wins,
      SUM(CASE WHEN res.position = '\\N' OR res.statusId != 1 THEN 1 ELSE 0 END) AS dnf,
      SUM(CASE WHEN CAST(res.position AS INTEGER) <= 10 AND res.position != '\\N' THEN 1 ELSE 0 END) AS top_10_finishes,
      SUM(res.points) AS total_points
    FROM results res
    JOIN drivers d ON res.driverId = d.driverId
    JOIN races r ON res.raceId = r.raceId
    GROUP BY d.driverId, r.year
    ORDER BY r.year, total_points DESC
  ")

  message("Creating constructor_summary_view...")
  DBI::dbExecute(con, "DROP VIEW IF EXISTS constructor_summary_view")
  DBI::dbExecute(con, "
    CREATE VIEW constructor_summary_view AS
    SELECT
      c.constructorId,
      c.name AS constructor_name,
      c.nationality,
      r.year,
      COUNT(DISTINCT res.raceId) AS total_races,
      SUM(CASE WHEN res.position = '1' THEN 1 ELSE 0 END) AS total_wins,
      SUM(CASE WHEN res.position = '\\N' OR res.statusId != 1 THEN 1 ELSE 0 END) AS dnf,
      SUM(CASE WHEN CAST(res.position AS INTEGER) <= 10 AND res.position != '\\N' THEN 1 ELSE 0 END) AS top_10_finishes,
      SUM(res.points) AS total_points
    FROM results res
    JOIN constructors c ON res.constructorId = c.constructorId
    JOIN races r ON res.raceId = r.raceId
    GROUP BY c.constructorId, r.year
    ORDER BY r.year, total_points DESC
  ")

  message("Views created successfully.")
}


#' Run the full data pipeline
#' @export
run_pipeline <- function() {
  message("=== F1 Data Pipeline (Local Zip) ===")
  
  message("Step 1/4: Extracting data...")
  extract_local_data()

  message("Step 2/4: Clearing database...")
  drop_all_tables()

  message("Step 3/4: Loading CSVs to database...")
  load_csvs_to_db()

  message("Step 4/4: Creating summary views...")
  create_views()

  # Cleanup temp files
  temp_dir <- TEMP_DIR
  if (dir.exists(temp_dir)) {
    unlink(temp_dir, recursive = TRUE)
    message("Cleaned up temp directory.")
  }

  message("=== Pipeline complete! ===")
}


# Run if called directly
if (sys.nframe() == 0) {
  run_pipeline()
}
