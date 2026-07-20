## ================================= NOTES ================================== ##
#
#   PURPOSE: 
#
#        Generates tables for mechanisms/LBD robustness analysis.
#        Focuses on table-related functions.
#
#   INPUTS:
#   
#       mechanism_prod_micro_robustness_results_estout.csv     
#
#   OUTPUTS:
#
#       plant_lbd_robust_mechanism for KABLE rendering.
#
## ==============================  TOP MATTER =============================== ##



## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS. -------------------------------------------------
## ========================================================================== ##

 7.

font_size_argument <- 9
table_caption_string <- "Robustness: Plant and Industry-Level Learning, by Treatment Status"
table_label_string <- "appendixmicrolbd"
footnote_string <- "This table shows the robustness of plant-level estimates from equation (5) for alternative outcomes. 
Unit Cost is measured using total real intermediate costs per unit of (real) revenue. TFP outcomes are 
estimated using Ackerberg-Caves-Frazer (ACF), Levinsohn-Petrin (LP), Olley-Pakes 
(OP), and Wooldridge (W) methods. Panel A shows estimates for log Experience, and 
Panel B shows log Experience per worker. 'Plant Experience' refers to plant-level 
cumulative learning, and 'Industry Experience' refers to industry-level learning, 
calculated at the 4-digit industry level. All equations control for log plant size 
(workers). Additional controls include (log): capital intensity, skill ratio, investment 
per worker, and intermediate input intensity per worker. Linear Combination, at 
the bottom, gives the combined effects for Plant and Industry Experience for HCI 
establishments. All specifications are estimated using plant, industry, and year 
fixed effects. Two-way standard errors are clustered at the industry and plant levels."

# This remove linebreaks in footnote string (above) just in case. 
footnote_string <- gsub( "\\n" , " " , footnote_string )

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')

## ========================================================================== ##
# II. SUB-FUNCTIONS: Helper and sub-helper functions. -----------------------
## ========================================================================== ##

# Helper function to retrieve row indices based on regex matching
getrows_helper <- function(dataset, regexstring) {
  
  # Identify rows where the first column matches the regex pattern
  rowindex <- stringr::str_detect(dataset[[1]], regexstring) %>%
    which()
  
  return(rowindex)
}

## ========================================================================== ##
# III. LOAD AND PREPARE TABLE DATA ----------------------------------------------
## ========================================================================== ##

## A. LOAD DATA ---------------------------------------------------------------

# Define the output file name
outputfile <- "mechanism_prod_micro_robustness_results_estout.csv"

# Read the ESTOUT CSV into a dataframe with specified separator
dataset <- file.path(included_dir, outputfile) %>%
  read.csv(file = ., sep = ",")

# Ensure the loaded dataset is not empty
testthat::test_that("Filtered table is not empty", {
  testthat::expect_equal(plyr::empty(dataset), FALSE)
})

## B. CLEAN DATA --------------------------------------------------------------

# Standardize and clean the first column using regex replacements
dataset[[1]] <- stringr::str_replace_all(dataset[[1]], c(
  "[Ee]xperience" = "Experience",
  "(.*hci\\#.*[Ee]xperience|.*[Ee]xperience\\#.*hci)$" = "Targeted \\\\(\\\\times\\\\)  Experience",
  "(.*hci\\#.*[Ee]xperience.*ksic|.*[Ee]xperience.*ksic.*\\#.*hci)$" = "Targeted \\\\(\\\\times\\\\)  Ind. Experience",
  "^[Ee]xperience.*ksic" = "Ind. Experience",
  "[Rr].*[Ss]quared" = "R2"
))

# Remove non-alphanumeric characters from column names
names(dataset) <- stringr::str_replace_all(names(dataset), "[._aA-zZ]", "")

# Adjust column numbering, excluding the first column
n_cols <- ncol(dataset) - 1
names(dataset) <- c("", as.character(1:n_cols))

# Remove the first two rows which contain metadata from Stata
dataset <- dataset[-c(1, 2), ]

# Ensure the cleaned dataset is not empty
testthat::test_that("Filtered table is not empty", {
  testthat::expect_equal(plyr::empty(dataset), FALSE)
})

## ========================================================================== ##
# IV. MAKING THE KABLE TABLE. --------------------------------------------------  
## ========================================================================== ##

## A. GET INDEX AND DIMENSIONS FOR STYLING TABLE. ------------------------------

# Calculate the number of data columns
n_cols <- ncol(dataset) - 1

# Determine the last row number
lastrow <- nrow(dataset)

# Retrieve row indices for different table sections using helper function
startcontrols    <- min(getrows_helper(dataset, "[Cc]ontrol"))
endcontrols      <- max(getrows_helper(dataset, "[Cc]ontrol"))

startextrastats  <- min(getrows_helper(dataset, "[Ee]ffect"))
endextrastats    <- min(getrows_helper(dataset, "^[Cc]luster"))

startlinearcombo  <- min(getrows_helper(dataset, "^[Cc]luster")) + 1
endlinearcombo    <- max(getrows_helper(dataset, "[Sst.][EeRr.]"))

# Compile row indices into a vector for testing
testvars <- c(startcontrols, endcontrols, 
             startextrastats, endextrastats, 
             startlinearcombo, endlinearcombo)

# Verify all indices are integers
testthat::test_that("All elements of the vector are integers", {
  testthat::expect_true(all(testvars == floor(testvars)), 
                        info = "Not all elements of the vector are integers")
})

# Update column names with parentheses for alignment
names(dataset) <- c(" ", paste0("(", 1:n_cols, ")"))

# Define column alignment: left for first column, center for others
alignstring <- c("l", rep("c", n_cols))

## B. OUTPUT TABLE -------------------------------------------------------------

# Create the KABLE table with grouped rows and styling
plant_lbd_robust_mechanism <- knitr::kable(
  dataset, 
  format = "latex", 
  booktabs = TRUE, 
  longtable = FALSE,
  row.names = FALSE,
  escape = FALSE,
  caption = table_caption_string,
  label = table_label_string,
  align = alignstring,
  linesep = ""
) %>%
  kableExtra::group_rows(
    "Controls",  
    start_row = startcontrols,
    end_row = endcontrols,
    latex_wrap_text = TRUE,
    latex_gap_space = "0.75em"
  ) %>% 
  kableExtra::group_rows(
    " ",  
    start_row = startextrastats,
    end_row = endextrastats,
    latex_wrap_text = TRUE,
    hline_before = FALSE,
    hline_after = FALSE,
    latex_gap_space = "0.75em"
  ) %>% 
  kableExtra::group_rows(
    "Combined Effects",  
    start_row = startlinearcombo,
    end_row = endlinearcombo,
    latex_wrap_text = TRUE,
    hline_before = FALSE,
    hline_after = TRUE,
    latex_gap_space = "0.75em"
  ) %>%    
  # Add multi-level headers for better table structure
  kableExtra::add_header_above(
    c("", "Unit cost\n(revenue)" = 1, "(ACF)" = 1, "(LP)" = 1, "(W)" = 1, "(OP)" = 1, 
      "Unit cost\n(revenue)" = 1, "(ACF)" = 1, "(LP)" = 1, "(W)" = 1, "(OP)" = 1), 
    line = TRUE
  ) %>%
  kableExtra::add_header_above(
    c(" " = 1, 
      " " = 1,
      "TFP" = (n_cols / 2) - 1,
      " " = 1,
      "TFP" = (n_cols / 2) - 1), 
    line = TRUE,
    bold = FALSE
  ) %>% 
  kableExtra::add_header_above(
    c(" " = 1, 
      "Panel A) Experience" = n_cols / 2, 
      "Panel B) Experience (per worker)" = n_cols / 2), 
    line = TRUE,
    bold = FALSE
  ) %>% 
  # Apply styling options for LaTeX output
  kableExtra::kable_styling(
    latex_options = c("scale_down"), 
    protect_latex = TRUE,
    repeat_header_text = "\\textit{(continued)}",
    repeat_header_continued = TRUE,
    full_width = FALSE, 
    table.envir = "table", 
    font_size = font_size_argument
  ) %>%
  # Add footnotes to the table
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
  "plant_lbd_robust_mechanism.tex"
)

cat(plant_lbd_robust_mechanism, file = output_file)

testthat::test_that("Kable table is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})


                  
          