## =============================================================================
# PURPOSE:
#   Creates tables showing dynamic differences-in-differences estimates for the
#   relationship between forward linkage exposure and downstream export performance.
#
# INPUTS:
#   - did_io_comtrade_rolling_bothlink_allvars_4estout.csv
#
# OUTPUTS:
#   - tablerollingforwardtrade.tex
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS. -------------------------------------------------
## ========================================================================== ##

tablelabelstring <- "supprcaforwardlink"
tablecaptionstring <- "Forward Linkage Exposure on Downstream Export Performance"

## PREPARE NOTES ----------------------------------------------------

footnotestring <- "This table reports shows dynamic differences-in-differences estimates for the relationship between forward linkage exposure and export development. RCA is the conventional Balassa measure of comparative advantage; asinh-transformed RCA is also shown. CDK is a relative export productivity measure. . Estimates are relative to 1972, the year before HCI. All specifications include industry and year effects. 'Full sample' refers to estimates for full sample of all manufacturing industries; full-sample regressions include controls for HCI sectors (Targeted x Year). 'Non-HCI Sample' refers to sample excluding treated industry. All regressions include controls for both linkage types. Standard errors are clustered at the industry level. * Significant at the 10 percent level. ** Significant at the 5 percent level. *** Significant at the 1 percent level."

# Font size argument for the table
font_size_argument <- 7

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')


## ========================================================================== ##
# II. SUB-FUNCTIONS: Helper and sub-helper functions. --------------------------
## ========================================================================== ##

## A. Get row IDs using REGEX. -------------------------------------------------

getrowids <- function(dataset, regexstring) {
  rowindex <- paste0(regexstring) %>%
    grepl(., dataset[[1]]) %>%
    which(dataset[., ]) %>%
    as.numeric()
  return(rowindex)
}

## B. Loading function ---------------------------------------------------------

loadandcleanestouttable <- function(table_file) {
  dataset <- file.path(intermediate_dir, paste0(table_file)) %>%
    utils::read.csv(file = ., sep = "\t", header = TRUE)
  
  testthat::test_that("Prepared data.frame is not empty", {
    testthat::expect_false(plyr::empty(dataset))
  })
  
  # Exclude the BACKWARD LINKAGE ROWS for visibility
  toprow <- min(getrowids(dataset, "make"))
  bottomrow <- max(getrowids(dataset, "make")) + 1
  dataset <- dataset %>% dplyr::slice(-(toprow):-(bottomrow))
  
  # Set strings for linkage selection
  regexstring_forward <- "\\.\\#c\\..*hci.*([uU]se|\\_in).*0"
  regexstring_backward <- "\\.\\#c\\..*hci.*([mM]ake|\\_out).*0"
  
  # Clean row strings
  dataset[, 1] <- dataset[, 1] %>%
    stringr::str_replace_all("year", "") %>%
    stringr::str_replace_all(paste0(regexstring_forward), " \\\\(\\\\times\\\\) Forward Link") %>%
    stringr::str_replace_all(paste0(regexstring_backward), "  \\\\(\\\\times\\\\) Backward Link")
  
  # Remove duplicate control/fe row indicators
  dataset <- dataset[!duplicated(dataset), ]
  
  testthat::test_that("Prepared data.frame is not empty", {
    testthat::expect_false(plyr::empty(dataset))
  })
  
  return(dataset)
}

## ========================================================================== ##
# III. LOAD AND PREPARE DATA. --------------------------------------------------
## ========================================================================== ##

## A. Load and clean datasets --------------------------------------------------
table_file <- "did_io_comtrade_rolling_bothlink_allvars_4estout.csv"

dataset <- loadandcleanestouttable(table_file)

# Remove first row if it contains variable names
sumtrue <- sum(grepl("[_aA-zZ]{4}", dataset[1, ]))
if (sumtrue >= 3) {
  dataset <- dataset[-1, ]
}

testthat::test_that("Prepared data.frame is not empty", {
  testthat::expect_false(plyr::empty(dataset))
})

## ========================================================================== ##
# IV. MAKE THE TABLE -----------------------------------------------------------
## ========================================================================== ##

## A. GET TABLE DIMENSIONS -----------------------------------------------------

num_regs <- ncol(dataset) - 1
names(dataset) <- c("", paste0("(", 1:num_regs, ")"))
align_string <- c("l", rep("c", num_regs))

# Get indices for striped rows
striperow <- getrowids(stackeddatasets, "19")

# Sample vector names
vectorofnames <- c("", rep(c("Full\nSample", "Non-HCI\nOnly"), num_regs / 2))

## B. MAKE KABLE ---------------------------------------------------------------

# Create the main table using kable and kableExtra
rca_link_table <- knitr::kable(
  dataset,
  format = "latex",
  digits = 2,
  booktabs = TRUE,
  longtable = FALSE,
  row.names = FALSE,
  escape = FALSE,
  align = align_string,
  caption = tablecaptionstring,
  label = tablelabelstring,
  linesep = ""
) %>%
  kableExtra::add_indent(1:max(striperow), level_of_indent = 1) %>%
  kableExtra::add_header_above(
    vectorofnames,
    italic = FALSE,
    bold = FALSE,
    line = TRUE,
    escape = FALSE,
    font_size = font_size_argument - 1,
    align = "c"
  ) %>%
  kableExtra::kable_styling(
    latex_options = c("scale_down", "repeat_header", "striped"),
    protect_latex = TRUE,
    stripe_index = striperow,
    full_width = FALSE,
    table.envir = "table",
    font_size = font_size_argument - 1
  ) %>%
  kableExtra::footnote(
    general = footnotestring,
    general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
    footnote_as_chunk = TRUE,
    threeparttable = TRUE,
    escape = FALSE
  ) %>%
  kableExtra::add_header_above(
    c(
      "",
      "RCA (Balassa)" = 2,
      "RCA (log)" = 2,
      "Relative Export \n Product. (CDK)" = 2
    ),
    font_size = font_size_argument,
    line = TRUE,
    align = "c"
  ) %>%
  kableExtra::add_header_above(
    c("", "Export outcomes (1965-1986)" = num_regs),
    line = TRUE,
    line_sep = 2,
    align = "c",
    font_size = font_size_argument + 1
  )

## ========================================================================== ##
## V. SAVE THE KABLE TABLE ------------------------------------------------------
## ========================================================================== ##

output_file <- file.path( tables_supplementalappendix_dir, 
                          "tablerollingforwardtrade.tex")

cat(rca_link_table, file = output_file)

testthat::test_that("Rolling Forward Linkage Trade kable is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})



