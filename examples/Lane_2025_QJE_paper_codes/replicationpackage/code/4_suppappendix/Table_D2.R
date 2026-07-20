## =============================================================================
# PURPOSE:
#   Creates tables showing dynamic differences-in-differences estimates for the
#   relationship between HCI and investment outcomes across different asset classes.
#
# INPUTS:
#   - did_largerolling_mainpolicydisaggregatedcapital.csv
#
# OUTPUTS:
#   - tablerollingcapital2.tex
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS. -------------------------------------------------
## ========================================================================== ##

tablecaptionstring <- "Industrial Policy and Investment by Asset Class, HCI vs. Non-HCI Industry"
tablelabelstring <- "supptablerollingcapital2"

## PREPARE NOTES.---------------------------------------------------------------

footnotestring <- "The table reports dynamic differences-in-differences estimates for the relationship between heavy and chemical industry drive and (log) investment across asset class. All outcomes are logged. Machine equipment is investment in equipment and machinery. Transportation equipment is value of investment in vehicles and transportation equipment. Structures are value investment in building and structures. Land investment is also shown. Standard errors are clustered at the industry level. * Significant at the 10 percent level. ** Significant at the 5 percent level. *** Significant at the 1 percent level." 

# Font size argument for the table
font_size_argument <- 7

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
    read.csv(., header = TRUE, sep = "\t")
  
  # Test the table is non-empty
  testthat::test_that("Filtered table is not empty", {
    testthat::expect_equal(plyr::empty(dataset), FALSE)
  })
  
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
  testthat::test_that("Filtered table is not empty", {
    testthat::expect_equal(plyr::empty(dataset), FALSE)
  })
  
  return(dataset)
}

## ========================================================================== ##
# IV. LOAD AND PREPARE DATA ----------------------------------------------------
## ========================================================================== ##

## A. Load and clean datasets --------------------------------------------------
table_file <- "did_largerolling_policydisaggregatedcapital.csv"
dataset <- loadandcleanestouttable(table_file)

## B. GET TABLE DIMENSIONS -----------------------------------------------------
num_regs <- ncol(dataset) - 1
names(dataset) <- c("", paste0("(", 1:num_regs, ")"))
alignstring <- c("l", rep("c", num_regs))
striperow <- getrowids(dataset, "19")

## C. MAKE TABLE ---------------------------------------------------------------

# KABLE FUNCTION FOR COMBINED ROWS.
supp_capital_table <- knitr::kable(
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
  # Add indent to the first row.
  kableExtra::add_indent(1:max(striperow), level_of_indent = 1) %>%
  
  # Add styling.
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

  # Add footnote.
  kableExtra::footnote(
    general = footnotestring,
    general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
    footnote_as_chunk = TRUE,
    threeparttable = TRUE,
    escape = FALSE
  ) %>%

  # Add header above.
  kableExtra::add_header_above(
    c(
      "",
      "Machinery" = 1,
      "Transport\nEquipment" = 1,
      "Buildings and\nStructures" = 1,
      "Land" = 1
    ),
    font_size = font_size_argument + 1
  ) %>%
  kableExtra::add_header_above(
    c(
      "",
      "Outcome: Investment by asset class" = 4
    ),
    font_size = font_size_argument + 1,
    line = TRUE,
    line_sep = 2
  )

## ========================================================================== ##
## V. SAVE THE KABLE TABLE ------------------------------------------------------
## ========================================================================== ##

output_file <- file.path( tables_supplementalappendix_dir, 
                          "tablerollingcapital2.tex")

cat(supp_capital_table, file = output_file)

testthat::test_that("Rolling Capital kable is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})

