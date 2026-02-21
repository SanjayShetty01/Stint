box::use(
  testthat[expect_true, expect_is, expect_gt, expect_named, test_that],
)
box::use(
  app/logic/db_utils
)

# Tests run from project root (Rhino convention),
# but set explicit working directory just in case
if (file.exists("../../db/f1_data")) {
  withr::local_dir("../..")
}

test_that("db_connect returns a valid connection", {
  conn <- db_utils$db_connect()
  expect_true(DBI::dbIsValid(conn))
  DBI::dbDisconnect(conn)
})

test_that("get_available_years returns numeric vector of years", {
  conn <- db_utils$db_connect()
  years <- db_utils$get_available_years(conn)
  expect_true(is.numeric(years))
  expect_gt(length(years), 0)
  expect_true(2024 %in% years)
  expect_true(1950 %in% years)
  DBI::dbDisconnect(conn)
})

test_that("get_ranking_view returns driver data for a given year", {
  conn <- db_utils$db_connect()
  data <- db_utils$get_ranking_view("driver_summary_view", 2023, conn)
  expect_true(is.data.frame(data))
  expect_gt(nrow(data), 0)
  expected_cols <- c("driverId", "driver_name", "nationality", "year",
                     "total_races", "total_wins", "dnf",
                     "top_10_finishes", "total_points")
  for (col in expected_cols) {
    expect_true(col %in% names(data), info = paste("Missing column:", col))
  }
  DBI::dbDisconnect(conn)
})

test_that("get_ranking_view returns constructor data for a given year", {
  conn <- db_utils$db_connect()
  data <- db_utils$get_ranking_view("constructor_summary_view", 2023, conn)
  expect_true(is.data.frame(data))
  expect_gt(nrow(data), 0)
  expect_true("constructor_name" %in% names(data))
  DBI::dbDisconnect(conn)
})

test_that("get_all_drivers returns character vector", {
  conn <- db_utils$db_connect()
  drivers <- db_utils$get_all_drivers(conn)
  expect_true(is.character(drivers))
  expect_gt(length(drivers), 0)
  expect_true("Max Verstappen" %in% drivers)
  DBI::dbDisconnect(conn)
})

test_that("get_all_constructors returns character vector", {
  conn <- db_utils$db_connect()
  constructors <- db_utils$get_all_constructors(conn)
  expect_true(is.character(constructors))
  expect_gt(length(constructors), 0)
  expect_true("Ferrari" %in% constructors)
  DBI::dbDisconnect(conn)
})

test_that("get_driver_progression returns data for a known driver", {
  conn <- db_utils$db_connect()
  data <- db_utils$get_driver_progression("Lewis Hamilton", conn)
  expect_true(is.data.frame(data))
  expect_gt(nrow(data), 5)
  expect_true("year" %in% names(data))
  expect_true("total_points" %in% names(data))
  DBI::dbDisconnect(conn)
})

test_that("get_constructor_progression returns data for a known constructor", {
  conn <- db_utils$db_connect()
  data <- db_utils$get_constructor_progression("Ferrari", conn)
  expect_true(is.data.frame(data))
  expect_gt(nrow(data), 10)
  expect_true("year" %in% names(data))
  expect_true("total_points" %in% names(data))
  DBI::dbDisconnect(conn)
})
