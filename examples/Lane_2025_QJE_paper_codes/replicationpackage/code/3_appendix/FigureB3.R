## =============================================================================
# PURPOSE:
#   Creates visualizations showing the relationship between HCI and total factor
#   productivity using various estimation methods.
#
# INPUTS:
#   - did_largerolling_results_tfp_all_results.csv
#
# OUTPUTS:
#   - industrytfpfigure
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS. -------------------------------------------------
## ========================================================================== ##
font_size_argument <- 11

footnote_string <- "\\indent This figure shows the relationship between HCI 
and total factor productivity. The coefficients in the figure are estimated from 
equation (1). TFP outcomes are estimated using Ackerberg-Caves-Frazer 
(ACF), Levinsohn-Petrin (LP), Olley-Pakes (OP), Wooldridge (W) methods, as well as 
baseline OLS using the Solow residual. Data are estimated using the 5-digit 
(long) panel, where capital stocks are available; log-transformed production 
functions are structurally estimated at the 2-digit level. Event study estimates 
are performed relative to the start year of the panel, 1970, as opposed to 1972, 
due to the significant dip in TFP in 1972. This is done for transparency; using 
1972 as the omitted category may overstate event study estimates. Standard errors 
are clustered at the industry level. Bars show 95 percent confidence intervals."

footnote_string <- gsub( "\n" , " " , footnote_string )

dodgewidth <- 1
tfplegentitle <- "Total Factor Productivity Estimate"


## ========================================================================== ##
# II. SETUP DATA ---------------------------------------------------------------
## ========================================================================== ##

## A. DATA LOADER --------------------------------------------------------------

# Dataset loader for all functions
regdataloader <- function( dataset_name_arg ) {
  
  df <- paste0( dataset_name_arg ) %>%
    
          # Read in the data set...
          file.path( intermediate_dir , . ) %>%
          read.csv( . , header = TRUE , 
                        na.strings = c( "" , "." , "NA" ) ) 
  
  # This is the final dataset.
  test_that("Test that prepared data.frame is not empty", {
    expect_equal( plyr::empty( df ), FALSE ) })

  return( df )
}

## B. GG PLOT THEME ------------------------------------------------------------

# TFP theme with small bars... 
ggplotter_smallbarstheme <- function( df ){
  
  # Widen the x-axis for visibility and dodge
  start_year <- 1970-1
  end_year <- 1987

  gsub <- ggplot( data = df , 
                          aes( x = year, 
                               group = outcome,
                               color = outcome)  ) +
            geom_hline( yintercept = 0 , 
                        color = med_grey_argument, 
                        size = .2 ) +
            geom_vline( xintercept = 1972 , 
                        color = med_grey_argument , 
                        lty = "dashed" , 
                        size = .3) +
            geom_vline( xintercept = 1979 , 
                        color = med_grey_argument , 
                        lty = "dashed" , 
                        size = .3) +
            geom_point( aes( x = year , 
                             y = coef , 
                             shape = outcome, 
                             color = outcome, 
                             fill = outcome) , 
                        size = 1.65, 
                        alpha = 0.90, 
                        position = position_dodge( width = dodgewidth ) ) +
            geom_errorbar( aes( min = ci_lower , 
                                max = ci_upper),
                           alpha = .5, 
                           width = 0, 
                           position = position_dodge( width = dodgewidth ) ) +
            scale_x_continuous( breaks = c( start_year+1 , 
                                            1972 , 
                                            1979 , 
                                            end_year-1 ), 
                                labels = c( paste0( start_year+1 ), 
                                            "1972" , 
                                            "1979", 
                                            paste0( end_year-1 ) ) ,
                                limits = c( start_year , 
                                            end_year ) )
  return( gsub )
}

## B. GGPLOT FUNCTION ----------------------------------------------------------

## This is the main function for the rolling GGPLOT graphic. 
make_tfp_plot  <- function( dataset_name ){
  
  ### 1) ======== LOAD THE DATASET. ======== ### 

  ## Load and clean data. Filter only essentials...
  table <- regdataloader( dataset_name ) %>%

                # Filter the outcome keyword and ONLY interaction terms...
                filter( . , grepl( "^(1o*\\.hci\\#[0-9]{4}b*\\.year)" , var ) )
  
    
    # Generate YEAR variable from VAR variable string. 
    table$year <- table$var %>% 
                    str_match( . , "[0-9]{4}") %>% 
                    as.numeric( . )
               
  ### 2) ======== CLEAN REGRESSION OUTPUT DATASET FOR PLOTTING. ======== ### 

  ## Prepare - Slim down table to essentials, and prepare for plotting...
  
  # Clean the TFP outcome labels. 
  table$outcome <- stringr::str_replace_all(table$outcome, "[^[:alnum:]]", " ")
  table$outcome <- stringr::str_replace_all(table$outcome, "^[Tt][Ff][Pp]", "")
  table$outcome <- stringr::str_to_upper(table$outcome) 

  ### 3) ======== Generate MAIN baseline GGPLOT object. ======== ###
  
  # Start with the prepared dataframe, pass to main ggplot function.
  g <- ggplotter_smallbarstheme( table )
 
  ### 4) ======== Adjust the aesthetics of GGPLOT object, g. ======== ###
  
  # Simplifying plot aesthetics. 
  g <- g + theme( text = element_text( size = font_size_argument, 
                               color = annotation_color ) ,
          plot.title = element_text( size = font_size_argument,  
                                     color = annotation_color,
                                     hjust = 0.5 ) , 
          axis.text = element_text( size = font_size_argument , 
                                    hjust = 0 , 
                                    color = annotation_color) ,
          axis.text.x = element_text( vjust = .5 ,
                                      hjust = 0.5, 
                                      angle = 0 , 
                                      color = annotation_color,
                                      size = font_size_argument),
          axis.title.x = element_text( size = font_size_argument + 1, 
                                     color = annotation_color,
                                     margin = margin( t = 10, r = 10, b = 10, l = 10 )) ,
          axis.title.y = element_text( size = font_size_argument + 1, 
                                       color = annotation_color),
          axis.ticks = element_line( size =.2, 
                                     colour = med_grey_argument ), 
          axis.ticks.length = unit( 3, "pt" ), 
          panel.grid = element_blank() ,
          legend.position = "bottom",
          legend.text = element_text( size = font_size_argument -1, 
                                     color = annotation_color ),
          legend.title = element_text( size = font_size_argument + 1,
                                       hjust = 0.5,
                                       color = annotation_color ) ) +
      guides(color = guide_legend(nrow = 2)) +  # Arrange in 2 rows
      scale_color_viridis( discrete = TRUE,
                           end = .7 ,
                           option = "mako" )

  ### 5) ======== Return GGPLOT g object..  ======== ###
  g <- g + labs( x = "Year", 
                 y = "Coefficient (Targeted x Year)" , 
                 color = tfplegentitle, 
                 shape = tfplegentitle,
                 fill = tfplegentitle) + 
    theme(  legend.title.position = "top",
            legend.title = element_text( size = rel(1)))
  
  return( g )

}

## ========================================================================== ##
# III. MAKE PLOTS --------------------------------------------------------------
## ========================================================================== ##

## Use the dataset name to make the TFP figure.
dataset_name <- "did_largerolling_results_tfp_all_results.csv"

## MAKE plots from 4c...R file.
industrytfpfigure <- make_tfp_plot( dataset_name )

## ========================================================================== ##
# IV. SAVE PLOT AND FOOTNOTE ---------------------------------------------------
## ========================================================================== ##

# Save plot.
save_plot( plot_object = industrytfpfigure ,
           filename = "industrytfpfigure" ,
           width = 8 ,
           height = 6 ,
           output_dir = figures_appendix_dir )

save_figure_footnote( footnote_string ,
                      output_dir = figures_appendix_dir ,
                      label = "industrytfpfigure" )


test_that("Test that plot and footnote are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                        "industrytfpfigure.pdf" ) ) )
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                        "industrytfpfigure.tex" ) ) )
})
