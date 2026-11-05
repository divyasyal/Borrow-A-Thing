# ============================================================
# BORROW A THING - PLUMBER API (R)
# Serves the website, CSV database, R analytics, ggplot2 graphics, PDF receipts
# Start with:  source("run.R")
# ============================================================
library(plumber)
library(jsonlite)
options(stringsAsFactors = FALSE)

source("R/core.R",   local = TRUE)
source("R/charts.R", local = TRUE)
source("R/pdfs.R",   local = TRUE)

gv <- function(b, k, d = "") { v <- b[[k]]; if (is.null(v) || length(v) == 0 || is.na(v[1])) d else v[1] }
parse_body <- function(req) tryCatch(fromJSON(req$postBody, simplifyVector = TRUE), error = function(e) list())
fail <- function(res, msg, code = 400) { res$status <- code; list(success = FALSE, message = msg) }
refresh <- function() { write_outputs(); CHARTS$dirty <- TRUE }
public_user <- function(row) as.list(row[, setdiff(names(row), "password"), drop = FALSE])

# ---- start-up: build orders.csv, analysis CSVs, Tableau exports and graphics ----
ensure_orders(); write_outputs(); ensure_charts(force = TRUE)
message("Graphics ready: ", length(CHARTS$meta), " charts")

rentals_df <- function(sid = NULL, limit = NULL) {
  j <- joined()
  if (!is.null(sid)) j <- j[j$student_id == sid, , drop = FALSE]
  j <- j[order(j$date, decreasing = TRUE), , drop = FALSE]
  if (!is.null(limit)) j <- head(j, limit)
  if (nrow(j) == 0) {
    return(data.frame(borrow_id = character(0), student_id = character(0), item_id = character(0), item_name = character(0),
                      icon = character(0), category = character(0), borrow_date = character(0), days = numeric(0),
                      rent_per_day = numeric(0), total_amount = numeric(0), returned = logical(0),
                      payment_method = character(0), return_date = character(0), receipt_url = character(0)))
  }
  data.frame(borrow_id = j$borrow_id, student_id = j$student_id, item_id = j$item_id, item_name = j$item_name,
             icon = j$icon, category = j$category, borrow_date = j$borrow_date, days = j$days,
             rent_per_day = j$rent_per_day, total_amount = j$amount, returned = j$returned_b,
             payment_method = j$payment_method, return_date = j$return_date,
             receipt_url = paste0("/receipt/", j$borrow_id, ".pdf"), stringsAsFactors = FALSE)
}

file_raw <- function(path) readBin(path, "raw", file.info(path)$size)

#* @filter cors
function(req, res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
  res$setHeader("Cache-Control", "no-store")
  if (identical(req$REQUEST_METHOD, "OPTIONS")) return("")
  plumber::forward()
}

# ------------------------------------------------------------ website
#* @get /
#* @serializer html
function() {
  x <- paste(readLines("static/index.html", warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  Encoding(x) <- "UTF-8"; x
}

#* @get /health
#* @serializer json list(auto_unbox = TRUE)
function() list(success = TRUE, status = "online", message = "Borrow A Thing R Plumber API is running", time = as.character(Sys.time()))

#* @get /config
#* @serializer json list(auto_unbox = TRUE)
function() {
  cfg <- tryCatch(fromJSON("config.json"), error = function(e) list())
  list(success = TRUE, tableau_embed_url = gv(cfg, "tableau_embed_url"),
       tableau_public_url = gv(cfg, "tableau_public_url", "https://public.tableau.com/"))
}

# ------------------------------------------------------------ login (students.csv)
#* @post /login
#* @serializer json list(auto_unbox = TRUE)
function(req, res) {
  b <- parse_body(req)
  email <- tolower(trimws(as.character(gv(b, "email")))); pw <- as.character(gv(b, "password"))
  if (email == "" || pw == "") return(fail(res, "Email and password are required."))
  s <- rd("students.csv")
  m <- s[(tolower(trimws(s$email)) == email | tolower(s$student_id) == email) & s$password == pw, , drop = FALSE]
  if (nrow(m) == 0) return(fail(res, "Invalid email or password.", 401))
  u <- public_user(m[1, , drop = FALSE])
  tryCatch(build_user(u$student_id), error = function(e) message("User charts failed: ", conditionMessage(e)))
  list(success = TRUE, message = paste("Welcome", u$name), user = u, student = u)
}

#* @get /student/<sid>
#* @serializer json list(auto_unbox = TRUE)
function(sid, res) {
  s <- rd("students.csv"); m <- s[s$student_id == sid, , drop = FALSE]
  if (nrow(m) == 0) return(fail(res, "Student not found.", 404))
  list(success = TRUE, student = public_user(m[1, , drop = FALSE]))
}

# ------------------------------------------------------------ items
#* @get /items
#* @serializer json list(auto_unbox = TRUE)
function(search = "", category = "") {
  df <- rd("items.csv"); q <- tolower(trimws(search))
  if (q != "") df <- df[grepl(q, tolower(df$item_name), fixed = TRUE) | grepl(q, tolower(df$category), fixed = TRUE), , drop = FALSE]
  if (category != "" && tolower(category) != "all") df <- df[tolower(df$category) == tolower(category), , drop = FALSE]
  list(success = TRUE, count = nrow(df), items = df)
}

# ------------------------------------------------------------ statistics
#* @get /stats
#* @serializer json list(auto_unbox = TRUE)
function() c(list(success = TRUE), kpis())

#* @get /statistics
#* @serializer json list(auto_unbox = TRUE)
function() { k <- kpis(); c(list(success = TRUE, statistics = k), k) }

#* @get /category-analysis
#* @serializer json list(auto_unbox = TRUE)
function() { d <- category_table(); list(success = TRUE, data = d, analysis = d, categories = d) }

#* @get /advanced-analytics
#* @serializer json list(auto_unbox = TRUE)
function() { d <- head(item_table(), 100); list(success = TRUE, data = d, analysis = d) }

#* @get /prediction
#* @serializer json list(auto_unbox = TRUE)
function(query = "") {
  q <- tolower(trimws(query))
  rec <- "Try searching the marketplace for books, calculators, electronics, lab equipment or project kits."
  if (grepl("ssc|exam|bank|competitive", q)) rec <- "For competitive exams, check Books, Calculators and Stationery."
  else if (grepl("physics|chemistry|lab", q)) rec <- "For laboratory study, check Lab Equipment and Project Kits."
  else if (grepl("\\b(computer|programming|coding|it|python|java)\\b", q)) rec <- "For Computer Science, check Books, Electronics, Tablets and Project Kits."
  else if (grepl("math", q)) rec <- "For Mathematics, check Books and Calculators."
  list(success = TRUE, query = query, recommendation = rec, message = rec, prediction = rec)
}

#* @get /lockers
#* @serializer json list(auto_unbox = TRUE)
function() { l <- rd("lockers.csv"); l <- l[, setdiff(names(l), "otp"), drop = FALSE]; list(success = TRUE, count = nrow(l), lockers = l, data = l) }

# ------------------------------------------------------------ rentals
#* @get /my-borrowings/<sid>
#* @serializer json list(auto_unbox = TRUE)
function(sid) { d <- rentals_df(sid); list(success = TRUE, borrowings = d, data = d, count = nrow(d)) }

#* @get /borrowings
#* @serializer json list(auto_unbox = TRUE)
function(limit = "100") { d <- rentals_df(limit = as.integer(limit)); list(success = TRUE, borrowings = d, count = nrow(d)) }

#* @get /my-reservations/<sid>
#* @serializer json list(auto_unbox = TRUE)
function(sid) {
  r <- rd("reservations.csv"); r <- r[r$student_id == sid, , drop = FALSE]
  i <- rd("items.csv")[, c("item_id", "item_name")]
  list(success = TRUE, reservations = merge(r, i, by = "item_id", all.x = TRUE, sort = FALSE))
}

#* @post /borrow
#* @serializer json list(auto_unbox = TRUE)
function(req, res) {
  b <- parse_body(req); sid <- as.character(gv(b, "student_id")); iid <- as.character(gv(b, "item_id"))
  days <- suppressWarnings(as.integer(as.numeric(gv(b, "days", 1)))); if (is.na(days) || days < 1) days <- 1L
  pay <- as.character(gv(b, "payment_method", "Demo Payment"))
  if (sid == "" || iid == "") return(fail(res, "Student ID and Item ID are required."))
  ensure_orders()
  s <- rd("students.csv"); it <- rd("items.csv"); bw <- rd("borrowings.csv"); od <- rd("orders.csv")
  si <- which(s$student_id == sid); ii <- which(it$item_id == iid)
  if (length(si) == 0) return(fail(res, "Student not found.", 404))
  if (length(ii) == 0) return(fail(res, "Item not found.", 404))
  si <- si[1]; ii <- ii[1]
  if (tolower(it$status[ii]) %in% c("rented", "borrowed", "unavailable", "reserved")) return(fail(res, "This item is currently unavailable.", 409))
  rate <- num(it$rent_per_day[ii]); if (is.na(rate)) rate <- 0
  total <- rate * days; today <- as.character(Sys.Date())
  bid <- next_id(bw$borrow_id, "BRW"); oid <- next_id(od$order_id, "ORD")
  bw <- add_row(bw, list(borrow_id = bid, student_id = sid, item_id = iid, borrow_date = today, days = days,
                         returned = "FALSE", payment_method = pay, return_date = ""))
  od <- add_row(od, list(order_id = oid, borrow_id = bid, student_id = sid, item_id = iid, amount = round(total),
                         payment_method = pay, order_date = today, status = "Paid"))
  it$status[ii] <- "Borrowed"
  s$money_saved[si] <- as.character(round(num(s$money_saved[si]) + total))
  s$eco_points[si]  <- as.character(round(num(s$eco_points[si]) + days))
  wr(bw, "borrowings.csv"); wr(od, "orders.csv"); wr(it, "items.csv"); wr(s, "students.csv")
  refresh()
  list(success = TRUE, message = paste("Successfully borrowed", it$item_name[ii]), borrow_id = bid, order_id = oid,
       item = it$item_name[ii], days = days, rent_per_day = rate, total_amount = total, payment_method = pay,
       receipt_url = paste0("/receipt/", bid, ".pdf"))
}

#* @post /return
#* @serializer json list(auto_unbox = TRUE)
function(req, res) {
  b <- parse_body(req); bid <- as.character(gv(b, "borrow_id"))
  bw <- rd("borrowings.csv"); it <- rd("items.csv"); i <- which(bw$borrow_id == bid)
  if (length(i) == 0) return(fail(res, "Borrowing record not found.", 404))
  i <- i[1]; bw$returned[i] <- "TRUE"; bw$return_date[i] <- as.character(Sys.Date()); wr(bw, "borrowings.csv")
  k <- which(it$item_id == bw$item_id[i])
  if (length(k) > 0) { it$status[k[1]] <- "Available"; wr(it, "items.csv") }
  refresh()
  list(success = TRUE, message = "Item returned successfully.", borrow_id = bid)
}

#* @post /reserve
#* @serializer json list(auto_unbox = TRUE)
function(req, res) {
  b <- parse_body(req); sid <- as.character(gv(b, "student_id")); iid <- as.character(gv(b, "item_id"))
  r <- rd("reservations.csv"); it <- rd("items.csv")
  if (!(iid %in% it$item_id)) return(fail(res, "Item not found.", 404))
  rid <- next_id(r$reservation_id, "RES")
  r <- add_row(r, list(reservation_id = rid, student_id = sid, item_id = iid, reservation_date = as.character(Sys.Date()),
                       days = as.integer(as.numeric(gv(b, "days", 1))), status = "Active"))
  wr(r, "reservations.csv")
  list(success = TRUE, message = "Item reserved successfully.", reservation_id = rid)
}

# ------------------------------------------------------------ smart lockers
#* @post /generate-locker-otp
#* @serializer json list(auto_unbox = TRUE)
function(req, res) {
  b <- parse_body(req); iid <- as.character(gv(b, "item_id"))
  l <- rd("lockers.csv"); i <- which(l$item_id == iid)
  if (length(i) == 0) i <- which(tolower(l$status) == "available")
  if (length(i) == 0) return(fail(res, "No lockers available.", 404))
  i <- i[1]; otp <- sprintf("%04d", sample(0:9999, 1)); l$otp[i] <- otp; l$status[i] <- "Awaiting Pickup"; wr(l, "lockers.csv")
  list(success = TRUE, message = "Smart locker OTP generated.", locker_id = l$locker_id[i], location = l$location[i], otp = otp)
}

#* @post /unlock-locker
#* @serializer json list(auto_unbox = TRUE)
function(req, res) {
  b <- parse_body(req); lid <- as.character(gv(b, "locker_id")); otp <- as.character(gv(b, "otp"))
  l <- rd("lockers.csv"); i <- which(l$locker_id == lid)
  if (length(i) == 0) return(fail(res, "Locker not found.", 404))
  i <- i[1]
  if (otp == "" || l$otp[i] != otp) return(fail(res, "Invalid OTP.", 401))
  l$status[i] <- "Unlocked"; wr(l, "lockers.csv")
  list(success = TRUE, message = "Locker unlocked successfully.", locker_id = lid)
}

# ------------------------------------------------------------ PDFs
#* @get /receipt/<bid>
#* @serializer contentType list(type = "application/pdf")
function(bid, res) {
  bid <- sub("\\.pdf$", "", bid); j <- joined(); r <- j[j$borrow_id == bid, , drop = FALSE]
  if (nrow(r) == 0) { res$status <- 404; return(raw(0)) }
  res$setHeader("Content-Disposition", paste0('attachment; filename="Receipt_', bid, '.pdf"'))
  pdf_receipt(r[1, ])
}

#* @get /statement/<sid>
#* @serializer contentType list(type = "application/pdf")
function(sid, res) {
  j <- joined(); j <- j[j$student_id == sid, , drop = FALSE]; j <- j[order(j$date), , drop = FALSE]
  res$setHeader("Content-Disposition", paste0('attachment; filename="Statement_', sid, '.pdf"'))
  pdf_statement(sid, j)
}

#* @get /report.pdf
#* @serializer contentType list(type = "application/pdf")
function(res) {
  res$setHeader("Content-Disposition", 'attachment; filename="Borrow_A_Thing_Analytics_Report.pdf"')
  pdf_report(kpis())
}

# ------------------------------------------------------------ graphics
#* @get /graphics
#* @serializer json list(auto_unbox = TRUE)
function() {
  ensure_charts()   # rebuilds only if data changed since the last build
  list(success = TRUE, charts = CHARTS$meta, running = FALSE, updated = CHARTS$updated)
}

#* @post /graphics/generate
#* @get /graphics/generate
#* @serializer json list(auto_unbox = TRUE)
function(student_id = "") {
  ensure_charts(force = TRUE)
  if (student_id != "") tryCatch(build_user(student_id), error = function(e) NULL)
  list(success = TRUE, message = "Graphics generated")
}

#* @get /graphics/user/<f>
#* @serializer contentType list(type = "image/png")
function(f, res) {
  p <- file.path(GFX_DIR, "user", basename(f))
  if (!file.exists(p)) { res$status <- 404; return(raw(0)) }
  file_raw(p)
}

#* @get /graphics/<f>
#* @serializer contentType list(type = "image/png")
function(f, res) {
  p <- file.path(GFX_DIR, basename(f))
  if (!file.exists(p)) { res$status <- 404; return(raw(0)) }
  file_raw(p)
}

# ------------------------------------------------------------ downloads
#* @get /tableau/<f>
#* @serializer contentType list(type = "text/csv")
function(f, res) {
  p <- file.path(TABLEAU_DIR, basename(f))
  if (!file.exists(p)) { res$status <- 404; return(raw(0)) }
  res$setHeader("Content-Disposition", paste0('attachment; filename="', basename(f), '"'))
  file_raw(p)
}

#* @get /download/<f>
#* @serializer contentType list(type = "text/csv")
function(f, res) {
  ok <- c("borrowings.csv", "items.csv", "category_analysis.csv", "item_analysis.csv", "analytics_summary.csv", "reservations.csv", "orders.csv")
  if (!(f %in% ok)) { res$status <- 403; return(raw(0)) }   # students.csv (passwords) is never exposed
  res$setHeader("Content-Disposition", paste0('attachment; filename="', f, '"'))
  file_raw(file.path(DATA_DIR, f))
}

#* @get /category-analysis-csv
#* @serializer contentType list(type = "text/csv")
function() file_raw(file.path(DATA_DIR, "category_analysis.csv"))

#* @get /item-analysis-csv
#* @serializer contentType list(type = "text/csv")
function() file_raw(file.path(DATA_DIR, "item_analysis.csv"))

#* @get /analytics-summary-csv
#* @serializer contentType list(type = "text/csv")
function() file_raw(file.path(DATA_DIR, "analytics_summary.csv"))
