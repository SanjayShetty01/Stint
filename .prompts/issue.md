# Codebase Issues

## 1. CI/CD — Missing Packages in `deploy_shiny.yml` — ✅ Fixed

Initialized `renv` with a full `renv.lock` capturing all project dependencies.
Updated `deploy_shiny.yml` to use `renv::restore()` instead of manual `install.packages()`.
Added renv entries to `.gitignore`.

**Files**: `renv.lock`, `renv/`, `.github/workflows/deploy_shiny.yml`, `.gitignore`

---

## 2. Dead CSS — `input[type='number']` Rules in `main.scss` — ⏸ Kept

User decision: Keep the CSS for the color styling.

---

## 3. Verbose Dev Comments in Progression Modules — ✅ Fixed

Removed thinking-out-loud comments from `driver_progression.R`.

**File**: `app/view/driver_progression.R`

---

## 4. `actionButton` Uses `bs4Dash`-Only Arguments — ✅ Fixed

Replaced `status = "warning", size = "lg"` with `class = "btn-warning btn-lg"`.
Added CSS for shinyalert confirm button to use brand orange.

**Files**: `app/view/driver_progression.R`, `app/view/constructor_progression.R`, `app/styles/main.scss`

---

## 5. Empty Name in Dropdown — ✅ Fixed

Removed the empty string `""` from `choices = c("", drivers)` → `choices = drivers`.
Placeholder text still shows when nothing is selected.

**Files**: `app/view/driver_progression.R`, `app/view/constructor_progression.R`

---

## 6. Outdated Intro Text — "Powered by the Ergast API" — ✅ Fixed

Updated to: "Powered by historical Formula 1 data sourced from Kaggle (Ergast API database dump)".

**File**: `app/view/introduction_page.R`
