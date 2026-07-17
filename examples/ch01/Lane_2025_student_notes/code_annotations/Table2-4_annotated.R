# Annotated copy for replication audit.
# Original script: Lane2025QJE/replicationpackage/code/2_tables/Table2-4.R
# Purpose: Generates Tables 2-4.
#
# This file intentionally keeps the original .R extension.
# The original code is copied below. Comments in this header identify the
# script role, inputs, outputs, and audit linkage. The earlier prose note is
# archived at: markdown_notes_archive/Table2_4_R.md
#
# Audit linkage:
# - Methods report: explains the estimating or output logic.
# - Derivation report: maps equations/design objects to code.
# - Replication report: documents inputs, outputs, and reproducibility limits.
#
# Original code begins after this header.

## =============================================================================
# PURPOSE:
#   Process and prepare output files from the semi-parametric/doubly robust
#   estimation procedure to produce kable tables for the paper.
#
# INPUTS:
#   - "doublyrobust_all_results.csv" (Main regression output)
#   - "doublyrobust_trade_all_results.csv" (Trade regression output)
#   - "doublyrobust_invest_all_results.csv" (Investment regression output)
#
# OUTPUTS:
#   - Multiple LaTeX formatted Kable tables for industrial development,
#     export development, and input use/investment analysis
# ==============================================================================

## =============================================================================
# I. TEXT AND TABLE ARGUMENTS --------------------------------------------------
## =============================================================================

font_size_argument <- 10

## 1. TABLE NOTES --------------------------------------------------------------

# COMMON TEXT
commonendnotes <- "Specifications include controls for pre-1973 industry averages 
(log): avg. wages, avg. plant size, intermediate outlays, and labor productivity. 
Standard errors are clustered at the industry level. Double robust DD estimates
come from \\\\eqref{eq:semi}. Double robust estimators use bootstrapped 
standard errors (10,000 iterations) and are adjusted to allow for 
within-industry correlation. * Significant at the 10 percent level. 
** Significant at the 5 percent level. *** Significant at the 1 percent level."

commonendnotes <- gsub(pattern = "\n", replacement = " ", x = commonendnotes)


## A. MAIN TABLE.---------------------------------------------------------------
captionname_1 <- "Average Impact of Industrial Policy: Industrial Development"
labelname_1 <- "semitable"

bodytext_1 <- "This table shows the average treatment effect on the treated 
(ATT) for industrial policy. Average DD estimates are shown for double robust 
and TWFE estimators. Outcomes are log: output is the real value of gross 
output shipped (shipments), alongside other measures of real output: value 
added and gross output. Employment is the total number of workers. Prices 
are industry output prices. Labor Prod. is real value added per employee. 
Output Share is the manufacturing share of industry output. Labor Share is 
the manufacturing share of industry employment." 

bodytext_1 <- gsub(pattern = "\n", replacement = " ", x = bodytext_1)

footnote_string_1 <- paste( bodytext_1 , commonendnotes , sep = " " )


## B. EXPORT TABLE.-------------------------------------------------------------
captionname_2 <- "Average Impact of Industrial Policy: Export Development"
labelname_2 <- "semitablerca"

bodytext_2 <- "This table shows the average treatment effect on the treated (ATT)
 for industrial policy. Average DD estimates are shown for double robust, PPML 
 TWFE, and linear TWFE estimators. RCA is the standard Balassa index measure of 
 revealed comparative advantage. RCA (CDK) is relative productivity estimated 
 using CDK. See text for their calculation. The indicator I[RCA>1] is a binary 
 dummy variable equal to 1 when an industry has achieved comparative advantage, 
 0 otherwise. I also show transformed versions of RCA (asinh and log)."

bodytext_2 <- gsub(pattern = "\n", replacement = " ", x = bodytext_2)

footnote_string_2 <- paste( bodytext_2 , commonendnotes , sep = " " )


## C. INVEST TABLE.-------------------------------------------------------------
captionname_3 <- "Average Impact of Industrial Policy: Input Use and Investment"
labelname_3 <- "semitableinvest"

bodytext_3 <- "This table shows the average treatment effect on the treated (ATT)
 for industrial policy. Average DD estimates are shown for double robust and 
 TWFE estimators. Intermediate outlays (log) is real intermediate input costs. 
 Investment Total (log) is real total gross capital formation. I also show 
 outcomes in per worker terms."

bodytext_3 <- gsub(pattern = "\n", replacement = " ", x = bodytext_3)

footnote_string_3 <- paste( bodytext_3 , commonendnotes , sep = " " )


## ========================================================================== ##
# II. SUB-FUNCTIONS: Helper and sub-helper functions. -----------------------
## ========================================================================== ##

## A. MAKE BRAKETS FOR STANDARD ERRORS -----------------------------------------

# Function to format standard errors with parentheses
round_tostandarderrors <- function(string) {
  return(paste0("(", string, ")"))
}

## B. STAR MAKER ---------------------------------------------------------------

# Function to assign significance stars based on p-value
signif_num <- function(pvalueargument) {
  return(stats::symnum(pvalueargument, 
                        corr = FALSE, 
                        na = FALSE, 
                        legend = FALSE, 
                        cutpoints = c(0, 0.01, 0.05, 0.1, 1), 
                        symbols = c("***", "**", "*", " ")))
}

## C. STRING CLEANING ----------------------------------------------------------

# Function to clean and standardize dataset variable names
stringcleaner <- function(dataset_argument) {
  replacements <- c(
    "(^l_)export.*sh" = "export share (log)",
    "(^h_)export_sh" = "export share (asinh)",
    "(^l_)rca.*core" = "rca (log)",
    "(^h_)rca.*core" = "rca (asinh)",
    "^rca.*core" = "rca",
    "^rca.*dummy" = "prob. comparative adv.",
    "(^h_|^l_)" = "",
    "gross[0-9]+|grossoutput" = "gross output",
    "export_sh" = "export share",
    "ship_sh" = "output share",
    "ppi" = "prices",
    "ship$" = "output (shipm.)",
    "lab_sh" = "labor share",
    "avg_" = "avg. ",
    "y_n" = "labor prod.",
    "est|_est" = "num. plants",
    "valueadded" = "value added",
    "workers" = "employment",
    "costs" = "intermediate outlays",
    "m_n" = "intermediate outlays (per worker)",
    "inv_tot" = "investment",
    "i_n" = "investment (per worker)",
    "_" = " "
  )
  
  cleaned_dataset <- dataset_argument %>%
    stringr::str_replace_all(replacements) %>%
    stringr::str_to_title() %>%
    stringr::str_replace_all(c("[Rr]ca" = "RCA", 
                                "[Cc]dk" = "(CDK)",
                                "[Ll]og" = "log",
                                "[Aa]sinh" = "asinh"))
  return(cleaned_dataset)
}

## D. INTERPRET RESULTS --------------------------------------------------------

# Function to clean and interpret a single table entry
simple_interpretation_workflow <- function(single_table_entry) {
  # Convert input to character vector
  if (is.data.frame(single_table_entry) || is.list(single_table_entry)) {
    single_table_entry <- as.character(unlist(single_table_entry))
  } else if (!is.vector(single_table_entry)) {
    stop("Input must be a list, vector, or data frame")
  }
  
  # Extract numeric values and clean the vector
  cleaned <- stringr::str_extract_all(single_table_entry, "[\\.\\-0-9]+") %>%
                unlist() %>%
                as.numeric() %>%
                na.omit()
  
  if (length(cleaned) < 2) {
    stop("Insufficient data for interpretation")
  }
  
  # Calculate interaction using the first two cleaned values
  betahat <- cleaned[1]
  se <- cleaned[2]
  vhat <- (se)^2 
  interaction <- round(100 * (exp(betahat - 0.5 * vhat) - 1), 2)
  
  return(interaction)
}

## E. TAKE KABLE TIBBLE AND SELECT COLUMNS -------------------------------------

# Function to filter and select specific columns from a tibble
filter_and_select <- function(tibble_input, 
                              stringtomatch, 
                              colnumstring) {
  
  # Convert tibble to data frame
  df <- as.data.frame(tibble_input)
  
  # Filter rows matching the regex in the first column
  filtered_df <- df[grepl(stringtomatch, df[, 1], ignore.case = TRUE), ]
  
  # Function to strip non-numeric characters and convert to numeric
  strip_non_numeric <- function(x) {
    suppressWarnings(as.numeric(stringr::str_replace_all(x, "[^0-9.-]", "")))
  }
  
  # Clean and strip data
  cleaned_df <- as.data.frame(apply(filtered_df, 2, strip_non_numeric))
  
  # Select specified columns
  output_return <- cleaned_df %>% 
                    dplyr::select(where(~ !any(is.na(.)))) %>%
                    dplyr::select(matches(colnumstring)) 
    
  
  return(output_return)
}

## F. TAKE KABLE TIBBLE, FILTER VAR, AND GET MIN/MAX ---------------------------

# Function to filter a tibble and get min/max transformed values
filter_and_minmax <- function(tibble_input, pattern) {
  # Filter rows where the first column matches the pattern
  filtered_df <- tibble_input %>%
    dplyr::filter(str_detect(.[[1]], regex(pattern, ignore_case = TRUE)))
  
  # Ensure column names are unique
  colnames(filtered_df) <- make.names(colnames(filtered_df), unique = TRUE)
  
  # Convert values to numeric, stripping non-numeric characters
  cleaned_df <- filtered_df %>%
    dplyr::mutate(across(-1, ~ as.numeric(str_replace_all(., "[^0-9.-]", ""))))
  
  # Get the first row, excluding the first column
  first_row <- cleaned_df[1, -1]
  
  # Find the columns with min and max values
  min_col_name <- names(which.min(first_row))
  max_col_name <- names(which.max(first_row))
  
  # Extract min and max values from the first row
  selected_values <- cleaned_df[, c(min_col_name, max_col_name)]
  
  # Calculate interaction using the first two cleaned values
  betahats <- selected_values[1,] # Get first row Betas
  ses <- selected_values[2,] # Get second row SEs
  vhats <- (ses)^2 # Square of SEs
  transformed_values <- round(100 * (exp(betahats - 0.5 * vhats) - 1), 1)
  
  # Assign names to the results
  colnames(transformed_values) <- c("min", "max")

  return(transformed_values)
}

## ========================================================================== ##
# III. DATA FUNCTIONS: ---------------------------------------------------------
## ========================================================================== ##

## A. DATA LOADER ---------------------------------------------------------------

# Data set loader for all functions
loadregressiondata <- function(dataset_name_arg) {
  # Construct file path for the dataset
  file_path <- file.path(intermediate_dir, dataset_name_arg)
  
  # Read in the dataset
  df <- read.csv(file_path, header = T, stringsAsFactors = F)
  
  # Test that the data is not empty
  test_that("Test that prepared data.frame is not empty", {
    expect_equal(plyr::empty(df), FALSE)
  })
  
  # Convert to tibble
  df <- as_tibble(df)
  
  return(df)
}

## B. DATA CLEANER ---------------------------------------------------------------

# Data set loader for all functions
cleanandshapedata <- function(datasetname_arg) {
  # i. First initial cleaning.  
  df <- (loadregressiondata(datasetname_arg) %>%
    dplyr::mutate(
      # Indicate 4 or 5 digits
      digit = ifelse(grepl("4", dataset), 4, 5),
      
      # Clean outcome variable/indicator
      outcome = stringcleaner(outcome),
      id = stringcleaner(regress_id),
      
      # Round stderr and coef to 4 decimal places
      stderr = round(as.numeric(stderr), 4),
      coef = round(as.numeric(coef), 4)
    ) %>%
    # Select essential columns
    dplyr::select(id, coef, stderr, pval, didtype, digit, outcome)
  )
  
  # Test that the data is not empty
  test_that("Test that prepared data.frame is not empty", {
    expect_equal(plyr::empty(df), FALSE)
  })
  
  # ii. Add stars to initial cleaning based on pval
  df_stars <- dplyr::mutate(df, 
    coef = paste0(as.character(coef), signif_num(pval)),
    stderr = round_tostandarderrors(as.character(stderr)),
    pval = NULL)
  
  # iii.Reshape the table.
  
  # Reshape from WIDE to LONG: A regression for each line:
  df_long <- tidyr::pivot_longer(df_stars, -c(id, digit, outcome, didtype))
  
  # iv. Make wide: outcome x estimator x data set:
  df_wide <- df_long %>% 
    # Now rotate (widen) control and 4/Five-Digit rows to columns.
    tidyr::pivot_wider(., id_cols = c(outcome, name), 
                       names_from = c(didtype, digit)) %>% 
    # Drop redundant column.
    dplyr::select(-name)
  
  # v. Add model numbers to top of columns.
  # Number columns
  endcol <- ncol(df_wide) - 1
  colnums <- c("", paste0("(", 1:endcol, ")"))
  
  # Rename columns
  names(df_wide) <- setNames(colnums, colnums)
  
  # Test that the data is not empty
  test_that("Test that prepared data.frame is not empty", {
    expect_equal(plyr::empty(df_wide), FALSE)
  })
  
  return(df_wide)
}

## ========================================================================== ##
# IV. MAKING EACH TABLE. -------------------------------------------------------
## ========================================================================== ##

# ============================================================================ #
## 1. MAIN TABLE 4 & 5 DIGIT - TABLE 1/3 --------------------------------------

### A. Load and clean data for the main table. --------------------------------

mainfile <- "doublyrobust_att.csv"
main_cleaned_tibble <- cleanandshapedata(mainfile)

### B. Make main analysis KABLE. -----------------------------------------------

# Clarify first col is outcomes (logs):
names(main_cleaned_tibble)[1] <- "\\textit{Outcomes (log)}"

## Construct and print KABLE.
kable_att <- kable(main_cleaned_tibble, 
                    format = "latex", 
                    booktabs = T, 
                    longtable = F, 
                    row.names = F, 
                    align = "lcccc",
                    escape = F,
                    caption = captionname_1,
                    label = labelname_1,
                    linesep = "") %>%
  add_header_above(c("",
                     "Double Robust" = 1,
                     "TWFE" = 1,
                     "Double Robust" = 1,
                     "TWFE" = 1)) %>%
  # Add the upper header.
  add_header_above(c("",
                     "A) Five-Digit Panel" = 2,
                     "B) Four-Digit Panel" = 2)) %>%
  # Collapse
  collapse_rows(columns = 1,
                valign = "top",
                latex_hline = "none") %>%
  kableExtra::kable_styling(.,
                            latex_options = c("repeat_header"),
                            protect_latex = TRUE,
                            full_width = FALSE,
                            table.envir = "table",
                            font_size = font_size_argument) %>%
  kableExtra::footnote(general = footnote_string_1,
                       general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
                       escape = FALSE,
                       footnote_as_chunk = TRUE,
                       threeparttable = TRUE)

# ============================================================================ #
## 2. TRADE TABLE - ATT TABLE 2/3 ----------------------------------------------

### A. Load and clean data for the main table. --------------------------------
tradefile <- "doublyrobust_trade_att.csv"
trade_cleaned_tibble <- cleanandshapedata(tradefile)


### B. Make trade analysis KABLE. ----------------------------------------------

names(trade_cleaned_tibble)[1] <- "\\textit{Outcomes}"

# Generate trade table.
kable_trade_att <- kable(trade_cleaned_tibble, 
                          format = "latex", 
                          booktabs = T, 
                          longtable = F, 
                          row.names = F, 
                          align = "lcccc",
                          escape = F,
                          caption = captionname_2,
                          label = labelname_2,
                          linesep = "") %>%
  add_header_above(c("",
                     "Double Robust" = 1,
                     "TWFE" = 1,
                     "PPML" = 1 )) %>%
  # Add the upper header
  add_header_above(c("",
                     "Type of Estimator" = 3)) %>%
  # Collapse
  collapse_rows(columns = 1,
                valign = "top",
                latex_hline = "none") %>%
  # Style
  kableExtra::kable_styling(.,
                            latex_options = c("repeat_header"),
                            protect_latex = TRUE,
                            full_width = FALSE,
                            table.envir = "table",
                            font_size = font_size_argument) %>%
  kableExtra::footnote(general = footnote_string_2,
                       general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
                       escape = FALSE,
                       footnote_as_chunk = TRUE,
                       threeparttable = TRUE)

# ============================================================================ #
## 3. INVEST TABLE 3/3 ---------------------------------------------------------

### A. Load and clean data for the main table. ---------------------------------

## i. Load separate data for log and levels.
invest <- "doublyrobust_invest_att.csv"
invest_cleaned_tibble <- cleanandshapedata(invest)

## ii. Make lines 
endtoptable <- nrow(invest_cleaned_tibble)

### B. Make invest analysis KABLE. ---------------------------------------------

names(invest_cleaned_tibble)[1] <- "\\textit{Outcomes (log)}"

# Construct and print KABLE.
kable_invest_att <- kable(invest_cleaned_tibble, 
                           format = "latex", 
                           booktabs = T, 
                           longtable = F, 
                           row.names = F, 
                           align = "lcccc",
                           escape = F,
                           caption = captionname_3,
                           label = labelname_3,
                           linesep = "") %>%
  
  kableExtra::add_header_above(c("",
                                "Double Robust" = 1,
                                "TWFE" = 1,
                                "Double Robust" = 1,
                                "TWFE" = 1)) %>%
  # Add the upper header.
  kableExtra::add_header_above(c("",
                                "A) Five-Digit Panel" = 2,
                                "B) Four-Digit Panel" = 2)) %>%
  # Col spec
  kableExtra::column_spec(1, width = "17.5em") %>%
  
  # Collapse
  kableExtra::collapse_rows(columns = 1,
                           valign = "top",
                           row_group_label_position = "identity",
                           latex_hline = "none") %>%
  kableExtra::kable_styling(.,
                             latex_options = c("repeat_header"),
                             protect_latex = TRUE,
                             full_width = FALSE,
                             table.envir = "table",
                             font_size = font_size_argument) %>%
  kableExtra::footnote(general = footnote_string_3,
                       general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
                       escape = FALSE,
                       footnote_as_chunk = TRUE,
                       threeparttable = TRUE)

## ========================================================================== ##
## 4. SAVE TEX TABLES. ---------------------------------------------------------

# Save the tables.
main_table_file <- file.path(tables_dir, "kable_att.tex")
cat( kable_att, file = main_table_file)

trade_table_file <- file.path(tables_dir, "kable_trade_att.tex")
cat( kable_trade_att, file = trade_table_file)

invest_table_file <- file.path(tables_dir, "kable_invest_att.tex")
cat( kable_invest_att, file = invest_table_file)  



# ============================================================================ #
# V. INTERPRETATION OF RESULTS.-------------------------------------------------
# ============================================================================ #

## A. Interpretation of main table. --------------------------------------------

## i. Outputs ------------------------------------------------------------------

# DR results 
results_semi_ship <- main_cleaned_tibble %>% 
  filter_and_select(., "ship", "1") %>%
  simple_interpretation_workflow(.)

results_ols_ship <- main_cleaned_tibble %>% 
  filter_and_select(., "ship", "2") %>%
  simple_interpretation_workflow(.)

# Save results
cat( results_semi_ship, 
     file = file.path( tables_dir, "results_semi_ship.tex"))

# And OLS
cat( results_ols_ship, 
     file = file.path( tables_dir, "results_ols_ship.tex"))


## ii. Prices ------------------------------------------------------------------

# Price DR results 
results_semi_prices <- main_cleaned_tibble %>% 
  filter_and_select(., "price", "1") %>%
  simple_interpretation_workflow(.)

results_ols_prices <- main_cleaned_tibble %>% 
  filter_and_select(., "price", "2") %>%
  simple_interpretation_workflow(.)

# Save results
cat( results_semi_prices, 
     file = file.path( tables_dir, "results_semi_prices.tex"))

cat( results_ols_prices, 
     file = file.path( tables_dir, "results_ols_prices.tex"))


## iii. Labor ------------------------------------------------------------------

# Labor results.
results_semi_labor <- main_cleaned_tibble %>% 
  filter_and_select(., "emp", "1") %>%
  simple_interpretation_workflow(.) 

results_ols_labor <- main_cleaned_tibble %>% 
  filter_and_select(., "emp", "2") %>%
  simple_interpretation_workflow(.) 

results_semi_labor4 <- main_cleaned_tibble %>% 
  filter_and_select(., "emp", "3") %>%
  simple_interpretation_workflow(.) 

# Save results
cat( results_semi_labor, 
     file = file.path( tables_dir, "results_semi_labor.tex"))

cat( results_ols_labor, 
     file = file.path( tables_dir, "results_ols_labor.tex"))

cat( results_semi_labor4, 
     file = file.path( tables_dir, "results_semi_labor_4digit.tex"))



## B. Min and maxs of main table. ----------------------------------------------

# i. Prices
results_min_price <- filter_and_minmax(main_cleaned_tibble, "price")$min
results_max_price <- filter_and_minmax(main_cleaned_tibble, "price")$max

# Save results
cat( results_min_price, 
     file = file.path( tables_dir, "results_min_price.tex"))

cat( results_max_price, 
     file = file.path( tables_dir, "results_max_price.tex"))



# ii. y/n - Results 
results_semi_max_yn <- filter_and_minmax(main_cleaned_tibble, "prod")$max
results_semi_min_yn <- filter_and_minmax(main_cleaned_tibble, "prod")$min

# Save results
cat( results_semi_max_yn, 
     file = file.path( tables_dir, "results_semi_max_yn.tex"))

cat( results_semi_min_yn, 
     file = file.path( tables_dir, "results_semi_min_yn.tex"))


## C. Interpretation of trade table. -------------------------------------------

# Calculate results.
results_log_rca <- trade_cleaned_tibble %>% 
  filter_and_select(., "^rca.*log*", "1") %>%
  simple_interpretation_workflow(.) 

results_export_share <- trade_cleaned_tibble %>% 
  filter_and_select(., "^exp.*log*", "1") %>%
  simple_interpretation_workflow(.) 

results_prob_rca <- trade_cleaned_tibble %>% 
  filter_and_select(., "^prob", "1") %>%
  .[1,] * 100 %>%
  round(., 1) 


# Save results
cat( results_log_rca, 
     file = file.path( tables_dir, "results_log_rca.tex"))

cat( results_export_share, 
     file = file.path( tables_dir, "results_export_share.tex"))

cat( results_prob_rca, 
     file = file.path( tables_dir, "results_prob_rca.tex"))


## D. Interpretation of invest table. ------------------------------------------

# Results 
results_semi_invest <- invest_cleaned_tibble %>% 
  filter_and_select( . , "invest", "1") %>%
  simple_interpretation_workflow(.) 

results_ols_invest <- invest_cleaned_tibble %>% 
  filter_and_select(., "invest", "2") %>%
  simple_interpretation_workflow(.) 

results_semi_costs <- invest_cleaned_tibble %>% 
  filter_and_select(., ".*outlay*", "1") %>%
  simple_interpretation_workflow(.) 

results_ols_costs <- invest_cleaned_tibble %>% 
  filter_and_select(., ".*outlay*", "2") %>%
  simple_interpretation_workflow(.) 


# Save results
cat( results_semi_invest, 
     file = file.path( tables_dir, "results_semi_invest.tex"))

cat( results_ols_invest, 
     file = file.path( tables_dir, "results_ols_invest.tex"))

cat( results_semi_costs, 
     file = file.path( tables_dir, "results_semi_costs.tex"))

cat( results_ols_costs, 
     file = file.path( tables_dir, "results_ols_costs.tex"))
