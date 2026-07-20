## =============================================================================
# PURPOSE:
#   Creates tables showing dynamic differences-in-differences estimates for the
#   relationship between HCI and industrial development outcomes.
#
# INPUTS:
#   - did_largerolling_allproductivity_results_estout.csv
#   - did_largerolling_allproductivity_4d_results_estout.csv
#
# OUTPUTS:
#   - tablerollingdevelopment.tex
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS. -------------------------------------------------
## ========================================================================== ##

## CURRENTLY IN THE RMARKDOWN CHUNK

## PREPARE TITLES AND SUBTITLES, TEX LABELS ------------------------------------
tablecaptionstring <- "Robustness: Industrial Policy and Industrial Development by Treatment Status, Multiple Measures of Output"
tablelabelstring <- "supptablerollingdevelopment"


## PREPARE NOTES AND FOOTNOTES -------------------------------------------------

# Table-specific notes.
footnotestring <- "The table reports dynamic differences-in-differences estimates for the relationship between heavy and chemical industry drive and (log) industrial outcomes. Output share is the industry share of manufacturing output. Prices are output prices. Labor Productivity is value added per worker. Number of Plants is the count of establishments. Employment is total number of industry workers. Labor (output) Share is the industry's share of manufacturing employment (output). Estimates are relative to 1972, the year before HCI. Specifications with controls include pre-1973 industry (log) averages: avg. wages, avg. plant size, intermediate input costs, and labor productivity, interacted with time. Standard errors are clustered at the industry level. * Significant at the 10 percent level. ** Significant at the 5 percent level. *** Significant at the 1 percent level."

# Font size argument for the table
font_size_argument <- 7

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')

## ========================================================================== ##
# II. SUB-FUNCTIONS ------------------------------------------------------------
## ========================================================================== ##


## A. Get row IDs using REGEX. --------------------------------------------------

getrowids <- function( dataset, regexstring ){
  
  # Get row number by REGEX string.
  rowindex <- paste0( regexstring ) %>%  
    # Paste into GREP function, use first column.
    grepl( . , dataset[[1]] ) %>%
    # Use GREP to get rows matching GREP in dataframe:
    which( dataset[. , ] ) %>%
    # Convert rownames to numeric
    as.numeric
  
  # Return integer.
  return( rowindex )
  
}



## ========================================================================== ##
# III. MAIN FUNCTION -----------------------------------------------------------
## ========================================================================== ##

# Helper function for loading rolling dataset.
loadandcleanestouttable <- function( table_file ){
  
  # Convert ESTOUT CSV into a dataframe.
  dataset <- file.path( intermediate_dir , table_file ) %>%
              read.csv( . , header = TRUE, sep = "\t" )
  
  # Test the table is non-empty....
  test_that( "Filtered table is not empty", {
    expect_equal( plyr::empty( dataset ), FALSE ) } )
  
  ## Clean row strings only.
  dataset[,1] <- dataset[,1] %>%
    stringr::str_replace_all( "year" , "" ) %>% 
    stringr::str_replace_all( "[#\\.]" , "" ) %>% 
    stringr::str_replace_all( "^1" , "" ) %>%
    stringr::str_replace_all( "hci" , "Targeted \\\\(\\\\times\\\\) " ) %>%
    stringr::str_replace_all( "[Ff][Ee]$" , "FE" ) 

  
  # Correct column names
  names( dataset ) <- str_to_lower( names( dataset ) ) %>%
    str_replace_all("[\\._a-z]" , "" )
  
  # Test the table is non-empty....
  test_that( "Filtered table is not empty", {
    expect_equal( plyr::empty( dataset ), FALSE ) } )
  
  return( dataset )
}


## ========================================================================== ##
# IV. LOAD AND PREPARE DATA ---------------------------------------------------
## ========================================================================== ##


## A. Load and clean datasets --------------------------------------------------

# Generate cleaned ESTOUT tables.
table_fileA <- "did_largerolling_allproductivity_results_estout.csv"
table_fileB <- "did_largerolling_allproductivity_4d_results_estout.csv"


## Clean and combine 4 and 5-digit datasets.
datasetA <- loadandcleanestouttable( table_fileA )
datasetB <- loadandcleanestouttable( table_fileB )


test_that("Test sure n cols of datasets are equal", {
  expect_equal( length(datasetA) , 
                length(datasetB)) })


## B. Make blank chunk for 5-digit data frame. ---------------------------------

# Make blank chunk for 5-digit data frame:
gap_nrow <- nrow(datasetB)-nrow(datasetA)
blankpadding <- data.frame(matrix(ncol = ncol(datasetA), 
                                  nrow = gap_nrow))

# Inherit names for blank space.
names( blankpadding ) <- names( datasetA )

# Stack blank data onto dataset A
datasetA <- rbind( blankpadding, datasetA )


## C. Combine datasets ---------------------------------------------------------

# Bind both datasets and attach (side by side):
stackeddatasets <- cbind( datasetB[,1], 
                          datasetA[,-1] ,
                          datasetB[,-1] )

test_that("Test that prepared data.frame is not empty", {
  expect_equal( plyr::empty( stackeddatasets ), FALSE ) })



## ========================================================================== ##
# V. MAKE THE TABLE ------------------------------------------------------------
## ========================================================================== ##


## A. GET TABLE DIMENSIONS -----------------------------------------------------

# Add combined named list to new dataset.
num_regs <- ncol(stackeddatasets)-1
names(stackeddatasets) <- c("",paste0("(",1:num_regs,")"))

# Gen alignment string for latex: e.g. lcccc.
alignstring <- c("l",rep("c",num_regs))

# Get indices
striperow <- getrowids( stackeddatasets, "19")


## B. MAKE KABLE ---------------------------------------------------------------

# KABLE FUNCTION FOR COMBINED ROWS.
stackeddevtable <- kable( stackeddatasets , 
                          format = "latex", 
                          digits = 2,
                          escape = FALSE,
                          booktabs = T , 
                          longtable = F ,
                          row.names = F ,
                          align = alignstring ,
                          caption = tablecaptionstring ,
                          label = tablelabelstring,
                          linesep = "") %>%
  
  # Adding coefficient indents for clarity (distinguish from "pack row" labels).
  add_indent(. ,  1:max(striperow) , 
             level_of_indent = 1 ) %>% 
  
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
  kableExtra::footnote(
    general = footnotestring,
    general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
    footnote_as_chunk = TRUE,
    threeparttable = TRUE,
    escape = FALSE
  ) %>%
  # Headers below here for editing.
  # l_ship_sh l_ppi l_y_n l_est l_avg_size l_workers l_lab_sh  
  add_header_above(. , c("",
                         "Output\nShare" = 1,
                         "Prices" = 1,
                         "Labor\nProduct." = 1,
                         "Average\nSize" = 1,
                         "Plants" = 1,
                         "Employment" = 1,
                         "Employment\nShare" = 1,
                         "Output\nShare" = 1,
                         "Prices" = 1,
                         "Labor\nProduct." = 1,
                         "Average\nSize" = 1,
                         "Plants" = 1,
                         "Employment" = 1,
                         "Employment\nShare" = 1),
                   line = TRUE ,
                   bold = FALSE, 
                   line_sep = 2 ,
                   align = "c" ,
                   font_size = font_size_argument  ) %>%
  
  # Add header above.
  add_header_above(. , 
                   c(" ", 
                     "Panel A) 5-Digit Panel, 1970 - 1986" = ncol(datasetA)-1, 
                     "Panel B) 4-Digit Panel, 1967 - 1986" = ncol(datasetB)-1) ,
                   line = TRUE ,
                   bold = FALSE, 
                   align = "c" ,
                   font_size = font_size_argument + 1 )

## ========================================================================== ##
## VI. SAVE THE KABLE TABLE ------------------------------------------------------
## ========================================================================== ##

output_file <- file.path( tables_supplementalappendix_dir, 
                          "tablerollingdevelopment.tex")

cat(stackeddevtable, file = output_file)

testthat::test_that("DD Rolling Development kable is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})



