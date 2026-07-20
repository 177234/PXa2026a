## =============================================================================
# PURPOSE:
#   Creates LaTeX tables for linkage analysis by processing regression output
#   located in the /analysis directory.
#
# INPUTS:
#   - "did_io_main_prepost_bothlink_l_ppi_5estout.csv" (Main regression output)
#   - "did_io_main_prepost_bothlink_l_ppi_4estout.csv" (Additional regression output)
#
# OUTPUTS:
#   - avg_price_table (LaTeX formatted Kable table)
# ==============================================================================

## =============================================================================
# I. TEXT AND TABLE ARGUMENTS --------------------------------------------------
## =============================================================================

# Font size for table elements
font_size_argument <- 9

# Table arguments.
table_caption_string <- "Linkage Exposure and Output Prices, Before and After 1973"
table_label_string <- "prepostlinkprices"


footnote_string <- "Average differences-in-differences estimates, before and 
after 1973. Regressions interact linkage measures with a Post indicator. 
Estimates correspond to equation \\\\eqref{eq:networkflexible}. The outcome 
variable is log output price. Both linkage interactions (forward and backward) 
are shown. Analysis is performed for the sample of i) only non-treated 
industries and ii) the full sample of industries. Estimates for the full sample 
separately control for the Targeted \\\\(\\\\times\\\\) Year effects to account 
for the main impact of policy. Standard errors are clustered at the industry 
level. * Significant at the 10 percent level. ** Significant at the 5 percent 
level. *** Significant at the 1 percent level."

footnote_string <- gsub("\n", " ", footnote_string)


## =============================================================================
# II. SUB-FUNCTIONS: Helper and Sub-Helper Functions --------------------------
## =============================================================================

## A. HELPER FUNCTION: LOAD AND CLEAN ESTOUT TABLE ---------------------------

#' Load and Clean ESTOUT Table
#'
#' This function loads an ESTOUT CSV file, cleans column and row names,
#' and ensures the dataset is not empty.
#'
#' @param table_file Character. Filename of the ESTOUT CSV.
#' @param prepost_indicator Optional. Indicator for pre/post processing.
#' @return Data frame. Cleaned dataset.
load_and_clean_estout_table <- function(table_file, prepost_indicator = NULL) {
  
  # Load the CSV file into a dataframe
  dataset <- file.path(intermediate_dir, paste0(table_file)) %>%
    read.csv(sep = "\t", header = TRUE)
  
  # Ensure the dataset is not empty
  test_that("Prepared data.frame is not empty.", {
    expect_equal(plyr::empty(dataset), FALSE)
  })
  
  # Clean column names by removing specific characters
  names(dataset) <- stringr::str_replace_all(
    names(dataset), "[._aA-zZ]", ""
  )
  
  # Define regex patterns for linkage selection
  regex_forward <- "\\#c\\..*hci.*([uU]se|\\_in|orward).*0"
  regex_backward <- "\\#c\\..*hci.*([mM]ake|\\_out|ackward).*0"
  
  # Clean row strings based on regex patterns
  dataset[, 1] <- dataset[, 1] %>%
    stringr::str_replace_all(regex_forward, "Forward Linkage") %>% 
    stringr::str_replace_all(regex_backward, "Backward Linkage") %>%
    stringr::str_replace_all("1\\.post", "Post \\\\(\\\\times\\\\) ") %>% 
    stringr::str_replace_all("1\\.Post", "Post \\\\(\\\\times\\\\) ") %>% 
    stringr::str_replace_all("postc", "Post \\\\(\\\\times\\\\) ") %>%
    stringr::str_replace_all("[Tt]argeted.*[xX].*", "Targeted \\\\(\\\\times\\\\) Year ") %>%
    stringr::str_replace_all(" FE", " Effect") %>%
    stringr::str_replace_all("[Rr]2|[Rr].*squared", "\\\\(R^2\\\\)")

  # Remove duplicate rows
  dataset <- dataset[!duplicated(dataset), ]
  
  # Final check to ensure dataset is not empty
  test_that("Prepared data.frame is not empty after cleaning.", {
    expect_equal(plyr::empty(dataset), FALSE)
  })
  
  return(dataset)
}

## B. FUNCTION TO INTERPRET RESULTS --------------------------------------------

#' Simple Interpretation Workflow
#'
#' Cleans and interprets a single table entry, extracting the betahat value.
#'
#' @param single_table_entry Vector, List, or DataFrame. The table entry to interpret.
#' @return Numeric. The extracted betahat value.
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

## C. FUNCTION TO FILTER AND SELECT COLUMNS FROM KABLE TIBBLE ------------------

#' Filter and Select Columns from Tibble
#'
#' Filters rows based on a regex pattern and selects specific columns.
#'
#' @param tibble_input Tibble. The input tibble to process.
#' @param regexstring Character. Regex pattern to filter rows.
#' @param colnumstring Character. Regex pattern to select columns.
#' @return Data frame. The filtered and selected dataset.
filter_and_select <- function(tibble_input, regexstring, colnumstring) {
  
  # Convert tibble to data frame
  df <- as.data.frame(tibble_input)
  
  # Logical vector for rows matching the regex
  logical_vector <- grepl(regexstring, df[, 1], ignore.case = TRUE)
  
  # Include the row following each match
  extended_logical <- logical_vector | c(FALSE, logical_vector[-length(logical_vector)])
  
  # Filter rows based on the logical vector
  filtered_df <- df[extended_logical, ]
  
  # Function to strip non-numeric characters and convert to numeric
  strip_non_numeric <- function(x) {
    stringr::str_replace_all(x, "[^0-9.-]", "") %>% as.numeric()
  }
  
  # Apply cleaning function to all elements
  cleaned_df <- as.data.frame(
    apply(filtered_df, c(1, 2), strip_non_numeric)
  )
  
  # Select specified columns
  selected_df <- cleaned_df %>%
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

## =============================================================================
# III. LOAD AND PREPARE DATA ---------------------------------------------------
## =============================================================================

## A. SETUP HEADER AND KABLE DIMENSIONS ----------------------------------------

# Define input filenames
output_file_A <- "did_io_main_prepost_bothlink_l_ppi_5estout.csv"
output_file_B <- "did_io_main_prepost_bothlink_l_ppi_4estout.csv"

# Load and clean datasets using helper function
dataset_A <- load_and_clean_estout_table(output_file_A)
dataset_B <- load_and_clean_estout_table(output_file_B)

# Combine datasets side-by-side, excluding the first column of dataset B
side_by_side_datasets <- cbind(
  dataset_A,
  dataset_B[, -1]
)

# Rename columns, keeping the first column unnamed
names(side_by_side_datasets) <- c("", names(side_by_side_datasets)[-1])

# Ensure the combined dataset is not empty
test_that("Combined dataset is not empty.", {
  expect_equal(plyr::empty(side_by_side_datasets), FALSE)
})


## =============================================================================
# IV. MAKE WIDE TABLE KABLE OUTPUT ---------------------------------------------
## =============================================================================

## A. SETUP HEADER AND KABLE DIMENSIONS ----------------------------------------

# Calculate number of regression columns
num_reg_in_table <- (ncol(dataset_A) - 1) * 2

# Calculate number of columns for each panel
num_col_panel_a <- ncol(dataset_A) - 1
num_col_panel_b <- ncol(dataset_B) - 1


# Define start and end rows for statistics section
start_stats <- get_rows_helper(side_by_side_datasets, "[Ii]ndustry")
end_stats <- nrow(side_by_side_datasets)


# Assign numeric labels to columns
names(side_by_side_datasets) <- c(
  "",
  paste0("(", 1:num_reg_in_table, ")")
)

# Prepare sample names for headers
vector_of_sample_names <- c(
  "",
  rep(
    c("Full\nSample", "Non-HCI\nSample"), 
    ceiling((num_col_panel_a + num_col_panel_b) / 2)
  )
)[1:(num_reg_in_table + 1)]

# Define column alignment
column_alignment <- c("l", rep("c", num_reg_in_table))

# Ensure alignment length matches sample names
test_that("Alignment and sample names length match.", {
  expect_equal(length(column_alignment), length(vector_of_sample_names))
})

## B. CREATE KABLE TABLE -------------------------------------------------------

avg_prices_table <- knitr::kable(
  side_by_side_datasets, 
  format = "latex",
  digits = 4,
  booktabs = TRUE, 
  longtable = FALSE,
  row.names = FALSE,
  align = column_alignment,
  escape = FALSE,
  caption = table_caption_string,
  label = table_label_string,
  linesep = ""
) %>%
  
  # Add sample names as header
  kableExtra::add_header_above(
    .,
    header = c(vector_of_sample_names),
    line = TRUE,
    italic = TRUE,
    bold = FALSE,
    font_size = font_size_argument,
    align = "c"
  ) %>%
  
  # Add panel headers
  kableExtra::add_header_above(
    .,
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
  
  # Add outcome header
  kableExtra::add_header_above(
    .,
    header = c(
      " ",
      "Outcome: Output Prices (log)" = num_reg_in_table
    ),
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
  
  # Apply table styling
  kableExtra::kable_styling(
    .,
    latex_options = c("scale_down", "repeat_header"), 
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
    threeparttable = TRUE,
    general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
    escape = FALSE,
    footnote_as_chunk = TRUE
  )


## =============================================================================
# V. SAVE THE KABLE TABLE ------------------------------------------------------
## =============================================================================

# Save the kable table to a LaTeX file
output_file <- file.path(tables_dir, "avg_prices_table.tex")
cat(avg_prices_table, file = output_file)

# Confirm that the file was saved
test_that("Kable table is saved correctly", {
  expect_true(file.exists(output_file))
})


## =============================================================================
# VI. INTERPRET RESULTS --------------------------------------------------------
## =============================================================================

# Interpret results for all forward prices
results_forwardprices_all <- dataset_A %>% 
  filter_and_select("[Ff]orward", "1") %>% 
  simple_interpretation_workflow()

# Interpret results for non-HCI forward prices
results_forwardprices_nonhci <- dataset_A %>% 
  filter_and_select("[Ff]orward", "2") %>% 
  simple_interpretation_workflow()

# Full sample prices
cat( results_forwardprices_all, 
     file = file.path( tables_dir,
                       "results_forwardprices_all.tex"))
# Non-hci sample prices
cat( results_forwardprices_nonhci, 
     file = file.path( tables_dir,
                       "results_forwardprices_nonhci.tex"))