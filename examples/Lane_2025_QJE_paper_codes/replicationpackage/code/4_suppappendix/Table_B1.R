## =============================================================================
# PURPOSE:
#   Creates a stacked output table showing dynamic differences-in-differences
#   estimates for the relationship between HCI and industrial output.
#
# INPUTS:
#   - did_largerolling_mainresults_alloutput_results_estout.csv
#   - did_largerolling_mainresults_alloutput_4d_results_estout.csv
#
# OUTPUTS:
#   - tablerollingoutput.tex
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS -----------------------------------------------
## ========================================================================== ##

# Font size argument for the table
font_size_argument <- 7

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')

# Generate cleaned ESTOUT tables.
tablecaptionstring <- "Robustness: Industrial Policy and Industrial Output by Treatment Status"
tablelabelstring <- "supptablerollingoutput"

## PREPARE NOTES. --------------------------------------------------------------

footnotestring <- "The table reports dynamic differences-in-differences estimates for the relationship between heavy and chemical industry drive and log industrial output. This robustnesss table reports estimates for three different measures of output: real value shipped, real gross output, and real value added.. Estimates are relative to 1972, the year before HCI. Specifications with controls include pre-1973 industry (log) averages: avg. wages, avg. plant size, intermediate input costs, and labor productivity, interacted with time. Standard errors are clustered at the industry level. * Significant at the 10 percent level. ** Significant at the 5 percent level. *** Significant at the 1 percent level."

## ========================================================================== ##
# II. SUB-FUNCTIONS ------------------------------------------------------------
## ========================================================================== ##

### A. Get row indices matching a regex pattern in the first column of a dataset.

#' Get row indices matching a regex pattern in the first column of a dataset.
#'
#' @param dataset Data frame to search.
#' @param regexstring Regular expression pattern to match.
#' @return Integer vector of row indices.
get_rows_helper <- function(dataset, regexstring) {
  
  # Get row numbers matching the regex pattern in the first column.
  rowindex <- which(stringr::str_detect(dataset[[1]], regexstring))
  
  # Test to ensure rowindex is not empty.
  testthat::test_that("Row index is not empty.", {
    testthat::expect_true(length(rowindex) > 0)
  })
  
  return(rowindex)
}

## ========================================================================== ##
# III. MAIN FUNCTION -----------------------------------------------------------
## ========================================================================== ##

#' Load and clean ESTOUT CSV tables.
#'
#' @param table_file Name of the ESTOUT CSV file to load.
#' @return Cleaned data frame.
loadandcleanestouttable <- function(table_file) {
  
  # Construct file path and read CSV.
  dataset <- file.path(intermediate_dir, table_file) %>%
    utils::read.csv(file = ., sep = "\t", header = TRUE)
  
  # Test to ensure the dataset is not empty.
  testthat::test_that("Filtered table is not empty.", {
    testthat::expect_false(plyr::empty(dataset))
  })
  
  # Clean row strings in the first column.
  dataset[[1]] <- dataset[[1]] %>%
    stringr::str_replace_all("year", "") %>%
    stringr::str_replace_all("[#\\.]", "") %>%
    stringr::str_replace_all("^1", "") %>%
    stringr::str_replace_all("hci", "Targeted \\\\(\\\\times\\\\) ") %>%
    stringr::str_replace_all("[Ff][Ee]$", "FE")
  
  baseline_year <- 1973
  
  # Adjust the year for _Lead and _Lag and replace with proper year.
  dataset[[1]] <- ifelse(
    stringr::str_detect(dataset[[1]], "_[Ll]ead"),
    paste0("Targeted \\(\\times\\) ", baseline_year - as.numeric(gsub(".*_[Ll]ead(\\d+).*", "\\1", dataset[[1]]))),
    ifelse(
      stringr::str_detect(dataset[[1]], "_[Ll]ag"),
      paste0("Targeted \\(\\times\\) ", baseline_year + as.numeric(gsub(".*_[Ll]ag(\\d+).*", "\\1", dataset[[1]]))),
      dataset[[1]]  # Leave other strings unchanged
    )
  )

  
  # Correct column names.
  names(dataset) <- names(dataset) %>%
    stringr::str_to_lower() %>%
    stringr::str_replace_all("[\\._a-z]", "")
  
  # Test to ensure the dataset is not empty after cleaning.
  testthat::test_that("Filtered table is not empty after cleaning.", {
    testthat::expect_false(plyr::empty(dataset))
  })
  
  return(dataset)
}

## ========================================================================== ##
# IV. LOAD AND PREPARE DATA ----------------------------------------------------
## ========================================================================== ##

## A. Load and clean datasets. -------------------------------------------------

# Generate cleaned ESTOUT tables.
table_fileA <- "did_largerolling_mainresults_alloutput_results_estout.csv"
table_fileB <- "did_largerolling_mainresults_alloutput_4d_results_estout.csv"

# Load and clean datasets.
datasetA <- loadandcleanestouttable(table_fileA)
datasetB <- loadandcleanestouttable(table_fileB)

# Test to ensure outcome lengths are equal.
testthat::test_that("Test outcome lengths are equal.", {
  testthat::expect_equal(ncol(datasetA), ncol(datasetB))
})

## B. Pad datasetA with blank rows to match the number of rows in datasetB.-----

# Calculate the number of rows to pad.
gap_nrow <- nrow(datasetB) - nrow(datasetA)
blankpadding <- data.frame(matrix(ncol = ncol(datasetA), nrow = gap_nrow))

# Inherit column names for blank padding.
names(blankpadding) <- names(datasetA)

# Stack blank padding on top of datasetA.
datasetA <- rbind(blankpadding, datasetA)

## C. Combine datasets. --------------------------------------------------------

# Combine datasets side by side.
stackeddatasets <- cbind(datasetB[, 1], datasetA[, -1], datasetB[, -1])

# Test to ensure the combined dataset is not empty.
testthat::test_that("Prepared data.frame is not empty.", {
  testthat::expect_false(plyr::empty(stackeddatasets))
})

## ========================================================================== ##
# V. MAKE THE TABLE ------------------------------------------------------------
## ========================================================================== ##

## A. Get table dimensions. ----------------------------------------------------

# Number of regressions.
num_regs <- ncol(stackeddatasets) - 1

# Add parentheses and numbers to column names.
names(stackeddatasets) <- c("", paste0("(", 1:num_regs, ")"))

# Generate alignment string for LaTeX (e.g., 'lcccc').
alignstring <- c("l", rep("c", num_regs))

# Get indices for striped rows.
striperow <- get_rows_helper(stackeddatasets, "19")


## B. Assemble Kable table. ----------------------------------------------------

# Create the Kable table.
stackedouttable <- knitr::kable(
  stackeddatasets, 
  format = "latex", 
  digits = 2,
  escape = FALSE,
  booktabs = TRUE, 
  longtable = FALSE,
  row.names = FALSE,
  align = alignstring,
  caption = tablecaptionstring,
  label = tablelabelstring,
  linesep = ""
) %>%
  # Add a header above the table columns.
  kableExtra::add_header_above(
    c(
      "",
      "Value Shipped" = 2,
      "Gross Output" = 2,
      "Value Added" = 2,
      "Value Shipped" = 2,
      "Gross Output" = 2,
      "Value Added" = 2
    ),
    line = TRUE,
    bold = FALSE, 
    line_sep = 2,
    align = "c",
    font_size = font_size_argument
  ) %>%
  # Add a second header specifying panel details.
  kableExtra::add_header_above(
    c(
      " ", 
      "Panel A) Five-Digit Panel (1970 - 1986)" = ncol(datasetA) - 1, 
      "Panel B) Four-Digit Panel (1967 - 1986)" = ncol(datasetB) - 1
    ),
    line = TRUE,
    bold = FALSE, 
    align = "c",
    font_size = font_size_argument + 1
  ) %>%
  # Apply styling options to the table.
  kableExtra::kable_styling(
    latex_options = c("scale_down", "repeat_header", "striped"), 
    protect_latex = TRUE,
    repeat_header_text = "\\textit{(continued)}",
    repeat_header_continued = TRUE,
    stripe_index = striperow,
    full_width = FALSE, 
    table.envir = "table", 
    font_size = font_size_argument
  ) %>%
  # Add footnotes to the table.
  kableExtra::footnote(
    general = footnotestring,
    general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
    footnote_as_chunk = TRUE,
    threeparttable = TRUE,
    escape = FALSE
  )

## ========================================================================== ##
## VI. SAVE THE KABLE TABLE ------------------------------------------------------
## ========================================================================== ##

output_file <- file.path( tables_supplementalappendix_dir, 
                          "tablerollingoutput.tex")

cat(stackedouttable, file = output_file)

testthat::test_that("DD Rolling Output kable is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})
