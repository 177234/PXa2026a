## =============================================================================
# PURPOSE:
#   Creates visualizations showing dynamic differences-in-differences estimates
#   for the relationship between HCI and investment responses, including potential
#   crowding out effects.
#
# INPUTS:
#   - did_largerolling_crowding_basic_all_results.csv
#   - did_largerolling_crowding_intensity_all_results.csv
#
# OUTPUTS:
#   - combined_crowdout_plot
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS.--------------------------------------------------
## ========================================================================== ##



## A. BASIC ARGUMENTS. ---------------------------------------------------------
font_size_argument <- 11

footnote_string <- "This figure shows dynamic differences-in-differences estimates for the relationship between HCI and responses to investment incentives.
Panel A shows the changes in (log, real) investment for targeted and non-targeted industries, relative to 1972.
Panel A plots the coefficients from equation (10), estimated separately by treatment status. Panel B assesses 
the degree to which non-treated, capital-intensive industries may have been squeezed by HCI drive credit policy. 
Panel (B) shows the evolution of investment in high versus low capital-intensive 
industries, estimated separately by treatment status. Coefficients are from the 
interaction Year \\(\\times\\) log Capital Intensity, with 1972 as the omitted 
category. Pre-treatment capital intensity is the pre-1973 real capital stock per worker."

footnote_string <- gsub( "\n" , " " , footnote_string )


## B. New minimal theme. -------------------------------------------------------

alpha_argument <- 0.6
dodge_width <- .75
error_width <- 0

# For the main plot.
newminimaltheme <- theme( 
  plot.title = element_text( size = rel(1.1),  
                              hjust = 0.5 ,
                              margin = margin(t = 7.5, r = 0, b = 7.5, l = 0)), 
  axis.text.x = element_text( size = rel(.9) , 
                              color = annotation_color ) ,
  axis.text.y = element_text( size = rel(.9) , 
                              color = annotation_color ) ,
  axis.title.x = element_text( size = rel(1) , 
                               color = annotation_color,
                               margin = margin(10)) ,
  axis.title.y = element_text( size = rel(1) ), 
  axis.ticks.x = element_line( linewidth = .30, 
                             colour = med_grey_argument ), 
  axis.ticks.y = element_line( linewidth = .30, 
                               colour = med_grey_argument ), 
  panel.grid = element_blank() ,
  plot.margin = margin( 0.5 , 0.5 , 0.5 , 0.5 , "cm" ) ,
  legend.position = "bottom" ,
  legend.direction = "horizontal" , 
  legend.title = element_blank() ,
  legend.text = element_text( size = font_size_argument , 
                              color = annotation_color ) ,
  legend.background = element_blank() ,
  legend.key = element_blank() 
)

## ========================================================================== ##
# II SUB-FUNCTIONS: HELPER AND SUB-HELPER FUNCTIONS. ---------------------------
## ========================================================================== ##

## ========================================================================== ##
##  1. SUB-FUNCTIONS. ----------------------------------------------------------
testnonemptydata <- function( dataargument ){
  # TEST: Confirm output not empty.
  if (dim(dataargument)[1] == 0) {stop("Table contains no observations.")}
}

# Data set loader for all functions
regsavedataloader <- function( dataset_name_arg ) {
  
    df <- file.path( intermediate_dir , paste0( dataset_name_arg ) ) %>%
          read.csv( . , header = TRUE , na.strings = c( "" , "." , "NA" ) )

  # TEST: Prepared data.frame is empty.
  test_that("Prepared data.frame is empty.", {
    expect_equal( plyr::empty( df ), FALSE ) })
  
  return( df )
}


## ========================================================================== ##
## 2. GGPLOT THEME -----------------------------------------------------------

ggplotter_smallbarstheme_dodge <- function( df , 
                                            variabletolayer,
                                            start_year_arg = NULL,
                                            end_year_arg = NULL ){
  # If no start year, were equal.
  ifelse( !is.null( start_year_arg ),
          start_year <- start_year_arg ,
          start_year <- 1970 )
  
  # If no start year, were equal.
  ifelse( !is.null( end_year_arg ),
          end_year <- end_year_arg ,
          end_year <- 1986 )
  
  # Make the graph.
  gsubgraph <- ggplot( data = df ,
                       aes( x = year ,
                            group = variabletolayer, 
                            color = variabletolayer ) ) +
    geom_errorbar( aes( min = ci_lower ,
                        max = ci_upper),
                   alpha = alpha_argument, 
                   width = error_width, 
                   position = position_dodge(width = dodge_width) ) +
    geom_hline( yintercept = 0 , 
                color = light_grey_argument, 
                size = .2 ) +
    geom_vline( xintercept = 1972 , 
                color = med_grey_argument , 
                lty = "dashed" , 
                size = .3) +
    geom_vline( xintercept = 1979 , 
                color = med_grey_argument , 
                lty = "dashed" , 
                size = .3 ) +
    geom_point( aes( x = year , 
                     y = coef ,
                     shape = variabletolayer , 
                     color = variabletolayer , 
                     fill = variabletolayer ) , 
                size = 2, 
                alpha = .9, 
                position = position_dodge(width = dodge_width) ) +
    scale_x_continuous( breaks = c( start_year ,
                                    1972 ,
                                    1979 ,
                                    end_year ),
                        labels = c( paste0( start_year ),
                                    "1972" ,
                                    "1979",
                                    paste0( end_year ) ) ,
                        limits = c( start_year-1 ,
                                    end_year+1 ) ) 

  # Add labels.
  gsubgraph <- gsubgraph + labs( x = "Year", y = "" )
  
  return(gsubgraph)
  
}



## ========================================================================== ##
## 3. GGPLOT FUNCTIONS FOR BASIC REGRESSIONS ----------------------------------



## This is the main function for the rolling GGPLOT graphic. 
rolling_plots_crowdingout_basic  <- function( dataset_name ,
                                             outcome_keyword ){

  ### 1) ======== LOAD THE DATASET. ======== ### 
  
  ## Load and clean data. Filter only essentials...
  table <- regsavedataloader( dataset_name ) %>%
    
          # Filter the outcome keyword and ONLY interaction terms...
          dplyr::filter( . , outcome == outcome_keyword ) %>%
          dplyr::filter( . , grepl( "(^[0-9]{4}b*\\.year$)|(^[0-9]{4}b*\\.year.*intensity)" , var ) ) %>%
          
          # Mutate variables a bit. Make into dummies
          dplyr::mutate(. , constrainttype = ifelse( grepl( "1", constrainttype), 
                                              "Targeted industry sample" , 
                                              "Non-targeted industry sample" ) ) 
        
          
          # Generate YEAR variable from VAR variable string. 
          table$year <- table$var %>% 
                            str_match( . , "[0-9]{4}") %>% 
                            as.numeric( . )
          
 # Test if data is empty.
  test_that("Prepared data.frame is empty.", {
    expect_equal( plyr::empty( table ), FALSE ) })
  
  ### 2) ======== Generate MAIN baseline GGPLOT object. ======== ###
  
  # NOTE: Inserts the minimum year below:
  g <- ggplotter_smallbarstheme_dodge( table , 
                                       table$constrainttype )
  
  ### 3) ======== Adjust the aesthetics of GGPLOT object, g. ======== ###
  
  # Simplifying plot aesthetics. 
  g <- g + newminimaltheme

  # Color scales 
  g <- g + scale_color_manual( values = c(control_grey_argument, 
                                          deep_red_argument))
  
  ### 5) ======== Return GGPLOT g object..  ======== ###
  return( g )
  
}


## ========================================================================== ##
# III. MAKE CROWDING OUT PLOTS.-------------------------------------------------
## ========================================================================== ##


## 1. FIRST CROWDING OUT PLOT. -------------------------------------------------


# NOTE: Main crowding out plot, by industry.

## Main arguments for the functions below.
dataset <- "did_largerolling_crowding_basic_all_results.csv"
mainoutcome <- "l_inv_tot"

## Make plots.
gg_crowdingout_basic <- rolling_plots_crowdingout_basic( dataset,
                                                          mainoutcome ) 
## Add title.
gg_crowdingout_basic <- gg_crowdingout_basic + 
  labs(title = "Panel A) Changes in Investment (log) Through Time", 
       y = "Coefficient (Year)")


## 2. SECOND CROWDING OUT PLOT. ------------------------------------------------


# NOTE: Main crowding out plot, by intensity.


## Defining arguments for data frames in the plots.
dataset <- "did_largerolling_crowding_intensity_all_results.csv"
mainoutcome <- "l_inv_tot"

## Make plots.
gg_crowdingout_intensity <- rolling_plots_crowdingout_basic( dataset,
                                                                mainoutcome ) 
## Add title.
gg_crowdingout_intensity <- gg_crowdingout_intensity + 
  labs(title = "Panel B) Evolution of Investment (log) in Capital Intensive Industries", 
       y = "Coefficient (Year x Cap.Int.)")



## 3. MAKE COMBINED PLOT FOR RENDERING -----------------------------------------

combined_crowdout_plot <- ggpubr::ggarrange( 
                            plotlist = list(gg_crowdingout_basic, 
                                            gg_crowdingout_intensity) , 
                               nrow = 2 , 
                               ncol = 1 , 
                               common.legend = TRUE, 
                               legend	= "bottom" )

## ========================================================================== ##
# SAVE PLOT AND FOOTNOTE ---------------------------------------------------
## ========================================================================== ##
save_plot( plot_object = combined_crowdout_plot ,
           filename = "combined_crowdout_plot" ,
           width = 9 ,
           height = 7 ,
           output_dir = figures_appendix_dir )

save_figure_footnote( footnote_string ,
                      output_dir = figures_appendix_dir ,
                      label = "combined_crowdout_plot" )

test_that("Test that plot and footnote are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "combined_crowdout_plot.pdf" ) ) )
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "combined_crowdout_plot.tex" ) ) )
})
