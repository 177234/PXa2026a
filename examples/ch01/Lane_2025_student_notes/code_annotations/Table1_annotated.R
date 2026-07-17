# Annotated copy for replication audit.
# Original script: Lane2025QJE/replicationpackage/code/2_tables/Table1.R
# Purpose: Generates Table 1.
#
# This file intentionally keeps the original .R extension.
# The original code is copied below. Comments in this header identify the
# script role, inputs, outputs, and audit linkage. The earlier prose note is
# archived at: markdown_notes_archive/Table1_R.md
#
# Audit linkage:
# - Methods report: explains the estimating or output logic.
# - Derivation report: maps equations/design objects to code.
# - Replication report: documents inputs, outputs, and reproducibility limits.
#
# Original code begins after this header.

## =============================================================================
# PURPOSE:
#   Creates a simple table for Total Factor Productivity (TFP).
#
# INPUTS:
#   - "did_crossection_results_microtfp_results_estout.csv" (Regression output CSV)
#
# OUTPUTS:
#   - tfpbasic_kable (LaTeX formatted Kable table)
# ==============================================================================

## =============================================================================
# I. TEXT AND TABLE ARGUMENTS --------------------------------------------------
## =============================================================================
font_size_argument <- 10

table_caption_string <- "Differences in Plant-Level Total Factor Productivity, By Treatment Status(1980-1986)"

table_label_string <- "tfpcrosssection"

footnote_string <- "This table shows the relationship between plant-level TFP 
and HCI (targeted industries) for the post-HCI period (1980-1986), using equation 
\\\\eqref{eq:tfpplantregression}. TFP is estimated using Ackerberg-Caves-Frazer 
(ACF), Levinsohn-Petrin (LP), Olley-Pakes (OP), and Wooldridge (W) methods. I also 
include TFP estimated using OLS as a baseline estimate. The table reports estimates 
from the following specification: 
\\\\begin{equation}
\\\\label{eq:tfpplantregression}
\\\\log(TFP_{it}) = \\\\beta_{1} Targeted_{i} + \\\\gamma_{t} + \\\\epsilon_{it}
\\\\end{equation}
where TFP is estimated using a log-transformed, value added production function. 
The Targeted indicator is defined by the plant's main industry. All regressions 
control for year-by-industry (4-digit level) fixed effects. Regressions use two-way 
clustered standard errors at the plant and industry levels. * Significant at the 10 
percent level. ** Significant at the 5 percent level. *** Significant at the 1 percent 
level."

footnote_string <- gsub("\n", " ", footnote_string)


## =============================================================================
# II. SUB-FUNCTIONS: Helper and Sub-Helper Functions ------------------------
## =============================================================================

# 1. Interpret Coefficient ----------------------------------------------------

### A. Clean Single Numeric Values in the Dataset -----------------------------

#' Clean and extract numeric values from a string.
#'
#' @param x Character vector containing numeric values embedded in strings.
#' @return Numeric vector with cleaned values.
cleannumber_strings <- function(x) {
  cleaned_values <- str_extract_all(x, "[\\.\\-0-9]+", simplify = TRUE)
  
  # Convert to numeric and remove NAs
  vectorized_values <- as.numeric(na.omit(as.vector(cleaned_values)))
  
  return(vectorized_values)
}

### B. Interpret the Vector ---------------------------------------------------

#' Calculate the interaction effect from beta and its standard error.
#'
#' @param df Numeric vector where the first element is beta and the second is SE(beta).
#' @return Numeric value representing the interaction effect.
interpret_vector <- function(df) {
  betahat <- df[1]
  se <- df[2]
  
  # Calculate interaction effect
  interaction <- 100 * (exp(betahat - 0.5 * se^2) - 1)
  
  return(interaction)
}

### C. Interpret Estimates ----------------------------------------------------

#' Workflow to interpret a single table entry.
#'
#' @param single_table_entry Character vector of a single table entry.
#' @return Rounded absolute interaction effect.
interpretestimate_workflow <- function(single_table_entry) {
  simple <- single_table_entry %>%
    cleannumber_strings() %>%
    interpret_vector() %>%
    round(1) %>%
    abs()  # Take absolute value
  return(simple)
}

# 2. Load and Clean ESTOUT Table ------------------------------------------------

#' Load and clean the ESTOUT CSV table.
#' @param table_file Filename of the ESTOUT CSV table.
#' @return Cleaned dataframe.
load_and_clean_estout_table <- function(table_file) {
  # Read the ESTOUT CSV file.
  dataset <- read.csv(file.path(included_dir, table_file), 
                     sep = "\t", header = TRUE)
  
  # Clean variable names.
  names(dataset) <- c("", paste0("V", seq_len(ncol(dataset) - 1)))
  
  # Define pattern replacements.
  pattern_replacements <- c("_cons" = "Constant",
                            "year" = "",
                            "#" = "",
                            "^1" = "",
                            "hci" = "Targeted",
                            "\\." = "",
                            "(C|c)\\.*(h|l)_" = "")
  # Apply replacements to the first column.
  dataset[[1]] <- str_replace_all(dataset[[1]], pattern_replacements)
  return(dataset)
}

## 3. Get row helper -----------------------------------------------------------
#' Get row indices matching a regex pattern in the first column of a dataset.
#' @param dataset Data frame to search.
#' @param regex_string Regular expression pattern to match.
#' @return Integer vector of row indices.
get_rows_helper <- function( dataset, regexstring ){
  
  # Get row number by REGEX string.
  rowindex <- which(
    grepl(
      paste0( regexstring ), 
      dataset[,1], 
      ignore.case = TRUE
    )
  )
  
  testthat::test_that("Row index is not empty.", {
    testthat::expect_equal(length(rowindex) > 0, TRUE)
  })
  
  # Return integer.
  return( rowindex )
}

## =============================================================================
# III. MAKE KABLE TABLE -------------------------------------------------------
## =============================================================================

## A. SETUP -------------------------------------------------------------------

# Define the ESTOUT CSV filename.
dataset_name <- "did_crossection_results_microtfp_results_estout.csv" 

# Load and clean the dataset.
dataset <- load_and_clean_estout_table(dataset_name) 

# Add a bottom information row.
bottom_info_row <- c("Estimation Type (TFP)", "W", "ACF", "LP", "OP", "OLS")
dataset <- rbind(dataset, bottom_info_row)


## B. ARGUMENTS AND TABLE DIMENSIONS ------------------------------------------

# Generate column names.
num_regs <- ncol(dataset) - 1
last_row <- nrow(dataset)
names(dataset) <- c("", paste0("(", 1:num_regs, ")"))

# Define column alignment.
align_string <- c("l", rep("c", num_regs))


# Get row index for stats
start_stats <- get_rows_helper( dataset, "year" )
end_stats <- last_row-1


## C. MAKE TABLE --------------------------------------------------------------

# Create the Kable table with LaTeX formatting.
tfpbasic_kable <- dataset %>%
  kable(format = "latex",
        booktabs = TRUE, 
        longtable = FALSE,
        row.names = FALSE,
        align = align_string,
        escape = FALSE,
        caption = table_caption_string,
        label = table_label_string ) %>%

  add_header_above(c("", "Outcomes: Total Factor Productivity (TFP)" = num_regs),
                   align = "c",
                   font_size = font_size_argument + 1,
                   line = TRUE,
                   bold = FALSE) %>%
  
  kableExtra::group_rows(group_label = " ", 
             start_row = start_stats, 
             end_row = end_stats, 
             latex_gap_space = "0.1em") %>%
  
  kableExtra::group_rows(group_label = " ", 
             start_row = last_row, 
             end_row = last_row, 
             hline_before = TRUE) %>%

  kable_styling(protect_latex = TRUE,
                table.envir = "table", 
                font_size = font_size_argument) %>%
  
  footnote(general = footnote_string, 
           general_title = "\\\\hspace{1em}\\\\textit{Notes.}", 
           footnote_as_chunk = TRUE, 
           threeparttable = TRUE, 
           escape = FALSE) 

## =============================================================================
# IV. SAVE TABLE ---------------------------------------------------------------
## =============================================================================

# Save the table to the tables_dir directory.
tfp_table_file <- file.path(tables_dir, "tfpcrossection_kable.tex")
cat( tfpbasic_kable, file = tfp_table_file)

# Unit test for the TFP table LaTeX file.
test_that("TFP table LaTeX file is saved correctly", {
  # Define the expected file path
  tfp_table_file <- file.path(tables_dir, 
                               "tfpcrossection_kable.tex")
  # Check if the file exists
  expect_true(file.exists(tfp_table_file), 
              info = "tfpcrossection_kable.tex file was not created.")
})

## =============================================================================
# V. INTERPRET TFP RESULTS -----------------------------------------------------
## =============================================================================

# Load and clean the dataset for interpretation.
tfpcrossection_df <- load_and_clean_estout_table(dataset_name) 
num_estimates <- ncol(tfpcrossection_df)

# Interpret estimates across all relevant columns.
list_of_interps <- lapply(2:num_estimates, function(i) {
  tfpcrossection_df[1:2, i] %>%
    interpretestimate_workflow() 
})

# Determine the maximum and minimum TFP interpretations.
maxtfp <- round(max(unlist(list_of_interps)), 0)
mintfp <- round(min(unlist(list_of_interps)), 0)

# Save results. 

# maxtfp and mintfp to output files:

# Here we save point estimates from the table, that are used in the body text.
cat( mintfp, 
     file = file.path( tables_dir, "results_tfpcrossection_mintfp.tex"))

# Save the table to the tables_dir directory.
cat( maxtfp, 
     file = file.path( tables_dir, "results_tfpcrossection_maxtfp.tex"))


test_that("TFP table files are saved correctly", {
  # Define file paths
  mintfp_file <- file.path(tables_dir, 
                            "results_tfpcrossection_mintfp.tex")
  maxtfp_file <- file.path(tables_dir, 
                            "results_tfpcrossection_maxtfp.tex")
  # Check if files exist
  expect_true(file.exists(mintfp_file), 
              info = "mintfp.tex file was not created.")
  expect_true(file.exists(maxtfp_file), 
              info = "maxtfp.tex file was not created.")
})
