box::use("DBI")
box::use("RSQLite")


#fetch zip from the internet
fetch_zip <- function(url, destfile) {
  utils::download.file(url, destfile)
  utils::unzip(destfile)
}

#load csv to sqlitedb
load_csv_to_sqlite <- function(csv_file, db_file, table_name) {
  con <- DBI::dbConnect(RSQLite::SQLite(), db_file)
  DBI::dbWriteTable(con, table_name, 
                    read.csv(csv_file), 
                    overwrite = TRUE)
  DBI::dbDisconnect(con)
}

#execute sql query from a file using functions from RSQLite handle comments
execute_sql_from_file <- function(db_file, sql_file) {
  con <- DBI::dbConnect(RSQLite::SQLite(), db_file)
  sql <- readLines(sql_file)
  sql <- paste(sql, collapse = " ")
  sql <- gsub("--.*?\n", "", sql)
  DBI::dbExecute(con, sql)
  DBI::dbDisconnect(con)
}
