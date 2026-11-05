# ============================================================
# BORROW A THING - START THE APP
# In RStudio: open this folder (File > Open Project / Session > Set Working Directory),
# then run:   source("run.R")
# ============================================================
if (!file.exists("api.R")) stop("Set the working directory to the BorrowAThing_R folder first, e.g. setwd('C:/Users/Admin/Desktop/BorrowAThing_R')")

need <- c("plumber", "jsonlite", "ggplot2")
miss <- need[!vapply(need, requireNamespace, logical(1), quietly = TRUE)]
if (length(miss) > 0) install.packages(miss, repos = "https://cloud.r-project.org")

library(plumber)
message("Building analytics + graphics (about 10-20 seconds)...")
pr <- plumb("api.R")
message("Open  http://127.0.0.1:8000  in your browser   (login: student@example.com / 1234)")
pr$run(host = "127.0.0.1", port = 8000)
