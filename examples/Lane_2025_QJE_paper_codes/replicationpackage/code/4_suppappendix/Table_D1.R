## =============================================================================
# PURPOSE:
#   Creates tables showing dynamic differences-in-differences estimates for the
#   relationship between HCI and investment outcomes.
#
# INPUTS:
#   - did_largerolling_mainpolicycapital.csv
#
# OUTPUTS:
#   - tablerollingcapital.tex
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS. -------------------------------------------------
## ========================================================================== ##

tablecaptionstring <- "Industrial Policy and Input Use: Investment and Intermediates"
tablelabelstring <- "supptablerollingcapital"

# PREPARE NOTES -------------------------------------------

footnotestring <- "The table reports dynamic differences-in-differences estimates for the relationship between heavy and chemical industry drive and investment outcomes. All outcomes are logged. Investment is real gross investment. Intermediate outlays are real value of intermediate input costs. Capital stock is also shown. Estimates are relative to 1972, the year before HCI. Standard errors are clustered at the industry level. * Significant at the 10 percent level. ** Significant at the 5 percent level. *** Significant at the 1 percent level."

# Font size argument for the table
font_size_argument <- 8

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')

## ========================================================================== ##
# II. SUB-FUNCTIONS ------------------------------------------------------------
## ========================================================================== ##

## A. Get row IDs using REGEX. -------------------------------------------------
getrowids <- function(dataset, regexstring) {
  rowindex <- paste0(regexstring) %>%
    grepl(., dataset[[1]]) %>%
    which(dataset[., ]) %>%
    as.numeric()
  return(rowindex)
}

## ========================================================================== ##
# III. MAIN FUNCTION -----------------------------------------------------------
## ========================================================================== ##

# Helper function for loading rolling dataset.
loadandcleanestouttable <- function(table_file) {
  # Convert ESTOUT CSV into a dataframe.
  dataset <- file.path(intermediate_dir, table_file) %>%
    read.csv(header = TRUE, sep = "\t")
  
  # Test the table is non-empty
  testthat::expect_false(plyr::empty(dataset))
  
  # Clean row strings only
  dataset[, 1] <- dataset[, 1] %>%
    stringr::str_replace_all("year", "") %>%
    stringr::str_replace_all("[#\\.]", "") %>%
    stringr::str_replace_all("^1", "") %>%
    stringr::str_replace_all("hci", "Targeted \\\\(\\\\times\\\\) ") %>%
    stringr::str_replace_all("[Ff][Ee]$", "FE")
  
  # Correct column names
  names(dataset) <- stringr::str_to_lower(names(dataset)) %>%
    stringr::str_replace_all("[\\._a-z]", "")
  
  # Test the table is non-empty
  testthat::expect_false(plyr::empty(dataset))
  
  return(dataset)
}

## ========================================================================== ##
# IV. LOAD AND PREPARE DATA ----------------------------------------------------
## ========================================================================== ##

## A. Load and clean datasets --------------------------------------------------
table_file <- "did_largerolling_mainpolicycapital.csv"
dataset <- loadandcleanestouttable(table_file)

## B. GET TABLE DIMENSIONS -----------------------------------------------------
num_regs <- ncol(dataset) - 1
names(dataset) <- c("", paste0("(", 1:num_regs, ")"))
alignstring <- c("l", rep("c", num_regs))
striperow <- getrowids(dataset, "19")

## C. MAKE TABLE ---------------------------------------------------------------

# KABLE FUNCTION FOR COMBINED ROWS.
main_capital_table <- knitr::kable(
  dataset,
  format = "latex",
  digits = 2,
  booktabs = TRUE,
  longtable = FALSE,
  row.names = FALSE,
  escape = FALSE,
  align = alignstring,
  caption = tablecaptionstring,
  label = tablelabelstring,
  linesep = ""
) %>%

  # Add indent
  kableExtra::add_indent(1:max(striperow), level_of_indent = 2) %>%

  # Add styling
  kableExtra::kable_styling(
    latex_options = c("scale_down", "repeat_header", "striped"),
    protect_latex = TRUE,
    stripe_index = striperow,
    repeat_header_text = "\\textit{(continued)}",
    repeat_header_continued = TRUE,
    full_width = FALSE,
    table.envir = "table",
    font_size = font_size_argument
  ) %>%

  # Add footnote
  kableExtra::footnote(
    general = footnotestring,
    general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
    footnote_as_chunk = TRUE,
    threeparttable = TRUE,
    escape = FALSE
  ) %>%

  # Add header
  kableExtra::add_header_above(c(
    "",
    "Input Outlays" = 1,
    "Investment" = 1,
    "Capital Stock" = 1
  )) %>%

  # Add header
  kableExtra::add_header_above(
    c("", "Outcomes: Investment and Outlays (log)" = ncol(dataset) - 1),
    line = TRUE,
    font_size = font_size_argument + 1,
    line_sep = 2,
    bold = TRUE
  )

## ========================================================================== ##
## V. SAVE THE KABLE TABLE ------------------------------------------------------
## ========================================================================== ##

output_file <- file.path( tables_supplementalappendix_dir, 
                          "tablerollingcapital.tex")

cat(main_capital_table, file = output_file)

testthat::test_that("Rolling Capital kable is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})

