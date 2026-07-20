## ========================================================================== ###
#   PURPOSE: 
#
#           - R table generation of the main datasets. To run by main paper R file.
#
#           - This is mainly a summarization script that runs over the pre-1973 dataset.
#
#           - Generates from the a) industrial panel dataset and b) Korean trade dataset.
#
#
#   INPUTS: 
#
#           4/5/sitc 4 digit datasets:
#                      
#             "pre1973_4digit.csv"
#             "pre1973_5digit.csv"
#             "pre1973_trade.csv"
#
#   OUTPUTS:
#
#         KABLE object rendered in the Appendix: 
#         
#         "descriptiveoutput_kable"
#
#
## ===========================================  TOP MATTER ===========================================  ##



## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS.-----------------------------------------------
## ========================================================================== ##



font_size_argument <- 9
table_caption_string <- "Pre-HCI Drive Statistics By Treatment Status"
table_label_string <- "appendixtabledescriptive"
footnote_string <- "Table reports pre-1973 statistics for a selection of core industrial 
variables. Panel A shows statistics for aggregated ('long') 4-digit industrial panel,
1967 to 1972. Panel B shows statistics for disaggregated ('short') 5-digit 
industrial panel, 1970 to 1972. Part i) of table reports Mining and Manufacturing
Survey/Census (MMS) outcomes, with the exception of prices, which come from the 
Bank of Korea publications. Part ii) shows data from the 1970 input-output tables 
published by the Bank of Korea (1970), harmonized and matched to industry-level 
data. Part iii) shows trade variables (from UN-Comtrade). All values are deflated
using 2010 baseline won, except for real USD trade values."

# This remove line breaks (regex "\\n") in footnote string above just in case. 
footnote_string <- gsub( "\\n" , " " , footnote_string )

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')

## ========================================================================== ##
# II. FUNCTIONS -------------------------------------------------------------
## ========================================================================== ##


## ========================================================================== ##
## 1. SUB-FUNCTIONS: Helper and sub-helper functions. -----------------------
## ========================================================================== ##



### A. HELPER FUNCTION - LOAD AND PREPARE THE DATASET. ----------------------

# NOTE: Trade data table generation handled in middle of the file, in Part II.
loadandprepare <- function(inputfilestring) {
  
  # 1 - Load/pre-clean:
  industrialdataset.df <- inputfilestring %>% 
    file.path(input_dir, .) %>%
    utils::read.csv(header = TRUE, sep = "\t")
  
  # 2 - Make sure ID/YEAR/HCI variables are factors. 
  variables_to_convert <- c("id", "year", "hci")
  
  industrialdataset.df[ , variables_to_convert] <- lapply(
    industrialdataset.df[ , variables_to_convert],
    factor
  )
  
  # 3 - Unit Test: Data is not empty
  testthat::test_that("Test that prepared data.frame is not empty", {
    testthat::expect_equal(plyr::empty(industrialdataset.df), FALSE)
  })
  
  return(industrialdataset.df)
}  


### A.ii. HELPER FUNCTION - TEST THAT DATA IS NOT EMPTY. ----------------------

test_non_empty_data <- function(data_argument) {
  
  # TEST: Confirm output not empty.
  if (dim(data_argument)[1] == 0) {
    stop("Table contains no observations.")
  }
  
}

### A.iii. HELPER FUNCTION - CLEAN VARIABLE NAMES. ----------------------------

clean_variable_names <- function(variable_argument) {
  
  # Clean variable names.
  cleaned_variable <- stringr::str_replace_all(
    variable_argument,
    c(
      "_" = " ",
      "_0" = "",
      ".[Mm]ean$" = "",
      "avg" = "average",
      "valueadded" = "value added",
      "^y sh" = "value added share",
      "^lab sh" = "labor share",
      "ppi" = "prices",
      "grossoutput" = "gross output",
      "ship$" = "shipments",
      "[Yy].[Nn]" = "labor productivity",
      "eq$" = " equipment",
      "est" = "establishments",
      "inv.tot" = "investment",
      "tariff" = "tariff",
      "qr" = "quant. restrictions",
      "trade export v" = "value exports",
      "trade import v" = "value imports",
      "core" = "(balassa)",
      "export.[Ss][Hh].*" = "export share",
      "import.[Ss][Hh].*" = "import share"
      )
    )
  
  return(cleaned_variable)
}



### B. FUNCTION - GENERATE VARIABLES FOR DATAFRAMES. ---------------------------


# Arguments
# Single dataset.
# variablelistargument is the list of variables whose names we want to use.


#### B.1. - FUNCTION FOR MAKING SINGLE TABLE -----------------------------------

# A main function for generating single table descriptives.
make_single_table <- function(industrial_dataset, variable_list) {
  
  # Ensure industrial_dataset is a data frame
  if (!is.data.frame(industrial_dataset)) {
    print("Converting to data.frame")
    industrial_dataset <- as.data.frame(industrial_dataset)
  }
  
  # Convert 'hci' from factor to character
  industrial_dataset$hci <- as.character(industrial_dataset$hci)
  
  ## FIRST - Generate a count variable.
  count_table <- industrial_dataset %>%
    dplyr::group_by(hci) %>%
    dplyr::summarize(count = dplyr::n())
  
  ## SECOND - Create summary statistics.
  main_table <- industrial_dataset %>%
    dplyr::group_by(hci) %>%
    dplyr::summarise_at(
      .vars = dplyr::vars(variable_list),
      .funs = list(mean = ~mean(.x, na.rm = TRUE))
    ) %>%
    dplyr::rename_at(
      .vars = dplyr::vars(dplyr::matches('mean')),
      .funs = ~stringr::str_replace_all(., c("_mean" = " mean"))
    )
  
  # Reshape and join with count_table
  main_table <- data.table::melt(
    data.table::as.data.table(main_table),
      id.vars = "hci",
      measure.vars = patterns( "mean"),
      variable.name = "variable",
      value.name = c( "mean")
  ) %>%
    dplyr::inner_join(count_table, by = "hci")
  
  # Unit Test: Data is not empty
  testthat::test_that("Test that prepared data.frame is not empty", {
    testthat::expect_equal(plyr::empty(main_table), FALSE)
  })
  
  ## THIRD - Replace variable indices with names.
  
  main_table$variable <- as.character(main_table$variable)
  main_table$hci <- as.character(main_table$hci)
  
  for(i in seq_along(variable_list)) {
    main_table <- main_table %>%
      dplyr::mutate(variable = dplyr::if_else(
        variable == as.character(i),
        variable_list[i],
        variable
      ))
  }
  
  # Replace HCI indicators
  main_table <- main_table %>%
    dplyr::mutate(
      hci = dplyr::case_when(
        hci == "1" ~ "HCI",
        hci == "0" ~ "Non-HCI",
        TRUE ~ hci
      )
    )
  
  # Return table as output after testing
  test_non_empty_data(main_table)
  
  ## FOURTH - Edit data frame for plotting:
  main_table <- main_table %>%
    data.table::setcolorder(c("hci", "variable", "mean", "count")) %>%
    as.data.frame()
  
  # Replace full variable names.
  main_table$variable <- main_table$variable %>%
    stringr::str_replace("hci.share.make.*", "backward linkage") %>%
    stringr::str_replace("hci.share.use.*", "forward linkage")
  
  # Replace observations.
  main_table$variable <- clean_variable_names(main_table$variable)
    
  # Capitalize variable label rows
  main_table$variable <- stringr::str_to_title(main_table$variable) %>%
    stringr::str_replace_all("[Hh][Cc][Ii]", "HCI") %>%
    stringr::str_replace_all("[Rr][Cc][Aa]", "RCA")
  
  # Fix variable names.
  names(main_table) <- names(main_table) %>%
    stringr::str_to_title() %>%
    stringr::str_replace_all("[Hh][Cc][Ii]", "HCI")
    
  
  # Unit Test: Data is not empty
  testthat::test_that("Test that prepared data.frame is not empty", {
    testthat::expect_equal(plyr::empty(main_table), FALSE)
  })
  
  return(main_table)
  
}


#### B.2 - WRAPPER FUNCTION FOR COMBINING TWO SUMMARY DATASETS -----------------

# Applies B.1 to two datasets, then joins them side by side.
# Runs over two datasets (4 and 5-digit), and combines them column-wise.
make_two_column_summary_table <- function(mms_dataset_list, 
                                          mms_main_variable_args) {
  
  # Generate summaries for first two datasets
  prepared_datasets <- lapply(
    mms_dataset_list[1:2],
    make_single_table,
    variable_list = mms_main_variable_args
  )
  
  # Join side-by-side using plyr::join
  combo_table <- plyr::join(
    prepared_datasets[[1]],
    prepared_datasets[[2]],
    by = c("HCI", "Variable"),
    type = "left",
    match = "all"
  )
  
  # Unit Test: Data is not empty
  testthat::test_that("Test that prepared data.frame is not empty", {
    testthat::expect_equal(plyr::empty(combo_table), FALSE)
  })
  
  return(combo_table)
  
}



## ========================================================================== ##
# III. MAKE INDIVIDUAL TABLES USING FUNCTIONS IN PART II -----------------------
## ========================================================================== ##


# 0. List of data to load.
# 1. Make core table from 0. 
# 2. Make linkage tables (from ind dataset) from 0.
# 3. Make trade tables from 0.


## 0. LOAD AND MAKE LIST OF DATASETS -------------------------------------------

# List of datasets for pre-1973 data.
dataset_name_list <- c(
  "pre1973_4digit.csv",
  "pre1973_5digit.csv",
  "pre1973_trade.csv"
)

# Load and prep datasets
industrial_dataset_list <- lapply(
  dataset_name_list, 
  loadandprepare
)



## 1. LOAD AND MAKE 4/5 DIGIT SUMMARY TABLE ------------------------------------

# Generate first main industrial table using industrial data function.

# First table variables
main_variable_list <- c(
  "avg_size", "workers",
  "lab_sh", "est",
  "valueadded", "y_sh", 
  "grossoutput", "ppi", 
  "y_n", "inv_tot"
)

# Run the wrapper function.
top_main_table <- make_two_column_summary_table(
  industrial_dataset_list,
  main_variable_list
)


## 2. MAKE LINKAGE TABLE. ------------------------------------------------------

# Second linkage sub-table, from industrial data function.

# Linkage variable list
linkage_variables_list <- c(
  "hci_share_make_tot_0", 
  "hci_share_use_tot_0"
)

# Run the wrapper, taking averages using links.
second_link_table <- make_two_column_summary_table(
  industrial_dataset_list,
  linkage_variables_list
)



## 3. MAKE TRADE TABLE. --------------------------------------------------------

# Main trade table, which does not use industrial data table generation.

# First table variables
trade_variable_list <- c("rca_core","export_sh","import_sh")


### A. Use B.1 Function on a single trade dataset (only 4-digit data) ----------

trade_table_list <- lapply(
  industrial_dataset_list[3], 
  make_single_table, 
  variable_list = trade_variable_list
)

### B. Adjust for stacking with other tables. ----------------------------------

# Extract the single trade table
trade_table <- trade_table_list[[1]]

# Add blank columns for stacking tables in KABLE function.
blank_table <- trade_table[ , (ncol(trade_table)-1):ncol(trade_table)]
blank_table[blank_table != 0] <- NA

# Final trade table for stacking.
third_trade_table <- cbind(trade_table, blank_table)



## ========================================================================== ##
# IV. ASSEMBLE/COMBINE MAIN KABLES FOR RENDER -------------------------------
## ========================================================================== ##

# Order the main variables in the industry dataset
top_main_table <- top_main_table[order(top_main_table$Variable), ]


# Combine sub-tables into a big dataframe
big_table <- rbind(top_main_table, second_link_table, third_trade_table)

# Order the big table
big_table <- big_table[, c(2, 1, 3:ncol(big_table))]


names(big_table) <- c("Variable", "Industry", "Mean", "N", "Mean", "N")


# Make align string:
cstring <- paste0( rep("c",4), collapse = "" )
align_string <- paste0("ll",cstring, collapse = "" )

# Create the kable table without collapse_rows()
descriptiveoutput_kable <- knitr::kable(
  big_table,
  format = "latex",
  row.names = FALSE,
  booktabs = TRUE,
  align = align_string,
  escape = TRUE,
  digits = 2,
  label = table_label_string,
  caption = table_caption_string
) %>%
  # Add header rows first
  kableExtra::add_header_above(
    c(
      " " = 2,
      "A) Four-Digit Panel (1967-1972)" = 2,
      "B) Five-Digit Panel (1970-1972)" = 2
    )
  ) %>%
  # Customize first column
  kableExtra::column_spec(1, 
                          width = "15em", 
                          border_right = FALSE, 
                          bold = FALSE) %>%
  # Collapse rows
  kableExtra::collapse_rows(
    columns = 1,
    latex_hline = "none",
    valign = "top",
    row_group_label_position = "identity"
  ) %>%
  # Add row groups without collapsing rows
  kableExtra::group_rows(
    "i) Industrial Statistics", 1, nrow(top_main_table),
    bold = TRUE,
    latex_gap_space = "0.2em",
    indent = TRUE
  ) %>%
  kableExtra::group_rows(
    "ii) Linkage Exposure to HCI Sectors",
    nrow(top_main_table) + 1,
    nrow(top_main_table) + nrow(second_link_table),
    bold = TRUE,
    latex_gap_space = "0.2em",
    indent = TRUE
  ) %>%
  kableExtra::group_rows(
    "iii) Trade Statistics (SITC trade data, 1965-1972)",
    nrow(top_main_table) + nrow(second_link_table) + 1,
    nrow(big_table),
    bold = TRUE,
    latex_gap_space = "0.2em",
    indent = TRUE
  ) %>%
  # Apply kableExtra styling adjustments for LaTeX
  kableExtra::kable_styling(
    latex_options = c("scale_down"),
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


## ========================================================================== ##
# V. INTERPRETATION AND OUTPUT ------------------------------------------------
## ========================================================================== ##

# Get only RCA trade measures:
df_trade <- dplyr::filter(trade_table, grepl("rca", stringr::str_to_lower(Variable), ignore.case = TRUE)) 

# Mean RCA for HCI
hci_rca_mean <- df_trade %>%
  dplyr::filter(grepl("^hci", stringr::str_to_lower(HCI), ignore.case = TRUE)) %>% 
  dplyr::select(Mean) %>%
  as.numeric(.) %>%
  round(.,2)

# Mean RCA for non-HCI
nonhci_rca_mean <- df_trade %>%
  dplyr::filter(grepl("^non", stringr::str_to_lower(HCI), ignore.case = TRUE)) %>% 
  dplyr::select(Mean) %>%
  as.numeric(.) %>%
  round(.,2)

rca_times <- round(nonhci_rca_mean / hci_rca_mean)


## ========================================================================== ##
# VI. SAVE THE KABLE TABLE -----------------------------------------------------
## ========================================================================== ##
output_file <- file.path(
  tables_appendix_dir,
  "tabledescriptive.tex"
)

cat(descriptiveoutput_kable, file = output_file)

testthat::test_that("Kable table is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})


## Also save interpretation of RCA means. --------------------------------------

# RCA means are used throughout the paper.
cat( hci_rca_mean , 
     file = file.path( tables_appendix_dir,
                       "results_hci_rca_mean.tex") )
cat( nonhci_rca_mean , 
     file = file.path( tables_appendix_dir,
                       "results_nonhci_rca_mean.tex") )





