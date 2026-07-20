## =============================================================================
# PURPOSE:
#   Creates visualizations showing dynamic differences-in-differences estimates
#   for the relationship between HCI and industrial development outcomes, with
#   and without controlling for downstream links and both direct and Leontief
#   linkage effects in non-treated sectors.
#
# INPUTS:
#   - did_io_downonly_sutva_all_results.csv
#   - did_iolf_downonly_sutva_all_results.csv
#   - did_io_sutva_all_results.csv
#   - did_iolf_sutva_all_results.csv
#
# OUTPUTS:
#   - gg_control_io_figure
# ==============================================================================

## ========================================================================== ##
# I. ARGUMENTS AND PLOT/TEXT SETTINGS -----------------------------------------
## ========================================================================== ##

## A. BASIC ARGUMENTS. ---------------------------------------------------------
font_size_argument <- 11

footnote_string <- "responses to industrial development outcomes. Estimates with
and without controls for linkage effects in non-treated sectors (linkage effects
only for non-treated industry). Panels A compares baseline estimates from equation (1)
to estimates that control for forward linkage exposure.Panel B compares baseline estimates 
from equation (1) to estimates controlling for both measures of linkage exposure."

footnote_string <- gsub( "\n" , " " , footnote_string )

## B. GGPLOT ARGUMENTS ---------------------------------------------------------

# Graphical arguments
error_width <- 0
error_alpha <- .6
dodge_width <- 1

# New minimal theme.
newminimaltheme <- theme( 
   text = element_text( size = font_size_argument + 1, 
                        color = annotation_color,
                        family = font_family_argument ) ,
   plot.title = element_text( size = rel(1),  
                              hjust = 0.5 ) , 
   axis.text = element_text( size = rel(.85)),
   axis.title.x = element_blank(),
   strip.text = element_text(size = rel(.7), 
                             color = "grey40"),
   strip.background = element_blank(),
   legend.margin = margin( 10 , 0 , 0 , 10 ),
   legend.title = element_blank(),
   legend.position = "bottom" ,
   legend.spacing.y = unit(0.5, "cm"),  # Adjust vertical spacing between legend entries
   legend.key.height = unit(1, "cm"),    # Adjust height of each legend key
   legend.text = element_text(lineheight = 1.1,
                              size = rel(.85))
)


## ========================================================================== ##
# II. - HELPING FUNCTIONS ------------------------------------------------------
## ========================================================================== ##


## A. LOAD DATA FUNCTION -------------------------------------------------------

# Dataset loader for all functions
regsavedataloader <- function( dataset_name_arg ) {
  
  # Load the data.
  df <- file.path( intermediate_dir , paste0( dataset_name_arg ) ) %>%
          read.csv( . , header = TRUE , 
                    na.strings = c( "" , "." , "NA" ) ) %>%
          as.data.frame( . )
        
  # Test that prepared data.frame is not empty.
  test_that("Test that prepared data.frame is not empty", {
    expect_equal( plyr::empty( df ), FALSE ) })
  
  return( df )
  
}

## B. VARIABLE CLEANING FUNCTION -----------------------------------------------

cleantablevariablelist_helper <- function(dataset_argument) {
  
  cleaned_dataset <- dataset_argument %>%
    str_replace_all(
      c(
        "(^h_|^l_)" = "",
        "gross[0-9]+|grossoutput" = "gross out.",
        "ship_sh" = "output share",
        "ppi" = "prices",
        "ship$" = "val. ship",
        "lab_sh" = "labor share",
        "avg_" = "avg. ",
        "y_n" = "labor prod.",
        "valueadded" = "value add.",
        "_" = " ",
        "^ | $" = ""
      )
    ) %>%
    str_to_title()
  
  return(cleaned_dataset)
  
}


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
                size = 1.55, 
                alpha = .9, 
                position = position_dodge(width = dodge_width) ) +
    scale_x_continuous( breaks = c( start_year ,
                                    1972 ,
                                    1979 ,
                                    end_year ),
                        labels = c( paste0( start_year+1 ),
                                    "1972" ,
                                    "1979",
                                    paste0( end_year-1 ) ) ,
                        limits = c( start_year ,
                                    end_year ) ) +
    labs( x = "Year", y = "" )
    
  # Test that the ggplot object 'g' has at least one layer
  testthat::test_that("Graph has layers", {
    expect_true(length(gsubgraph$layers) > 0)
  })
  
  return(gsubgraph)
  
}


# II.  LINKAGES - MAIN PLOT FUNCTIONS. -----------------------------------------


## This is the main function for the rolling GGPLOT graphic. 
rolling_plots_iosutva  <- function( dataset_name , 
                                    outcome_keyword ){
  
  ### 1) ======== LOAD THE DATASET. ======== ### 
  
  ## Load and clean data. Filter only essentials...
  table <- regsavedataloader( dataset_name ) %>%
              dplyr::filter( . , grepl( "^(1o*\\.hci\\#[0-9]{4}b*\\.year)$|^([0-9]{4}b*\\.year.*1o*\\.hci)$" , var ) ) %>%
              dplyr::filter( . , outcome == outcome_keyword ) %>%
              dplyr::mutate(. , controltype = ifelse( is.na( controltype ) | grepl( "[Nn]one" , controltype ) , "Main Effect" , controltype ) )
            
  # Test the table is non-empty....
  test_that( "Filtered table is not empty", {
    expect_equal( plyr::empty( table ), FALSE ) } )
  
  # Clean outcomes, since we have multiple outcomes on graph.
  table$outcome <- cleantablevariablelist_helper( table$outcome )
  
  # Generate YEAR variable from VAR variable string. 
  table$year <- stringr::str_match( table$var , "[0-9]{4}") %>% as.numeric( . )

    # Clean and add line breaks to table$controltype 
  # Add line breaks to table$controltype after every three words
  table$controltype <- table$controltype %>%
    stringr::str_replace_all("(\\w+\\s+\\w+\\s+\\w+)\\s", "\\1\n") %>%
    stringr::str_trim()

  ### 2) ======== GENERATE FACETED PLOT ======== ###
  
  g <- ggplotter_smallbars( table , table$controltype )
  
  g <- g + facet_grid( datatype ~ . ,  scales = "free_y" )
  
  ### 3) ======== Adjust the aesthetics of GGPLOT object, g. ======== ###
  
  # Simplifying plot aesthetics. 
  g <- g + newminimaltheme

  # Tweak labels colors.
  g <- g + scale_color_manual( values = c(deep_red_argument, annotation_color ))

  # Test that the ggplot object 'g' has at least one layer
  testthat::test_that("Graph has layers", {
    expect_true(length(g$layers) > 0)
  })
  
  return( g )
  
}

## ========================================================================== ##
# III. NOW MAKE THE PLOTS ------------------------------------------------------
## ========================================================================== ##


## ========================================================================== ##
## A. Make downstream only plots. ----------------------------------------------


# Generate the plots for downstream IO controls
gg_io_downonly_sutva <- rolling_plots_iosutva( "did_io_downonly_sutva_all_results.csv", 
                                               "l_ship" )

gg_io_downonly_sutva <- gg_io_downonly_sutva + 
  labs( title = "Direct Forward Links" ) +
  theme( plot.title = element_text( size = font_size_argument + 1.1))

# Generate the plots for downstream IO Leontief controls
gg_iolf_downonly_sutva <- rolling_plots_iosutva( "did_iolf_downonly_sutva_all_results.csv", 
                                                 "l_ship" )

gg_iolf_downonly_sutva <- gg_iolf_downonly_sutva + 
  labs( title = "Total Forward Links") + 
  theme( plot.title = element_text( size = font_size_argument + 1.1))

# Combine the two plots.
gg_io_downonly_combined <- ggpubr::ggarrange( gg_io_downonly_sutva,
                                              gg_iolf_downonly_sutva,
                                              ncol = 2,
                                              nrow = 1, 
                                              common.legend = TRUE ,
                                              legend = "bottom"  )

# Add title to combined plot.
gg_io_downonly_combined <- gg_io_downonly_combined + 
  labs(title = "Panel A) Controlling for Forward Linkages") +
  theme(plot.title = element_text(size = font_size_argument + 1.5,
                                  hjust = 0.5,
                                  margin = margin(25,5,25,5)))


## ========================================================================== ##
## B. Make plots with both links. ----------------------------------------------


# Generate the plots for both IO controls
gg_io_both_sutva <- rolling_plots_iosutva( "did_io_sutva_all_results.csv", 
                                           "l_ship" )

gg_io_both_sutva <- gg_io_both_sutva + 
  labs( title = "Both Direct Links") +
  theme( plot.title = element_text( size = font_size_argument + 1.1))

# Generate the plots for both IO Leontief controls
gg_iolf_both_sutva <- rolling_plots_iosutva( "did_iolf_sutva_all_results.csv",
                                             "l_ship" )

gg_iolf_both_sutva <- gg_iolf_both_sutva + 
  labs( title = "Both Total Links" ) +
  theme( plot.title = element_text( size = font_size_argument + 1.1))

# Combine the two plots.
gg_io_both_combined <- ggpubr::ggarrange( gg_io_both_sutva,
                                          gg_iolf_both_sutva,
                                          ncol = 2,
                                          nrow = 1, 
                                          common.legend = TRUE ,
                                          legend = "bottom"  )


# Add title to combined plot.
gg_io_both_combined <- gg_io_both_combined + 
  labs(title = "Panel B) Controlling for Both Linkages") +
  theme(plot.title = element_text(size = font_size_argument + 1.5,
                                  hjust = 0.5,
                                  margin = margin(25,5,25,5)))


## ========================================================================== ##
## C. Make combined plot for A and B -------------------------------------------
## ========================================================================== ##

## Render the single and leontief together.
gg_control_io_figure <- ggpubr::ggarrange( gg_io_downonly_combined,
                                           gg_io_both_combined,
                                           ncol = 1,
                                           nrow = 2 )

## ========================================================================== ##
# SAVE PLOT AND FOOTNOTE ---------------------------------------------------
## ========================================================================== ##

# Save plot.
save_plot( plot_object = gg_control_io_figure ,
           filename = "gg_control_io_figure" ,
           width = 9 ,
           height = 9 ,
           output_dir = figures_appendix_dir )

save_figure_footnote( footnote_string ,
                      output_dir = figures_appendix_dir ,
                      label = "gg_control_io_figure" )


test_that("Test that plot and footnote are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_control_io_figure.pdf" ) ) )
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_control_io_figure.tex" ) ) )
})
