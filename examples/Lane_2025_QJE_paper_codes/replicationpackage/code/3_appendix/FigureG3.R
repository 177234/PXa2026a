## =============================================================================
# PURPOSE:
#   Creates visualizations showing dynamic differences-in-differences estimates
#   for the relationship between HCI and investment responses, controlling for
#   forward and backward linkages in targeted and non-targeted sectors.
#
# INPUTS:
#   - did_io_crowdingout_all_results.csv
#
# OUTPUTS:
#   - gg_crowdingout_io_figure
# ==============================================================================

## ========================================================================== ##
# I. ARGUMENTS AND PLOT/TEXT SETTINGS -----------------------------------------
## ========================================================================== ##

## A. BASIC ARGUMENTS. ---------------------------------------------------------
font_size_argument <- 11

footnote_string <- "responses to investment incentives. Panels show the changes
in investment for targeted and non-targeted, relative to 1972, controlling for 
IO linkages. Regressions are performed on either the targeted-only or non-targeted 
samples. Coefficients are from the interaction Year $\\times$ Log Capital Intensity,
with 1972 as the omitted category. Pre-treatment capital intensity is measured as 
the pre-1973 levels of capital stock per worker. Left panel plots the Year $\\times$
Capital Intensity (main effects), controlling for forward and backard linkages
(interacted with Post). Right panel plots the Year $\\times$ Capital Intensity
(main effects), controlling for forward and backard linkages (interacted with Year)."

footnote_string <- gsub( "\n" , " " , footnote_string )

## B. GGPLOT ARGUMENTS ---------------------------------------------------------

# Graphical arguments
error_width <- 0
error_alpha <- .6

# Dodge width.
dodge_width <- .9

# New minimal theme.
newminimaltheme <- theme( 
  text = element_text( size = font_size_argument + 1, 
                       color = annotation_color,
                       family = font_family_argument ) ,
  plot.title = element_text( size = rel(1),  
                             hjust = 0.5 ) , 
  axis.text = element_text( size = rel(.8)),
  axis.title.x = element_blank(),
  strip.text = element_text(size = rel(.9), 
                            color = annotation_color),
  strip.background = element_blank(),
  legend.margin = margin( 10 , 0 , 0 , 10 ),
  legend.position = "bottom" ,
  legend.direction = "horizontal" ,
  legend.spacing.y = unit(0.5, "cm"),  # Adjust vertical spacing between legend entries
  legend.key.height = unit(1, "cm"),    # Adjust height of each legend key
  legend.text = element_text(size = rel(.8) )
)



## ========================================================================== ##
## A. LOAD DATA FUNCTION -------------------------------------------------------

# Dataset loader for all functions
regsavedataloader <- function( dataset_name_arg ) {
  
  # Load the data.
  df <- file.path( intermediate_dir , paste0( dataset_name_arg ) ) %>%
        read.csv( . , header = TRUE , 
                  na.strings = c( "" , "." , "NA" ) ) %>%
        as.data.frame( . )
      
  # Test the table is non-empty....
  test_that( "Filtered table is not empty", {
    expect_equal( plyr::empty( df ), FALSE ) } )
  
  return( df )
  
}


## ========================================================================== ##  
## B. VARIABLE CLEANING FUNCTION -----------------------------------------------

cleantablevariablelist_helper <- function(dataset_argument) {
  
  cleaned_dataset <- dataset_argument %>%
    str_replace_all(
      c(
        "gross[0-9]+|grossoutput" = "gross out.",
        "lab_sh" = "labor share",
        "avg_" = "avg. ",
        "y_n" = "labor prod.",
        "est|_est" = "num. plants",
        "valueadded" = "value add.",
        "_" = " ",
        "^ | $" = ""
      )
    ) %>%
    str_to_title()
  
  return(cleaned_dataset)
}


## ========================================================================== ##
## C. GG THEME SUB-FUNCTION ----------------------------------------------------

# Theme function for multiple regressions on the same plot.
ggplotter_smallbars <- function( df , variabletolayer ){
  
  # Set start and end year.
  start_year_arg <- min(as.numeric(df$year))
  ifelse( !is.null( start_year_arg ),
          start_year <- start_year_arg , 
          start_year <- 1968 )

  end_year_arg <- max(as.numeric(df$year))
  ifelse( !is.null( end_year_arg ),
          end_year <- end_year_arg , 
          end_year <- 1986 )  
  
  # Make subplot.
  gsubgraph <- ggplot( data = df ,
                       aes( x = year ,
                            group = variabletolayer, 
                            color = variabletolayer ) ) +
    geom_errorbar( aes( min = ci_lower ,
                        max = ci_upper),
                   alpha = error_alpha, 
                   width = error_width, 
                   size = .5,
                   position = position_dodge(width = dodge_width) ) +
    geom_hline( yintercept = 0 , 
                color = med_grey_argument, 
                size = .3 ) +
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
                     color = variabletolayer ) , 
                size = 1.5, 
                alpha = 1, 
                position = position_dodge(width = dodge_width) ) +
    scale_x_continuous( breaks = c( start_year,
                            1972 ,
                            1979 ,
                            end_year),
                labels = c( paste0( start_year ),
                            "1972" ,
                            "1979",
                            paste0( end_year) ) ,
                # Expand for dodge width.
                limits = c( start_year-2 ,
                            end_year+2 ) )

  # Tweak labels...
  gsubgraph <- gsubgraph + labs( x = "Year", y = "Coefficient" )
    
  # Test that graph is not empty.
  # Test that the ggplot object 'g' has at least one layer
  testthat::test_that("Graph has layers", {
    expect_true(length(gsubgraph$layers) > 0)
  })
  
  return(gsubgraph)
  
}

## ========================================================================== ##
# II.  LINKAGES - MAIN PLOT FUNCTIONS. -----------------------------------------
## ========================================================================== ##


## This is the main function for the rolling GGPLOT graphic. 
rolling_plots_kcrowdingout_io  <- function( dataset_name , outcome_keyword ){

  ### 1) ======== LOAD THE DATASET. ======== ### 
  
  ## Load and clean data. Filter only essentials...
  table <- regsavedataloader( dataset_name ) %>%
              dplyr::filter( . , outcome == outcome_keyword ) %>%
              dplyr::filter( . , grepl( "^([0-9]{4}b*\\.year)$|^([0-9]{4}b*\\.year.*c*intensity)$" , var ) ) %>%
              dplyr::mutate( . , constrainttype = ifelse( grepl( "1", constrainttype), 
                                                  "Targeted" , 
                                                  "Non-Targeted" ) ) 
            
  # Test the table is non-empty....
  test_that( "Filtered table is not empty", {
    expect_equal( plyr::empty( table ), FALSE ) } )
  
  # Clean outcomes, since we have multiple outcomes on graph.
  table$outcome <- cleantablevariablelist_helper( table$outcome )
  
  # Generate YEAR variable from VAR variable string. 
  table$year <- stringr::str_match( table$var , "[0-9]{4}") %>% 
                as.numeric( . )

  
  ### 2) ======== GENERATE FACETED PLOT ======== ###
  g <- ggplotter_smallbars( table , table$constrainttype )
  

  ### 3) ======== Adjust the aesthetics of GGPLOT object, g. ======== ###
  
  # Simplifying plot aesthetics. 
  g <- g + newminimaltheme
  
  # Color scales for the plot.
  g <- g + scale_color_manual( values = c(deep_red_argument, 
                                          control_grey_argument ), 
                               name = "Industry Sample" ) +
    scale_shape_manual( values = c( 16 , 17 ) , 
                        name = "Industry Sample" )
  
  # Test that the ggplot object 'g' has at least one layer
  testthat::test_that("Graph has layers", {
    expect_true(length(g$layers) > 0)
  })
  
  return( g )
  
}


## ========================================================================== ##
# III. NOW MAKE THE PLOTS, RUNNING THE GGPLOT FUNCTIONS. -----------------------
## ========================================================================== ##


### i) CROWDING OUT - Only YEARS.

## Defining arguments for data frames in the plots.
dataset_5d <- "did_io_crowdingout_all_results.csv"
mainoutcome <- "l_inv_tot"

# Run the function.
gg_crowdingout_io <- rolling_plots_kcrowdingout_io( dataset_5d,
                                                    mainoutcome ) 

# remove all borders from ggplots 
gg_crowdingout_io <- gg_crowdingout_io + 
  theme( panel.border = element_blank(),
         text = element_text(size = font_size_argument + 2, 
                             hjust = 0.5,
                             color = annotation_color))

# make facet wrap stack row-wise
gg_crowdingout_io <- gg_crowdingout_io + 
facet_wrap( . ~ fixedeffects, nrow = 2 )


# Render crowding out investment/io plots together:
gg_crowdingout_io_figure <- ggpubr::ggarrange( gg_crowdingout_io , 
                                               common.legend = TRUE, 
                                               legend	= "bottom" )

## ========================================================================== ##
# SAVE PLOT AND FOOTNOTE ---------------------------------------------------
## ========================================================================== ##

# Save plot.
save_plot( plot_object = gg_crowdingout_io_figure ,
           filename = "gg_crowdingout_io_figure" ,
           width = 8.75 ,
           height = 6.75 ,
           output_dir = figures_appendix_dir )

save_figure_footnote( footnote_string ,
                      output_dir = figures_appendix_dir ,
                      label = "gg_crowdingout_io_figure" )


test_that("Test that plot and footnote are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_crowdingout_io_figure.pdf" ) ) )
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_crowdingout_io_figure.tex" ) ) )
})
