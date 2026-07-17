# Annotated copy for replication audit.
# Original script: Lane2025QJE/replicationpackage/code/1_figures/Figure7.R
# Purpose: Generates Figure 7.
#
# This file intentionally keeps the original .R extension.
# The original code is copied below. Comments in this header identify the
# script role, inputs, outputs, and audit linkage. The earlier prose note is
# archived at: markdown_notes_archive/Figure7_R.md
#
# Audit linkage:
# - Methods report: explains the estimating or output logic.
# - Derivation report: maps equations/design objects to code.
# - Replication report: documents inputs, outputs, and reproducibility limits.
#
# Original code begins after this header.

## =============================================================================
# PURPOSE:
#   Creates a plot showing the relationship between forward linkage exposure
#   and downstream export performance using dynamic differences-in-differences
#   estimates.
# INPUTS:
#   - did_io_comtrade_all_results.csv
#
# OUTPUTS:
#   - GGPLOT object: gg_rcalink_grid
# ==============================================================================

## ========================================================================== ##
# X. FOOTNOTES. ----------------------------------------------------------------
## ========================================================================== ##

footnote_string <-  "\\indent This figure plots dynamic differences-in-differences
 estimates for the relationship between direct forward linkage exposure
and export development outcomes. The coefficients in the plot are estimated from 
equation \\eqref{eq:networkflexible}. Top row shows estimates using the raw RCA 
(Balassa) index, estimated using PPML. The middle row shows alternative RCA, transformed 
using inverse hyperbolic sine to account for 0s, and estimated using OLS. The bottom 
row shows OLS estimates for the relative export productivity (CDK) outcome. Linkage 
measures are calculated from the 1970 input-output tables (zero to one); see text for 
details. All estimates are relative to 1972, the year before HCI. The year 1979 corresponds 
to the collapse of the Park regime. Years are on the x-axis. Estimates for the main 
linkage interaction (forward) are on the y-axis: e.g., Linkage \\(\\times\\) Year. 
These estimates come from the DD specification that includes the impact of both measures. 
Full sample regressions control for the main HCI \\(\\times\\) Year effect. 95 percent 
confidence intervals are shown in gray."

footnote_string <- gsub( "\n", " ", footnote_string )

## ========================================================================== ##
# I. ARGUMENTS AND PLOT/TEXT SETTINGS -----------------------------------------
## ========================================================================== ##

# Error width
error_width <- 0
error_alpha <- 0.5

# New minimal theme
newminimaltheme <- theme( 
  text = element_text( size = font_size_argument ) ,
  plot.title = element_text( size = font_size_argument,  
                              color = annotation_color,
                              hjust = 0.5 ) , 
  axis.text = element_text( size = rel(.9) ) ,
  axis.title.x = element_blank(),
  axis.title.y = element_text( size = rel(.9),
                               lineheight = 1.1,
                               margin = margin( 0 , 10 , 0 , 10 ) ) ,
  axis.ticks = element_line( size =.25, 
                             colour = annotation_color )
)

## ========================================================================== ##
# II. - HELPING FUNCTIONS ------------------------------------------------------
## ========================================================================== ##

## A. LOAD DATA FUNCTION -------------------------------------------------------

# Dataset loader for all functions
regsavedataloader <- function( filename_arg ) {
  df <- file.path( intermediate_dir , paste0( filename_arg ) ) %>%
         read.csv( . , header = TRUE , na.strings = c( "" , "." , "NA" ) )
  # Test that prepared data.frame is not empty.
  test_that("Test that prepared data.frame is not empty", {
    expect_equal( plyr::empty( df ), FALSE ) })
  
  return( df )
}

## B. GGPLOT FUNCTION ----------------------------------------------------------
# Themes now saved in the pre-amble header.
ggplot_smallbars <- function( df , 
                              start_year_arg = NULL, 
                              end_year_arg = NULL ){
  
  # If no start year, were equal.
  ifelse( !is.null( start_year_arg ),
          start_year <- start_year_arg , 
          start_year <- 1965 )
  
  # If no start year, were equal.
  ifelse( !is.null( end_year_arg ),
          end_year <- end_year_arg , 
          end_year <- 1986 )  
  
  ## Make the ggplot object.
  g <- ggplot( data = df , 
              aes( x = year ) ) +
        geom_errorbar( aes( min = ci_lower , 
                            max = ci_upper),
                        alpha = error_alpha, 
                        width = error_width ) +
        geom_hline( yintercept = 0 , 
                    color = med_grey_argument, 
                    size = .25 ) +
        geom_vline( xintercept = 1972 , 
                    color = med_grey_argument , 
                    lty = "dotted" , 
                    size = .5 ) +
        geom_vline( xintercept = 1979 , 
                    color = med_grey_argument , 
                    lty = "dotted" , 
                    size = .5 ) +
        geom_point( aes( x = year , 
                          y = coef ) , 
                    size = 1, 
                    alpha = 0.75, 
                    color = annotation_color ) +
        scale_x_continuous( breaks = c( start_year , 
                                        1972 , 
                                        1979 , 
                                        end_year ), 
                            labels = c( paste0( start_year ), 
                                        "1972" , 
                                        "1979", 
                                        paste0( end_year ) ) ,
                            limits = c( start_year , 
                                        end_year ) )
  # Add labels
  g <- g + labs( x = "Year", y = "" )

  # Test that the GGPLOT object is not empty.
  test_that( "Test if ggplot object", {
    expect_true(is.ggplot(g))
  })
  
  # Return the GGPLOT object.
  return( g )
}

## ========================================================================== ##
# III. - MAIN FUNCTION FOR MAKING GGPLOT  --------------------------------------
## ========================================================================== ##

# This is the main function for the making GGPLOT graphic. 
make_link_plot <- function( filenamearg , 
                            outcomearg , 
                            restrictionsarg ){
  
  ### 1) ======== Load and clean data. ======== ###
  table <- regsavedataloader( filenamearg ) %>%
    
      # Filter coefficient lines:
      dplyr::filter( grepl( "(^[0-9]{4}[bB]?\\.year\\#[coi]+\\..*hci.*)" , var ) ) %>%
      dplyr::filter( grepl( ".*rolling|event.*" , didtype ) ) %>%
      
      # Filter based on outcome, datatype, and restrictions arguments:
      dplyr::filter( outcome == outcomearg ) %>%
      dplyr::filter( restrictions == restrictionsarg ) %>%
      dplyr::mutate( year = str_match( var, "[0-9]{4}") %>% as.numeric() ) %>%

      # Filter based on link type argument:
      dplyr::mutate( linktype = str_extract_all(var, "(use|_in|_out|make)", simplify = TRUE) )  %>%
      dplyr::filter( grepl( "(use|out)" , linktype ) )
    
  # Test the table is non-tempty....
  test_that( "Cleaned table is not empty", {
    expect_equal( plyr::empty( table ), FALSE ) } )

  ### 2) ======== Generate GGPLOT object. ======== ###
  
  # Start with the prepared data frame....
  g <- ggplot_smallbars( table )
  
  # Simplifying plot aesthetics.
  g <- g + newminimaltheme
  
  # Test that the GGPLOT object is not empty.
  test_that( "Test if ggplot object", {
    expect_true(is.ggplot(g))
  })  
  return( g )
}

## ========================================================================== ##
# IV. MAKE GGPLOTS AND EXECUTE FUNCTION ----------------------------------------
## ========================================================================== ##

## A. Prepare arguments. -------------------------------------------------------

# Filename of regression output.
regdatafilename <- "did_io_comtrade_all_results.csv"

# List of variables.
listofoutcomes <- c( "rca_core" , "rca_cdk", "h_rca_core")

# Column labels. First is entire sample, second is non-HCI only.
columnlabels <- c("Entire Sample", 
                  "Non-Treated Only")

# Create a data frame with combinations of arguments for mapply "loop"
argument_grid <- expand.grid(
  filenamearg = regdatafilename,
  outcomearg = listofoutcomes,
  restrictionsarg = c(9, 0),
  stringsAsFactors = FALSE
)

## B. Make plots by looping over the argument grid. ----------------------------
ggplot_list <- mapply( make_link_plot,
                       filenamearg = argument_grid$filenamearg,
                       outcomearg = argument_grid$outcomearg,
                       restrictionsarg = argument_grid$restrictionsarg,
                       USE.NAMES = TRUE,
                       SIMPLIFY = FALSE )
# Name the plots.
names(ggplot_list) <- paste("gg", 
                            argument_grid$outcomearg,
                            argument_grid$restrictionsarg, 
                            sep = "_" )
# Get lists by variables
rca_list <- ggplot_list[ grep("gg_rca.*core", names(ggplot_list)) ]
hrca_list <- ggplot_list[ grep("_h.*rca", names(ggplot_list)) ]
cdk_list <- ggplot_list[ grep("cdk", names(ggplot_list)) ]

## ========================================================================== ##
# V. PREPARE PLOTS FOR GRID ----------------------------------------------------
## ========================================================================== ##

# 1. PREPARE PLOT LABELS AND TITLES --------------------------------------------

## A. ADD ROW LABELS TO PLOTS TO Y-AXIS ----------------------------------------  

# Add labels to row (first only)
rca_list[[1]] <- rca_list[[1]] + labs( y = "RCA" )
hrca_list[[1]] <- hrca_list[[1]] + labs( y = "RCA (asinh)" )
cdk_list[[1]] <- cdk_list[[1]] + labs( y = "Relative Export\nProductivity (CDK)" ) 

## B. ADD TITLES TO PLOTS ------------------------------------------------------

# N - long list of title elements.
letterlist <- paste0(LETTERS[1:length(cdk_list)],")  ")
sampletitlelist <- c( "Full Sample", "Non-Treated Only" )

# Assemble title list.
titlelist <- paste0( letterlist[1:2], sampletitlelist[1:2],"\n" )

# Add titles to top row.
for (i in seq_along(rca_list)) {  
  # Add title to plot; only for top row.
  rca_list[[i]] <- rca_list[[i]] + 
    labs( title = paste0( titlelist[i] ) )
  # Remove X-ticks and style label titles
  rca_list[[i]] <- rca_list[[i]] + 
    theme(axis.text.x = element_blank(),
          axis.ticks.x = element_blank() )
  # Remove X-ticks and style label titles
  hrca_list[[i]] <- hrca_list[[i]] + 
    theme(axis.text.x = element_blank(),
          axis.ticks.x = element_blank() )
}

## C. ASSEMBLE PLOTS INTO GRID ------------------------------------------------
gg_rcalink_grid <- ggpubr::ggarrange( plotlist = c(rca_list,
                        hrca_list ,
                        cdk_list ),
                      ncol = 2,
                      nrow = length(listofoutcomes) )

## ========================================================================== ##
# VI. SAVE PLOT AND FOOTNOTE ---------------------------------------------------
## ========================================================================== ##

save_plot( gg_rcalink_grid, 
           "forwardlinkagetrade", 
           output_dir = figures_dir,
           width = 10.5, 
           height = 6 )

save_figure_footnote( footnote_string, 
                     figures_dir, 
                     "forwardlinkagetrade" )