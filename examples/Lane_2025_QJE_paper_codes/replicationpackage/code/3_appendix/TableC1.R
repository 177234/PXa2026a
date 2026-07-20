## =============================== TOP MATTER =============================== ##
#
#   PURPOSE: 
#         
#         Trade probability tables.
#
#   INPUTS:
#
#       - Files for the estimation in STATA.
#       
#       "did_probrca_results_estout.csv"
#
#   OUTPUTS:
#
#       This file creates KABLE objects for rendering:
#   
#       trade_prob_table
#
## =============================== TOP MATTER =============================== ##



## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS.-----------------------------------------------
## ========================================================================== ##



font_size_argument <- 9
table_caption_string <- "Probability of Attaining Comparative Advantage in Targeted Industry, South Korea v. Other Countries, Post-1972"
table_label_string <- "appendixprobrca"
footnote_string<- "The probability of attaining RCA (RCA>1) in HCI products for 
Korea versus other countries in the post-1972 period. Regressions include industry-by-year 
effects. Data is restricted to treated industries. Two-way standard errors are 
clustered at the industry and country levels."

# This remove linebreaks in footnote string (above) just in case. 
footnote_string <- gsub( "\\n" , " " , footnote_string )

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')

## ========================================================================== ##
# II. SUB-FUNCTIONS: Helper and sub-helper functions. -----------------------
## ========================================================================== ##


getrows_helper <- function( dataset, regexstring ){
  
  # Get row number by REGEX string.
  rowindex <-  paste0( regexstring ) %>%
    # Paste into GREP function, use first column.
    grepl( . , dataset[,1] ) %>%
    # Use GREP to get rows matching GREP in dataframe:
    which( . )
  
  # Return integer.
  return( rowindex )
  
}



# Function to extract and transform the minimum and maximum coefficients
filter_and_minmax <- function(data, pattern) {

  ## I. SELECT THE FIRST HALF OF REGRESSION COLUMNS ------------------------------

  # Calculate the number of columns
  num_cols <- ncol(data)

  # Verify that there are at least two columns
  if (num_cols < 2) {
    stop("Data must have at least two columns")
  }

  # Calculate the end column index for the first half
  end_col <- floor((num_cols - 1) / 2) + 1  # Adjusted index

  # Select the first half of the columns, including the first column
  data <- data[, 1:end_col]

  # Ensure column names are valid and unique
  colnames(data) <- make.names(colnames(data), unique = TRUE)

  ## II. FILTER ROWS MATCHING THE PATTERN -----------------------------------------

  # Retrieve the name of the first column
  first_col_name <- names(data)[1]

  # Filter rows where the first column matches the regex pattern
  filtered_data <- data %>%
    dplyr::filter(stringr::str_detect(
      .data[[first_col_name]],
      regex(pattern, ignore_case = TRUE)
    ))

  ## III. EXTRACT AND CLEAN COEFFICIENTS ------------------------------------------

  # Coefficient columns start from the second column
  coef_cols <- names(filtered_data)[-1]

  # Convert coefficients to numeric, stripping non-numeric characters
  cleaned_data <- filtered_data %>%
    dplyr::mutate(across(
      all_of(coef_cols),
      ~ as.numeric(stringr::str_replace_all(., "[^0-9.-]", ""))
    ))

  ## IV. IDENTIFY MINIMUM AND MAXIMUM COEFFICIENTS --------------------------------

  # Select the first row (assuming one variable matches the pattern)
  coefs <- cleaned_data[1, coef_cols]

  # Convert to numeric vector
  coefs_numeric <- as.numeric(coefs)

  # Find indices of min and max coefficients
  min_index <- which.min(coefs_numeric)
  max_index <- which.max(coefs_numeric)

  # Get the min and max coefficient values (convert to percentage points)
  min_value <- coefs_numeric[min_index] * 100
  max_value <- coefs_numeric[max_index] * 100

  # Get the names of the models corresponding to min and max coefficients
  min_model <- coef_cols[min_index]
  max_model <- coef_cols[max_index]

  ## V. RETURN RESULTS ------------------------------------------------------------

  # Create a data frame with the results
  result <- data.frame(
    model_min = min_model,
    min = min_value,
    model_max = max_model,
    max = max_value
  )

  return(result)
}



## ========================================================================== ##
# III. LOAD AND PREPARE DATA.---------------------------------------------------
## ========================================================================== ##


# Table file name.
table_file <- "did_probrca_results_estout.csv"


# ======== A. Load and prepare data. ======== #

# Convert ESTOUT CSV into a dataframe.
dataset <- file.path( intermediate_dir , table_file ) %>%
           read.csv( file = . , sep = "\t" )


# ======== B. Clean up regression rows. ======== #

# Clean variable names.
var_names <- names( dataset )

# Test that prepared data.frame is not empty.
test_that("Test that prepared data.frame is not empty", {
  expect_equal( plyr::empty( dataset ), FALSE ) })

# Clean important rows.
dataset[,1] <- dataset[,1] %>%
                  stringr::str_replace_all(c(
                    "_cons" = "Constant",
                    "r2" = "R2",
                    "year" = "",
                    "#" = "",
                    "korea" = "Korea",
                    "^1" = "",
                    "hci" = "Targeted",
                    "\\." = "",
                    "l_gdp_pc" = "GDP per capita",
                    "(C|c).(l|h)" = ""
                  ))

 # Clean these up:
dataset <- dataset[!duplicated(dataset), ]


# ======== C. Clean the table. ======== #

# Correct column names:
names( dataset ) <- names( dataset ) %>%
                        stringr::str_to_lower( . ) %>%
                        stringr::str_replace_all("[_a-z]" , "" ) %>%
                        stringr::str_replace_all("\\." , "" )

# Now, cut off the outcome list row - first row:
cleaneddataset <- dataset[-1,]


# Test that prepared data.frame is not empty.
test_that("Test that prepared data.frame is not empty", {
  expect_equal( plyr::empty( cleaneddataset ), FALSE ) })



## ========================================================================== ##
# IV. MAKE WIDE TABLE KABLE OUT.------------------------------------------------
## ========================================================================== ##

num_regs <- length(cleaneddataset) - 1

# Get indices for table.
start_stats_rows <- getrows_helper( cleaneddataset, "ffect")
end_stats_rows <- getrows_helper( cleaneddataset, "luster")

# Add names
names( cleaneddataset ) <- c("",paste0( "(", 1:num_regs, ")" ))


# Gen alignment string for latex: e.g. lcccc.
alignstring <- c("l",rep("c",num_regs))


# Make the table.
trade_prob_table <- kable( 
  cleaneddataset , 
  format = "latex",
  digits = 3,
  booktabs = TRUE,
  longtable = FALSE,
  row.names = FALSE,
  escape = FALSE,
  align = alignstring,
  label = table_label_string,
  caption = table_caption_string,
  linesep = ""
) %>%

# Adding coefficient indents for clarity (distinguish from "pack row" labels).
add_indent(., 1:nrow(cleaneddataset) ) %>% 

# Indent the control rows and test rows.
pack_rows( . , "", start_row = start_stats_rows, end_row = end_stats_rows ) %>% 

## KABLE Styling
kableExtra::kable_styling( . , 
  protect_latex = TRUE,
  repeat_header_continued = TRUE,
  full_width = FALSE , 
  table.envir = "table", 
  font_size = font_size_argument 
) %>%

# Add footnote...
footnote( 
  general = footnote_string ,
  general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
  footnote_as_chunk = TRUE,
  threeparttable = TRUE,
  escape = FALSE
)  %>%

# Add headers to the table.
kableExtra::add_header_above( . , 
  c("",
    "Full Sample" = 2,
    "Similar GDP"= 1,
    "Same GDP"= 1,
    "Full Sample" = 2,
    "Similar GDP"= 1,
    "Same GDP"= 1 
  ) , 
  align = "c" 
) %>%

# Add headers to the table.
kableExtra::add_header_above( . , 
  c("",
    "Estimates with OLS" = num_regs/2 ,
    "Estimates with PPML" = num_regs/2 
  ) , 
  align = "c" 
) %>%

# Add headers to the table.
kableExtra::add_header_above( . , 
  c("",
    "Outcomes: Probability of Comparative Advantage" = num_regs 
  ) , 
  font_size = font_size_argument + 1 , 
  align = "c" 
)



## ========================================================================== ##
# V. INTERPRETATION.------------------------------------------------------------
## ========================================================================== ##

# OLS estimates -- more appropriate for interpretation.
halfcols<-num_regs/2+1 # 1-4 for OLS, select
df <- cleaneddataset[ ,1:halfcols] 

# Get the min and max of OLS estimates
probworldrca_max <- filter_and_minmax( df , "korea" )$max
probworldrca_min <- filter_and_minmax( df , "korea" )$min


# Get the mean of OLS estimates
meanfirstcol <- cleaneddataset[ which(grepl("[Mm]ean", cleaneddataset[,1])), ] %>%
                    dplyr::select( . , grep("1", colnames(.)) ) %>%
                    as.numeric( . )

# Round to first decimal.
meanfirstcolpercent <- round( meanfirstcol*100 , 1)


## ========================================================================== ##
# VI. SAVE THE KABLE TABLE ------------------------------------------------
## ========================================================================== ##
output_file <- file.path(
  tables_appendix_dir,
  "trade_prob_table.tex"
)

cat(trade_prob_table, file = output_file)

testthat::test_that("Kable table is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})

## ======== SAVE OTHER RESULTS ======== ##

# MIN and MAX of RCA probabilities. 
cat( probworldrca_max, 
     file = file.path( tables_appendix_dir, "results_tradeprob_maxrca.tex"))

# Save the table to the tables_dir directory.
cat( probworldrca_min, 
     file = file.path( tables_appendix_dir, "results_tradeprob_minrca.tex"))

# For the Appendix.
cat( meanfirstcolpercent, 
     file = file.path( tables_appendix_dir, "results_tradeprob_meanrcahci.tex"))
