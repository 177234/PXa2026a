## =============================================================================
# PURPOSE:
#   Creates difference-in-differences plots showing the impact of Korean HCI
#   compared to world HCI sectors using SITC-level trade data.
#
# INPUTS:
#   - did_largerolling_worldtrade_supp_ppml_rca_all_results.csv
#
# OUTPUTS:
#   - combine_dd_rca_alt_figure
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND FIGURE ARGUMENTS. ------------------------------------------------
## ========================================================================== ##

## TITLE: Main figure title text.
mainlatex_label <- "\\label{fig:suppddaltrca}"
mainfigure_name <- "Differences-in-Differences - Industrial Policy on Export Development"
ddtradetitletext <- paste0( 
  mainlatex_label, 
  mainfigure_name
)

# Put things together.
footertext <- "\\indent This figure shows difference-in-differences estimates for the impact of Korean HCI compared to world HCI sectors, using SITC-level trade data. This is a slightly modified version of the baseline specification with additional country fixed effects. Fixed effects for each specification are shown in the legend. Estimates are relative to 1972, the year before the HCI policy intervention. The line at 1979 demarcates the fall of the Park regime. All specifications cluster standard errors at the country level. 95 percent confidence intervals are shown in gray."


## A. GGPLOT ARGUMENTS ---------------------------------------------------------

# Constants
dodge_width <- 1
error_width <- 0
alpha_errorbars <- 0.5

# Theme for all plots
newminimaltheme <- theme( 
    text = element_text( size = font_size_argument, 
                              color = annotation_color ) ,
    plot.title = element_text( size = rel(1.1),  
                                color = annotation_color,
                                hjust = 0.5 ) , 
    axis.text.y = element_text( size =  rel(.9), 
                              color = annotation_color ) ,
    axis.text.x = element_text( vjust = .5 ,
                                hjust = 0.5, 
                                size = rel(.95)),
    axis.title.x = element_blank(),
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
                lty = "dashed" , 
                linewidth = .3) +
    geom_vline( xintercept = 1979 , 
                color = med_grey_argument , 
                lty = "dashed" , 
                linewidth = .3) +
    geom_point( aes( x = year , 
                     y = coef , 
                     shape = facetfactor, 
                     color = facetfactor) , 
                size = 1.6, 
                alpha = 0.9, 
                position = position_dodge(width=dodge_width) ) +
    geom_errorbar( aes( min = ci_lower , 
                        max = ci_upper),
                   alpha = alpha_errorbars, 
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
  # Tweak labels...
  gsub <- gsub + labs( x = "Year", y = "" )
  
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
    dplyr::filter( . , grepl( "^([0-9]{4}b*\\.year.*korea)" , var ) )%>%
    dplyr::mutate( year = as.numeric( str_match( var , "[0-9]{4}") ) )
  
  # Test the table is non-tempty....
  test_that( "Filtered table is not empty", {
    expect_equal( plyr::empty( table ), FALSE ) } )
  
  
  # Translate fixed effects.
  table$fixedeffect <- stringr::str_replace_all( table$fixedeffect, 
                              "i.reportercode#i.code", 
                              "Industry-Country") %>% 
    stringr::str_replace_all( . , 
                              "reportercode", 
                              "Country") %>% 
    replace_na(., "None")
  
  
  ### 2) ======== Generate MAIN baseline GGPLOT object. ======== ###
  
  # Start with the prepared dataframe, pass to main ggplot function.
  g <- gg_smallbarstheme( table, table$fixedeffect )
  
  
  ### 3) ======== Set theme  ======== ###
  g <- g + scale_color_manual( values = c(annotation_color,
                                          deep_red_argument,
                                          med_grey_argument),
                               name = "Fixed Effects") +
    scale_shape_manual( values = c( 17,
                                    15, 
                                    19),
                        name = "Fixed Effects")
  
  ### 4) ======== Return GGPLOT g object..  ======== ###
  return( g )
  
}


## ========================================================================== ##
# IV. MAKE TRIPLE DIFFERENCE WORLD TRADE FIGS. ---------------------------------
## ========================================================================== ##


## ========================================================================== ##
## A. GENERATE WORLD TRADE FIGURES ---------------------------------------------

# Data set name
datasetcsvname <- "did_largerolling_worldtrade_supp_ppml_rca_all_results.csv"

# List of outcome keywords
listofoutcomes <- c( "rca_core",
                     "h_rca_core", 
                     "rca_cdk",
                     "rca_dummy" )

listoflabels <- c( "  A)  RCA (Balassa)\n" , 
                   "B)  RCA (log)\n" , 
                   "C)  Relative ExportProductivity (CDK)\n",
                   "D)  Probability of Comparative Advantage\n" )

# Make list of plots
gglist <- lapply( listofoutcomes ,
                  make_worldtrade_plots,
                  dataset_name = datasetcsvname )


## ========================================================================== ##
## B. EDIT PLOTS FOR PLOTTING --------------------------------------------------

# Apply labels to each ggplot as subtitle.
lapply(seq_along(gglist), function(i) {
  
  # Add the order of labels
  gglist[[i]] <<- gglist[[i]] + labs(title = listoflabels[[i]])
  
  # Adjust size.
  gglist[[i]] <<- gglist[[i]] + 
    theme(plot.title = element_text( size = font_size_argument+.5, 
                                     color = annotation_color , hjust = 0 ))
})


# Remove x times for all but the bottom plot.
lengthless1 <- length(listofoutcomes) - 1
gglist[1:lengthless1] <- lapply( gglist[1:lengthless1] , removexticks)


## ========================================================================== ##
## C. RENDER TRIPLE DIFFERENCE WORLD TRADE FIGS. -------------------------------

combine_dd_rca_alt_figure <- ggpubr::ggarrange( plotlist = gglist, 
                                              nrow = length(gglist), 
                                              common.legend = TRUE ,
                                              legend = "bottom" )

## ========================================================================== ##
# IV. SAVE FIGURE & FOOTNOTE ----------------------------------------------------
## ========================================================================== ##

save_plot( combine_dd_rca_alt_figure, 
           "combine_dd_rca_alt_figure", 
           width = 6, 
           height = 8,
           output_dir = figures_supplementalappendix_dir)

save_figure_footnote( footertext, 
                      figures_supplementalappendix_dir, 
                      "combine_dd_rca_alt_figure" )
