## =============================================================================
# PURPOSE:
#   Creates Kable and LaTeX tables for mechanisms/LBD analysis using regression
#   output tables.
#
# INPUTS:
#   - "mechanism_prod_interactions_results_estout.csv" (Regression output CSV)
#
# OUTPUTS:
#   - industry_lbd_mechanism_kable (LaTeX formatted Kable table)
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS.-----------------------------------------------
## ========================================================================== ##

font_size_argument <- 7
table_caption_string <- "Industry-Level Learning by Treatment Status"
table_label_string <- "lbdindustry"

footnote_string <-  "This table shows the industry-level relationship between 
industrial outcomes and (log) Experience in targeted vs. non-targeted industries. 
Estimates come from equation \\\\eqref{eq:lbdindustry}. The analysis is for the 
post-1972 period, using the 5-digit industry panel. The outcomes are log Unit Cost 
(total intermediate costs per unit of real gross output) and TFP, estimated using 
Ackerberg-Caves-Frazer (ACF), Levinsohn-Petrin (LP), and Wooldridge (W) methods. 
(log) Experience is measured as cumulative output (the sum of real gross output 
until the current year). All equations control for size/scale, measured as (log) 
industry employment and (log) average plant size. Additional controls include 
log: capital intensity, investment per worker, and intermediate input intensity 
per worker. Linear Combination, at the bottom, gives the combined effects. All 
specifications are estimated using industry and year fixed effects. Standard errors 
are clustered at the industry level. * Significant at the 10 percent level. 
** Significant at the 5 percent level. *** Significant at the 1 percent level."

footnote_string <- gsub("\n", " ", footnote_string)


## ========================================================================== ##
# II. SUB-FUNCTIONS: Helper and sub-helper functions. -----------------------
## ========================================================================== ##

## A. GET ROW INDICES BY REGEX -------------------------------------------------
# Retrieves row indices from a dataset where the first column matches the regex pattern.
# 
# @param dataset Data frame to search within.
# @param regex_string Regular expression pattern to match.
# @return Integer vector of matching row indices.
get_rows_helper <- function(dataset, regex_string) {
  
  row_indices <- grepl(regex_string, dataset[[1]]) %>%
    which()
  
  return(row_indices)
}

## B. FIND TFP ROWS -----------------------------------------------------------#
# Identifies rows in a data frame that contain "tfp" in any column.
# 
# @param df Data frame to search within.
# @return Integer vector of row indices containing "tfp".
find_tfp_rows <- function(df) {
  
  row_indices <- apply(df, 1, function(row) {
    any(grepl("tfp", row))
  })
  
  return(which(row_indices))
}

## C. LOAD AND CLEAN ESTOUT TABLE ---------------------------------------------#
# Loads an ESTOUT CSV file, cleans the data, and performs validation tests.
# 
# @param table_file Name of the ESTOUT CSV file to load.
# @return Cleaned data frame.
load_and_clean_estout_table <- function(table_file) {
  
  dataset <- file.path(intermediate_dir, table_file) %>%
    read.csv(sep = "\t", header = TRUE)
  
  # Ensure the dataset is not empty
  test_that("Prepared data.frame is not empty", {
    expect_equal(plyr::empty(dataset), FALSE)
  })
  
  # Clean column names by removing specific patterns
  names(dataset) <- stringr::str_replace_all(names(dataset), "[._aA-zZ]", "")
  
  # Clean row strings with specific replacements
  dataset[[1]] <- stringr::str_replace_all(
    dataset[[1]],
    c(
      "(_n)|(l|h)_|^(l|h)" = "",
      "_" = " ",
      "[Ee]xperience" = "Experience",
      "[Ee]xperience.*[Ee]xport" = "Experience (Export)",
      "(.*hci\\#.*[Ee]xperience|.*[Ee]xperience\\#.*hci)$" = "Targeted \\\\(\\\\times\\\\) Experience"
    )
  )
  
  # Remove duplicate rows
  dataset <- dataset[!duplicated(dataset), ]
  
  # Verify the cleaned dataset is not empty
  test_that("Prepared data.frame is empty.", {
    expect_equal(plyr::empty(dataset), FALSE)
  })
  return(dataset)
}

## ========================================================================== ##
# III. MAKING THE KABLE TABLE. ------------------------------------------------  
## ========================================================================== ##

## ========================================================================== ##
## 1. PREPARE THE TABLES -------------------------------------------------------
## ========================================================================== ##

### A. LOAD AND PREPARE DATASET ----------------------------------------------
# Generate cleaned ESTOUT tables.
output_file <- "mechanism_prod_interactions_results_estout.csv"

# Load and clean the ESTOUT table
dataset <- load_and_clean_estout_table(output_file)


### B. ADD VARIABLE NAMES TO EACH DATASET --------------------------------------
# Determine the number of regression columns
num_regs <- ncol(dataset) - 1

# Generate column names with numbering
number_list <- c("", paste0("(", 1:num_regs, ")"))

# Create a blank list for the first row
blank_list <- rep("", num_regs + 1)

# Validate the number of columns matches the expected length
testthat::expect_equal(length(number_list), ncol(dataset))

# Replace the first row with blanks
dataset[1, ] <- blank_list


## Create header lists with column spans
header_list <- c(
  " " = 1, 
  " " = 4, 
  "Total Factor Productivity" = 6
)

subheader_list <- c(
  " " = 1, 
  "Prices (log)" = 2, 
  "Unit cost (log)" = 2, 
  "(ACF)" = 2,
  "(LP)" = 2,
  "(W)" = 2
)

### C. GET ROW INDICES FOR TABLE -----------------------------------------------
# Identify start and end rows for control and fixed effects sections

# Control rows
controls_start <- min(get_rows_helper(dataset, "[Cc]ontrols"))
controls_end <- max(get_rows_helper(dataset, "[Cc]ontrols"))

# Fixed Effects rows
effects_start <- min(get_rows_helper(dataset, "^[Ii]nd"))
effects_end <- max(get_rows_helper(dataset, "^[Ii]nd"))

# Linear combination rows
start_linear_combo <- min(get_rows_helper(dataset, "[Ll]inear"))
end_linear_combo <- max(get_rows_helper(dataset, "[Sst.][EeRr.]"))

# Combine all relevant row indices
row_indices <- c(
  controls_start, controls_end, 
  effects_start, effects_end, 
  start_linear_combo, end_linear_combo
)

# Verify all row indices are integers
test_that("All elements of the vector are integers", {
  expect_true(all(row_indices == floor(row_indices)),
              info = "Not all elements of the vector are integers")
})

# Define column alignment for the table
column_alignment <- c("l", rep("c", num_regs))


## ========================================================================== ##
## 2. MAKE THE KABLE TABLE -----------------------------------------------------
## ========================================================================== ##

industry_lbd_mechanism_kable <- dataset %>%
  
  # Make the table
  knitr::kable(
    format = "latex", 
    longtable = FALSE,
    booktabs = TRUE, 
    row.names = FALSE,
    escape = FALSE,
    align = column_alignment,
    col.names = number_list,
    caption = table_caption_string,
    label = table_label_string 
  ) %>%
  
  # Style the table
  kableExtra::kable_styling(
    latex_options = c("scale_down"), 
    font_size = font_size_argument
  ) %>%
  
  # Add subheaders to the table
  kableExtra::add_header_above(
    subheader_list, 
    align = "c", 
    include_empty = FALSE, 
    line = TRUE,
    bold = FALSE,
    font_size = font_size_argument + 1
  ) %>%
  
  # Add main headers to the table
  kableExtra::add_header_above(
    header_list, 
    align = "c", 
    include_empty = FALSE, 
    line = TRUE,
    bold = FALSE,
    font_size = font_size_argument + 1 
  ) %>%
  
  # Group control rows
  kableExtra::group_rows(
    " ",
    start_row = controls_start,
    end_row = controls_end,
    indent = TRUE,
    latex_align = "c",
    latex_wrap_text = TRUE,
    hline_before = FALSE,
    hline_after = FALSE,
    latex_gap_space = "0.5em"
  ) %>%
  
  # Group fixed effects rows
  kableExtra::group_rows(
    " ",
    start_row = effects_start,
    end_row = nrow(dataset),
    indent = TRUE,
    hline_before = FALSE,
    hline_after = FALSE,
    latex_gap_space = "0.5em"
  ) %>%
  
  # Add the linear combination rows
  kableExtra::group_rows(
    " ",
    start_row = start_linear_combo,
    end_row = end_linear_combo,
    indent = FALSE,
    latex_wrap_text = TRUE,
    hline_before = TRUE,
    hline_after = FALSE,
    latex_gap_space = "0.5em"
  ) %>%
  
  # Add space after the last row
  kableExtra::row_spec(
    nrow(dataset) + 1, 
    extra_latex_after = "\\addlinespace[1em]"
  ) %>%
  
  # Add footnotes to the table
  kableExtra::footnote(
    general = footnote_string, 
    general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
    escape = FALSE,
    footnote_as_chunk = TRUE,
    threeparttable = TRUE 
  )
                  
## ========================================================================== ##
## 3. SAVE THE KABLE TABLE ------------------------------------------------------
## ========================================================================== ##

output_file <- file.path( tables_dir, 
                      "industry_lbd_mechanism_kable.tex")
                      
cat(industry_lbd_mechanism_kable, file = output_file)

testthat::test_that("Industry LBD kable is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})
