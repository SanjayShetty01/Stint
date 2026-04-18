#' Optimize the F1 SQLite database
#'
#' This script adds indexes and materializes views to dramatically speed up
#' query performance. Run once after any data refresh.
#'
#' Usage: Rscript db/optimize_db.R

library(DBI)
library(RSQLite)

con <- dbConnect(SQLite(), "db/f1_data")

cat("Adding indexes...\n")

# --- Core foreign-key and lookup indexes ---

# results table (26K rows) - most queried table
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_results_raceid ON results(raceId)")
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_results_driverid ON results(driverId)")
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_results_constructorid ON results(constructorId)")
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_results_race_driver ON results(raceId, driverId)")
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_results_race_constructor ON results(raceId, constructorId)")

# races table - year lookups
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_races_year ON races(year)")
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_races_year_round ON races(year, round)")

# driver_standings table (34K rows)
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_ds_raceid ON driver_standings(raceId)")
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_ds_driverid ON driver_standings(driverId)")
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_ds_race_driver ON driver_standings(raceId, driverId)")

# constructor_standings table (13K rows)
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_cs_raceid ON constructor_standings(raceId)")
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_cs_constructorid ON constructor_standings(constructorId)")
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_cs_race_constructor ON constructor_standings(raceId, constructorId)")

# seasons table
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_seasons_year ON seasons(year)")

cat("Indexes created.\n")

# --- Materialize summary views as tables for fast reads ---
cat("Materializing summary views...\n")

# Drop old materialized tables if they exist (from previous runs)
dbExecute(con, "DROP TABLE IF EXISTS driver_summary_mat")
dbExecute(con, "DROP TABLE IF EXISTS constructor_summary_mat")

# Create materialized tables from the views
dbExecute(con, "CREATE TABLE driver_summary_mat AS SELECT * FROM driver_summary_view")
dbExecute(con, "CREATE TABLE constructor_summary_mat AS SELECT * FROM constructor_summary_view")

# Add indexes on the materialized tables
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_dsm_year ON driver_summary_mat(year)")
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_dsm_year_points ON driver_summary_mat(year, total_points DESC)")
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_csm_year ON constructor_summary_mat(year)")
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_csm_year_points ON constructor_summary_mat(year, total_points DESC)")

cat("Materialized tables created.\n")

# --- Add a pre-computed driver full-name column for fast lookups ---
cat("Adding driver full_name column...\n")

# Check if column already exists
cols <- dbListFields(con, "drivers")
if (!"full_name" %in% cols) {
  dbExecute(con, "ALTER TABLE drivers ADD COLUMN full_name TEXT")
}
dbExecute(con, "UPDATE drivers SET full_name = forename || ' ' || surname")
dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_drivers_fullname ON drivers(full_name)")

cat("Driver full_name column ready.\n")

# --- Run ANALYZE for query planner ---
cat("Running ANALYZE...\n")
dbExecute(con, "ANALYZE")

cat("Done! Database optimized.\n")

dbDisconnect(con)
