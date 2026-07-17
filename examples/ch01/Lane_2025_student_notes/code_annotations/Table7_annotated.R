# Annotated copy for replication audit.
# Original script: Lane2025QJE/replicationpackage/code/2_tables/Table7.R
# Purpose: Generates Table 7.
#
# This file intentionally keeps the original .R extension.
# The original code is copied below. Comments in this header identify the
# script role, inputs, outputs, and audit linkage. The earlier prose note is
# archived at: markdown_notes_archive/Table7_R.md
#
# Audit linkage:
# - Methods report: explains the estimating or output logic.
# - Derivation report: maps equations/design objects to code.
# - Replication report: documents inputs, outputs, and reproducibility limits.
#
# Original code begins after this header.

## =============================================================================
# PURPOSE:
#   Creates LaTeX tables for linkage analysis by processing regression output
#   located in the /analysis directory.
#
# INPUTS:
#   - "did_io_main_prepost_bothlink_l_valueadded_5estout.csv" (Main regression output)
#   - "did_io_main_prepost_bothlink_l_valueadded_4estout.csv" (Additional regression output)
#
# OUTPUTS:
#   - avg_out_table (LaTeX formatted Kable table)
# ==============================================================================

## =============================================================================
# I. TEXT AND TABLE ARGUMENTS --------------------------------------------------
## =============================================================================

font_size_argument <- 9
table_caption_string <- "Linkage Exposure and Value Added, Before and After 1973"
table_label_string <- "prepostlinkoutput"



footnote_string <- "Average differences-in-differences estimates, before and 
after 1973. Estimates correspond to equation \\\\eqref{eq:networkflexible}. 
Regressions interact linkage measures with a Post indicator. The outcome is real 
log value added. Both linkage interactions (forward and backward) are shown. 
Analysis is performed for the sample of i) only non-treated industries and ii) 
the full sample of industries. Estimates for the full sample separately control 
for the Targeted \\\\(\\\\times\\\\) Year effects to account for the main impact 
of policy. Standard errors are clustered at the industry level. * Significant at 
the 10 percent level. ** Significant at the 5 percent level. *** Significant at 
the 1 percent level."

footnote_string <- gsub("\n", " ", footnote_string)

# ============================================================================ #
# II. SUB-FUNCTIONS: Helper and Sub-Helper Functions ---------------------------
# ============================================================================ #

# ============================================================================ #
## A. Helper Function: Load and Clean ESTOUT Table -----------------------------

#' Load and clean ESTOUT table from a CSV file.
#'
#' @param table_file The name of the CSV file to load.
#' @return A cleaned data frame.
load_and_clean_estout_table <- function(table_file) {
  
  # Construct the file path and read the CSV file
  dataset <- file.path(intermediate_dir, paste0(table_file)) %>%
    read.csv(file = ., sep = "\t", header = TRUE)
  
  # Verify that the dataset is not empty
  test_that("Prepared data.frame is not empty", {
    expect_equal(plyr::empty(dataset), FALSE)
  })
  
  # Clean column names by removing specific characters
  names(dataset) <- stringr::str_replace_all(names(dataset), "[._aA-zZ]", "")
  
  # Define regex patterns for linkage selection
  regex_forward <- "\\#c\\..*hci.*([uU]se|\\_in|orward).*0"
  regex_backward <- "\\#c\\..*hci.*([mM]ake|\\_out|ackward).*0"
  
  # Clean row strings by replacing patterns with readable labels
  dataset[, 1] <- dataset[, 1] %>%
    stringr::str_replace_all(regex_forward, "Forward Linkage") %>% 
    stringr::str_replace_all(regex_backward, "Backward Linkage") %>%
    stringr::str_replace_all("1\\.post", "Post \\\\(\\\\times\\\\) ") %>% 
    stringr::str_replace_all("1\\.Post", "Post \\\\(\\\\times\\\\) ") %>% 
    stringr::str_replace_all("postc", "Post \\\\(\\\\times\\\\) ") %>%
    stringr::str_replace_all("[Tt]argeted.*[xX].*", "Targeted \\\\(\\\\times\\\\) Year") %>%
    stringr::str_replace_all(" FE", " Effect") %>%
    stringr::str_replace_all("[Rr]2|[Rr].*squared", "\\\\(R^2\\\\)")

  # Remove duplicated rows
  dataset <- dataset[!duplicated(dataset), ]
  
  # Verify again that the dataset is not empty after cleaning
  test_that("Prepared data.frame is not empty after cleaning", {
    expect_equal(plyr::empty(dataset), FALSE)
  })
  
  return(dataset)
}

# ============================================================================ #
## B. Function to Interpret Results --------------------------------------------

#' Clean and interpret a single table entry to extract betahat.
#'
#' @param single_table_entry A list, vector, or data frame containing table entries.
#' @return The betahat value as numeric.
simple_interpretation_workflow <- function(single_table_entry) {
  
  # Extract numeric values from the character vector
  cleaned <- unlist(single_table_entry) %>%
              as.numeric() %>%
              na.omit() %>%
              as.vector()
  
  # Ensure there are enough numeric values for interpretation
  if (length(cleaned) < 2) {
    stop("Insufficient data for interpretation")
  }
  
  # Extract the first numeric value as betahat
  betahat <- cleaned[1]
  
  return(betahat)
}

# ============================================================================ #
## C. Function to Filter and Select Columns from Kable Tibble ------------------

#' Filter rows based on regex and select specific columns from a tibble.
#'
#' @param tibble_input The input tibble to process.
#' @param regexstring The regex pattern to filter rows.
#' @param colnumstring The regex pattern to select columns.
#' @return A data frame with selected columns.
filter_and_select <- function(tibble_input, 
                              regexstring, 
                              colnumstring) {
  
  # Convert tibble to data frame
  df <- as.data.frame(tibble_input)
  
  # Identify rows matching the regex pattern in the first column
  logical_vector <- grepl(regexstring, df[, 1], ignore.case = TRUE)
  
  # Include the row following each matching row
  extended_logical_vector <- logical_vector | c(FALSE, logical_vector[-length(logical_vector)])
  
  # Filter the data frame based on the extended logical vector
  filtered_df <- df[extended_logical_vector, ]
  
  # Function to strip non-numeric characters and convert to numeric
  strip_non_numeric <- function(x) {
    stringr::str_replace_all(x, "[^0-9.-]", "") %>%
    as.numeric(.)
  }
  
  # Apply cleaning function to all elements
  cleaned_df <- as.data.frame(apply(filtered_df, c(1, 2), strip_non_numeric))
  
  # Select columns matching the specified pattern
  selected_df <- cleaned_df %>%
    dplyr::select(where(~ !any(is.na(.)))) %>%
    dplyr::select(matches(colnumstring)) 
  
  return(selected_df)
}

## D. GET ROW INDICES BY REGEX -------------------------------------------------
# Retrieves row indices from a dataset where the first column matches the 
# regex pattern.

# @param dataset Data frame to search within.
# @param regex_string Regular expression pattern to match.
# @return Integer vector of matching row indices.
get_rows_helper <- function(dataset, regex_string) {
  
  row_indices <- grepl(regex_string, dataset[[1]]) %>%
    which()
  return(row_indices)
}

# ============================================================================ #
# III. LOAD AND PREPARE DATA ---------------------------------------------------
# ============================================================================ #

# Define input file paths
output_file_a <- "did_io_main_prepost_bothlink_l_valueadded_5estout.csv"
output_file_b <- "did_io_main_prepost_bothlink_l_valueadded_4estout.csv"

# Load and clean datasets using helper function
dataset_a <- load_and_clean_estout_table(output_file_a)
dataset_b <- load_and_clean_estout_table(output_file_b)

# Combine datasets side by side, excluding the first column of dataset_b to avoid duplication
side_by_side_datasets <- cbind(dataset_a, dataset_b[, -1])

# Verify that the combined dataset is not empty
test_that("Combined data.frame is not empty", {
  expect_equal(plyr::empty(side_by_side_datasets), FALSE)
})

# ============================================================================ #
# IV. MAKE WIDE TABLE KABLE OUTPUT ---------------------------------------------
# ============================================================================ #

## A. Setup Header and Kable Dimensions ----------------------------------------

# Calculate the number of regression columns
num_reg_in_table <- ncol(side_by_side_datasets) - 1

# Determine the number of columns for panels A and B
num_col_panel_a <- ncol(dataset_a) - 1
num_col_panel_b <- ncol(dataset_b) - 1

# Lines for statistics
start_stats <- get_rows_helper(side_by_side_datasets, "[Ii]ndustry")
end_stats <- nrow(side_by_side_datasets)


# Assign column labels with numbering
names(side_by_side_datasets) <- c("", paste0("(", 1:num_reg_in_table, ")"))

# Create labels for HCI vs. non-HCI samples
vector_sample_names <- c("", rep(c("Full\nSample", "Non-HCI\nSample"), 
                                 ceiling((num_col_panel_a + num_col_panel_b) / 2)))

# Define column alignment: left for the first column, center for others
column_alignment <- c("l", rep("c", num_reg_in_table))

# Ensure that the alignment vector matches the number of sample names
test_that("Column alignment matches the number of sample names", {
  expect_equal(length(column_alignment), length(vector_sample_names))
})

## B. Create Kable Table -------------------------------------------------------

# Generate the LaTeX table using kable and kableExtra
avg_out_table <- side_by_side_datasets %>%
  kable(
    format = "latex",
    digits = 4,
    booktabs = TRUE,
    longtable = FALSE,
    row.names = FALSE,
    align = column_alignment,
    escape = FALSE,
    caption = table_caption_string,
    label = table_label_string,
  ) %>%
  
  # Add sample names as a header above the main headers
  add_header_above(
    header = c(vector_sample_names),
    line = TRUE,
    italic = TRUE,
    bold = FALSE,
    font_size = font_size_argument,
    align = "c"
  ) %>%
  
  # Add panel labels (A and B) with respective column spans
  add_header_above(
    header = c(
      " ",
      "A) Five-Digit Panel (1970-1986)" = num_col_panel_a,
      "B) Four-Digit Panel (1967-1986)" = num_col_panel_b
    ),
    line = TRUE,
    line_sep = 1,
    align = "c",
    font_size = font_size_argument + 1,
    bold = FALSE
  ) %>%
  
  # Add outcome label spanning all regression columns
  add_header_above(
    header = c(" ", "Outcome: Value Added (log)" = num_reg_in_table),
    line = TRUE,
    align = "c",
    font_size = font_size_argument + 1,
    bold = FALSE
  ) %>%
  
  # Group rows based on the statistics section
  kableExtra::group_rows(
    " ",
    start_row = start_stats,
    end_row = end_stats,
    hline_before = FALSE,
    hline_after = FALSE,
    latex_gap_space = "0.25em"
  ) %>%
  
  # Apply additional styling using kableExtra
  kableExtra::kable_styling(
    latex_options = c("scale_down", "repeat_header"),
    protect_latex = TRUE,
    repeat_header_text = "\\textit{(continued)}",
    repeat_header_continued = TRUE,
    full_width = FALSE,
    table.envir = "table",
    font_size = font_size_argument
  ) %>%
  
  # Add footnote to the table
  footnote(
    general = footnote_string,
    general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
    escape = FALSE,
    footnote_as_chunk = TRUE,
    threeparttable = TRUE
  )

# ==============================================================================
# V. SAVE THE KABLE TABLE ------------------------------------------------------
# ==============================================================================

# Save the kable table to a LaTeX file
output_file <- file.path(tables_dir, "avg_out_table.tex")
cat(avg_out_table, file = output_file)

# Confirm that the file was saved
test_that("Kable table is saved correctly", {
  expect_true(file.exists(output_file))
})

# ==============================================================================
# VI. INTERPRET RESULTS --------------------------------------------------------
# ==============================================================================

# Interpret results for all forward outputs
results_forward_output_all <- dataset_a %>% 
  filter_and_select("orward", "1") %>% 
  simple_interpretation_workflow(.)

# Interpret results for non-HCI forward outputs
results_forward_output_nonhci <- dataset_a %>% 
  filter_and_select("orward", "2") %>% 
  simple_interpretation_workflow(.)

# Full sample output
cat( results_forward_output_all, 
     file = file.path( tables_dir,
                       "results_forwardoutput_all.tex"))

# Non-hci sample output
cat( results_forward_output_nonhci, 
     file = file.path( tables_dir,
                       "results_forwardoutput_nonhci.tex"))