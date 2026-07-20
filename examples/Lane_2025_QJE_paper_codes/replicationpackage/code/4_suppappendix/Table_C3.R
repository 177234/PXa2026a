## =============================================================================
# PURPOSE:
#   Creates tables showing difference-in-difference estimates for the impact of
#   Korean HCI compared to world HCI industries using SITC-level trade data.
#
# INPUTS:
#   - did_largerolling_koreatrade_rca_results_estout.csv
#
# OUTPUTS:
#   - tablerollingddaltrca.tex
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS. ------------------------------------------------
## ========================================================================== ##

## PREPARE TITLES AND SUBTITLES, TEX LABELS -------------------------
tablecaptionstring <- "Cross-Country Estimates (Differences-in-Differences): Industrial Policy on Export Development"
tablelabelstring <- "supddcrosscountryaltrca"


## PREPARE NOTES ---------------------------------------------------

footnotestring <- "This table reports difference-in-difference estimates for the impact of Korean HCI as compared to world HCI industries using SITC-level trade data. Estimates are relative to 1972, the year before the HCI policy intervention. The RCA (Balassa) specifications are estimated using PPML. Alternatively, transformed RCAs and relative export productivity (CDK) specifications are estimated using OLS. Estimates are relative to 1972, the year before the HCI policy intervention. For each outcome, the first regression column does not include any fixed effects in the specification. The second column for each outcome includes Country fixed effects. The third column for each outcome includes Industry-Country fixed effects. Standard errors are clustered at the country-level. * Significant at the 10 percent level. ** Significant at the 5 percent level. *** Significant at the 1 percent level."

# Font size argument for the table
font_size_argument <- 7

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')

## ========================================================================== ##
# II. SUB-FUNCTIONS -----------------------------------------------------------
## ========================================================================== ##

## A. Get row IDs using REGEX. ------------------------------------------------

getrowids <- function(dataset, regexstring) {
  # Find the rows where regexstring matches the first column of the dataset
  matches <- grepl(regexstring, dataset[[1]])
  # Get the indices of matched rows
  row_indices <- which(matches)
  # Return indices as numeric vector
  return(as.numeric(row_indices))
}

## B. Variable Cleaning Function ----------------------------------------------

cleantablevariablelist_helper <- function(dataset_argument) {
  cleaned_dataset <- dataset_argument %>%
    stringr::str_replace_all("1.korea", "x Korea") %>%
    stringr::str_replace_all("year", "") %>%
    stringr::str_replace_all("hci", "Targeted \\\\(\\\\times\\\\) ")
  return(cleaned_dataset)
}

## ========================================================================== ##
# III. MAIN FUNCTION ----------------------------------------------------------
## ========================================================================== ##

# Helper function for loading and cleaning the dataset
loadandcleanestouttable <- function(table_file) {
  # Convert ESTOUT CSV into a dataframe
  dataset <- file.path(intermediate_dir, table_file) %>%
    read.csv(file = ., sep = "\t", header = TRUE)
  
  # Clean column names
  names(dataset) <- stringr::str_replace_all(names(dataset), "[._aA-zZ]", "")
  
  # Clean row strings only
  dataset[, 1] <- stringr::str_replace_all(
    dataset[, 1],
    c(
      "(_n)" = "",
      "(l|h)_" = "",
      "_" = " ",
      "^(l|h)" = "",
      "#1.korea" = "X Korea",
      "1.hci#" = "Targeted \\\\(\\\\times\\\\) ",
      ".year" = " ",
      "[Rr].*[Ss]quared" = "R2"
    )
  )
  
  # Remove duplicated rows
  dataset <- dataset[!duplicated(dataset), ]
  
  # Test that prepared data.frame is not empty
  # test_that("Prepared data.frame is not empty.", {
  #   expect_equal(plyr::empty(dataset), FALSE)
  # })
  
  return(dataset)
}

## ========================================================================== ##
# V. MAKE THE TABLE -----------------------------------------------------------
## ========================================================================== ##

## A. Load and clean datasets -------------------------------------------------

outputfile <- "did_largerolling_worldtrade_supp_ppml_rca_results_estout.csv"

# Clean estout data
dataset <- loadandcleanestouttable(outputfile)

# Get minimum row to keep based on "Korea"
min_row_to_keep <- min(getrowids(dataset, "Korea"))

# Uncomment the following line if rows need to be removed
# dataset <- dataset[-seq(2, min_row_to_keep - 1), ]

### B. Add Variable Names to the Dataset --------------------------------------

# Number of regressions
num_regs <- ncol(dataset) - 1

# Assign column names to the dataset
names(dataset) <- c("", paste0("(", 1:num_regs, ")"))

# Replace first row with blanks
dataset[1, ] <- rep("", num_regs + 1)

# Header list with column spans
header_list <- c(
  " " = 1,
  "Relative Export\nProductivity (CDK)" = 3,
  "Probability of\nComparative Advantage" = 3,
  "RCA (Balassa)" = 3,
  "RCA (log)" = 3
)

# Alignment string for Kable
align_string <- c("l", rep("c", num_regs))

# Stripe rows for Kable
stripe_rows <- getrowids(dataset, "19")


## C. Make the Table ----------------------------------------------------------

# Create the Kable table with appropriate formatting
tablerollingddaltrca <- dataset %>%
  knitr::kable(
    format = "latex",
    longtable = FALSE,
    booktabs = TRUE,
    row.names = FALSE,
    escape = FALSE,
    align = align_string,
    col.names = names(dataset),
    caption = tablecaptionstring,
    label = tablelabelstring,
    linesep = ""
  ) %>%
  # Style the Kable table
  kableExtra::kable_styling(
    latex_options = c("hold_position", "scale_down", "striped"),
    font_size = font_size_argument, 
    stripe_index = stripe_rows
  ) %>%
  # Add main header above the columns
  kableExtra::add_header_above(
    header_list,
    align = "c",
    include_empty = FALSE,
    line = TRUE,
    bold = FALSE,
    font_size = font_size_argument + 1
  ) %>%
  # Add extra spacing after the last row
  kableExtra::row_spec(
    nrow(dataset) + 1,
    extra_latex_after = "\\addlinespace[1em]"
  ) %>%
  # Add footnote to the table
  kableExtra::footnote(
    general = footnotestring,
    general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
    footnote_as_chunk = TRUE,
    threeparttable = TRUE,
    escape = FALSE
  ) %>%
  # Add an additional header above
  kableExtra::add_header_above(
    c(
      "",
      "Outcomes: Export Development" = num_regs
    ),
    line = TRUE,
    font_size = font_size_argument + 1,
    line_sep = 2,
    bold = TRUE
  )

## ========================================================================== ##
## VI. SAVE THE KABLE TABLE ------------------------------------------------------
## ========================================================================== ##

output_file <- file.path( tables_supplementalappendix_dir, 
                          "tablerollingddaltrca.tex")

cat(tablerollingddaltrca, file = output_file)

testthat::test_that("Supplemental yearly DD RCA kable is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})

