## =============================================================================
# PURPOSE:
#   R-version of the main analysis for the paper, plotting dynamic DD graphs for
#   forward linkage exposure and outcomes.
#
# INPUTS:
#   - "did_io_main_all_results.csv" (Regression output)
#
# OUTPUTS:
#   - gg_forwardlink_grid (Combined ggplot object for forward linkage analysis)
# ==============================================================================

## =============================================================================
# I. TEXT AND PLOT ARGUMENTS --------------------------------------------------
## =============================================================================

footnote_string <- "\\indent This figure plots dynamic differences-in-differences 
estimates for the relationship between direct forward linkage exposure and log outcomes: real output 
(value shipped) (top) and output prices (bottom). The coefficients in the plot are estimated 
from equation \\eqref{eq:networkflexible}. Linkages are calculated from the 1970 input-output 
tables; see text for details. All estimates are relative to 1972, the year before HCI. The year 1979 
corresponds to the collapse of the Park regime. Years are on the x-axis. Estimates for the main 
linkage interaction (forward) are on the y-axis: e.g., Linkage \\(\\times\\) Year. 
These estimates come from the DD specification that includes the impact of both measures. 
Full sample regressions control for the main Targeted \\(\\times\\) Year effect. 95 percent 
confidence intervals are shown in gray."

footnote_string <- gsub( "\n", " ", footnote_string )

## =============================================================================
# I. ARGUMENTS AND PLOT/TEXT SETTINGS -----------------------------------------
## =============================================================================

# Error width
error_width <- 0
error_alpha <- 0.3

# Make the minimal theme.
newminimaltheme <- theme( 
    text = element_text( size = font_size_argument - 1 ) ,
    plot.title = element_text( size = font_size_argument,  
                               color = annotation_color,
                               lineheight = 1.1 ,
                               hjust = 0.5 ) , 
    axis.ticks = element_line( size = .25 ),
    axis.text = element_text( size = rel(.85)),
    axis.title.y = element_text( size = rel(1.1), 
                                 lineheight = 1.1, 
                                 margin = margin( r = 5 )),
    axis.title.x = element_blank()
)

## =============================================================================
# II. - HELPING FUNCTIONS ------------------------------------------------------
## =============================================================================

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

## B. GGPLOT THEMES  -----------------------------------------------------------
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
                        size = .7,    
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
                    alpha = 0.9, 
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
  g <- g + labs( x = "", y = "" )

  # Test that the GGPLOT object is not empty.
  test_that( "Test if ggplot object", {
    expect_true(is.ggplot(g))
  })
  
  # Return the GGPLOT object.
  return( g )  
}

## =============================================================================
# III. - MAIN FUNCTION FOR ROLLING GGPLOT GRAPH --------------------------------
## =============================================================================
make_link_plot <- function( filenamearg , 
                            outcomearg , 
                            datatypearg , 
                            restrictionsarg ){
  
  ### 1) ======== Load and clean data. ======== ###
  table <- regsavedataloader( filenamearg ) %>%
              
              # Filter coefficient lines:
              dplyr::filter( grepl( "(^[0-9]{4}[bB]?\\.year\\#[coi]+\\..*hci.*)" , var ) ) %>%
              dplyr::filter( grepl( ".*rolling|event.*" , didtype ) ) %>%
    
              # Filter based on outcome, datatype, and restrictions arguments:
              dplyr::filter( outcome == outcomearg ) %>%
              dplyr::filter( datatype == datatypearg ) %>%
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
  g <- ggplot_smallbars( table )
  
  # Simplifying plot aesthetics.
  g <- g + newminimaltheme
  
  # Test that the GGPLOT object is not empty.
  test_that( "Test if ggplot object", {
    expect_true(is.ggplot(g))
  })
  return( g )
}


## =============================================================================
# IV. MAKE GGPLOTS AND EXECUTE FUNCTION ----------------------------------------
## =============================================================================

## A. Prepare arguments. -------------------------------------------------------
regdatafilename <- "did_io_main_all_results.csv"
listofoutcomes <- c("l_valueadded","l_ppi")

# Create a data frame with combinations of arguments for mapply "loop"
argument_grid <- expand.grid(
  outcomearg = listofoutcomes,
  filenamearg = regdatafilename,
  restrictionsarg = c(9, 0),
  datatypearg = c(4, 5),
  stringsAsFactors = FALSE
)

## B. Make plots by looping over the argument grid. ----------------------------

# Make the plots.
ggplot_list <- mapply( make_link_plot,
                       argument_grid$filenamearg,
                       argument_grid$outcomearg,
                       argument_grid$datatypearg,
                       argument_grid$restrictionsarg,
                       SIMPLIFY = FALSE )
# Name the plots.
names(ggplot_list) <- paste("gg", 
                            argument_grid$outcomearg,
                            argument_grid$datatypearg,
                            argument_grid$restrictionsarg, 
                            sep = "_" )
names(ggplot_list)

# Get price list and output list.
price_plot_list <- ggplot_list[ grep("ppi", names(ggplot_list)) ]
output_plot_list <- ggplot_list[ grep("value", names(ggplot_list)) ]

## =============================================================================
# V. PREPARE PLOTS FOR GRID ----------------------------------------------------
## =============================================================================

# 1. PREPARE PLOT LABELS AND TITLES --------------------------------------------

## A. ADD ROW LABELS TO PLOTS TO Y-AXIS ----------------------------------------  
output_plot_list[[1]] <- output_plot_list[[1]] + labs( y = "Value Added (log)" )
price_plot_list[[1]] <- price_plot_list[[1]] + labs( y = "Prices (log)" ) 

## B. ADD TITLES TO PLOTS ------------------------------------------------------

# Add to top row.\
# N - long list of title elements.
letterlist <- paste0(LETTERS[1:length(price_plot_list)],")  ")
datatitlelist <- c( rep("Four-Digit Panel", 2) , rep("Five-Digit Panel", 2) )
sampletitlelist <- rep(c("Full Sample","Non-Treated Only") , 2)

# Assesmble title list.
titlelist <- paste0( letterlist[1:4], datatitlelist[1:4], 
                      "\n", sampletitlelist[1:4],"\n" )

# Add titles to top row.
for (i in seq_along(output_plot_list)) {
  
  # Add title to each ggplot
  output_plot_list[[i]] <- output_plot_list[[i]] + 
                            labs( title = paste0( titlelist[i] ) )
    
  # Remove X-ticks and style label titles
  output_plot_list[[i]] <- output_plot_list[[i]] + 
                            theme(axis.text.x = element_blank(),
                                  axis.ticks.x = element_blank())
}

## C. ASSEMBLE PLOTS INTO GRID ------------------------------------------------
gg_forwardlink_grid <- ggpubr::ggarrange( plotlist = c(output_plot_list,
                                                       price_plot_list), 
                                          ncol = length(output_plot_list),
                                          nrow = length(listofoutcomes) )

## =============================================================================
# VI. SAVE PLOT AND FOOTNOTE ----------------------------------------------------
## =============================================================================

save_plot( gg_forwardlink_grid, 
           "forwardlinkageplot", 
           output_dir = figures_dir,
           width = 11, 
           height = 5.75 )

save_figure_footnote( footnote_string, 
                     figures_dir, 
                     "forwardlinkageplot" )