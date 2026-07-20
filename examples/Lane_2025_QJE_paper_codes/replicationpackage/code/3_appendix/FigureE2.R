## =============================================================================
# PURPOSE:
#   Creates visualizations showing dynamic differences-in-differences estimates
#   for the relationship between total (Leontief) forward linkage exposure and
#   export development.
#
# INPUTS:
#   - did_iolf_comtrade_all_results.csv
#
# OUTPUTS:
#   - gg_rcatotallink_grid
# ==============================================================================

## ========================================================================== ##
# I. ARGUMENTS AND PLOT/TEXT SETTINGS -----------------------------------------
## ========================================================================== ##

.

## A. BASIC ARGUMENTS. ---------------------------------------------------------
font_size_argument <- 11

linkagestring <- "total (Leontief) forward"

footnote_string <- paste0( "\\indent The figure plots dynamic differences-in-differences
                           estimates for the relationship between ", linkagestring ," 
                           linkage exposure and export development. The coefficients 
                           in the plot are estimated from the main DD linkage specification. 
                           For the raw RCA (Balassa) index, regressions are estimated using PPML. RCA (asinh) 
                           and relative export productivity (CDK) are estimated 
                           using OLS. Linkage measures are calculated from the 
                           1970 input-output tables. All estimates are relative 
                           to 1972, the year before HCI. The year 1979 corresponds
                           to the collapse of the Park regime. Years are on the x-axis. 
                           Estimates for the main linkage interaction (", linkagestring ,") 
                           are on the y-axis: e.g., Linkage \\(\\times\\) Year.
                           These estimates come from the DD specification that includes 
                           the impact of both measures. Full sample regressions control 
                           for the main HCI \\(\\times\\) Year effect. 95 percent 
                           confidence intervals are shown in gray.")

footnote_string <- gsub( "\n" , " " , footnote_string )

## B. GGPLOT ARGUMENTS ---------------------------------------------------------

error_width <- 0
error_alpha <- 0.4

# Main minimal theme.
main_minimal_theme <- theme(
  text = element_text( size = font_size_argument ) ,
  plot.title = element_text( size = font_size_argument,  
                             color = annotation_color,
                             hjust = 0.5 ) , 
  axis.text = element_text( size = rel(.9) ) ,
  axis.title.x = element_blank(),
  axis.title.y = element_text( size = rel(1.1),
                               lineheight = 1.1,
                               margin = margin( 0 , 10 , 0 , 10 ) ) ,
  axis.ticks = element_line( size =.25, 
                             colour = annotation_color )
)

    

## ========================================================================== ##
# II. - HELPING FUNCTIONS ------------------------------------------------------
## ========================================================================== ##


## ========================================================================== ##
# A. LOAD DATA FUNCTION -------------------------------------------------------


# Dataset loader for all functions
regsavedataloader <- function( filename_arg ) {
  
  df <- file.path( intermediate_dir , paste0( filename_arg ) ) %>%
         read.csv( . , header = TRUE , na.strings = c( "" , "." , "NA" ) )
  
  # Test that prepared data.frame is not empty.
  test_that("Test that prepared data.frame is not empty", {
    expect_equal( plyr::empty( df ), FALSE ) })
  
  return( df )
}


## ========================================================================== ##
# B. MAKE GGPLOT WITH SMALL BARS THEME ----------------------------------------


# Themes now saved in the pre-amble header.
ggplot_smallbarstheme <- function( df , 
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
                      size = .3 ) +
          geom_vline( xintercept = 1972 , 
                      color = med_grey_argument , 
                      lty = "dashed" , 
                      size = .3 ) +
          geom_vline( xintercept = 1979 , 
                      color = med_grey_argument , 
                      lty = "dashed" , 
                      size = .3 ) +
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
  
  # Remove labels 
  g <- g + labs( x = "" , y = "" )
  
  # Return the GGPLOT object.
  return( g )
  
}

## ========================================================================== ##
# III. - MAIN FUNCTION FOR ROLLING GGPLOT GRAPH --------------------------------
## ========================================================================== ##

## This is the main function for the rolling GGPLOT graphic. 
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
  
  
  ### 2) ======== Generate MAIN baseline GGPLOT object. ======== ###
  
  # Start with the prepared data frame....
  g <- ggplot_smallbarstheme( table )
  
  # Simplifying plot aesthetics.
  g <- g + main_minimal_theme
  
  return( g )
  
}


## ========================================================================== ##
# IV. MAKE GGPLOTS AND EXECUTE FUNCTION ----------------------------------------
## ========================================================================== ##

## A. Prepare arguments. -------------------------------------------------------

# Filename of regression output.
regdatafilename <- "did_iolf_comtrade_all_results.csv"

# List of variables.
listofoutcomes <- c( "rca_core" , "rca_cdk", "h_rca_core")


# Create a data frame with combinations of arguments for mapply "loop"
argument_grid <- expand.grid(
  filenamearg = regdatafilename,
  outcomearg = listofoutcomes,
  restrictionsarg = c(9, 0),
  stringsAsFactors = FALSE
)


## B. Make plots by looping over the argument grid. ----------------------------

# Make the plots.
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
names(ggplot_list)


# Get lists by variables
rca_list <- ggplot_list[ grep("gg_rca.*core", names(ggplot_list)) ]
hrca_list <- ggplot_list[ grep("_h.*rca", names(ggplot_list)) ]
cdk_list <- ggplot_list[ grep("cdk", names(ggplot_list)) ]


## ========================================================================== ##
# V. PREPARE PLOTS FOR GRID ----------------------------------------------------
## ========================================================================== ##


## ========================================================================== ##
# 1. PREPARE PLOT LABELS AND TITLES --------------------------------------------


## A. ADD LABELS TO PLOTS ------------------------------------------------------

# Add labels to row (first only)

rca_list[[1]] <- rca_list[[1]] + labs( y = "RCA" ) +
  theme( axis.title.y = element_text( size = font_size_argument ) )

hrca_list[[1]] <- hrca_list[[1]] + labs( y = "RCA (asinh)" ) +
  theme( axis.title.y = element_text( size = font_size_argument ) )

cdk_list[[1]] <- cdk_list[[1]] + labs( y = "Relative export \n productivity (CDK)" ) +
  theme( axis.title.y = element_text( size = font_size_argument ) )


# And add the x-axis label to the bottom row.
cdk_list[[1]] <- cdk_list[[1]] + labs( x = "Year" )
cdk_list[[2]] <- cdk_list[[2]] + labs( x = "Year" )


## B. ADD TITLES TO PLOTS ------------------------------------------------------

# Add to top row.

# N - long list of title elements.
letterlist <- paste0("Panel ",LETTERS[1:length(cdk_list)],")  ")
sampletitlelist <- c( "Full Sample", "Non-HCI Only Sample" )

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
          axis.ticks.x = element_blank(),
          title = element_text( size = font_size_argument + 2 ) )
  
  # Remove X-ticks and style label titles
  hrca_list[[i]] <- hrca_list[[i]] + 
    theme(axis.text.x = element_blank(),
          axis.ticks.x = element_blank(),
          title = element_text( size = font_size_argument + 2 ) )
  
}


## C. ASSEMBLE PLOTS INTO GRID ------------------------------------------------

# Make list of plots.
gglist <- c( rca_list , hrca_list , cdk_list )

# Assemble into grid.
gg_rcatotallink_grid <- ggpubr::ggarrange( plotlist = gglist ,
                                                  ncol = 2,
                                                  nrow = length(listofoutcomes))

## ========================================================================== ##
# IV. SAVE PLOT AND FOOTNOTE ---------------------------------------------------
## ========================================================================== ##

# Save plot.
save_plot( plot_object = gg_rcatotallink_grid ,
           filename = "gg_rcatotallink_grid" ,
           width = 7 ,
           height = 5.25 ,
           output_dir = figures_appendix_dir )

save_figure_footnote( footnote_string ,
                      output_dir = figures_appendix_dir ,
                      label = "gg_rcatotallink_grid" )


test_that("Test that plot and footnote are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_rcatotallink_grid.pdf" ) ) )
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_rcatotallink_grid.tex" ) ) )
})
