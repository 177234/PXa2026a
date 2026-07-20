## =============================================================================
# PURPOSE:
#   Creates visualizations showing dynamic differences-in-differences estimates
#   for the relationship between HCI and industrial development outcomes, with
#   and without controlling for linkage effects, using exposure restrictions.
#
# INPUTS:
#   - did_io_limitexposure_all_results.csv
#
# OUTPUTS:
#   - gg_exposure_figure
# ==============================================================================

## ========================================================================== ##
# I. ARGUMENTS AND PLOT/TEXT SETTINGS -----------------------------------------
## ========================================================================== ##

## A. BASIC ARGUMENTS. ---------------------------------------------------------

font_size_argument <- 11

footnote_string <- "This figure shows dynamic differences-in-differences estimates 
for the relationship between HCI and responses to industrial development outcomes. 
It shows estimates with and without controlling for linkage effects. Panel A limits the
control group to industries with below median forward linkage exposure. Panel B 
limits the control group to industries below median exposure to total forward linkages."

footnote_string <- gsub( "\n" , " " , footnote_string )


## B. GGPLOT ARGUMENTS ---------------------------------------------------------

# Graphical arguments
error_width <- 0
error_alpha <- .5
dodge_width <- 1.1

# New minimal theme.
newminimaltheme <- theme( 
  text = element_text( size = font_size_argument + 1, 
                       color = annotation_color,
                       family = font_family_argument ) ,
  plot.title = element_text( size = rel(.9),  
                             hjust = 0.5 ) , 
  axis.text = element_text( size = rel(.7), margin = margin( b= 10) ),
  axis.title.x = element_blank(),
  strip.text = element_text(size = rel(.7), 
                            color = "grey40"),
  strip.background = element_blank(),
  legend.margin = margin( 10 , 0 , 0 , 10 ),
  legend.title = element_blank(),
  legend.position = "bottom" ,
  legend.spacing.y = unit(0.5, "cm"),  # Adjust vertical spacing between legend entries
  legend.key.height = unit(1, "cm"),    # Adjust height of each legend key
  legend.text = element_text(size = rel(.7) , color = "grey10"),
)


## ========================================================================== ##
# II. HELPING FUNCTIONS ------------------------------------------------------
## ========================================================================== ##

## ========================================================================== ##
## A. LOAD DATA FUNCTION -------------------------------------------------------

# Dataset loader for all functions
regsavedataloader <- function( dataset_name_arg ) {
  
  # Load the data.
  df <- file.path( intermediate_dir , dataset_name_arg ) %>%
        read.csv( . , header = TRUE , 
                  na.strings = c( "" , "." , "NA" ) ) %>%
        as.data.frame( . )
      
  # Test that prepared data.frame is not empty.
  test_that("Test that prepared data.frame is not empty", {
    expect_equal( plyr::empty( df ), FALSE ) })
  
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
                     color = variabletolayer , 
                     fill = variabletolayer ) , 
                size = 1.4, 
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
                            end_year+2 ) ) + 
    labs( x = "Year", y = "" )
  
  return(gsubgraph)
  
}


## ========================================================================== ##
# III.  LINKAGES - MAIN PLOT FUNCTIONS. ----------------------------------------
## ========================================================================== ##

rolling_plots_limitexposure  <- function( dataset_name , outcome_keyword ){

  
  ### 1) ======== PREPARE DATASET ======== ### 
  
  ## Load and clean data. Filter only essentials...
  table <- regsavedataloader( dataset_name ) %>%
    
        # Filter the outcome keyword and ONLY interaction terms...
        dplyr::filter( . , grepl( "^(1o*\\.hci\\#[0-9]{4}b*\\.year)$|^([0-9]{4}b*\\.year.*1o*\\.hci)$" , var ) ) %>%
        dplyr::filter( . , outcome == outcome_keyword )
  
  # Test the table is non-tempty....
  test_that( "Filtered table is not empty", {
    expect_equal( plyr::empty( table ), FALSE ) } )
  
  # Clean outcomes, since we have multiple outcomes on graph.
  table$outcome <- cleantablevariablelist_helper( table$outcome )
  
  # Generate YEAR variable from VAR variable string. 
  table$year <- stringr::str_match( table$var , "[0-9]{4}") %>%  as.numeric( . )

  # Clean and add line breaks to table$constraints 
  # Add line breaks to table$constraints after every three words
  table$constraints <- table$constraints %>%
    stringr::str_replace_all("(\\w+\\s+\\w+\\s+\\w+)\\s", "\\1\n") %>%
    stringr::str_trim()

  ### 2) ======== GENERATE FACETED PLOT ======== ###
  
  # Start with the prepared data frame....
  g <- ggplotter_smallbars( table , table$constraints )
  
  g <- g + facet_grid( datatype ~ . , scales = "free_y" )
  
  
  ### 3) ======== Adjust the aesthetics of GGPLOT object, g. ======== ###
  
  # Simplifying plot aesthetics. 
  g <- g + newminimaltheme
  
  # Tweak labels...
  g <- g + scale_color_manual( values = c(deep_red_argument, 
                                          annotation_color,
                                          med_grey_argument))
  
    # Test that the ggplot object 'g' has at least one layer
  testthat::test_that("Graph has layers", {
    expect_true(length(g$layers) > 0)
  })
  
  return( g )
  
}


## ========================================================================== ##
# IV. - MAKE AND ASSEMBLE SUTVA PLOTS. -----------------------------------------
## ========================================================================== ##


## ========================================================================== ##
## A. MAKE DIRECT LINK PLOTS ---------------------------------------------------

regdatasets <- "did_io_limitexposure_all_results.csv" 


### i. RUN PLOT FUNCTIONS - DIRECT LINKAGES ------------------------------------

# Generate the plots exposure. Shipments.
gg_exp_ship_sutva <- rolling_plots_limitexposure( regdatasets, "l_ship" )

gg_exp_ship_sutva <- gg_exp_ship_sutva + 
  labs( title = "Output (log)" ,
        text = element_text( size = font_size_argument + 1.5,
                             hjust = 0.5 ))


# Generate the plots exposure. Labor productivity.
gg_exp_prod_sutva <- rolling_plots_limitexposure( regdatasets, "l_y_n" )

gg_exp_prod_sutva <- gg_exp_prod_sutva + 
  labs( title = "Labor Productivity (log)" , 
        text = element_text( size = font_size_argument + 1.5,
                             hjust = 0.5 ))


### ii. COMBINE PLOTS -----------------------------------------------------------
gg_iodirect_exposure_figure <- ggpubr::ggarrange( gg_exp_ship_sutva,
                                            gg_exp_prod_sutva, 
                                            ncol = 2,
                                            nrow = 1, 
                                            common.legend = TRUE ,
                                            legend = "bottom" )


# Add title to combined plot.
gg_iodirect_exposure_figure <- gg_iodirect_exposure_figure + 
  labs(title = "Panel A) Below Median Control Group (Direct Forward Linkages)") +
  theme(plot.title = element_text(size = font_size_argument + 1.25,
                                  hjust = 0.5,
                                  family = font_family_argument,
                                  margin = margin(25,5,25,5)))



## ========================================================================== ##
## B. MAKE TOTAL LINK PLOTS ----------------------------------------------------

regdatasets <- "did_iolf_limitexposure_all_results.csv"

### i. RUN PLOT FUNCTIONS - TOTAL LINKAGES ------------------------------------


# Generate the plots exposure. Shipments.
gg_explf_ship_sutva <- rolling_plots_limitexposure( regdatasets, "l_ship" )

gg_explf_ship_sutva <- gg_exp_ship_sutva + 
  labs( title = "Output (log)" ,
        text = element_text( size = font_size_argument + 1.5,
                             hjust = 0.5))


# Generate the plots exposure. Labor productivity.
gg_explf_prod_sutva <- rolling_plots_limitexposure( regdatasets, "l_y_n" )

gg_explf_prod_sutva <- gg_exp_prod_sutva + 
  labs( title = "Labor Productivity (log)" , 
        text = element_text( size = font_size_argument + 1.5,
                             hjust = 0.5 ))


### ii. COMBINE PLOTS -----------------------------------------------------------

# COMBINE THESE
gg_iolf_exposure_figure <- ggpubr::ggarrange( gg_explf_ship_sutva,
                                              gg_explf_prod_sutva, 
                                            ncol = 2,
                                            nrow = 1, 
                                            common.legend = TRUE ,
                                            legend = "bottom" )


# Add title to combined plot.
gg_iolf_exposure_figure <- gg_iolf_exposure_figure + 
  labs(title = "Panel B) Below Median Control Group (Total Forward Linkages)") +
  theme(plot.title = element_text(size = font_size_argument + 1.25,
                                  hjust = 0.5,
                                  family = font_family_argument,
                                  margin = margin(25,5,25,5)))


## ========================================================================== ##
# V. MAKE COMBINED FINAL GRID FIGURE -------------------------------------------
## ========================================================================== ##


## Render the single and leontief together.
gg_io_exposure_figure <- ggpubr::ggarrange( gg_iodirect_exposure_figure,
                                            gg_iolf_exposure_figure,
                                           ncol = 1,
                                           nrow = 2,
                                           common.legend = FALSE )

## ========================================================================== ##
# SAVE PLOT AND FOOTNOTE ---------------------------------------------------
## ========================================================================== ##

# Save plot.
save_plot( plot_object = gg_io_exposure_figure ,
           filename = "gg_io_exposure_figure" ,
           width = 10 ,
           height = 10 ,
           output_dir = figures_appendix_dir )

save_figure_footnote( footnote_string ,
                      output_dir = figures_appendix_dir ,
                      label = "gg_io_exposure_figure" )


test_that("Test that plot and footnote are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_io_exposure_figure.pdf" ) ) )
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_io_exposure_figure.tex" ) ) )
})
