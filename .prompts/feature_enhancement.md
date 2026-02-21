# Feature Enhancements

Tracking feature enhancement requirements for the Stint project.

<!-- Add feature enhancement requirements below. Each entry should describe the feature and its specs. -->

### 1. Comparative analysis on progression pages

Added an optional "Compare With" dropdown on both driver and constructor progression pages. When a second driver/constructor is selected:
- A blue line overlays the chart alongside the orange primary line
- Shared tooltips show both entries' points side by side
- Diamond markers distinguish the comparison from the primary (circle markers)
- A legend identifies each entry by name
- Each dropdown label has a colored dot (●) matching its chart line color

**Files**: `driver_progression.R`, `constructor_progression.R` — ✅ Implemented

### 2. Polished tables with reactable

Replaced plain `shiny::tableOutput` with `reactable` across all 4 tables (rankings + progression details):
- Orange branded header row
- Striped rows with warm tint, hover highlight
- Sortable columns, proper column widths and alignment
- Bold points column for emphasis

**Files**: `driver_ranking.R`, `constructor_ranking.R`, `driver_progression.R`, `constructor_progression.R`, `dependencies.R` — ✅ Implemented

### 3. Redesigned Progression UI Workflow

Refactor `driver_progression.R` and `constructor_progression.R` to implement a step-by-step workflow:
- **Row 1**: Season Year selector (centered, width=4, offset=4)
- **Row 2**: Two parallel dropdowns (width=6 each) for primary and comparison selections (both start empty)
- **Row 3**: "Visualize" action button (centered)
- **Row 4**: Chart area (conditionally rendered only after clicking "Visualize")

**Files**: `driver_progression.R`, `constructor_progression.R` — ⏳ Pending

### 4. Database-Driven Year Selection (Global)

Replace the static `numericInput` for "Year" with a `selectizeInput` (dropdown) populated dynamically from the `seasons` table in the database **on all pages**:
- Driver Rankings
- Constructor Rankings
- Driver Progression (already done)
- Constructor Progression (already done)

**Files**: `driver_ranking.R`, `constructor_ranking.R` — ✅ Implemented

### 5. Loading Spinner on Progression Charts

Added a branded loading spinner (pulsing orange dots) to the progression chart area using `shinycssloaders::withSpinner`. Shows while the Highcharter chart renders.

**Files**: `driver_progression.R`, `constructor_progression.R`, `dependencies.R` — ✅ Implemented

### 6. Auto-Update Chart on Dropdown Change

After the first Visualize click, subsequent dropdown changes (primary or compare) automatically re-fetch data and update the chart without needing to click the button again. Year change resets this state.

**Files**: `driver_progression.R`, `constructor_progression.R` — ✅ Implemented
