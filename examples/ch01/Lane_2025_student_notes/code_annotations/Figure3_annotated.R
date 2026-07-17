# Annotated copy for replication audit.
# Original script: Lane2025QJE/replicationpackage/code/1_figures/Figure3.R
# Purpose: Generates Figure 3.
#
# This file intentionally keeps the original .R extension.
# The original code is copied below. Comments in this header identify the
# script role, inputs, outputs, and audit linkage. The earlier prose note is
# archived at: markdown_notes_archive/Figure3_R.md
#
# Audit linkage:
# - Methods report: explains the estimating or output logic.
# - Derivation report: maps equations/design objects to code.
# - Replication report: documents inputs, outputs, and reproducibility limits.
#
# Original code begins after this header.

## =============================================================================
# PURPOSE:
#   Creates dynamic differences-in-differences graphs for industrial development
#   and export development outcomes.
#
# INPUTS:
#   - "did_largerolling_allproductivity_all_results.csv" (5-digit panel results)
#   - "did_largerolling_allproductivity_4d_all_results.csv" (4-digit panel results)
#   - "did_largerolling_koreatrade_ppml_rca_all_results.csv" (Trade analysis results)
#
# OUTPUTS:
#   - combinedplots (Combined ggplot object for industrial and export development)
# ==============================================================================

## =============================================================================
# I. TEXT AND PLOT ARGUMENTS --------------------------------------------------
## =============================================================================

## ========================================================================== ##
# X. TEXT FOR THE FOOTNOTE. ----------------------------------------------------
## ========================================================================== ##

footnote_string <- "\\indent This figure shows the dynamic differences-in-differences 
estimates for the relationship between HCI and industrial development (log) outcomes 
(Panel A) and export development outcomes (Panel B). Coefficients in the plot are estimated 
using equation \\eqref{eq:mainflexible}. For Panel A: Left (i) are estimates from long panel 
data (4-digit), right (ii) are estimates from detailed short panel data (5-digit). Panel A reports 
estimates for log outcomes: total employment; labor productivity (real value added per worker); 
output prices; number of plants; and output (labor) share is industry's share of total manufacturing 
output (employment). Panel B presents outcomes for trade data. RCA is the plain Balassa index, 
estimated using PPML; all other trade outcomes are estimated using OLS. RCA (asinh) is transformed 
using inverse hyperbolic sine. Relative export productivity is structurally estimated using CDK. 
The probability of reaching comparative advantage is defined as cases where the RCA index > 1. 
All estimates are relative to 1972, the year before the HCI policy. 1979 demarcates the end of the 
Park regime. Standard errors are clustered at the industry level. 95 percent confidence intervals 
are shown in gray."

footnote_string <- gsub( "\n", " ", footnote_string )

## ========================================================================== ##
# I. TEXT AND FIGURE ARGUMENTS. ------------------------------------------------
## ========================================================================== ##

error_width <- 0
light_grey_argument <- "grey50"

# Minimal theme.
newminimaltheme <- theme(
    plot.title = element_text( size = rel(.95) ,  
                                color = annotation_color,
                                hjust = 0.5,
                                margin = margin( t = 5, b = 5 )) ,
    plot.subtitle = element_text( size = rel(.85) , 
                                  color = annotation_color,
                                  hjust = 0,
                                  margin = margin( t = 5, b = 12.5 ) ) ,
    axis.text.y = element_text( size = rel(.8)) ,
    axis.text.x = element_text( size = rel(.8)),
    axis.title.x = element_blank(),
    panel.grid = element_blank() ,
    legend.position = "bottom" ,
    legend.background = element_blank() ,
    legend.key = element_blank() 
)

## ========================================================================== ##
# II. FUNCTIONS ----------------------------------------------------------------
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

## C. VARIABLE CLEANER FUNCTION ------------------------------------------------

cleanvariablename <- function(df_argument){
  cleaned_df <- df_argument %>%
                  stringr::str_replace_all(
                    c(
                      "(^l_)" = "",
                      "ship_sh" = "output share (log)",
                      "est" = "number plants  (log)",
                      "ppi" = "prices  (log)",
                      "lab_sh" = "labor share (log)",
                      "y_n" = "labor productivity (log)",
                      "workers" = "employment (log)",
                      "_" = " " ) 
                    ) %>%
                  stringr::str_to_title() %>%
                  stringr::str_replace_all( "([Ll]og)" , "log" )        
  return( cleaned_df )
}

## D. GGPLOT THEME FUNCTION ----------------------------------------------------
gg_smallbarstheme <- function( df ){

  # Grab year arguments for GGPLOT scope.
  start_year <- min( as.numeric( df$year ) , 
                     na.rm = TRUE)
  end_year <- max( as.numeric( df$year ) , 
                   na.rm = TRUE)
  
  # ggplot sub plot.
  gsub <- ggplot( data = df , 
                  aes( x = year ) ) +
    geom_errorbar( aes( min = ci_lower , 
                        max = ci_upper),
                   alpha = 0.5, 
                   width = error_width ) +
    geom_hline( yintercept = 0 , 
                color = light_grey_argument , 
                linewidth = .3 ) +
    geom_vline( xintercept = 1972 , 
                color = "grey50" , 
                lty = "dotted" , 
                linewidth = .5) +
    geom_vline( xintercept = 1979 , 
                color = "grey50" , 
                lty = "dotted" , 
                linewidth = .5) +
    geom_point( aes( x = year , y = coef ) , 
                size = 1, 
                alpha = .9, 
                color = annotation_color ) +
    scale_y_continuous( breaks = pretty_breaks(n = 3) ) +
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
  # Plot aesthetics. 
  gsub <- gsub + newminimaltheme
  gsub <- gsub + labs( x = "Year", y = "" )

  return( gsub )
}


## C. MAIN GG PLOT FUNCTION ----------------------------------------------------

## This is the main function for the rolling GGPLOT graphic. 
make_rolling_plots  <- function( dataset_name , 
                                 outcome_keyword, 
                                 sublabel = NULL ){
  
    ## Load and clean data. Filter only essentials...
    table <- regsavedataloader( dataset_name ) %>%
                dplyr::filter( outcome == outcome_keyword ) %>%
                dplyr::filter( grepl( "^(1o*\\.hci\\#[0-9]{4}b*\\.year)" , var ) ) %>%
                dplyr::mutate( year = as.numeric( str_match( var , "[0-9]{4}") ) )
              
    # Test the table is non-tempty....
    test_that( "Filtered table is not empty", {
      expect_equal( plyr::empty( table ), FALSE ) } )
    
  # Make main ggplot object.
  g <- gg_smallbarstheme( table )
  
  # Add variable name for subplot of option selected.
  if ( !is.null( sublabel ) ){
    cleaned_variable <- cleanvariablename( outcome_keyword )
  } else {
    cleaned_variable <- " "
  }
  
  # Add subtitle to ggplot.
  g <- g + labs( subtitle = paste0( cleaned_variable) )
  
  return( g ) 
}

## ========================================================================== ##
# III.  MAKE GGPLOTS FOR THE MAKE 4-DIGIT AND 5-DIGIT DEVELOPMENT PLOTS. -------
## ========================================================================== ##

## A. SETUP DATASETS AND OUTCOMES ----------------------------------------------

# Dataset names.
dataset5d <- "did_largerolling_allproductivity_all_results.csv"
dataset4d <- "did_largerolling_allproductivity_4d_all_results.csv"

# Run plot for the following outcomes. 
outcomelist <- c("l_y_n", "l_ppi", "l_workers", "l_est", "l_ship_sh" , "l_lab_sh" )

## B. MAKE THE DEVELOPMENT GRAPHS - DEV. FIGURE 4. PANEL A ---------------------


# Apply functions to list of outcomes for 5 and 4-digit lists.
gglist_5d <- lapply( outcomelist,
                     make_rolling_plots,
                     dataset_name = dataset5d )

# 4-digit uses sublabel argument.
gglist_4d <- lapply( outcomelist,
                     make_rolling_plots,
                     dataset_name = dataset4d,
                     sublabel = TRUE )

## C. EDIT PLOTS FOR PLOTTING -------------------------------------------------

# Remove x times for all but the bottom plot.
lengthless1 <- length(outcomelist) - 1
gglist_4d[1:lengthless1] <- lapply( gglist_4d[1:lengthless1] , removexticks)
gglist_5d[1:lengthless1] <- lapply( gglist_5d[1:lengthless1] , removexticks)

# Edit figure annotations for GGARRANG:
gglist_4d[[1]] <- gglist_4d[[1]] + labs(title = "i) Four-Digit Panel\n")
gglist_5d[[1]] <- gglist_5d[[1]] + labs(title = "ii) Five-Digit Panel\n")

## D. ASSEMBLE graphs into grid.- ----------------------------------------------

gg_devgrid <- ggpubr::ggarrange( plotlist = c(gglist_4d[1],gglist_5d[1],
                                       gglist_4d[2],gglist_5d[2],
                                       gglist_4d[3],gglist_5d[3],
                                       gglist_4d[4],gglist_5d[4],
                                       gglist_4d[5],gglist_5d[5],
                                       gglist_4d[6],gglist_5d[6]),
                                  ncol = 2, 
                                  heights = c(1.5,1,1,1,1,1.25), 
                                  nrow = length(outcomelist))

## ========================================================================== ##
# IV.  MAKE GGPLOTS FOR THE TRADE OUTCOMES -------------------------------------
## ========================================================================== ##

## A. SETUP DATASETS AND OUTCOMES ----------------------------------------------
tradedataset <- "did_largerolling_koreatrade_ppml_rca_all_results.csv"

# Run plot for the list.
listofoutcomes <- c("rca_core", 
                    "h_rca_core",
                    "rca_cdk",
                    "rca_dummy",
                    "l_export_sh")

listoflabels <- c("RCA", 
                  "RCA (asinh)",
                  "Relative Export Productivity (CDK)",
                  "Prob. of Comparative Advantage",
                  "Export Share of Manufacturing (log)")

# Make list of ggplots for each trade outcome.
gglist <- lapply( listofoutcomes,
                   make_rolling_plots, 
                   dataset_name = tradedataset )

## B. EDIT PLOTS FOR PLOTTING --------------------------------------------------

# Apply labels to each ggplot as subtitle.
lapply(seq_along(gglist), function(i) {
  gglist[[i]] <<- gglist[[i]] + labs(subtitle = listoflabels[[i]])
})

# Remove x times for all but the bottom plot.
lengthless1 <- length(listofoutcomes) - 1
gglist[1:lengthless1] <- lapply( gglist[1:lengthless1] , removexticks)

## C. ASSEMBLE graphs into grid.------------------------------------------------
gg_tradegrid <- ggpubr::ggarrange( plotlist = c( gglist[1:length(gglist)] ) ,
                                    ncol = 1,
                                    nrow = length(gglist) )

## ========================================================================== ##
# V.  RENDER COMBINED FIGURES --------------------------------------------------
## ========================================================================== ##

## A. ADD TITLES TO EACH GRID --------------------------------------------------
gg_devgrid <- ggpubr::annotate_figure( gg_devgrid ,
                                       top = text_grob( paste0("A) Industrial Development"),
                                                               size = font_size_argument ) )

gg_tradegrid <- ggpubr::annotate_figure( gg_tradegrid ,
                                         top = text_grob( paste0("B) Export Development"),
                                                            size = font_size_argument ) )

## B. COMBINE PLOTS INTO ONE GRID ----------------------------------------------
combinedplots <- ggpubr::ggarrange( gg_devgrid , 
                                    NULL ,
                                    gg_tradegrid, 
                                    ncol = 3, 
                                    widths = c(1.75,.25,1))
## ========================================================================== ##
# IV. SAVE FIGURE FOOTNOTE. ----------------------------------------------------
## ========================================================================== ##

save_plot( combinedplots, 
           "devcombinedplot", 
           width = 11, 
           height = 8,
           output_dir = figures_dir )

save_figure_footnote( footnote_string, 
                     figures_dir, 
                     "devcombinedplot" )