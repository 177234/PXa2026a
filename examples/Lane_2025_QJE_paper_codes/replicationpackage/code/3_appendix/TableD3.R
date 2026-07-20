## ===============================  NOTES  =============================== ##
#
#   PURPOSE: 
#       Generate a cleaned LaTeX table using kable for trade policies.
#
#   INPUTS:
#       - did_input_tradepolicy_results_estout.csv
#       - did_output_tradepolicy_results_estout.csv
#
#   OUTPUTS:
#       - tradepolicy_kable (LaTeX table)
#
#
## ======================================================================= ##

# Font size for the table
font_size_argument <- 9
table_caption_string <- "Differences in Trade Policy by Treatment Status, 1968-1982"
table_label_string <- "appendixtradepolicy"
footnotestring1 <- "Table shows trade policy by treatment status (targeted vs. 
non-targeted), using nominal trade policy data for 1968-1982 (intermittent). Columns 
(1-8) show estimates in levels and columns (9-12) show changes. All regressions 
are at the 4-digit industry level. Columns (1-4) report estimates for log tariffs. 
Columns (5-8) report estimates for log quantitative restriction coverage. Columns 
(9-10) show estimates for changes in log tariff rates. Columns (11-12) show 
estimates for changes in log quantitative restrictions."
footnotestring2 <- "Panel A presents tariff and quantitative restriction outcomes 
for output market protection (industry-level): the average level or change in tariff 
or quantitative restriction coverage. Panel B shows outcomes for input protection. 
Exposure to input protection is calculated using the weighted sum of tariffs or 
QRs for an industry's input basket, with weights taken from the 1970 input-output 
accounts. See text for calculation. Sample refers to whether all five periods are
used, or whether only post-HCI (1973) observations are used."

# Combine table-specific notes and obligatory notes.
footnote_string <- paste( footnotestring1 , 
                         footnotestring2 ,
                         sep = " ")

# This remove linebreaks in footnote string (above) just in case. 
footnote_string <- gsub( "\\n" , " " , footnote_string )

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')


## ==============================  FUNCTIONS  ============================= ##

# Function to load and clean ESTOUT tables
load_and_clean_estout_table <- function(table_file) {
  dataset <- file.path(intermediate_dir, table_file) %>%
    read.csv(header = FALSE, sep = "\t")
  
  # Clean column names and replace "hci" with "Targeted"
  names(dataset) <- str_replace_all(names(dataset), "[._aA-zZ]", "")
  dataset[[1]] <- str_replace_all(dataset[[1]], "hci", "Targeted")
  
  # Remove metadata rows and rename columns
  dataset <- dataset[-c(1:2), ]
  n_length <- ncol(dataset) - 1 
  names(dataset) <- c(" ", as.character(1:n_length))
  
  # Test that the dataset is not empty
  test_that("Filtered table is not empty", {
    expect_true(nrow(dataset) > 0)
  })
  
  return(dataset)
}

# Helper function to get row indices matching a regex
get_rows_helper <- function(dataset, regex_string) {
  row_index <- which(
    grepl(regex_string, dataset[[1]], ignore.case = TRUE)
  )
  
  # Test that row index is not empty
  test_that("Row index is not empty", {
    expect_true(length(row_index) > 0)
  })
  
  return(row_index)
}

## ===========================  LOAD DATA  ================================ ##

# File names
output_policy_file <- "did_output_tradepolicy_results_estout.csv"
input_policy_file <- "did_input_tradepolicy_results_estout.csv"

# Load and clean data
output_policy_data <- load_and_clean_estout_table(output_policy_file) 
input_policy_data <- load_and_clean_estout_table(input_policy_file) 

# Stack the regression tables
stacked_trade_policy_panel <- bind_rows(output_policy_data, input_policy_data)

# Test that the combined data frame is not empty
test_that("Prepared data.frame is not empty", {
  expect_true(nrow(stacked_trade_policy_panel) > 0)
})

## ==========================  MAKE TABLE  ================================ ##

# Index calculations for styling
starts_first_table <- 1
ends_first_table <- nrow(output_policy_data)
start_second_table <- ends_first_table + 1
end_second_table <- nrow(stacked_trade_policy_panel)

target_rows <- get_rows_helper(stacked_trade_policy_panel, "Targeted")
target_row_one <- min(target_rows)
target_row_two <- max(target_rows)

# Update column names and alignment
n_cols <- ncol(stacked_trade_policy_panel) - 1
names(stacked_trade_policy_panel) <- c(" ", paste0("(", 1:n_cols, ")"))
align_string <- c("l", rep("c", n_cols))

# Build the kable table
tradepolicy_kable <- kable(
  stacked_trade_policy_panel,
  format = "latex",
  booktabs = TRUE,
  row.names = FALSE,
  escape = FALSE,
  align = align_string,
  caption = table_caption_string,
  label = table_label_string,
  linesep = ""
) %>%
  # Group controls and extra statistics for Panel A
  pack_rows(
    group_label = NULL,
    start_row = target_row_one + 2,
    end_row = ends_first_table,
    latex_gap_space = "0.3em",
    hline_before = FALSE,
    hline_after = FALSE
  ) %>%
  # Group rows for Output Protection
  pack_rows(
    group_label = "Panel A) Output Protection",
    start_row = starts_first_table,
    end_row = ends_first_table,
    latex_gap_space = "1em",
    indent = TRUE,
    hline_after = TRUE
  ) %>%
  # Group controls and extra statistics for Panel B
  pack_rows(
    group_label = NULL,
    start_row = target_row_two + 2,
    end_row = end_second_table,
    latex_gap_space = "0.3em",
    hline_before = FALSE,
    hline_after = FALSE
  ) %>%
  # Group rows for Exposure to Input Protection
  pack_rows(
    group_label = "Panel B) Exposure to Input Protection",
    start_row = start_second_table,
    end_row = end_second_table,
    latex_gap_space = "1em",
    indent = TRUE
  ) %>%
  # Add headers
  add_header_above(
    header = c(
      " " = 1,
      "Tariff Rate (log)" = 4,
      "Quantitative\nRestrictions (log)" = 4,
      "Tariff Rate (log)" = 2,
      "Quantitative\nRestrictions (log)" = 2
    ),
    font_size = font_size_argument
  ) %>%
  add_header_above(
    header = c(
      " " = 1,
      "Outcomes: Levels" = 8,
      "Outcomes: Changes" = 4
    ),
    font_size = font_size_argument
  ) %>%
  # Apply styling
  kable_styling(
    latex_options = c("scale_down"), 
    protect_latex = TRUE,
    repeat_header_text = "\\textit{(continued)}",
    repeat_header_continued = TRUE,
    full_width = FALSE, 
    table.envir = "table", 
    font_size = font_size_argument
  ) %>%
  # Add footnote
  kableExtra::footnote(
    general = footnote_string, 
    general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
    footnote_as_chunk = TRUE,
    threeparttable = TRUE,
    escape = FALSE
  )

## ========================  INTERPRETATION  ============================= ##

# A. Interpreting calculation for OUTPUT tariff post-1973
key_output_row <- filter(output_policy_data, 
                         str_detect(output_policy_data[[1]], "[Tt]argeted"))
key_coefficient_output <- key_output_row[[which(str_detect(names(key_output_row), "4"))]]

print(key_coefficient_output)

levels_tariff <- key_coefficient_output %>%
  str_remove_all("\\*") %>%
  as.numeric() %>%
  exp() - 1 %>%
  round(2)

# B. Interpreting calculation for INPUT tariff exposure post-1973
key_input_row <- filter(input_policy_data, 
                        str_detect(input_policy_data[[1]], "[Tt]argeted"))
key_coefficient_input <- key_input_row[[which(str_detect(names(key_input_row), "4"))]]
input_levels_tariff <- key_coefficient_input %>%
  str_remove_all("\\*") %>%
  as.numeric() %>%
  exp() - 1 %>%
  round(2)

print(key_coefficient_input)

## ========================================================================== ##
# VI. SAVE THE KABLE TABLE ------------------------------------------------
## ========================================================================== ##
output_file <- file.path(
  tables_appendix_dir,
  "tradepolicy_kable.tex"
)

cat(tradepolicy_kable, file = output_file)

testthat::test_that("Kable table is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})

