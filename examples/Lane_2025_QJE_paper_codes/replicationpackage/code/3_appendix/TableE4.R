## ========================================================================== ###
#   PURPOSE: 
#
#        Linkage/Leontief tables for robustness/appendix.
#
#   INPUTS:
#       
#       # Generate cleaned ESTOUT tables.
#       outputfileA <- "did_iolf_moredev_prepost_bothlink_allvars_5estout.csv"
#       outputfileB <- "did_iolf_moredev_prepost_bothlink_allvars_4estout.csv"
#
#   OUTPUTS:
# 
#       avg_lf_moredev_kable to render in the RMARKDOWN.
#
## =============================== TOP MATTER =============================== ##


## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS.-----------------------------------------------
## ========================================================================== ##

font_size_argument <- 9
table_label_string <- "appprepostlfmoredev"
table_caption_string <- "Total Linkage Exposure and Industrial Development"
footnote_string <- "This table shows average differences-in-differences estimates,
before and after 1973. Estimates come from the main DD linkage specification. Both linkage
interactions (forward and backward) are shown. Note that dynamic figures present 
only estimates for the linkage of interest."

# This remove linebreaks in footnote string (above) just in case. 
footnote_string <- gsub( "\\n" , " " , footnote_string )

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')


## ========================================================================== ##
# II. SUB-FUNCTIONS: Helper and sub-helper functions. -----------------------
## ========================================================================== ##


## ========================================================================== ##
## A. Loading function ---------------------------------------------------------
loadandcleanestouttable <- function(table_file) {
  
  # Construct file path and read CSV.
  dataset <- file.path(intermediate_dir, table_file) %>%
    utils::read.csv(file = ., sep = "\t", header = TRUE)
  
  # Clean column names by removing special characters.
  names(dataset) <- stringr::str_replace_all(names(dataset), "[._aA-zZ]", "")
  
  # Define regex patterns for linkage selection.
  regexstring_forward <- "\\#c\\..*hci.*([uU]se|\\_in|orward).*0"
  regexstring_backward <- "\\#c\\..*hci.*([mM]ake|\\_out|ackward).*0"
  
  # Clean row strings based on regex patterns.
  dataset[[1]] <- dataset[[1]] %>%
    stringr::str_replace_all(regexstring_forward, "Forward Linkage") %>%
    stringr::str_replace_all(regexstring_backward, "Backward Linkage") %>%
    stringr::str_replace_all("1.post|1.Post|postc", "Post \\\\(\\\\times\\\\) ") %>%
    stringr::str_replace_all("1.hci#c.h_", "Targeted \\\\(\\\\times\\\\) ")
  
  # Remove duplicated rows.
  dataset <- dataset[!duplicated(dataset), ]
  
  # Preserve original column names.
  names_preserve <- names(dataset)
  
  # Re-apply original column names.
  names(dataset) <- names_preserve
  
  # Test to ensure the prepared data frame is not empty.
  testthat::test_that("Prepared data.frame is not empty.", {
    testthat::expect_false(plyr::empty(dataset))
  })
  
  return(dataset)
}


## ========================================================================== ##
# III. LOAD AND PREPARE DATA.---------------------------------------------------
## ========================================================================== ##


# Define input file names.
outputfileA <- "did_iolf_moredev_prepost_bothlink_allvars_5estout.csv"
outputfileB <- "did_iolf_moredev_prepost_bothlink_allvars_4estout.csv"

# Load and clean datasets using helper function.
datasetA <- loadandcleanestouttable(outputfileA)
datasetB <- loadandcleanestouttable(outputfileB)

# Combine datasets side by side, excluding the first column of datasetB.
sidebysidedatasets <- cbind(datasetA, datasetB[ , -1])

# Update column names with parentheses.
names(sidebysidedatasets) <- c("", paste0("(", names(sidebysidedatasets)[-1], ")"))

# Determine the number of columns for panels A and B.
ncol_panel_a <- ncol(datasetA) - 1
ncol_panel_b <- ncol(datasetB) - 1

# Test to ensure the combined dataset is not empty.
testthat::test_that("Prepared side-by-side data.frame is not empty.", {
  testthat::expect_false(plyr::empty(sidebysidedatasets))
})

# Calculate the number of regression columns in the table.
nreg_in_table <- (ncol(datasetA) - 1) * 2

# Create a vector of sample names for labeling.
vectorofsamplenames <- c("Sample", rep(c("Full", "Non-HCI"), ncol_panel_a / 2 + ncol_panel_b / 2))

# Test to ensure the length of sample names matches the number of columns.
testthat::test_that("Number of sample names matches the number of columns.", {
  testthat::expect_equal(length(sidebysidedatasets), length(vectorofsamplenames))
})

# Append sample names as the last row of the dataset.
sidebysidedatasets <- rbind(sidebysidedatasets, vectorofsamplenames)


## ========================================================================== ##
# IV. MAKE WIDE TABLE KABLE OUT.-------------------------------------------------
## ========================================================================== ##


## ========================================================================== ##
## A. SETUP HEADER AND KABLE DIMENSIONS ----------------------------------------

# Define alignment for table columns.
alignstring <- c("l", rep("c", nreg_in_table))


## ========================================================================== ##
## B. MAKE KABLE TABLE --------------------------------------------------------

avg_lf_moredev_kable <- knitr::kable(
  sidebysidedatasets[-1, ], 
  format = "latex",
  digits = 3,
  booktabs = TRUE, 
  longtable = FALSE,
  row.names = FALSE,
  escape = FALSE,
  align = alignstring,
  caption = table_caption_string,
  label = table_label_string,
  linesep = ""
) %>%
  
  # Add first header above the table columns.
  kableExtra::add_header_above(
    c(
      "",
      "Employment" = 2,
      "Num. Plants" = 2,
      "Labor Prod." = 2,
      "TFP (ACF)" = 2,
      "Avg. Wage." = 2,
      "Employment" = 2,
      "Num. Plants" = 2,
      "Labor Prod." = 2,
      "Avg. Wage." = 2
    ),
    line = TRUE,
    align = "c",
    font_size = font_size_argument + 1
  ) %>%
    
  # Outcome row headder:
  kableExtra::add_header_above(
    c(
      "",
      "Outcomes (log)\n" = ncol_panel_a ,
      "Outcomes (log)\n" = ncol_panel_b
    ),
    line = FALSE,
    align = "c",
    font_size = font_size_argument + 1,
    bold = FALSE
  ) %>%
  # Add second header specifying panel details.
  kableExtra::add_header_above(
    c(
      " ",
      "Panel A) Five-Digit Panel (1970-1986)" = ncol_panel_a,
      "Panel B) Four-Digit Panel (1967-1986)" = ncol_panel_b
    ),
    line = TRUE,
    line_sep = 1,
    align = "c",
    font_size = font_size_argument + 1,
    bold = FALSE
  ) %>%
  
  # Apply styling options to the table.
  kableExtra::kable_styling(
    latex_options = c("scale_down", "repeat_header"), 
    protect_latex = TRUE,
    repeat_header_text = "\\textit{(continued)}",
    repeat_header_continued = TRUE,
    full_width = FALSE, 
    table.envir = "table", 
    font_size = font_size_argument
  ) %>% 
  
  # Add footnotes to the table.
  kableExtra::footnote(
    general = footnote_string, 
    general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
    footnote_as_chunk = TRUE,
    threeparttable = TRUE,
    escape = FALSE
  )

## ========================================================================== ##
# VI. SAVE THE KABLE TABLE ------------------------------------------------
## ========================================================================== ##
output_file <- file.path(
  tables_appendix_dir,
  "avg_lf_moredev_kable.tex"
)

cat(avg_lf_moredev_kable, file = output_file)

testthat::test_that("Kable table is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})
