## =============================================================================
# PURPOSE:
#   Creates a comparison table showing sectors targeted by South Korea's HCI and
#   earlier Japanese industrial policies.
#
# INPUTS:
#   - japan_legalact_table.csv
#
# OUTPUTS:
#   - japansectoractlisttable.tex
# ==============================================================================


## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS -----------------------------------------------
## ========================================================================== ##

# Set font size for the table in LaTeX
font_size_argument <- 7

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')

footnotestring <- "This table shows a comparison of broad sectors targeted by South Korea's HCI and the sectors targeted by earlier Japanese industrial policies. Table compares major sectoral legislation and industrial policy action from HCI to the tables and legislation presented by Ozaki (1998) and Yoshioka and Kawasaki (2016). Japanese sectoral targeting corresponds to Japanese Five-Year Plan for Economic Self-Support and Industrial Policy."

tablelabelstring <- "suppappendixjapanlist"

tablecaptionstring <- "Japanese Targeting (1950s) v. South Korean Heavy-Chemical Industry Targeting (1970s)"


## ========================================================================== ##
# II. LOAD AND PREPARE DATA ---------------------------------------------------
## ========================================================================== ##

## A. Load Data -----------------------------------------------------------------

# Load CSV data
csv_file_path <- file.path(policy_dir, "japan_legalact_table.csv")
csvdata <- read.csv(csv_file_path, header = TRUE, sep = ",")

# Check that the data is not empty
testthat::test_that("Prepared data.frame is not empty", {
  testthat::expect_false(plyr::empty(csvdata))
})

## B. Prepare Data --------------------------------------------------------------

# Subset data to include only relevant columns
csvdata <- csvdata[1:4]

# Generate alignment string for LaTeX (e.g., "lcccc")
num_regs <- ncol(csvdata) - 1
alignstring <- c("l", rep("l", num_regs))

# Make labels more descriptive
listofnamesfull <- c(
  "Sector",
  "Korea 1970s",
  "Japan 1950s",
  "Japan Industrial Policy"
)

last_col <- ncol(csvdata)

names(csvdata) <- listofnamesfull
## ========================================================================== ##
# III. MAKE THE TABLE --------------------------------------------------------
## ========================================================================== ##

# Create LaTeX table using kable
japan_korea_kable <- knitr::kable(
  csvdata,
  format = "latex",
  booktabs = TRUE,
  longtable = TRUE,
  row.names = FALSE,
  label = tablelabelstring,
  caption = tablecaptionstring
) %>%
  # Apply styling to the table
  kableExtra::kable_styling(
    latex_options = c("scale_down"),
    font_size = font_size_argument,
    full_width = FALSE,
    position = "center"
  ) %>%

  # Add footnote to the table
  kableExtra::footnote(
    general = footnotestring,
    general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
    footnote_as_chunk = TRUE,
    threeparttable = TRUE,
    escape = FALSE
  )

## ========================================================================== ##
## IV. SAVE THE KABLE TABLE ------------------------------------------------------
## ========================================================================== ##

output_file <- file.path( tables_supplementalappendix_dir, 
                          "japansectoractlisttable.tex")

cat(japan_korea_kable, file = output_file)

testthat::test_that("Japan Act kable is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})
