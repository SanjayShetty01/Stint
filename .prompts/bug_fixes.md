# Bug Fixes

Tracking bug fixes for the Stint project.

### 1. Compare Dropdown Highlight Color

The compare dropdown's selected item was highlighting in orange (the brand color), making it indistinguishable from the primary dropdown. Fixed via CSS targeting `[id*="compare_"]` to use teal (`#39CCCC`).

**File**: `app/styles/main.scss` — ✅ Fixed

### 2. Progression UI Fixes

- **Crash on Visualize**: Fixed `could not find function "ns"` error by defining `ns <- session$ns` in server functions.
- **Alignment**: Centered dropdowns using `width=4` with `offset=2` for proper spacing.
- **Validation**: Added error handling (`shinyalert` modal) to ensure a driver/constructor is selected before visualizing.

**Files**: `driver_progression.R`, `constructor_progression.R` — ✅ Fixed
