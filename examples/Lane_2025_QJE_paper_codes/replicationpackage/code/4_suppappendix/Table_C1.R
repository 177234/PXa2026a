## =============================================================================
# PURPOSE:
#   Creates tables showing dynamic differences-in-differences estimates for the
#   relationship between HCI and trade development outcomes.
#
# INPUTS:
#   - did_largerolling_koreatrade_rca_results_estout.csv
#
# OUTPUTS:
#   - tablerollingrca.tex
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS. -------------------------------------------------
## ========================================================================== ##

## PREPARE TITLES AND SUBTITLES, TEX LABELS ------------------------------------

# Generate cleaned ESTOUT tables.
tablecaptionstring <- "Industrial Policy and Export Development by Treatment Status"
tablelabelstring <- "supptablerollingrca"

## PREPARE NOTES. --------------------------------------------------------------

# Table-specific notes.
footnotestring <- "The table reports dynamic differences-in-differences estimates for the relationship between heavy and chemical industry drive and trade development outcomes. Revealed export productivity are the CDK measure. RCA is revealed comparative advantage; the classic Balassa index is shown alongside log and asinh-transformed RCA measures. Log export shares also shown. 'Dummy' is an indicator equal to one if an industry has realized RCA (RCA>1). Trade values reflect real values (2010 base). PPML used to for RCA estimates, OLS used for all others.. Estimates are relative to 1972, the year before HCI. Specifications with controls include pre-1973 industry (log) averages: avg. wages, avg. plant size, intermediate input costs, and labor productivity, interacted with time. Standard errors are clustered at the industry level. * Significant at the 10 percent level. ** Significant at the 5 percent level. *** Significant at the 1 percent level."

# Font size argument for the table
font_size_argument <- 6.5

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')

## ========================================================================== ##
# II. SUB-FUNCTIONS ------------------------------------------------------------
## ========================================================================== ##

## A. Get row IDs using REGEX. -------------------------------------------------
getrowids <- function(dataset, regexstring) {
  stringr::str_which(dataset[[1]], regexstring)
}

## ========================================================================== ##
# III. MAIN FUNCTION -----------------------------------------------------------
## ========================================================================== ##

# Helper function for loading rolling dataset.
loadandcleanestouttable <- function(table_file) {

  # Convert ESTOUT CSV into a dataframe.

  # A. Load data
  # Convert ESTOUT CSV into a dataframe.
  dataset <- file.path( intermediate_dir , table_file ) %>%
    read.csv( . , header = TRUE, sep = "\t" )
  
  # Test the table is non-empty....
  testthat::expect_false(plyr::empty(dataset))
  
  ## Clean row strings only.
  dataset[[1]] <- dataset[[1]] %>%
    stringr::str_remove_all("year|[#\\.]") %>%
    stringr::str_remove("^1") %>%
    stringr::str_replace("hci", "Targeted \\\\(\\\\times\\\\) ") %>%
    stringr::str_replace("[Ff][Ee]$", "FE")
  
  # Correct column names
  names(dataset) <- stringr::str_to_lower(names(dataset)) %>%
    stringr::str_remove_all("[\\._a-z]")
  
  # Test the table is non-empty....
  testthat::expect_false(plyr::empty(dataset))
  
  return(dataset)
}

## ========================================================================== ##
# V. MAKE THE TABLE ------------------------------------------------------------
## ========================================================================== ##

## A. Load and clean datasets --------------------------------------------------
table_file <- "did_largerolling_koreatrade_ppml_rca_results_estout.csv"

## Clean estout data.
dataset <- loadandcleanestouttable(table_file)

## B. GET TABLE DIMENSIONS -----------------------------------------------------

# Add combined named list to new dataset.
num_regs <- ncol(dataset) - 1
names(dataset) <- c("", paste0("(", 1:num_regs, ")"))

# Gen alignment string for latex: e.g. lcccc.
alignstring <- c("l", rep("c", num_regs))

# Get indices
striperow <- getrowids(dataset, "19")

#dataset <- dataset[-1, ]

## C. MAKE TABLE ---------------------------------------------------------------

# KABLE FUNCTION FOR COMBINED ROWS.
rca_table <- knitr::kable(dataset, 
                          format = "latex", 
                          digits = 2,
                          booktabs = TRUE, 
                          longtable = FALSE,
                          row.names = FALSE,
                          escape = FALSE,
                          align = alignstring,
                          caption = tablecaptionstring,
                          label = tablelabelstring, 
                          linesep = "" ) %>%
  
  # Adding coefficient indents for clarity
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
  # Add header rows
  kableExtra::add_header_above(c("",
                                 "RCA (Balassa)" = 1,
                                 "RCA (log)" = 1,
                                 "Relative Export\nProd. (CDK)" = 1,
                                 "Prob. of \nComp. Adv." = 1,
                                 "Export Share (log)" = 1)) %>%
  kableExtra::add_header_above(c("",
                                 "Outcomes: Export development" = num_regs),
                               line = TRUE,
                               bold = FALSE, 
                               align = "c",
                               font_size = font_size_argument + 1)

## ========================================================================== ##
## VI. SAVE THE KABLE TABLE ------------------------------------------------------
## ========================================================================== ##

output_file <- file.path( tables_supplementalappendix_dir, 
                          "tablerollingrca.tex")

cat(rca_table, file = output_file)

testthat::test_that("Rolling RCA kable is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})
