## =============================================================================
# PURPOSE:
#   Creates a table showing the cross-sectional relationship between trade policy
#   and HCI targeting for the year 1968, before the intervention.
#
# INPUTS:
#   - did_output_tradepolicy_1968only_results_estout.csv
#
# OUTPUTS:
#   - pretradepolicytable.tex
# ==============================================================================

## ========================================================================= ##
# I. TEXT AND TABLE ARGUMENTS -----------------------------------------------
## ========================================================================= ##

# Font size argument for the table.
font_size_argument <- 11

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')

tablecaptionstring <- "Differences in Trade Policy by Treatment Status, 1968 Only"

tablelabelstring <- "supptradepolicyprehci"

# FOOTNOTE:
footnotestring <- "This table shows the cross-sectional relationship between trade policy and HCI targeting for the year 1968, the period of trade policy before the intervention. All regressions are at the 4-digit SITC level. The first set of columns report results for regressions in levels. The second set of columns reports differences outcomes. Columns (1-2) report estimates for tariffs. Columns (3-4) reports estimates for quantitative restriction coverage (QR). * Significant at the 10 percent level. ** Significant at the 5 percent level. *** Significant at the 1 percent level." 

## ========================================================================= ##
# II. SUB-FUNCTIONS: Helper and sub-helper functions. -----------------------
## ========================================================================= ##

## A. LOAD AND CLEAN ESTOUT TABLES --------------------------------------------

#' Load and clean an ESTOUT CSV table.
#'
#' @param table_file A string representing the name of the ESTOUT CSV file to load.
#' @return A cleaned data frame ready for table generation.
loadandcleanestouttable <- function(table_file) {
  
  # Convert ESTOUT CSV into a data frame.
  dataset <- file.path(intermediate_dir, table_file) %>%
    utils::read.csv(file = ., header = FALSE, sep = "\t")
  
  # Correct column names by removing special characters.
  names(dataset) <- stringr::str_replace_all(names(dataset), "[._aA-zZ]", "")
  
  # Clean row strings in the first column.
  dataset[, 1] <- dataset[, 1] %>%
    stringr::str_replace_all("hci", "Targeted")
  
  # Remove the first two rows (assumed to be headers or irrelevant data).
  dataset <- dataset[-c(1:2), ]
  
  # Adjust table column names - set first column to blank, others to sequential numbers.
  nlength <- ncol(dataset) - 1
  names(dataset) <- c("", seq_len(nlength))
  
  # Test that the table is not empty.
  testthat::test_that("Filtered table is not empty", {
    testthat::expect_equal(plyr::empty(dataset), FALSE)
  })
  
  return(dataset)
}


## ========================================================================= ##
# III. MAKE THE TABLE
## ========================================================================= ##

## A. Load and clean datasets --------------------------------------------------

# Define the input file name.
file_name <- "did_output_tradepolicy_1968only_results_estout.csv"

# Load and clean the dataset using the helper function.
tabledata <- loadandcleanestouttable(file_name)

# Generate alignment string for LaTeX table formatting.
num_regs <- ncol(tabledata) - 1
alignstring <- c("l", rep("c", num_regs))
colnamestring <- c("", paste0("(", seq_len(num_regs), ")"))

## B. Generate the table using kable -------------------------------------------

# Create the LaTeX table using kable and kableExtra.
prehcitrade_kable <- knitr::kable(
  tabledata,
  format = "latex",
  booktabs = TRUE,
  longtable = FALSE,
  row.names = FALSE,
  escape = FALSE,
  align = alignstring,
  col.names = colnamestring,
  caption = tablecaptionstring,
  label = tablelabelstring,
  linesep = ""
) %>%
  # Indent the first row.
  kableExtra::add_indent(
    position = 1,
    target_cols = 1
  ) %>%
  # Add headers above the table.
  kableExtra::add_header_above(
    header = c(
      "",
      "Tariff Rate" = 2,
      "QRs Coverage" = 2
    ),
    font_size = font_size_argument
  ) %>%
  # Add another header above.
  kableExtra::add_header_above(
    header = c(
      "",
      "Outcomes: (log) Levels of Output Protection" = ncol(tabledata) - 1
    ),
    align = "c"
  ) %>%
  # Apply kable styling options.
  kableExtra::kable_styling(
    protect_latex = TRUE,
    repeat_header_text = "\\textit{(continued)}",
    repeat_header_continued = TRUE,
    full_width = FALSE,
    table.envir = "table",
    font_size = font_size_argument
  ) %>%
  # Add footnote to the table.
  kableExtra::footnote(
    general = footnotestring,
    general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
    footnote_as_chunk = TRUE,
    threeparttable = TRUE,
    escape = FALSE
  )

## ========================================================================== ##
## V. SAVE THE KABLE TABLE ------------------------------------------------------
## ========================================================================== ##

output_file <- file.path( tables_supplementalappendix_dir, 
                          "pretradepolicytable.tex")

cat(prehcitrade_kable, file = output_file)

testthat::test_that("Pre-HCI kable is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})
