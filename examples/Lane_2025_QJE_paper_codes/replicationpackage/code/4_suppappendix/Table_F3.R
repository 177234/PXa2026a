## =============================================================================
# PURPOSE:
#   Creates LaTeX tables for total backward linkage analysis by processing regression
#   output located in the /analysis directory.
#
# INPUTS:
#   - did_iolf_main_rolling_bothlink_l_valueadded_5estout.csv
#   - did_iolf_main_rolling_bothlink_l_valueadded_4estout.csv
#
# OUTPUTS:
#   - backlinkoutputlf.tex
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS. -------------------------------------------------
## ========================================================================== ##

# Generate cleaned ESTOUT tables.
tablecaptionstring <- "Total Backward Linkage Exposure and Upstream Output"
tablelabelstring <- "supptablebacklinkoutputlf"

footnotestring <- "This table reports dynamic differences-in-differences estimates for the relationship between backward linkage exposure and output or real value added . Estimates are relative to 1972, the year before HCI. All specifications include industry and year effects. Panel A shows estimates using detailed 5-digit level industrial data (1970-1986). Panel B shows estimates using longer, aggregate 4-digit level industrial data (1967-1986). 'Full sample' refers to estimates for full sample of all manufacturing industries; full-sample regressions include controls for HCI sectors (Targeted x Year). 'Non-HCI Sample' refers to sample excluding treated industry. Standard errors are clustered at the industry level. * Significant at the 10 percent level. ** Significant at the 5 percent level. *** Significant at the 1 percent level." 

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

## C. Loading function ---------------------------------------------------------

loadandcleanestouttable <- function(table_file) {
  dataset <- file.path(intermediate_dir, paste0(table_file)) %>%
    read.csv(file = ., sep = "\t", header = TRUE)
  
  toprow <- min(getrowids(dataset, "use"))
  bottomrow <- max(getrowids(dataset, "use")) + 1
  
  dataset <- dataset %>%
    dplyr::slice(-(toprow):-(bottomrow))
  
  regexstring_forward <- "\\.\\#c\\..*hci.*([uU]se|\\_in).*0"
  regexstring_backward <- "\\.\\#c\\..*hci.*([mM]ake|\\_out).*0"
  
  dataset[,1] <- dataset[,1] %>%
    stringr::str_replace_all("year", "") %>% 
    stringr::str_replace_all(paste0(regexstring_forward), " \\\\(\\\\times\\\\) Forward Link") %>% 
    stringr::str_replace_all(paste0(regexstring_backward), " \\\\(\\\\times\\\\) Backward Link")
  
  dataset <- dataset[!duplicated(dataset), ]
  
  testthat::test_that("Prepared data.frame is not empty", {
    testthat::expect_equal(plyr::empty(dataset), FALSE)
  })
  
  return(dataset)
}

## ========================================================================== ##
# III. LOAD AND PREPARE DATA.---------------------------------------------------
## ========================================================================== ##

## A. Load and clean datasets --------------------------------------------------

outputfileA <- "did_iolf_main_rolling_bothlink_l_valueadded_5estout.csv"
outputfileB <- "did_iolf_main_rolling_bothlink_l_valueadded_4estout.csv"

datasetA <- loadandcleanestouttable(outputfileA)
datasetB <- loadandcleanestouttable(outputfileB)

testthat::test_that("Number of columns in datasets are equal", {
  testthat::expect_equal(length(datasetA), length(datasetB))
})

## B. Make blank chunk for 5-digit data frame. ---------------------------------

gap_nrow <- nrow(datasetB) - nrow(datasetA)
blankpadding <- data.frame(matrix(ncol = ncol(datasetA), nrow = gap_nrow))
names(blankpadding) <- names(datasetA)
datasetA <- rbind(blankpadding, datasetA)

## C. Combine datasets ---------------------------------------------------------

stackeddatasets <- cbind(datasetB[,1], datasetA[,-1], datasetB[,-1])

testthat::test_that("Prepared data.frame is not empty", {
  testthat::expect_equal(plyr::empty(stackeddatasets), FALSE)
})

## ========================================================================== ##
# IV. MAKE THE TABLE -----------------------------------------------------------
## ========================================================================== ##

## A. GET TABLE DIMENSIONS -----------------------------------------------------

num_regs <- ncol(stackeddatasets) - 1
names(stackeddatasets) <- c("", paste0("(", 1:num_regs, ")"))
align_string <- c("l", rep("c", num_regs))
striperow <- getrowids(stackeddatasets, "19")
vectorofnames <- c("", rep(c("Full\nsample", "Non-HCI\nonly"), num_regs/2))

## B. MAKE KABLE ---------------------------------------------------------------

# Create the main table using kable and kableExtra
back_lfoutput_table <- knitr::kable(
  stackeddatasets,
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
    align = "c"
  ) %>%
  kableExtra::kable_styling(
    latex_options = c("scale_down", "repeat_header", "striped"),
    protect_latex = TRUE,
    stripe_index = striperow,
    repeat_header_text = "\\textit{(continued)}",
    repeat_header_continued = TRUE,
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
    c(" ", "Outcome: Value added (log)" = num_regs),
    line = TRUE,
    bold = TRUE,
    align = "c",
    font_size = font_size_argument + 2
  )

## ========================================================================== ##
## V. SAVE THE KABLE TABLE ------------------------------------------------------
## ========================================================================== ##

output_file <- file.path( tables_supplementalappendix_dir, 
                          "backlinkoutputlf.tex")

cat(back_lfoutput_table, file = output_file)

testthat::test_that("Kable is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})
