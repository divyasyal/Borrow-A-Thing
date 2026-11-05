# Borrow A Thing - R version (Plumber + ggplot2)

## Run
1. Install R (4.1+) and RStudio.
2. RStudio: File > Open Project... is not needed - just `setwd("C:/Users/Admin/Desktop/BorrowAThing_R")`
   (or Session > Set Working Directory > To Source File Location after opening run.R).
3. Run:  `source("run.R")`   (first run installs plumber, jsonlite, ggplot2)
4. Open http://127.0.0.1:8000 and log in: `student@example.com` / `1234`.

## Files
- `api.R` - Plumber API (all endpoints + serves the website)
- `R/core.R` - CSV database + analytics (writes category_analysis.csv, item_analysis.csv, analytics_summary.csv, tableau/*.csv)
- `R/charts.R` - 20 ggplot2 charts + personal charts at login
- `R/pdfs.R` - PDF receipts, statements, analytics report
- `static/index.html` - the website (same UI as before, enhanced)
- `data/` - your CSVs (orders.csv is created automatically); originals in `data_original/`
- `generate_data.R` - your original data generator (unchanged)
