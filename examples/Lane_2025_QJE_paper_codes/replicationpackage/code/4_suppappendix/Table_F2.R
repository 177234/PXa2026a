## =============================================================================
# PURPOSE:
#   Creates LaTeX tables for backward linkage price analysis by processing regression
#   output located in the /analysis directory.
#
# INPUTS:
#   - did_io_main_rolling_bothlink_l_ppi_5estout.csv
#   - did_io_main_rolling_bothlink_l_ppi_4estout.csv
#
# OUTPUTS:
#   - tablebacklinkprices.tex
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS. -------------------------------------------------
## ========================================================================== ##


tablecaptionstring <- "Direct Backward Linkage Exposure and Upstream Prices"
tablelabelstring <- "supptablebacklinkprices"

footnotestring <- "This table reports dynamic differences-in-differences estimates for the relationship between backward linkage exposure and output or real value added . Estimates are relative to 1972, the year before HCI. All specifications include industry and year effects. Panel A shows estimates using detailed 5-digit level industrial data (1970-1986). Panel B shows estimates using longer, aggregate 4-digit level industrial data (1967-1986). 'Full sample' refers to estimates for full sample of all manufacturing industries; full-sample regressions include controls for HCI sectors (Targeted x Year). 'Non-HCI Sample' refers to sample excluding treated industry. All regressions include controls for both linkage types. Standard errors are clustered at the industry level. * Significant at the 10 percent level. ** Significant at the 5 percent level. *** Significant at the 1 percent level."

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
    read.csv(file = ., sep = "\t", header = TRUE)
  
  testthat::test_that("Prepared data.frame is not empty", {
    expect_equal(plyr::empty(dataset), FALSE)
  })
  
  # Exclude the FORWARD LINKAGE ROWS for visibility.
  toprow <- min(getrowids(dataset, "use"))
  bottomrow <- max(getrowids(dataset, "use"))+1
  
  # Exclude "use/forward linkage" chunk.
  dataset <- dataset %>%
    dplyr::slice(-(toprow):-(bottomrow))
  
  # Set strings for linkage selection:
  regexstring_forward <- "\\.\\#c\\..*hci.*([uU]se|\\_in).*0"
  regexstring_backward <- "\\.\\#c\\..*hci.*([mM]ake|\\_out).*0"
  
  ## Clean row strings only.
  dataset[,1] <- dataset[,1] %>%
    stringr::str_replace_all("year", "") %>%
    stringr::str_replace_all(paste0(regexstring_forward), " \\\\(\\\\times\\\\) Forward Link") %>%
    stringr::str_replace_all(paste0(regexstring_backward), " \\\\(\\\\times\\\\) Backward Link")
  
  # Remove duplicate control/fe row indicators.
  dataset <- dataset[!duplicated(dataset), ]
  
  # TEST: Prepared data.frame is empty.
  test_that("Prepared data.frame is empty.", {
    expect_equal(plyr::empty(dataset), FALSE)
  })
  
  return(dataset)
}


## ========================================================================== ##
# III. LOAD AND PREPARE DATA.---------------------------------------------------
## ========================================================================== ##


## A. Load and clean datasets --------------------------------------------------

# Generate cleaned ESTOUT tables.
outputfileA <- "did_io_main_rolling_bothlink_l_ppi_5estout.csv"
outputfileB <- "did_io_main_rolling_bothlink_l_ppi_4estout.csv"

## Get sum numbers from helper function:
datasetA <- loadandcleanestouttable(outputfileA)
datasetB <- loadandcleanestouttable(outputfileB)

test_that("Test sure n cols of datasets are equal", {
  expect_equal(length(datasetA), 
                length(datasetB))
})

## B. Make blank chunk for 5-digit data frame. ---------------------------------

# Make blank chunk for 5-digit data frame:
gap_nrow <- nrow(datasetB)-nrow(datasetA)
blankpadding <- data.frame(matrix(ncol = ncol(datasetA), 
                                  nrow = gap_nrow))

# Inherit names for blank space.
names(blankpadding) <- names(datasetA)

# Stack blank data onto dataset A
datasetA <- rbind(blankpadding, datasetA)


## C. Combine datasets ---------------------------------------------------------

# Bind both datasets and attach (side by side):
stackeddatasets <- cbind(datasetB[,1], 
                          datasetA[,-1] ,
                          datasetB[,-1] )

test_that("Test that prepared data.frame is not empty", {
  expect_equal(plyr::empty(stackeddatasets), FALSE)
})

## ========================================================================== ##
# IV. MAKE THE TABLE -----------------------------------------------------------
## ========================================================================== ##

## A. GET TABLE DIMENSIONS -----------------------------------------------------

# Add combined named list to new dataset.
num_regs <- ncol(stackeddatasets)-1
names(stackeddatasets) <- c("",paste0("(",1:num_regs,")"))

# Gen alignment string for latex: e.g. lcccc.
alignstring <- c("l",rep("c",num_regs))

# Get indices
striperow <- getrowids(stackeddatasets, "19")

# Sample
vectorofnames <- c("",rep(c("Full\nSample","Non-HCI\nOnly"), num_regs/2))


## B. MAKE KABLE ---------------------------------------------------------------

# KABLE FUNCTION FOR COMBINED ROWS.
back_linkprices_table <- kable(stackeddatasets, 
                                format = "latex", 
                                digits = 2,
                                booktabs = T , 
                                longtable = F ,
                                row.names = F ,
                                escape = FALSE,
                                align = alignstring ,
                                caption = tablecaptionstring ,
                                label = tablelabelstring,
                                linesep = "") %>%
  
  # Adding coefficient indents for clarity (distinguish from "pack row" labels).
  add_indent(. ,  1:max(striperow) , 
             level_of_indent = 1 ) %>% 
  
  add_header_above( . ,
                    vectorofnames ,
                    italic = FALSE,
                    bold = FALSE, 
                    line = TRUE ,
                    align = "c" ) %>% 
  
  kableExtra::kable_styling( . , 
                             latex_options = c("scale_down","repeat_header","striped"), 
                             protect_latex = TRUE,
                             stripe_index = striperow,
                             repeat_header_text = "\\textit{(continued)}",
                             repeat_header_continued = TRUE,
                             full_width = FALSE , 
                             table.envir = "table", 
                             font_size = font_size_argument - 1 ) %>%
  # Add footnote...
  footnote( general = footnotestring , 
            general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
            footnote_as_chunk = TRUE,
            threeparttable = TRUE,
            escape = FALSE ) %>%
  
  add_header_above(. ,
                   c(" ",
                     "Outcome: Output prices (log)" = num_regs ) ,
                   line = TRUE ,
                   bold = TRUE , 
                   align = "c" ,
                   font_size = font_size_argument + 2)


## ========================================================================== ##
## V. SAVE THE KABLE TABLE ------------------------------------------------------
## ========================================================================== ##

output_file <- file.path( tables_supplementalappendix_dir, 
                          "tablebacklinkprices.tex")

cat(back_linkprices_table, file = output_file)

testthat::test_that("Backward Linkage Prices kable is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})


