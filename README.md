# Stint

[![deploy-shiny](https://github.com/SanjayShetty01/Stint/actions/workflows/deploy_shiny.yml/badge.svg)](https://github.com/SanjayShetty01/Stint/actions/workflows/deploy_shiny.yml)

An interactive Shiny dashboard for exploring historical Formula 1 data, built with the [Rhino](https://appsilon.github.io/rhino/) framework.

## Overview

Stint provides a comprehensive look at Formula 1 seasons through driver and constructor rankings, along with season progression charts. The data is sourced from [Kaggle](https://www.kaggle.com/), which in turn is a dump of the [Ergast API](http://ergast.com/mrd/) database.

### Features

- **Driver Rankings** -- Season standings with points, wins, and nationality displayed in sortable tables.
- **Constructor Rankings** -- Team standings for any available season.
- **Driver Progression** -- Cumulative points progression across a season, with an optional comparison overlay.
- **Constructor Progression** -- Same progression view for constructor teams.
- **Compare Mode** -- Select two drivers (or constructors) to see their season arcs side by side on a single chart.
- **Dynamic Year Selection** -- All pages use a database-driven dropdown, so available seasons are always up to date.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | [Rhino](https://appsilon.github.io/rhino/) (modular Shiny) |
| UI | [bs4Dash](https://rinterface.github.io/bs4Dash/) (Bootstrap 4) |
| Charts | [Highcharter](https://jkunst.com/highcharter/) |
| Tables | [Reactable](https://glin.github.io/reactable/) |
| Database | SQLite via DBI / RSQLite |
| Module system | [box](https://klmr.me/box/) |
| Styling | SCSS compiled by Rhino |
| Dependency management | [renv](https://rstudio.github.io/renv/) |
| CI/CD | GitHub Actions, deployed to [shinyapps.io](https://www.shinyapps.io/) |

## Project Structure

```
Stint/
├── app/
│   ├── main.R                  # App entry point (UI + server)
│   ├── view/
│   │   ├── introduction_page.R # Landing page
│   │   ├── driver_ranking.R    # Driver standings module
│   │   ├── constructor_ranking.R
│   │   ├── driver_progression.R    # Season progression chart module
│   │   ├── constructor_progression.R
│   │   ├── dashboard_body.R    # Tab layout
│   │   ├── sidebar_menu.R      # Navigation sidebar
│   │   └── components/         # Reusable UI components
│   ├── logic/
│   │   └── db_utils.R          # Database queries
│   └── styles/
│       └── main.scss           # Global styles
├── data_processor_r/
│   └── main.R                  # ETL: extracts CSV from zip, loads into SQLite
├── db/                         # SQLite database (generated)
├── renv.lock                   # Locked package versions
├── dependencies.R              # Package manifest for deployment
├── config.yml                  # Rhino configuration
└── app.R                       # Shiny entry point (calls rhino::app())
```

## Getting Started

### Prerequisites

- R (>= 4.3)
- [renv](https://rstudio.github.io/renv/) (installed automatically on first run)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/SanjayShetty01/Stint.git
   cd Stint
   ```

2. Restore dependencies:
   ```r
   renv::restore()
   ```

3. Build the database (requires `f1_data.zip` in the project root):
   ```r
   source("data_processor_r/main.R")
   ```

4. Compile styles:
   ```r
   rhino::build_sass()
   ```

5. Run the app:
   ```r
   shiny::runApp()
   ```

## Data

The raw data comes from Kaggle as a zip archive of CSV files covering F1 seasons from 1950 to the present. The `data_processor_r/main.R` script extracts the CSVs, processes them, and loads them into a local SQLite database at `db/f1_data`.

Key tables used: `results`, `races`, `drivers`, `constructors`, `constructor_results`, `constructor_standings`, `driver_standings`.

## Deployment

The app is deployed automatically to shinyapps.io via GitHub Actions on pushes to `main`/`master`. The workflow uses `renv::restore()` to install the exact package versions from `renv.lock`.

To deploy manually:

```r
rsconnect::deployApp(appName = "Stint")
```

## Acknowledgements

Parts of this project were developed with the assistance of [Antigravity](https://deepmind.google/), an AI coding assistant by Google DeepMind.

## License

MIT -- see [LICENSE](LICENSE) for details.
