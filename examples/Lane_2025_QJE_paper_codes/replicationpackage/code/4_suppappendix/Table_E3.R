## =============================================================================
# PURPOSE:
#   Creates tables showing dynamic differences-in-differences estimates for the
#   relationship between forward linkage exposure and downstream industrial development.
#
# INPUTS:
#   - did_io_moredev_rolling_bothlink_allvars_5estout.csv
#   - did_io_moredev_rolling_bothlink_allvars_4estout.csv
#
# OUTPUTS:
#   - tablerollingforwarddev.tex
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS. -------------------------------------------------
## ========================================================================== ##

tablecaptionstring <- "Direct Forward Linkage Exposure and Downstream Industrial Development"
tablelabelstring <- "subrollingforwarddev"

footnotestring <- "This table reports dynamic differences-in-differences estimates for the relationship between forward linkage exposure and development outcomes . Estimates are relative to 1972, the year before HCI. All specifications include industry and year effects. Panel A shows estimates using detailed 5-digit level industrial data (1970-1986). Panel B shows estimates using longer, aggregate 4-digit level industrial data (1967-1986). 'Full sample' refers to estimates for full sample of all manufacturing industries; full-sample regressions include controls for HCI sectors (Targeted x Year). 'Non-HCI Sample' refers to sample excluding treated industry. All regressions include controls for both linkage types. Standard errors are clustered at the industry level. * Significant at the 10 percent level. ** Significant at the 5 percent level. *** Significant at the 1 percent level."

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
  
  toprow <- min(getrowids(dataset, "make"))
  bottomrow <- max(getrowids(dataset, "make")) + 1
  
  dataset <- dataset %>%
    dplyr::slice(-(toprow):-(bottomrow))
  
  regexstring_forward <- "\\.\\#c\\..*hci.*([uU]se|\\_in).*0"
  regexstring_backward <- "\\.\\#c\\..*hci.*([mM]ake|\\_out).*0"
  
  dataset[, 1] <- dataset[, 1] %>%
    stringr::str_replace_all("year", "") %>% 
    stringr::str_replace_all(paste0(regexstring_forward), " \\\\(\\\\times\\\\) Fwd Link") %>% 
    stringr::str_replace_all(paste0(regexstring_backward), " \\\\(\\\\times\\\\) Bwd. Link")
  
  dataset <- dataset[!duplicated(dataset), ]
  
  testthat::test_that("Prepared data.frame is not empty", {
    testthat::expect_false(plyr::empty(dataset))
  })
  
  return(dataset)
}

## ========================================================================== ##
# III. LOAD AND PREPARE DATA.---------------------------------------------------
## ========================================================================== ##

## A. Load and clean datasets --------------------------------------------------

outputfileA <- "did_io_moredev_rolling_bothlink_allvars_5estout.csv"
outputfileB <- "did_io_moredev_rolling_bothlink_allvars_4estout.csv"

datasetA <- loadandcleanestouttable(outputfileA)
datasetB <- loadandcleanestouttable(outputfileB)

sumtrue <- sum(grepl("[_aA-zZ]{4}", datasetA[1, ]))

if (sumtrue >= 3) {
  datasetA <- datasetA[-1, ]
  datasetB <- datasetB[-1, ]
}

## B. Make blank chunk for 5-digit data frame. ---------------------------------

gap_nrow <- nrow(datasetB) - nrow(datasetA)
blankpadding <- data.frame(matrix(ncol = ncol(datasetA), nrow = gap_nrow))
names(blankpadding) <- names(datasetA)
datasetA <- rbind(blankpadding, datasetA)

## C. Combine datasets ---------------------------------------------------------

stackeddatasets <- cbind(datasetB[, 1], datasetA[, -1], datasetB[, -1])

testthat::test_that("Test that prepared data.frame is not empty", {
  testthat::expect_false(plyr::empty(stackeddatasets))
})

## ========================================================================== ##
# IV. MAKE THE TABLE -----------------------------------------------------------
## ========================================================================== ##

## A. GET TABLE DIMENSIONS -----------------------------------------------------

num_regs <- ncol(stackeddatasets) - 1
names(stackeddatasets) <- c("", paste0("(", 1:num_regs, ")"))
align_string <- c("l", rep("c", num_regs))

striperow <- getrowids(stackeddatasets, "19")
vectorofnames <- c("", rep(c("Full\nSample", "Non-HCI\nOnly"), num_regs / 2))

## B. MAKE KABLE ---------------------------------------------------------------

# KABLE FUNCTION FOR COMBINED ROWS.
more_linkmore_table <- knitr::kable(
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
    font_size = font_size_argument - 1,
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
    c(
      "",
      "Employment" = 2,
      "Num. Plants" = 2,
      "Labor Prod." = 2,
      "TFP" = 2,
      "Avg. Wages" = 2,
      "Employment" = 2,
      "Num. Plants" = 2,
      "Labor Prod." = 2,
      "Avg. Wages" = 2
    ),
    line = TRUE,
    align = "c"
  ) %>%
  kableExtra::add_header_above(
    c(
      " ",
      "Panel A) Five-Digit Panel (1970-1986)" = ncol(datasetA) - 1,
      "Panel B) Four-Digit Panel (1967-1986)" = ncol(datasetB) - 1
    ),
    line = TRUE,
    line_sep = 2,
    align = "c",
    font_size = font_size_argument,
    bold = FALSE
  )

## ========================================================================== ##
## V. SAVE THE KABLE TABLE ------------------------------------------------------
## ========================================================================== ##

output_file <- file.path( tables_supplementalappendix_dir, 
                          "tablerollingforwarddev.tex")

cat(more_linkmore_table, file = output_file)

testthat::test_that("Rolling Forward Linkage MoreVars kable is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})


