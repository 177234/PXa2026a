# Annotated copy for replication audit.
# Original script: Lane2025QJE/replicationpackage/code/1_figures/Figure4.R
# Purpose: Generates Figure 4.
#
# This file intentionally keeps the original .R extension.
# The original code is copied below. Comments in this header identify the
# script role, inputs, outputs, and audit linkage. The earlier prose note is
# archived at: markdown_notes_archive/Figure4_R.md
#
# Audit linkage:
# - Methods report: explains the estimating or output logic.
# - Derivation report: maps equations/design objects to code.
# - Replication report: documents inputs, outputs, and reproducibility limits.
#
# Original code begins after this header.

## =============================================================================
# PURPOSE:
#   Graphs rolling regressions and coefficients for triple-difference trade analysis.
#
# INPUTS:
#   - "did_largerolling_worldtrade_ppml_rca_all_results.csv" (World trade regression results)
#
# OUTPUTS:
#   - combine_ddd_trade_plots (ggplot object for rendering)
# ==============================================================================

## ========================================================================== ##
#
#   PURPOSE: 
#       - File for graphing rolling regressions and coefficients. 
#       - Takes the rolling dataset and graphs it. 
#
#   INPUTS:
#       - Uses output regressions:
#       "did_largerolling_worldtrade_ppml_rca_all_results.csv"
#
#   OUTPUTS:
#       - ggplot object to render. 
#       combine_ddd_trade_plots
# 
## ==============================  TOP MATTER =============================== ##

## ========================================================================== ##
# X. TEXT FOR THE FOOTNOTE. ----------------------------------------------------
## ========================================================================== ##

footnote_string <- "\\indent This figure plots triple difference estimates for 
the impact of the Korean HCI drive using SITC-level trade data. Specifically, 
plots show the interaction, Korea \\(\\times\\) Targeted \\(\\times\\) Year, estimated 
from equations \\eqref{eq:ddd}-\\eqref{eq:ddd2}. Fixed effects are shown in the legend. 
RCA (Balassa) specifications are estimated using PPML. Alternatively, RCA is transformed 
using inverse hyperbolic sine to accommodate zeros and estimated using OLS. Relative export 
productivity (CDK) specifications are estimated using OLS. Estimates are relative to 1972, 
the year before the HCI policy intervention. The line at 1979 demarcates the end of the 
Park regime. All specifications use two-way clustering at the country and industry level. 
95 percent confidence intervals are shown."

footnote_string <- gsub( "\n", " ", footnote_string )

## ========================================================================== ##
# I. ARGUMENTS AND PLOT/TEXT SETTINGS -----------------------------------------
## ========================================================================== ##

# How extreme dodging will be
dodge_width <- 1
error_alpha <- 0.5
error_width <- 0

# Minimal theme for the final plot.
newminimaltheme <- theme( 
    text = element_text( size = font_size_argument, 
                              color = annotation_color ) ,
    plot.title = element_text( size = rel(1.1),  
                                color = annotation_color,
                                hjust = 0.5 ) , 
    axis.text.y = element_text( size =  rel(.9) ) ,
    axis.text.x = element_text( vjust = .5 ,
                                hjust = 0.5, 
                                size = rel(.95)),
    axis.title.x = element_blank(),
    axis.ticks = element_line(color = med_grey_argument ,
                              size = .33), 
    legend.position = "bottom" ,
    legend.background = element_blank() ,
    legend.key = element_blank(), 
    legend.title = element_text( size = rel(1), 
                                 color = annotation_color ),
    legend.text = element_text( size = rel(.9)),
    legend.title.position = "top",
    legend.direction = "horizontal"
)

## ========================================================================== ##
# II. FUNCTIONS. ---------------------------------------------------------------
## ========================================================================== ##

## A. DATA LOADER --------------------------------------------------------------

# Dataset loader for all functions
regsavedataloader <- function( dataset_name_arg ) {
  
  df <- file.path( intermediate_dir , paste0( dataset_name_arg ) ) %>%
        read.csv( . , header = TRUE ,
                  na.strings = c( "" , "." , "NA" ) )
      
  # Test that data is not empty.
  test_that( "Data is not empty" , {
    expect_true( nrow( df ) > 0 )
  })
  return( df )
}

## B. REMOVE X-AXIS TICKS AND LABELS -------------------------------------------

# Remove x-axis ticks and labels from ggplot
removexticks <- function( ggplot_object ){
  return(ggplot_object + rremove("x.text") + rremove("x.ticks"))
}

## C. GGPLOT THEME FUNCTION ----------------------------------------------------
gg_smallbarstheme <- function( df, facetfactor ){
    
    # Grab year arguments for GGPLOT scope.
    start_year <- min( as.numeric( df$year ) , 
                       na.rm = TRUE)
    end_year <- max( as.numeric( df$year ) , 
                     na.rm = TRUE)
    
    # ggplot sub plot.
    gsub <- ggplot( data = df , 
                    aes( x = year, 
                         group = facetfactor,
                         color = facetfactor) ) +
      geom_hline( yintercept = 0 , 
                  color = light_grey_argument, 
                  linewidth = .2 ) +
      geom_vline( xintercept = 1972 , 
                  color = med_grey_argument , 
                  lty = "dotted" , 
                  linewidth = .5) +
      geom_vline( xintercept = 1979 , 
                  color = med_grey_argument , 
                  lty = "dotted" , 
                  linewidth = .5) +
      geom_point( aes( x = year , 
                       y = coef , 
                       shape = facetfactor, 
                       color = facetfactor) , 
                  size = 1.5, 
                  alpha = 0.95, 
                  position = position_dodge(width=dodge_width) ) +
      geom_errorbar( aes( min = ci_lower , 
                          max = ci_upper),
                     alpha = error_alpha, 
                     width = error_width, 
                     position = position_dodge(width=dodge_width) )
      scale_x_continuous( breaks = c( start_year , 
                                      1972 , 
                                      1979 , 
                                      end_year ), 
                          labels = c( paste0( start_year ), 
                                      "1972" , 
                                      "1979", 
                                      paste0( end_year ) ) ,
                          limits = c( start_year-1, 
                                      end_year+1) )
    # Simplifying plot aesthetics. 
    gsub <- gsub + newminimaltheme
    gsub <- gsub + labs( x = "", y = "" )

  return( gsub )
}

## ========================================================================== ##
# III. MAIN FUNCTION. ----------------------------------------------------------
## ========================================================================== ##
make_worldtrade_plots <- function( dataset_name , 
                                    outcome_keyword ){
  
  ### 1) ======== LOAD THE DATASET. ======== ### 

  ## Load and clean data. Filter only essentials...
  table <- regsavedataloader( dataset_name ) %>%
                dplyr::filter( . , outcome == outcome_keyword ) %>%
                dplyr::filter( . , grepl( "^(1*\\.hci\\#[0-9]{4}b*\\.year.*korea)" , var ) )%>%
                dplyr::mutate( year = as.numeric( str_match( var , "[0-9]{4}") ) )
  
  # Test the table is non-tempty....
  test_that( "Filtered table is not empty", {
    expect_equal( plyr::empty( table ), FALSE ) } )
  
  
  # Translate fixed effects.
  table$fixedeffect <- stringr::str_replace_all( table$fixedeffect, 
                                        "i.code#i.year i.reportercode#i.year i.reportercode#i.code", 
                                        "Industry-Year, Country-Year, Country-Industry") %>% 
                        stringr::str_replace_all( . , 
                                         "i.code#i.year i.reportercode#i.year", 
                                         "Industry-Year, Country-Year") %>% 
                        stringr::str_replace_all( . , 
                                         "code reportercode", 
                                         "Industry, Year, Country")    
  ### 2) ======== Generate MAIN baseline GGPLOT object. ======== ###

  # Start with the prepared dataframe, pass to main ggplot function.
  g <- gg_smallbarstheme( table, table$fixedeffect )

  ### 3) ======== Set theme  ======== ###
  g <- g + scale_color_manual( values = c(annotation_color,
                                          deep_red_argument,
                                           "grey50"),
                               breaks = c("Industry, Year, Country", 
                                          "Industry-Year, Country-Year",
                                          "Industry-Year, Country-Year, Country-Industry"),
                               name = "Fixed Effects") +
            scale_shape_manual( values = c( 17,
                                            15, 
                                            19),
                                breaks = c("Industry, Year, Country",
                                           "Industry-Year, Country-Year", 
                                           "Industry-Year, Country-Year, Country-Industry"),
                                name = "Fixed Effects") 
  return( g )
}

## ========================================================================== ##
# IV. MAKE TRIPLE DIFFERENCE WORLD TRADE FIGS. ---------------------------------
## ========================================================================== ##

## A. GENERATE WORLD TRADE FIGURES ---------------------------------------------

# Data set name
datasetcsvname <- "did_largerolling_worldtrade_ppml_rca_all_results.csv"

# List of outcome keywords
listofoutcomes <- c( "rca_core",
                     "h_rca_core", 
                     "rca_cdk",
                     "rca_dummy" )

listoflabels <- c( "A)  Revealed Comparative Advantage" , 
                   "B)  Revealed Comparative Advantage (asinh)" , 
                   "C)  Relative Export Productivity (CDK)",
                   "D)  Probability of Comparative Advantage" )

# Make list of plots
gglist <- lapply( listofoutcomes ,
                  make_worldtrade_plots,
                  dataset_name = datasetcsvname )

## B. EDIT PLOTS FOR PLOTTING --------------------------------------------------

# Apply labels to each ggplot as subtitle.
lapply(seq_along(gglist), function(i) {
  
  # Add the order of labels
  gglist[[i]] <<- gglist[[i]] + labs(title = listoflabels[[i]])
  
  # Adjust size.
  gglist[[i]] <<- gglist[[i]] + 
      theme(plot.title = element_text( size = font_size_argument + .5, 
                                     color = annotation_color , 
                                     hjust = 0 ))
})

# Remove x times for all but the bottom plot.
lengthless1 <- length(listofoutcomes) - 1
gglist[1:lengthless1] <- lapply( gglist[1:lengthless1] , removexticks)

# Add year for clarity to bottom
gglist[[4]] <- gglist[[4]] + labs( x = "\nYear" ) + 
  theme(axis.title.x = element_text( size = font_size_argument, 
                                     color = annotation_color, 
                                     margin = margin( t = 4 ) ))

## C. RENDER TRIPLE DIFFERENCE WORLD TRADE FIGS. -------------------------------
combine_ddd_trade_plots <- ggpubr::ggarrange( plotlist = gglist, 
                                              nrow = length(gglist), 
                                              common.legend = TRUE ,
                                              legend = "bottom" )

combine_ddd_trade_plots <- ggpubr::annotate_figure( 
  combine_ddd_trade_plots, 
  left = text_grob("Coefficients ( Targeted x Year )",
                   color = annotation_color ,
                   rot = 90,
                   hjust = 0.5,
                   size = font_size_argument +1 )
)

## ========================================================================== ##
# V. SAVE PLOT AND FOOTNOTE ----------------------------------------------------
## ========================================================================== ##

save_plot( combine_ddd_trade_plots, 
           "dddtradeplot", 
           output_dir = figures_dir,
           width = 12, 
           height = 7.5 )

save_figure_footnote( footnote_string, 
                     figures_dir, 
                     "dddtradeplot" )