## =============================================================================
# PURPOSE:
#   Creates visualizations showing dynamic differences-in-differences estimates
#   for the relationship between total (Leontief) backward linkage exposure and
#   log real value added.
#
# INPUTS:
#   - did_iolf_main_all_results.csv
#
# OUTPUTS:
#   - gg_backwardlink_lf_grid
# ==============================================================================

## ========================================================================== ##
# I. ARGUMENTS AND PLOT/TEXT SETTINGS -----------------------------------------
## ========================================================================== ##

## A. BASIC ARGUMENTS. ---------------------------------------------------------
font_size_argument <- 11

notebody <- "log real value added."

linkagestring <- "total backward"

footnote_string <- "\\indent This figure plots dynamic differences-in-differences
 estimates for the relationship between total backward linkage exposure and outcomes: 
 log real value added. Estimates are relative to, 1972, the year before HCI. 
 The year 1979 corresponds to collapse of Park regime. Years are on the x-axis. 
 Estimates for the effect of total backward (Linkage $\\times$ Year) linkages 
 are on y-axis. Full sample regressions control for the main HCI $\\times$ Year 
 effect. All regressions include controls for total forward linkage connections, 
 interacted with time. 95 percent confidence intervals are shown in gray."

footnote_string <- gsub( "\n" , " " , footnote_string )

## B. GGPLOT ARGUMENTS ---------------------------------------------------------

# Graphical arguments
error_width <- 0
error_alpha <- .6

# Aesthetics for the main output plot at end. Using gg theme().
newminimaltheme <- ggplot2::theme(
  plot.title = ggplot2::element_text(size = rel(1), hjust = 0.5),
  axis.text.x = ggplot2::element_text(size = rel(1)),
  axis.text.y = ggplot2::element_text(size = rel(1)),
)

## ==========================================================================   ##
# II. - HELPING FUNCTIONS ------------------------------------------------------
## ========================================================================== ##


## A. LOAD DATA FUNCTION -------------------------------------------------------


# Dataset loader for all functions
regsavedataloader <- function( dataset_name_arg ) {
  
  df <- paste0( dataset_name_arg ) %>%
    
    # Read in the data set...
    file.path( intermediate_dir , . ) %>%
    read.csv( . , header = TRUE , 
              na.strings = c( "" , "." , "NA" ) ) %>%
    as.data.frame( . )
  
  # Test that prepared data.frame is not empty.
  test_that("Test that prepared data.frame is not empty", {
    expect_equal( plyr::empty( df ), FALSE ) })
  
  return( df )
  
}

## B. GG THEME SUB-FUNCTION ----------------------------------------------------

ggplotter_smallbars <- function( df ,
                                start_year_arg = NULL,
                                end_year_arg = NULL ){
  
  
  # If no start year, were equal.
  ifelse( !is.null( start_year_arg ),
          start_year <- start_year_arg , 
          start_year <- min( df$year ) )
  
  # If no start year, were equal.
  ifelse( !is.null( end_year_arg ),
          end_year <- end_year_arg , 
          end_year <- max( df$year ) )  

  # Make subplot.  
  gsub <- ggplot( data = df , 
                  aes( x = year ) ) +
    geom_errorbar( aes( min = ci_lower , 
                        max = ci_upper),
                   alpha = error_alpha, 
                   width = error_width ) +
    geom_hline( yintercept = 0 , color = med_grey_argument, size = .2 ) +
    geom_vline( xintercept = 1972 , color = med_grey_argument , lty = "dashed" , size = .3) +
    geom_vline( xintercept = 1979 , color = med_grey_argument , lty = "dashed" , size = .3) +
    geom_point( aes( x = year , y = coef ) , size = 1, alpha = .9, color = annotation_color ) +
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

  # Add blank labels, added later.
  gsub <- gsub + labs( x = "", y = "" )

  return(gsub)
}


# III.  LINKAGES - MAIN PLOT FUNCTIONS. ----------------------------------------

rolling_graphs_linkage_main  <- function( dataset_name , 
                                          outcome_keyword , 
                                          datatype_argument, 
                                          restrictions_argument,
                                          linktype_argument){
  
  ### 1) ======== LOAD THE DATASET. ======== ### 

  ## Load and clean data. Filter only essentials...
  table <- regsavedataloader( dataset_name ) %>%
    dplyr::filter(grepl("^[0-9]{4}[bB]?\\.year\\#[coi]+\\..*hci.*", var)) %>%
    dplyr::filter(grepl(".*rolling|event.*", didtype)) %>%
    dplyr::filter(outcome == outcome_keyword) %>%
    dplyr::filter(datatype == datatype_argument) %>%
    dplyr::filter(restrictions == restrictions_argument)
  
  # Test the table is non-tempty....
  test_that( "Filtered table is not empty", {
    expect_equal( plyr::empty( table ), FALSE ) } )
  
  # Generate YEAR variable from VAR variable string. 
  table$year <- table$var %>% 
    str_match( . , "[0-9]{4}") %>% 
    as.numeric( . )
  
  # Generate proper link variables. Using forward/backward language.       
  table$linktype <- stringr::str_extract_all( table$var , "(use|_in|_out|make)" , simplify = TRUE ) 
  
  # Now last filter, based on link to show in graph
  table <- dplyr::filter( table , grepl( paste0( ".*", linktype_argument ,".*") , 
                                         linktype ) )
  
  # Test the table is non-empty....
  test_that( "Cleaned table is not empty", {
    expect_equal( plyr::empty( table ), FALSE ) } )
  
  ### 2) ======== Generate MAIN baseline GGPLOT object. ======== ###
  
  # Start with the prepared data frame....
  g <- ggplotter_smallbars( table )
  
  ### 3) ======== Adjust the aesthetics of GGPLOT object, g. ======== ###
  
  # Simplifying plot aesthetics for the main output plot
  g <- g + newminimaltheme
  # Add labels.  
    return( g )
}

# III. (FOR MAIN) WRAPPER FUNCTION FOR EASE. -----------------------------------

# Wrapper for the function that allows us to vary things more simply.
gglinkplotwrapper <- function(x , filename , digit, sample ){
  
  rolling_graphs_linkage_main( dataset_name = filename , 
                               outcome_keyword = x , 
                               datatype_argument = digit , 
                               restrictions_argument = sample ,
                               linktype_argument = "make" )
}

# IV. LEONTIEF LINKAGES AND OUTPUT ---------------------------------------------

datasetname <- "did_iolf_main_all_results.csv"
outcome <- "l_valueadded"


## A. MAKE OUTPUT PLOTS --------------------------------------------------------

# ASSEMBLE GGPLOTS.
gg_backlfva_allsample_4 <- gglinkplotwrapper(outcome, 
                                             filename = datasetname, 
                                             digit = 4, 
                                             sample = 9)

gg_backlfva_nonhci_4 <- gglinkplotwrapper(outcome, 
                                          filename = datasetname, 
                                          digit = 4, 
                                          sample = 0)

gg_backlfva_allsample_5 <- gglinkplotwrapper(outcome, 
                                             filename = datasetname, 
                                             digit = 5, 
                                             sample = 9)

gg_backlfva_nonhci_5 <- gglinkplotwrapper(outcome, 
                                          filename = datasetname, 
                                          digit = 5, 
                                          sample = 0)


## B. EDIT PLOTS -----------------------------------------------------

columnlabels <- c("Full Sample", 
                  "Non-Targeted Only")

# Add titles to the plots.
gg_backlfva_allsample_4 <- gg_backlfva_allsample_4 +
  labs(title = paste0("A) ", columnlabels[1], ", Four-Digit Panel"))

gg_backlfva_nonhci_4 <- gg_backlfva_nonhci_4 +
  labs(title = paste0("B) ", columnlabels[2], ", Four-Digit Panel"))

gg_backlfva_allsample_5 <- gg_backlfva_allsample_5 +
  labs(title = paste0("C) ", columnlabels[1], ", Five-Digit Panel"))

gg_backlfva_nonhci_5 <- gg_backlfva_nonhci_5 +
  labs(title = paste0("D) ", columnlabels[2], ", Five-Digit Panel"),
       x = "Year") 


# C. ASSEMBLE GRAPHS INTO GRID ----------------------------------------------

## ASSEMBLE graphs into grid.
gg_backwardlink_lf_grid <- ggpubr::ggarrange(
  gg_backlfva_allsample_4, 
  gg_backlfva_nonhci_4,
  gg_backlfva_allsample_5, 
  gg_backlfva_nonhci_5,
  nrow = 4, 
  ncol = 1
)

# Add title to the grid
gg_backwardlink_lf_grid <- ggpubr::annotate_figure(gg_backwardlink_lf_grid, 
                            left = text_grob("Coefficient (Backward Linkage x Year)\n", 
                                            size = font_size_argument+1, 
                                            rot = 90,
                                            hjust = 0.5))

## ========================================================================== ##
# SAVE PLOT AND FOOTNOTE ---------------------------------------------------
## ========================================================================== ##

# Save plot.
save_plot( plot_object = gg_backwardlink_lf_grid ,
           filename = "gg_backwardlink_lf_grid" ,
           width = 10.5 ,
           height = 7.5 ,
           output_dir = figures_appendix_dir )

save_figure_footnote( footnote_string ,
                      output_dir = figures_appendix_dir ,
                      label = "gg_backwardlink_lf_grid" )

test_that("Test that plot and footnote are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_backwardlink_lf_grid.pdf" ) ) )
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_backwardlink_lf_grid.tex" ) ) )
})