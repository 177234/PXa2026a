## =============================================================================
# PURPOSE:
#   Creates LaTeX tables for mechanisms/LBD analysis by processing regression
#   output located in the /analysis directory.
#
# INPUTS:
#   - "mechanism_prod_micro_results_estout.csv" (Regression output CSV)
#
# OUTPUTS:
#   - plant_lbd_mechanism_kable (LaTeX formatted Kable table)
# ==============================================================================


# I. TEXT AND TABLE ARGUMENTS --------------------------------------------------

font_size_argument <- 9
table_caption_string <- "Plant and Industry-Level Learning by Treatment Status"
table_label_string <- "lbdmicro"

footnote_string <- "This table shows the plant-level relationship between industrial
development and (log) Experience in targeted vs. non-targeted industries. Estimates
come from a plant-level version of equation \\\\eqref{eq:lbdindustry}. 
Outcomes are the following: log Unit Cost (total intermediate costs per unit 
of real gross output) and TFP (estimated using Ackerberg-Caves-Frazer). 
Experience is measured as cumulative output (the sum of real gross output 
until the current year). 'Plant Experience' refers to plant-level cumulative 
learning, and 'Industry Experience' refers to industry-level learning, 
calculated at the 4-digit industry level. All equations control for log 
plant size (employment). Additional controls include log: capital intensity, 
skill ratio, investment per worker, and intermediate input intensity per 
worker. Linear Combination, at the bottom, gives the combined effects. All 
specifications are estimated using plant, industry, and year fixed effects. 
'Polynomial Controls' adds cubic polynomials in the control variables. Two-way 
standard errors are clustered at the industry and plant levels. * Significant 
at the 10 percent level. ** Significant at the 5 percent level. *** Significant 
at the 1 percent level."

footnote_string <- gsub("\n", " ", footnote_string)


# II. SUB-FUNCTIONS: Helper and Sub-Helper Functions ---------------------------

# A. Get Rows Helper Function --------------------------------------------------
get_rows_helper <- function(dataset, regex_pattern) {
  row_indices <- grep(regex_pattern, dataset[[1]])
  return(row_indices)
}

# B. Find TFP Rows Function ----------------------------------------------------
find_tfp_rows <- function(df) {
  tfp_logical <- apply(df, 1, function(row) any(grepl("tfp", row, ignore.case = TRUE)))
  return(which(tfp_logical))
}

# C. Load and Clean Estout Table Function --------------------------------------
load_and_clean_estout_table <- function(table_file) {
  dataset_path <- file.path(included_dir, table_file)
  dataset <- read.csv(file = dataset_path, sep = "\t", header = TRUE, stringsAsFactors = FALSE)
  
  # Unit Test: Dataset should not be empty
  testthat::test_that("Prepared data.frame is not empty", {
    testthat::expect_false(nrow(dataset) == 0)
  })
  
  # Clean column names by removing special characters and spaces
  cleaned_names <- stringr::str_replace_all(names(dataset), "[._aA-zZ]", "")
  names(dataset) <- cleaned_names
  
  # Clean first column strings
  dataset[[1]] <- stringr::str_replace_all(dataset[[1]], c(
    "(_n)" = "",
    "(l|h)_" = "",
    "_" = " ",
    "^(l|h)" = "",
    "[Rr].*[Ss]quared" = "R2"
  ))
  
  # Remove duplicate rows
  dataset <- dataset[!duplicated(dataset), ]
  
  # Unit Test: Dataset should not be empty after cleaning
  testthat::test_that("Prepared data.frame is empty.", {
    testthat::expect_false(nrow(dataset) == 0)
  })
  
  return(dataset)
}

# III. MAKING THE KABLE TABLE --------------------------------------------------

# A. Load and Prepare Dataset --------------------------------------------------

# Define the ESTOUT file name
estout_file <- "mechanism_prod_micro_results_estout.csv"

# Load and clean the ESTOUT dataset
dataset <- load_and_clean_estout_table(estout_file)

# Adjust column names and count
n_cols <- ncol(dataset) - 1
names(dataset) <- c("", paste0("(", seq_len(n_cols), ")"))

# Remove top rows containing "tfp" if present
tfp_row <- max(find_tfp_rows(dataset))
if (!is.infinite(tfp_row) && !is.nan(tfp_row)) {
  dataset <- dataset[-c(1:tfp_row), ]
} else {
  dataset <- dataset[-1, ]
}

# B. Get Index and Dimensions for Styling Table -------------------------------

# Number of columns after adjustment
n_cols <- ncol(dataset) - 1

# Indices for table styling
start_controls <- min(get_rows_helper(dataset, "[Cc]ontrol"))
end_controls <- max(get_rows_helper(dataset, "[Cc]ontrol"))

start_extra_stats <- min(get_rows_helper(dataset, "[Ee]ffect"))
end_extra_stats <- min(get_rows_helper(dataset, "^[Cc]luster"))

start_linear_combo <- min(get_rows_helper(dataset, "^[Cc]luster")) + 1
end_linear_combo <- max(get_rows_helper(dataset, "[Sst.][EeRr.]"))

# Aggregate all relevant row indices into a vector
row_indices_vector <- c(
  start_controls, end_controls, 
  start_extra_stats, end_extra_stats, 
  start_linear_combo, end_linear_combo
)

# Unit Test: Ensure all row indices are integers
testthat::test_that("All elements of the vector are integers", {
  testthat::expect_true(all(row_indices_vector == floor(row_indices_vector)), 
                        info = "Not all elements of the vector are integers")
})

# Define column alignment
column_alignment <- c("l", rep("c", n_cols))

# C. Make Kable Table ---------------------------------------------------------

plant_lbd_mechanism_kable <- knitr::kable(
                                  dataset,
                                  format = "latex",
                                  booktabs = TRUE,
                                  longtable = FALSE,
                                  row.names = FALSE,
                                  escape = FALSE,
                                  align = column_alignment,
                                  caption = table_caption_string,
                                  label = table_label_string,
                                  linesep = "") %>%
  
  kableExtra::group_rows(
    " ",
    start_row = start_controls,
    end_row = end_controls,
    latex_wrap_text = TRUE,
    hline_before = FALSE,
    hline_after = FALSE,
    latex_gap_space = "0.5em"
  ) %>%
  
  kableExtra::group_rows(
    " ",
    start_row = start_extra_stats,
    end_row = end_extra_stats,
    latex_wrap_text = TRUE,
    hline_before = FALSE,
    hline_after = FALSE,
    latex_gap_space = "0.5em"
  ) %>%
  
  kableExtra::group_rows(
    " ",
    start_row = start_linear_combo,
    end_row = end_linear_combo,
    latex_wrap_text = TRUE,
    hline_before = TRUE,
    hline_after = FALSE,
    latex_gap_space = "0.5em"
  ) %>%
  
  kableExtra::add_header_above(
    c(" " , "Unit cost (log)" = n_cols / 2, "TFP" = n_cols / 2),
    line = TRUE,
    font_size = font_size_argument + 1
  ) %>%
  
  kableExtra::kable_styling(
    latex_options = c("scale_down"),
    protect_latex = TRUE,
    repeat_header_text = "\\textit{(continued)}",
    repeat_header_continued = TRUE,
    full_width = FALSE,
    table.envir = "table",
    font_size = font_size_argument
  ) %>%
  
  # Add space after the last row
  row_spec(
    nrow(dataset) + 1, 
    extra_latex_after = "\\addlinespace[1em]"
  ) %>%
  
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

output_file <- file.path(
  tables_dir,
  "plant_lbd_mechanism_kable.tex"
)

cat(plant_lbd_mechanism_kable, file = output_file)

testthat::test_that("Plant LBD kable is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})