## ========================================================================== ##
#   PURPOSE: 
#         Creates the pre-post average Leontief linkage table for PRICES.
#   INPUTS:
#     - "did_iolf_main_prepost_bothlink_l_ppi_5estout.csv"
#     - "did_iolf_main_prepost_bothlink_l_ppi_4estout.csv"
#
#   OUTPUTS:
#       Creates a LaTeX table for rendering:
#       - "avg_lf_prices_table"
## ========================================================================== ##


## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS.-----------------------------------------------
## ========================================================================== ##


# Font size for table
font_size_argument <- 9
table_caption_string <- "Total Linkage Exposure and Output Prices"
table_label_string <- "appendixprepostlfprices"
footnote_string <- "This table shows average differences-in-differences estimates, 
before and after 1973. Estimates come from the main DD linkage specification. Both linkage 
interactions (forward and backward) are shown. Note that dynamic figures present 
only estimates for the linkage of interest."

# This remove linebreaks in footnote string (above) just in case. 
footnote_string <- gsub( "\\n" , " " , footnote_string )

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')

## ========================================================================== ##
# II. SUB-FUNCTIONS: Helper and Sub-Helper Functions. -----------------------
## ========================================================================== ##
get_rows_helper <- function( dataset, regexstring ){
  
  # Get row number by REGEX string.
  rowindex <- which(
    grepl(
      paste0( regexstring ), 
      dataset[,1], 
      ignore.case = TRUE
    )
  )
  
  testthat::test_that("Row index is not empty.", {
    testthat::expect_equal(length(rowindex) > 0, TRUE)
  })
  
  # Return integer.
  return( rowindex )
}

#' Load and clean ESTOUT table from a CSV file.
#'
#' @param table_file Name of the ESTOUT CSV file.
#' @return Cleaned data frame.
load_and_clean_estout_table <- function(table_file) {
  
  # Construct file path and read CSV
  dataset <- file.path(intermediate_dir, table_file) %>%
             utils::read.csv(file = ., sep = "\t", header = FALSE)
  
  # Clean column names by removing non-alphanumeric characters
  names(dataset) <- stringr::str_replace_all(names(dataset), "[._aA-zZ]", "")
  
  # Remove duplicate rows
  dataset <- dataset[!duplicated(dataset), ]
  
  ## Filter linkage types
  
  # Define regex patterns for forward and backward linkages
  regex_forward <- "\\#c\\..*hci.*([uU]se|\\_in|orward).*0"
  regex_backward <- "\\#c\\..*hci.*([mM]ake|\\_out|ackward).*0"
  
  # Clean first column strings
  dataset[[1]] <- dataset[[1]] %>%
                  stringr::str_replace_all("[Rr].*[Ss]quared", "R2") %>% 
                  stringr::str_replace_all(regex_forward, "Forward Linkage") %>%
                  stringr::str_replace_all(regex_backward, "Backward Linkage") %>%
                  stringr::str_replace_all("1.[pP]ost", "Post \\\\(\\\\times\\\\) ") %>% 
                  stringr::str_replace_all("postc", "Post \\\\(\\\\times\\\\) ")
  
  # Remove duplicate rows after cleaning
  dataset <- dataset[!duplicated(dataset), ]
  
  # Remove the first row which may contain headers or irrelevant information
  dataset <- dataset[-1, ]
  
  # Unit test to ensure the dataset is not empty
  testthat::test_that("Prepared data.frame is not empty.", {
    testthat::expect_false(nrow(dataset) == 0)
  })
  
  return(dataset)
}

## ========================================================================== ##
# III. LOAD AND PREPARE DATA.---------------------------------------------------
## ========================================================================== ##

# Define input table files
table_file_a <- "did_iolf_main_prepost_bothlink_l_ppi_5estout.csv"
table_file_b <- "did_iolf_main_prepost_bothlink_l_ppi_4estout.csv"

# Load and clean datasets
dataset_a <- load_and_clean_estout_table(table_file_a)
dataset_b <- load_and_clean_estout_table(table_file_b)

# Combine datasets side-by-side, excluding the first column of dataset B to avoid redundancy
side_by_side_datasets <- dplyr::bind_cols(dataset_a, dataset_b[ , -1])

# Identify the starting row for effects in the table
start_row <- get_rows_helper(side_by_side_datasets, "industry")

# Calculate the number of regression columns in the table
num_reg_columns <- (ncol(dataset_a) - 1) * 2

# Assign row names with parentheses for numbering
names(side_by_side_datasets) <- c("", paste0("(", 1:num_reg_columns, ")"))

# Define alignment string for LaTeX table columns
alignstring <- c("l", rep("c", num_reg_columns))

## ========================================================================== ##
# IV. MAKE THE TABLES, ASSEMBLING KABLE TABLES. -------------------------------
## ========================================================================== ##

# Assemble the LaTeX table using kable and kableExtra
avg_lf_prices_table <- knitr::kable(
  side_by_side_datasets, 
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
  
  # Add header rows above the main table
  kableExtra::add_header_above(
    .,
    c("",
      "Full Sample" = 1,
      "Non-HCI Sample" = 1,
      "Full Sample" = 1,
      "Non-HCI Sample" = 1),
    italic = TRUE,
    line = TRUE,
    align = "c"
  ) %>%
  
  kableExtra::add_header_above(
    .,
    c(" ", 
      "A) Five-Digit Panel (1970-1986)" = ncol(dataset_a) - 1, 
      "B) Four-Digit Panel (1967-1986)" = ncol(dataset_b) - 1),
    line = TRUE,
    line_sep = 1,
    align = "c",
    font_size = font_size_argument + 1,
    bold = FALSE
  ) %>%
  
  # Group rows for better readability
  kableExtra::group_rows(
    " ", 
    start_row, 
    nrow(side_by_side_datasets),
    latex_gap_space = "0.25em"
  ) %>%
  
  # Apply styling to the table
  kableExtra::kable_styling(
    .,
    protect_latex = TRUE,
    repeat_header_text = "\\textit{(continued)}",
    repeat_header_continued = TRUE,
    full_width = FALSE, 
    table.envir = "table", 
    font_size = font_size_argument
  ) %>%
  
  # Add another header for the outcome
  kableExtra::add_header_above(
    .,
    c(" ",
      "Outcome: Prices (log)" = num_reg_columns),
    line = TRUE,
    line_sep = 2,
    align = "c",
    font_size = font_size_argument + 1
  ) %>%
  
  # Add footnote to the table
  kableExtra::footnote(
    general = footnote_string,
    threeparttable = TRUE,
    general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
    footnote_as_chunk = TRUE,
    escape = FALSE
  )

## ========================================================================== ##
# VI. SAVE THE KABLE TABLE -----------------------------------------------------
## ========================================================================== ##
output_file <- file.path(
  tables_appendix_dir,
  "avg_lf_prices_table.tex"
)

cat(avg_lf_prices_table, file = output_file)

testthat::test_that("Kable table is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})
