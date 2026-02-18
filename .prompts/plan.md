# Stint — Project Plan

## 1. What Is This Project?

**Stint** (deployed as **"Stint"**) is an **R Shiny dashboard** for exploring historical Formula 1 data — driver & constructor rankings and their race-by-race progression within any season from 1950 to 2024.

- **Data Source**: Local CSV Archive (sourced from Kaggle/Ergast export)
- **Framework**: [Rhino](https://appsilon.github.io/rhino/) (opinionated Shiny project framework by Appsilon)
- **UI Framework**: `bs4Dash` (Bootstrap 4 AdminLTE3 dashboard)
- **Database**: SQLite (`db/f1_data`, ~20 MB, 1950–2024)
- **Charting**: `highcharter` — interactive, animated charts with smooth line-drawing animations
- **Deployment**: shinyapps.io via GitHub Actions on push to `main`/`master`

---

## 2. Project Structure

```
Stint/
├── app.R                  # Rhino entrypoint (do not edit)
├── rhino.yml              # Rhino config (sass: node)
├── config.yml             # Logging config
├── dependencies.R         # Library declarations for rsconnect
│
├── app/                   # Main application code
│   ├── main.R             # Root Shiny module (UI + all server wiring)
│   ├── js/index.js        # JS entrypoint
│   ├── styles/main.scss   # Global SCSS ($brand-color: #ff851b)
│   │
│   ├── logic/             # Business logic (Shiny-independent)
│   │   ├── __init__.R
│   │   └── db_utils.R     # DB connection + all query helpers
│   │
│   └── view/              # Shiny UI modules
│       ├── __init__.R
│       ├── dash_brand.R              # Dashboard header/branding
│       ├── sidebar_menu.R            # Sidebar navigation (5 tabs)
│       ├── dashboard_body.R          # Tab routing (wired to all modules)
│       ├── introduction_page.R       # Home page
│       ├── driver_ranking.R          # Driver standings table
│       ├── constructor_ranking.R     # Constructor standings table
│       ├── driver_progression.R      # Driver race-by-race animated chart
│       ├── constructor_progression.R # Constructor race-by-race animated chart
│       └── components/
│           ├── button_ui.R           # Reusable action button
│           └── dropdown_ui.R         # Reusable dropdown
│
├── data_processor_r/      # Data pipeline scripts
│   ├── main.R             # Full pipeline: extract local zip → SQLite → create views
│   ├── raw_data/          # Contains f1_data.zip
│   └── utils.R            # Utility functions
│
├── db/
│   └── f1_data            # SQLite database (~20 MB)
│
├── .prompts/              # AI prompt docs (ignored for deployment, tracked in git)
│   ├── plan.md            # Project spec & requirements
│   ├── bug_fixes.md       # Bug fix prompts
│   └── feature_enhancement.md  # Feature enhancement prompts
│
├── tests/
│   ├── testthat/
│   │   └── test-main.R
│   └── cypress/
│       ├── cypress.config.js
│       └── e2e/app.cy.js
│
└── .github/workflows/
    └── deploy_shiny.yml   # CI/CD: install deps → deploy to shinyapps.io
```

---

## 3. Tech Stack

| Layer         | Technology                     |
|---------------|--------------------------------|
| Language      | R                              |
| Framework     | Rhino (Shiny)                  |
| UI            | bs4Dash + shinyWidgets         |
| Module System | `box` (imports)                |
| Styling       | SCSS (compiled via Node)       |
| Database      | SQLite via DBI + RSQLite       |
| Charting      | highcharter (animated)         |
| Data Source   | Local CSV Archive (Kaggle)     |
| Deployment    | shinyapps.io (GitHub Actions)  |

---

## 4. App Pages & Requirements

The app has 5 pages accessible via a sidebar. Brand color is `#ff851b` (orange) throughout.

### Sidebar Navigation

The sidebar uses collapsible sub-menus to keep labels short and organized:

```
🏠 Home
👤 Drivers ▸
    🏆 Rankings
    📈 Progression
🚗 Constructors ▸
    🏆 Rankings
    📈 Progression
```

- Driver-related items use the `person` icon, constructor items use `car`
- Sub-items use `trophy` (rankings) and `chart-line` (progression)

### 4.1 Home (Introduction Page)

A welcome page with:
- App title "🏎️ Stint"
- Description of the dashboard and data source
- "Start Exploring 🏁" button — navigates to the Drivers tab on click

### 4.2 Driver Rankings

| Input | Output |
|-------|--------|
| Season year (numeric, 1950–2024) | Standings table sorted by points descending |

**Table columns**: Rank, Driver Name, Nationality, Total Races, Total Wins, DNF, Top 10 Finishes, Total Points

Data source: `driver_summary_view` in SQLite.

### 4.3 Constructor Rankings

| Input | Output |
|-------|--------|
| Season year (numeric, 1950–2024) | Standings table sorted by points descending |

**Table columns**: Rank, Constructor Name, Nationality, Total Races, Total Wins, DNF, Top 10 Finishes, Total Points

Data source: `constructor_summary_view` in SQLite.

### 4.4 Driver Ranking Progression

### 4.4 Driver Ranking Progression

**Layout**:
1. **Row 1**: Season year selector (centered)
2. **Row 2**: Two driver dropdowns side-by-side (Driver 1 & Driver 2)
   - No default selection
   - Placeholder: "Select Driver"
3. **Row 3**: "Visualize ⚡" button (centered)
4. **Row 4**: Animated chart (hidden until button click)

**Interactions**:
- User selects Year → Drivers update
- User selects Driver 1 & Driver 2 (optional)
- User clicks **Visualize** → Chart renders

**Chart specs** (highcharter):
- **Type**: Areaspline — line with gradient fill underneath (orange → transparent)
- **X axis**: Race name (one tick per race in the season)
- **Y axis**: Cumulative points
- **Animation**: Smooth line-drawing effect (2.5s, easeOutQuart easing)
- **Interactivity**: Crosshair on hover, dark shared tooltips, styled markers
- **Comparison mode**: When a second driver is selected, a teal line overlays the chart with diamond markers. Shared tooltips show both drivers' points side by side. A legend identifies each driver

Data source: `driver_standings` joined with `races` and `drivers` tables.

### 4.5 Constructor Ranking Progression

Same layout and behavior as Driver Progression (§4.4):
- **Row 1**: Season year (centered)
- **Row 2**: Two constructor dropdowns side-by-side
- **Row 3**: "Visualize ⚡" button
- **Row 4**: Animated chart (on click)

**Chart**:
- Animated areaspline chart with optional comparison overlay (orange vs teal)
- Shared tooltips, legend, diamond markers for comparison

Data source: `constructor_standings` joined with `races` and `constructors` tables.

---

## 5. Data Pipeline (`data_processor_r/main.R`)

Automated pipeline using local data:
1. **Extract**: Unzip `data_processor_r/raw_data/f1_data.zip`
2. **Reset**: Drop all existing tables and views in SQLite
3. **Load**: Parse all 14 CSV files into the SQLite database
4. **Create views**: Build `driver_summary_view` and `constructor_summary_view`  range: 1950–2024

---

## 6. Implementation Status

| Item | Status | Files |
|------|--------|-------|
| Home page | ✅ | `introduction_page.R` |
| Start Exploring → Drivers tab | ✅ | `introduction_page.R`, `main.R` |
| Driver Rankings | ✅ | `driver_ranking.R` |
| Constructor Rankings | ✅ | `constructor_ranking.R` |
| Driver Progression (animated + comparison) | ✅ | `driver_progression.R` |
| Constructor Progression (animated + comparison) | ✅ | `constructor_progression.R` |
| Module wiring | ✅ | `main.R`, `dashboard_body.R` |
| DB utilities | ✅ | `db_utils.R` |
| Data pipeline | ✅ | `data_processor_r/main.R` |
| Dependencies & CI/CD | ✅ | `dependencies.R`, `deploy_shiny.yml` |
| Sidebar (icons + sub-menus) | ✅ | `sidebar_menu.R` |
| Tests | ⏸️ | — |
