## =============================================================================
# PURPOSE:
#   Creates tables showing triple difference estimates for the impact of Korean
#   HCI drive using SITC-level trade data.
#
# INPUTS:
#   - did_largerolling_koreatrade_rca_results_estout.csv
#
# OUTPUTS:
#   - tablerollingdddrca.tex
# ==============================================================================

## ================================================================================== ##
# I. TEXT AND TABLE ARGUMENTS
## ================================================================================== ##

## PREPARE TITLES AND SUBTITLES, TEX LABELS -------------------------
tablecaptionstring <- "Cross-Country Estimates (Triple Differences): Industrial Policy and Export Development"
tablelabelstring <- "supprollingddd"


## PREPARE NOTES ---------------------------------------------------

footnotestring <- "This table reports triple difference estimates (DDD) for the impact of Korean HCI drive using SITC-level trade data. Estimates are relative to 1972, the year before the HCI policy intervention. RCA (Balassa) specifications are estimated using PPML. Alternatively, transformed RCAs and relative export productivity (CDK) specifications are estimated using OLS. For each outcome, the first regression column includes Industry, Country, and Year fixed effects. The second column for each outcome includes Country-Year and Industry-Year fixed effects. The third column for each outcome includes Country-Year, Industry-Year, and Industry-Country fixed effects. Standard errors are clustered at the industry and country level. * Significant at the 10 percent level. ** Significant at the 5 percent level. *** Significant at the 1 percent level."

# Font size argument for the table
font_size_argument <- 7

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')

## ================================================================================== ##
# II. SUB-FUNCTIONS
## ================================================================================== ##

# A. Get row IDs using REGEX
getrowids <- function(dataset, regexstring) {
  # Get row numbers matching regexstring in the first column of dataset
  rowindex <- grepl(regexstring, dataset[[1]]) %>% which()
  # Return integer vector of row indices
  return(as.numeric(rowindex))
}

# B. Variable cleaning function
cleantablevariablelist_helper <- function(dataset_argument) {
  cleaned_dataset <- dataset_argument %>%
    stringr::str_replace_all("1.korea", "x Korea") %>%
    stringr::str_replace_all("year", "") %>%
    stringr::str_replace_all("hci", "Targeted \\\\(\\\\times\\\\) ")
  return(cleaned_dataset)
}

## ================================================================================== ##
# III. MAIN FUNCTION
## ================================================================================== ##

# Helper function for loading and cleaning the dataset
loadandcleanestouttable <- function(table_file) {
  # Read the ESTOUT CSV into a dataframe
  dataset <- file.path(intermediate_dir, table_file) %>%
    read.csv(file = ., sep = "\t", header = TRUE)
  
  # Test that the prepared data.frame is not empty
  testthat::test_that("Prepared data.frame is not empty", {
    testthat::expect_equal(plyr::empty(dataset), FALSE)
  })
  
  # Clean column names
  names(dataset) <- stringr::str_replace_all(names(dataset), "[._aA-zZ]", "")
  
  # Clean row strings only
  dataset[, 1] <- stringr::str_replace_all(dataset[, 1], c(
    "(_n)" = "",
    "(l|h)_" = "",
    "_" = " ",
    "^(l|h)" = "",
    "#1.korea" = "X Korea",
    "1.hci#" = "Targ. X ",
    ".year" = " ",
    "[Rr].*[Ss]quared" = "R2"
  ))
  
  # Remove duplicate rows
  dataset <- dataset[!duplicated(dataset), ]
  
  # Test that the dataset is not empty after cleaning
  testthat::test_that("Dataset is not empty after cleaning", {
    testthat::expect_equal(plyr::empty(dataset), FALSE)
  })
  
  return(dataset)
}

## ================================================================================== ##
# V. MAKE THE TABLE ------------------------------------------------------------
## ================================================================================== ##

## A. Load and clean datasets --------------------------------------------------
outputfile <- "did_largerolling_worldtrade_ppml_rca_results_estout.csv"

# Clean estout data
dataset <- loadandcleanestouttable(outputfile)

min_row_to_keep <- min(getrowids(dataset, "Korea"))
dataset <- dataset[-seq(2, min_row_to_keep - 1), ]

### B. Add Variable Names to the Dataset ---------------------------------------
# Number of columns
num_regs <- ncol(dataset) - 1

# Generate column names
names(dataset) <- c("", paste0("(", 1:num_regs, ")"))


### C. Create table arguments --------------------------------------------------
stripe_rows <- getrowids(dataset, "19")

# Create alignment string for kable
align_string <- c("l", rep("c", num_regs))

# Replace first row with blanks
dataset[1, ] <- rep("", num_regs + 1)

# Create the header list with column spans
header_list <- c(
  " " = 1,
  "Relative Export\nProductivity (CDK)" = 3,
  "Probability of\nComparative Advantage" = 3,
  "RCA (Balassa)" = 3,
  "RCA (log)" = 3
)

## D MAKE THE TABLE ------------------------------------------------------------

# Generate the kable table
tablerollingdddrca <- dataset %>%
  knitr::kable(
    format = "latex",
    longtable = FALSE,
    booktabs = TRUE,
    row.names = FALSE,
    escape = FALSE,
    align = align_string,
    caption = tablecaptionstring,
    label = tablelabelstring,
    linesep = ""
  ) %>%
  kableExtra::kable_styling(
    latex_options = c("hold_position", "scale_down", "striped"),
    font_size = font_size_argument, 
    stripe_index = stripe_rows
  ) %>%
  # Add headers to the table
  kableExtra::add_header_above(
    header = header_list,
    align = "c",
    bold = FALSE,
    font_size = font_size_argument + 1
  ) %>%
  # Add extra space after the last row
  kableExtra::row_spec(
    nrow(dataset) + 1,
    extra_latex_after = "\\addlinespace[1em]"
  ) %>%
  # Add footnote
  kableExtra::footnote(
    general = footnotestring,
    general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
    footnote_as_chunk = TRUE,
    threeparttable = TRUE,
    escape = FALSE
  ) %>%
  # Add overarching header
  kableExtra::add_header_above(
    header = c(" " = 1, "Outcomes: Export Development" = num_regs),
    line = TRUE,
    font_size = font_size_argument + 1,
    line_sep = 2,
    bold = TRUE
  )

## ========================================================================== ##
## VI. SAVE THE KABLE TABLE ------------------------------------------------------
## ========================================================================== ##

output_file <- file.path( tables_supplementalappendix_dir, 
                          "tablerollingdddrca.tex")

cat(tablerollingdddrca, file = output_file)

testthat::test_that("DD Yearly RCA kable is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})

