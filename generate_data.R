# ============================================================
# BORROW A THING
# CSV DATABASE GENERATOR
# Creates 200 demo records
# ============================================================

set.seed(2026)

dir.create("data", showWarnings = FALSE)

# ============================================================
# BASIC DATA
# ============================================================

first_names <- c(
  "Aarav","Vivaan","Aditya","Arjun","Reyansh",
  "Krishna","Ishaan","Kabir","Rohan","Rahul",
  "Ananya","Diya","Aanya","Myra","Ira",
  "Sara","Meera","Kiara","Avni","Nisha"
)

last_names <- c(
  "Sharma","Verma","Kaur","Singh","Kumar",
  "Gupta","Malhotra","Arora","Kapoor","Mehta"
)

departments <- c(
  "Computer Science",
  "Information Technology",
  "Electronics",
  "Mechanical",
  "Commerce",
  "Management",
  "Physics",
  "Mathematics"
)

categories <- c(
  "Books",
  "Electronics",
  "Calculators",
  "Lab Equipment",
  "Stationery",
  "Project Kits",
  "Tablets",
  "Accessories"
)

conditions <- c(
  "Excellent",
  "Good",
  "Very Good",
  "Fair"
)

icons <- c(
  "📚",
  "💻",
  "🧮",
  "🔬",
  "✏️",
  "🛠️",
  "📱",
  "🎧"
)

item_names <- c(
  "Programming in C",
  "Data Structures Book",
  "Computer Networks",
  "Operating Systems",
  "DBMS Complete Guide",
  "Python Programming",
  "Java Programming",
  "Web Development",
  "Discrete Mathematics",
  "Computer Graphics",
  "Scientific Calculator",
  "Casio Calculator",
  "Arduino Kit",
  "Raspberry Pi",
  "Laptop",
  "Tablet",
  "Keyboard",
  "Mouse",
  "USB Hub",
  "Headphones",
  "Projector",
  "Breadboard Kit",
  "Multimeter",
  "Physics Lab Kit",
  "Chemistry Lab Kit",
  "Engineering Drawing Kit",
  "Presentation Clicker",
  "HDMI Cable",
  "Webcam",
  "Microphone"
)

# ============================================================
# STUDENTS - 200
# ============================================================

students <- data.frame(
  student_id = sprintf("STU%03d", 1:200),
  name = paste(
    sample(first_names, 200, replace = TRUE),
    sample(last_names, 200, replace = TRUE)
  ),
  email = paste0(
    "student",
    1:200,
    "@borrowathing.com"
  ),
  password = "1234",
  department = sample(
    departments,
    200,
    replace = TRUE
  ),
  year = sample(
    c("1st Year","2nd Year","3rd Year","Final Year"),
    200,
    replace = TRUE
  ),
  reliability_score = sample(
    65:100,
    200,
    replace = TRUE
  ),
  money_saved = sample(
    100:5000,
    200,
    replace = TRUE
  ),
  eco_points = sample(
    10:1000,
    200,
    replace = TRUE
  ),
  stringsAsFactors = FALSE
)

# Demo login
students$email[1] <- "student@example.com"
students$password[1] <- "1234"
students$name[1] <- "Demo Student"

write.csv(
  students,
  "data/students.csv",
  row.names = FALSE
)

# ============================================================
# ITEMS - 200
# ============================================================

items <- data.frame(
  item_id = sprintf("ITM%03d", 1:200),
  item_name = sample(
    item_names,
    200,
    replace = TRUE
  ),
  category = sample(
    categories,
    200,
    replace = TRUE
  ),
  condition = sample(
    conditions,
    200,
    replace = TRUE
  ),
  rent_per_day = sample(
    c(10,20,30,40,50,75,100,150,200,250),
    200,
    replace = TRUE
  ),
  status = sample(
    c(
      "Available",
      "Available",
      "Available",
      "Borrowed",
      "Reserved"
    ),
    200,
    replace = TRUE
  ),
  owner_id = sample(
    students$student_id,
    200,
    replace = TRUE
  ),
  icon = sample(
    icons,
    200,
    replace = TRUE
  ),
  location = sample(
    c(
      "Library",
      "Block A",
      "Block B",
      "Lab 1",
      "Lab 2",
      "Innovation Centre",
      "Locker Room"
    ),
    200,
    replace = TRUE
  ),
  stringsAsFactors = FALSE
)

write.csv(
  items,
  "data/items.csv",
  row.names = FALSE
)

# ============================================================
# BORROWINGS - 200
# ============================================================

start_date <- as.Date("2026-01-01")
end_date <- as.Date("2026-09-23")

borrowings <- data.frame(
  borrow_id = sprintf("BRW%03d", 1:200),
  student_id = sample(
    students$student_id,
    200,
    replace = TRUE
  ),
  item_id = sample(
    items$item_id,
    200,
    replace = TRUE
  ),
  borrow_date = sample(
    seq(start_date, end_date, by = "day"),
    200,
    replace = TRUE
  ),
  days = sample(
    1:15,
    200,
    replace = TRUE
  ),
  returned = sample(
    c(TRUE, TRUE, TRUE, FALSE),
    200,
    replace = TRUE
  ),
  payment_method = sample(
    c(
      "Demo UPI",
      "Cash",
      "Card",
      "Wallet"
    ),
    200,
    replace = TRUE
  ),
  stringsAsFactors = FALSE
)

borrowings$return_date <- ifelse(
  borrowings$returned,
  as.character(
    borrowings$borrow_date +
      borrowings$days
  ),
  NA
)

borrowings$borrow_date <- as.character(
  borrowings$borrow_date
)

write.csv(
  borrowings,
  "data/borrowings.csv",
  row.names = FALSE
)

# ============================================================
# RESERVATIONS - 200
# ============================================================

reservations <- data.frame(
  reservation_id = sprintf("RES%03d", 1:200),
  student_id = sample(
    students$student_id,
    200,
    replace = TRUE
  ),
  item_id = sample(
    items$item_id,
    200,
    replace = TRUE
  ),
  reservation_date = as.character(
    sample(
      seq(
        as.Date("2026-01-01"),
        as.Date("2026-09-23"),
        by = "day"
      ),
      200,
      replace = TRUE
    )
  ),
  days = sample(
    1:10,
    200,
    replace = TRUE
  ),
  status = sample(
    c(
      "Active",
      "Completed",
      "Cancelled"
    ),
    200,
    replace = TRUE
  ),
  stringsAsFactors = FALSE
)

write.csv(
  reservations,
  "data/reservations.csv",
  row.names = FALSE
)

# ============================================================
# LOCKERS - 200
# ============================================================

lockers <- data.frame(
  locker_id = sprintf("LCK%03d", 1:200),
  item_id = items$item_id,
  location = sample(
    c(
      "Library Locker Area",
      "Block A Locker Area",
      "Block B Locker Area",
      "Smart Locker Zone"
    ),
    200,
    replace = TRUE
  ),
  status = sample(
    c(
      "Available",
      "Occupied",
      "Available",
      "Available"
    ),
    200,
    replace = TRUE
  ),
  otp = sprintf(
    "%04d",
    sample(
      1000:9999,
      200,
      replace = TRUE
    )
  ),
  stringsAsFactors = FALSE
)

write.csv(
  lockers,
  "data/lockers.csv",
  row.names = FALSE
)

# ============================================================
# CATEGORY ANALYSIS
# ============================================================

category_count <- table(
  items$category
)

category_analysis <- data.frame(
  category = names(category_count),
  total_items = as.integer(category_count),
  stringsAsFactors = FALSE
)

write.csv(
  category_analysis,
  "data/category_analysis.csv",
  row.names = FALSE
)

# ============================================================
# ITEM ANALYSIS
# ============================================================

item_analysis <- data.frame(
  item_id = items$item_id,
  item_name = items$item_name,
  category = items$category,
  borrow_count = sample(
    0:30,
    200,
    replace = TRUE
  ),
  average_days = round(
    runif(200, 1, 15),
    2
  ),
  stringsAsFactors = FALSE
)

write.csv(
  item_analysis,
  "data/item_analysis.csv",
  row.names = FALSE
)

# ============================================================
# ANALYTICS SUMMARY
# ============================================================

total_students <- nrow(students)
total_items <- nrow(items)
total_borrowings <- nrow(borrowings)

mean_days <- mean(
  borrowings$days
)

money_saved <- sum(
  students$money_saved
)

eco_points <- sum(
  students$eco_points
)

analytics_summary <- data.frame(
  metric = c(
    "total_students",
    "total_items",
    "total_borrowings",
    "mean_days",
    "money_saved",
    "eco_points"
  ),
  value = c(
    total_students,
    total_items,
    total_borrowings,
    mean_days,
    money_saved,
    eco_points
  ),
  stringsAsFactors = FALSE
)

write.csv(
  analytics_summary,
  "data/analytics_summary.csv",
  row.names = FALSE
)

cat("\n========================================\n")
cat("BORROW A THING DATA GENERATED\n")
cat("========================================\n")
cat("Students       :", nrow(students), "\n")
cat("Items          :", nrow(items), "\n")
cat("Borrowings     :", nrow(borrowings), "\n")
cat("Reservations   :", nrow(reservations), "\n")
cat("Lockers        :", nrow(lockers), "\n")
cat("========================================\n")
cat("Login:\n")
cat("Email    : student@example.com\n")
cat("Password : 1234\n")
cat("========================================\n")