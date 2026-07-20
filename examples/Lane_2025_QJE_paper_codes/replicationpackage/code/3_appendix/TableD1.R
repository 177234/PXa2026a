## ========================================================================== ###
#   PURPOSE: 
#
#        Generates tables for mechanisms/LBD robustness analysis within 
#        the industry analysis. This script focuses on table creation functions.
#
#   INPUTS:
#   
#       - mechanism_prod_interactions_alt_results_estout.csv     
#
#   OUTPUTS:
#
#       - industry_lbd_robust_mechanism for KABLE rendering
#
## ==============================  TOP MATTER ==============================  ##

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS -------------------------------------------------
## ========================================================================== ##

font_size_argument <- 9
table_caption_string <- "Robustness: Learning in Industrial-Level Data, by Treatment Status"
table_label_string <- "appendixindustrylbd"
footnote_string <- "This table shows the robustness of industry-level estimates from equation (5) for alternative outcomes. 
Unit Cost is the baseline unit cost measure: (log) total real intermediate cost per real gross
output; Unit Cost (revenue) is measured using total real intermediate costs per 
unit of real revenue. TFP outcomes are estimated using Ackerberg-Caves-Frazer 
(ACF), Levinsohn-Petrin (LP), Olley-Pakes (OP), and Wooldridge (W) methods. 
Table shows estimates for each outcome using two alternative Experience measures:
(log) Experience per worker, and Experience (alternative), which is experience 
calculated using cumulative value added units. All equations control for size and scale: 
(log) average plant size and total industry employment. Additional controls include 
(log): capital intensity, skill ratio, investment per worker, and intermediate 
input intensity per worker. Linear Combination, at the bottom, gives the combined
effects for Experience for targeted industries. All specifications are estimated 
using industry and year fixed effects. Standard errors are clustered at the industry level."

# This remove linebreaks in footnote string (above) just in case. 
footnote_string <- gsub( "\\n" , " " , footnote_string )

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')

## ========================================================================== ##
# II. SUB-FUNCTIONS: Helper and sub-helper functions ------------------------
## ========================================================================== ##

# Helper function to retrieve row indices based on a regex pattern
get_rows_helper <- function(dataset, regex_pattern) {
  which(grepl(regex_pattern, dataset[[1]]))
}

## ========================================================================== ##
# III. LOAD AND PREPARE TABLE DATA ----------------------------------------------
## ========================================================================== ##

## A. LOAD DATA ---------------------------------------------------------------

output_file <- "mechanism_prod_interactions_alt_results_estout.csv"

# Read the CSV into a dataframe
dataset <- file.path(intermediate_dir, output_file) %>%
  read.csv(sep = "\t")

# Ensure the dataset is not empty
test_that("Filtered table is not empty", {
  expect_false(plyr::empty(dataset))
})

## B. CLEAN DATA --------------------------------------------------------------

# Define patterns for cleaning
pattern_replace_first_col <- c(
  "l_" = "",
  "[Ee]xperience" = "Experience",
  "(.*hci\\#.*[Ee]xperience|.*[Ee]xperience\\#.*hci)$" = "Targeted \\\\(\\\\times\\\\) Experience",
  "[Rr].*[Ss]quared" = "R2"
)

pattern_replace_header <- c(
  "l_" = "",
  "_" = " ",
  "ucr" = "Unit Cost (revenue, log)",
  "uc" = "Unit Cost (log)",
  "ppi" = "Price (log)",
  "[Tt][Ff][pP]" = "TFP",
  "op" = "(OP)",
  "acf" = "(ACF)",
  "lp" = "(LP)",
  "w" = "(W)"
)

pattern_replace_names <- c(
  "^[Xx1]$" = "", 
  "l_" = "", 
  ".[0-9]$" = "",
  "[Ee]xperience" = "Experience",
  "_" = " ",
  "alt$" = "\n(alternative)",
  "n$" = "\nper worker"
)

# Clean the first column
dataset[[1]] <- stringr::str_replace_all(dataset[[1]], pattern_replace_first_col)

# Clean the header row
dataset[1, ] <- stringr::str_replace_all(dataset[1, ], pattern_replace_header)

# Update column names
names(dataset) <- names(dataset) %>%
  stringr::str_replace_all(pattern_replace_names)

# Create measure list excluding blank entries
measure_list <- c("\\textit{Alternative measures:}", names(dataset)[names(dataset) != ""])
num_measure_values <- length(measure_list) - 1
num_unique_measure_values <- length(unique(measure_list)) - 1

# Create a named vector for measure headers
measure_header <- setNames(c(1, rep(1, num_measure_values)), measure_list)

## Make variable name list for header:

# Remove the first row containing variable names
y_values <- dataset[1, ] 
dataset <- dataset[-1, ]

# Extract unique y-values, excluding blanks
y_value_list <- c(" ", unique(y_values[y_values != ""]))
num_y_values <- length(y_value_list) - 1

# Create a named vector for outcome headers
outcome_header <- setNames(
  c(1, rep(num_unique_measure_values, num_y_values)),
  y_value_list
)

# Ensure the dataset is not empty after cleaning
test_that("Filtered table is not empty after cleaning", {
  expect_false(plyr::empty(dataset))
})

## ========================================================================== ##
# IV. MAKING THE KABLE TABLE --------------------------------------------------  
## ========================================================================== ##

## A. GET INDEX AND DIMENSIONS FOR STYLING TABLE ------------------------------

num_cols <- ncol(dataset) - 1

# Retrieve row indices for different sections using helper function
start_controls      <- min(get_rows_helper(dataset, "[Cc]ontrol"))
end_controls        <- max(get_rows_helper(dataset, "[Cc]ontrol"))
start_extra_stats   <- min(get_rows_helper(dataset, "[Ee]ffect"))
end_extra_stats     <- min(get_rows_helper(dataset, "^[Cc]luster"))
start_linear_combo   <- min(get_rows_helper(dataset, "^[Cc]luster")) + 1
end_linear_combo     <- max(get_rows_helper(dataset, "[Sst.][EeRr.]"))

# Combine indices for testing
test_vars <- c(
  start_controls, end_controls, 
  start_extra_stats, end_extra_stats, 
  start_linear_combo, end_linear_combo
)

# Validate that all indices are integers
test_that("All index variables are integers", {
  expect_true(all(test_vars == floor(test_vars)), 
              info = "Not all index variables are integers")
})

# Preserve original column names
original_column_names <- names(dataset)

# Rename columns numerically for alignment
names(dataset) <- c("", paste0("(", 1:num_cols, ")"))

# Define column alignment: first column left-aligned, others centered
column_alignment <- c("l", rep("c", num_cols))

## B. OUTPUT TABLE -------------------------------------------------------------

# Create the Kable table with LaTeX formatting
industry_lbd_robust_mechanism <- kable(
  dataset, 
  format = "latex", 
  booktabs = TRUE, 
  longtable = FALSE,
  row.names = FALSE,
  escape = FALSE,
  caption = table_caption_string,
  label = table_label_string,
  align = column_alignment,
  linesep = ""
) %>%
  # Group rows for "Controls"
  kableExtra::group_rows(
    "Controls",  
    start_row = start_controls,
    end_row = end_controls,
    latex_wrap_text = TRUE,
    latex_gap_space = "0.75em"
  ) %>% 
  # Group rows for extra statistics
  kableExtra::group_rows(
    " ",  
    start_row = start_extra_stats,
    end_row = end_extra_stats,
    latex_wrap_text = TRUE,
    hline_before = FALSE,
    hline_after = FALSE,
    latex_gap_space = "0.75em"
  ) %>% 
  # Group rows for "Combined Effects"
  kableExtra::group_rows(
    "Combined Effects",  
    start_row = start_linear_combo,
    end_row = end_linear_combo,
    latex_wrap_text = TRUE,
    hline_before = FALSE,
    hline_after = TRUE,
    latex_gap_space = "0.75em"
  ) %>%    
  # Add header above for measures
  add_header_above(
    measure_header,
    include_empty = FALSE,
    font_size = font_size_argument - 1, 
    line = FALSE
  ) %>%
  # Add header above for outcomes
  add_header_above(
    outcome_header,
    include_empty = FALSE,
    line = TRUE
  ) %>%
  # Add top-level header for outcomes
  add_header_above(
    c("", "Outcomes" = num_cols),
    line_sep = 2,
    include_empty = FALSE,
    line = TRUE
  ) %>%
  # Apply additional styling with kableExtra
  kableExtra::kable_styling(
    latex_options = c("scale_down"), 
    protect_latex = TRUE,
    repeat_header_text = "\\textit{(continued)}",
    repeat_header_continued = TRUE,
    full_width = FALSE, 
    table.envir = "table", 
    font_size = font_size_argument
  ) %>%
  # Add footnotes
  kableExtra::footnote(
    general = footnote_string, 
    general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
    footnote_as_chunk = TRUE,
    threeparttable = TRUE,
    escape = FALSE
  )

## ========================================================================== ##
# VI. SAVE THE KABLE TABLE ------------------------------------------------
## ========================================================================== ##
output_file <- file.path(
  tables_appendix_dir,
  "industry_lbd_robust_mechanism.tex"
)

cat(industry_lbd_robust_mechanism, file = output_file)

testthat::test_that("Kable table is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})
