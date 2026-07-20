## =================================  NOTES ================================= ##
#
#   PURPOSE: 
#         
#         Creates the pre-post average Leontief linkage table for OUTPUT.
#
#   INPUTS:
#
#       - Files from estimation in STATA.
#       
#     Generate cleaned ESTOUT tables.
#     outputfileA <- "did_iolf_main_prepost_bothlink_l_valueadded_5estout.csv"
#     outputfileB <- "did_iolf_main_prepost_bothlink_l_valueadded_4estout.csv"
#
#   OUTPUTS:
#
#       This file creates GGPLOT objects for rendering:
#       "avg_lf_output_table"
#
## =============================== TOP MATTER =============================== ##



## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS.-----------------------------------------------
## ========================================================================== ##

# CURRENTLY IN THE RMARKDOWN CHUNK FOR TABLE.

font_size_argument <- 9
table_caption_string <- "Total Linkage Exposure and Output"
table_label_string <- "appendixprepostlfoutput"
footnote_string <- "This table shows average differences-in-differences estimates
, before and after 1973. Estimates come from the main DD linkage specification. Both linkage 
interactions (forward and backward) are shown. Note that dynamic figures present 
only estimates for the linkage of interest."

# This remove linebreaks in footnote string (above) just in case. 
footnote_string <- gsub( "\\n" , " " , footnote_string )

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')

## ========================================================================== ##
# II. SUB-FUNCTIONS: Helper and sub-helper functions. -----------------------
## ========================================================================== ##

#' Get row indices matching a regex pattern in the first column of a dataset.
#'
#' @param dataset Data frame to search.
#' @param regex_string Regular expression pattern to match.
#' @return Integer vector of row indices.
get_rows_helper <- function( dataset, regexstring ){
  
  # Get row number by REGEX string.
  rowindex <- which(grepl(  paste0( regexstring ) , dataset[,1] , ignore.case = TRUE))
  
  testthat::test_that("Row index is not empty.", {
    testthat::expect_equal(length(rowindex) > 0, TRUE)
  })
  
  # Return integer.
  return( rowindex )
  
}

loadandcleanestouttable <- function(table_file) {
  
  # Convert ESTOUT CSV into a dataframe.
  dataset <- file.path(intermediate_dir, table_file) %>%
              utils::read.csv(header = FALSE, sep = "\t")
  
  # Correct column names: lowercase and remove unwanted characters.
  names(dataset) <- names(dataset) %>%
    stringr::str_to_lower() %>%
    stringr::str_replace_all("[_a-z]", "") %>%
    stringr::str_replace_all("\\.", "")
  
  # Remove duplicate rows.
  dataset <- dataset[!duplicated(dataset), ]
  
  ## Filter "other" linkage than argument:
  
  # Define regex patterns for linkage selection.
  regexstring_forward <- "\\#c\\..*hci.*([uU]se|\\_in|orward).*0"
  regexstring_backward <- "\\#c\\..*hci.*([mM]ake|\\_out|ackward).*0"
  
  # Clean row strings with appropriate replacements.
  dataset[[1]] <- dataset[[1]] %>%
    stringr::str_replace_all("[Rr].*[Ss]quared", "R2") %>% 
    stringr::str_replace_all(regexstring_forward, "Forward Linkage") %>% 
    stringr::str_replace_all(regexstring_backward, "Backward Linkage") %>%
    # Replace control indicators from REGHDFE.
    stringr::str_replace_all("1.post", "Post \\\\(\\\\times\\\\) ") %>% 
    stringr::str_replace_all("1.Post", "Post \\\\(\\\\times\\\\) ") %>% 
    stringr::str_replace_all("postc", "Post \\\\(\\\\times\\\\) ")
  
  # Remove duplicate rows after cleaning.
  dataset <- dataset[!duplicated(dataset), ]
  
  # Remove the first row.
  dataset <- dataset[-1, ]
  
  # TEST: Ensure the prepared data.frame is not empty.
  testthat::test_that("Prepared data.frame is empty.", {
    testthat::expect_equal(plyr::empty(dataset), FALSE)
  })
  
  return(dataset)
}


## ========================================================================== ##
# III. LOAD AND PREPARE DATA.---------------------------------------------------
## ========================================================================== ##


# Define input file names.
table_fileA <- "did_iolf_main_prepost_bothlink_l_valueadded_5estout.csv"
table_fileB <- "did_iolf_main_prepost_bothlink_l_valueadded_4estout.csv"

# Load and clean data from both files.
datasetA <- loadandcleanestouttable(table_fileA)
datasetB <- loadandcleanestouttable(table_fileB)

# Combine datasets side-by-side, excluding the redundant first column in B.
sidebysidedatasets <- dplyr::bind_cols(datasetA, datasetB[,-1])

# Calculate the number of regression columns.
num_regs <- (ncol(datasetA) - 1) * 2

# Get effect row start of table.
start_row <- get_rows_helper( sidebysidedatasets, "industry" )

# Set row names with parentheses for clarity.
names(sidebysidedatasets) <- c("", paste0("(", 1:num_regs, ")"))

# Define alignment for table columns.
alignstring <- c("l", rep("c", num_regs))


## ========================================================================== ##
# IV. MAKE THE TABLES, ASSEMBLING KABLE TABLES. --------------------------------
## ========================================================================== ##

# Create the LaTeX table using Kable.
avg_lf_output_table <- knitr::kable(
  sidebysidedatasets, 
  format = "latex", 
  digits = 4,
  booktabs = TRUE, 
  longtable = FALSE,
  row.names = FALSE,
  escape = FALSE,
  align = alignstring,
  caption = table_caption_string,
  label = table_label_string,
  linesep = ""
) %>%
  
  # Add top headers for sample categories.
  kableExtra::add_header_above(
    ., 
    header = c(" " = 1,
               "Full Sample" = 1,
               "Non-HCI Sample" = 1,
               "Full Sample" = 1,
               "Non-HCI Sample" = 1),
    italic = TRUE,
    line = TRUE,
    align = "c"
  ) %>%
  
  # Add group:
  kableExtra::group_rows(
    " ", 
    start_row, 
    nrow(sidebysidedatasets),
    latex_gap_space = "0.25em",
    hline_before = FALSE
  ) %>%

  # Add sub-headers for panel details.
  kableExtra::add_header_above(
    ., 
    header = c(" " = 1, 
               "A) Five-Digit Panel (1970-1986)" = ncol(datasetA) - 1, 
               "B) Four-Digit Panel (1967-1986)" = ncol(datasetB) - 1),
    font_size = font_size_argument + 1,
    line = TRUE,
    align = "c",
    bold = FALSE
  ) %>%
  
  # Indent coefficients for clarity.
  kableExtra::add_indent(., 1:nrow(sidebysidedatasets)) %>%
  
  # Apply Kable styling.
  kableExtra::kable_styling(
    ., 
    protect_latex = TRUE,
    latex_options = c("scale_down","repeat_header"), 
    repeat_header_text = "\\textit{(continued)}",
    repeat_header_continued = TRUE,
    full_width = FALSE, 
    table.envir = "table", 
    font_size = font_size_argument
  ) %>%
  
  # Add a final header for outcome description.
  kableExtra::add_header_above(
    ., 
    header = c(" " = 1, "Outcome: Value Added (log)" = num_regs),
    line = TRUE,
    line_sep = 2,
    align = "c",
    font_size = font_size_argument + 1
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
  "avg_lf_output_table.tex"
)

cat(avg_lf_output_table, file = output_file)

testthat::test_that("Kable table is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})

    
