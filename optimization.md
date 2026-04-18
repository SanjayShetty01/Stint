# ⚡ Database & App Optimization

This document outlines the performance optimizations applied to the F1TimeCapsule Shiny application to reduce load times and improve responsiveness, particularly on the deployed server.

---

## Problem

The app was noticeably slow when switching tabs or loading charts — especially on the first visit to any page. Root cause analysis revealed:

- **No database indexes** on a 20MB SQLite database (26K+ result rows, 34K+ driver standings)
- **Summary views recomputed on every request** — expensive JOINs and aggregations ran each time a user selected a season
- **4 separate database connections** — each Shiny module opened its own connection to the same SQLite file
- **Redundant queries** — `get_available_years()` was called 4 times (once per module) returning identical data
- **Un-indexable WHERE clause** — driver progression used `forename || ' ' || surname` in the WHERE, which SQLite cannot optimize with an index

---

## Optimizations Applied

### 1. Database Indexes

Added **14 indexes** across the most-queried tables to eliminate full table scans:

| Table | Index | Purpose |
|-------|-------|---------|
| `results` | `raceId`, `driverId`, `constructorId` | FK lookups in summary views |
| `results` | `(raceId, driverId)`, `(raceId, constructorId)` | Composite indexes for JOIN performance |
| `races` | `year`, `(year, round)` | Season filtering and ordering |
| `driver_standings` | `raceId`, `driverId`, `(raceId, driverId)` | Progression queries |
| `constructor_standings` | `raceId`, `constructorId`, `(raceId, constructorId)` | Progression queries |
| `seasons` | `year` | Year dropdown population |

### 2. Materialized Views

The original `driver_summary_view` and `constructor_summary_view` were SQL views that recomputed JOINs + aggregations on every query. These were **materialized into tables**:

- `driver_summary_mat` — pre-computed driver season summaries with indexes on `(year)` and `(year, total_points)`
- `constructor_summary_mat` — same for constructors

The ranking queries now read from these pre-computed tables instead of recalculating on the fly.

> **Note:** After any data refresh, run `source("db/optimize_db.R")` to rebuild the materialized tables.

### 3. Pre-computed Driver Full Name

Added a `full_name` column to the `drivers` table (`forename || ' ' || surname`), with its own index. The driver progression query now filters on this indexed column instead of computing the concatenation in the WHERE clause at query time.

### 4. SQLite PRAGMA Tuning

Configured connection-level PRAGMAs for better read performance:

```sql
PRAGMA journal_mode=WAL;       -- Write-Ahead Logging for better read concurrency
PRAGMA mmap_size=67108864;     -- 64MB memory-mapped I/O
PRAGMA cache_size=-8000;       -- ~8MB page cache
```

### 5. Shared Database Connection

Replaced 4 per-module connections with a **single shared singleton connection** managed in `db_utils.R`. The connection is:

- Created once at app startup (in `main.R`)
- Reused by all modules automatically
- Disconnected on session end

### 6. In-Memory Query Caching

Static and semi-static data is cached in-memory after the first fetch:

| Data | Cache Behavior |
|------|---------------|
| Available years | Fetched once, cached for the session |
| Drivers by year | Cached per year after first request |
| Constructors by year | Cached per year after first request |

This eliminates redundant database round-trips when users navigate between tabs or revisit a previously selected season.

---

## Files Changed

| File | Change |
|------|--------|
| `db/optimize_db.R` | **New** — one-time script to add indexes, materialize views, and add `full_name` column |
| `app/logic/db_utils.R` | Rewritten — shared connection pool, PRAGMA tuning, caching, materialized table queries |
| `app/main.R` | Manages shared DB connection lifecycle (connect on start, disconnect on stop) |
| `app/view/driver_ranking.R` | Removed per-module connection management |
| `app/view/constructor_ranking.R` | Removed per-module connection management |
| `app/view/driver_progression.R` | Removed per-module connection management, uses `full_name` via updated `db_utils` |
| `app/view/constructor_progression.R` | Removed per-module connection management |

---

## Re-running After Data Updates

If the underlying F1 database (`db/f1_data`) is updated with new season data:

```r
source("db/optimize_db.R")
```

This will:
1. Recreate all indexes (idempotent via `CREATE INDEX IF NOT EXISTS`)
2. Drop and rebuild the materialized summary tables
3. Update the `full_name` column on any new drivers
4. Run `ANALYZE` for the SQLite query planner
