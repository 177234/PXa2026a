## =============================================================================
# PURPOSE:
#   Creates visualizations showing dynamic differences-in-differences estimates
#   for the relationship between HCI and industrial output outcomes.
#
# INPUTS:
#   - did_largerolling_mainresults_alloutput_all_results.csv
#   - did_largerolling_mainresults_alloutput_4d_all_results.csv
#
# OUTPUTS:
#   - gg_robust_output
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS --------------------------------------------------
## ========================================================================== ##


## A. ARGUMENTS ----------------------------------------------------------------

footnote_string <- "\\indent This figure shows dynamic differences-in-differences 
estimates for the relationship between HCI and industrial output outcomes. 
Plots show regression coefficients from equation (1) for three measures of log output: gross output, value added, and value of gross 
output shipped. Panel A shows results for 4- and 5-digit panels. Each column of 
the panels corresponds to a specification: the baseline two-way fixed effect 
specification and specifications adding additional controls. Controls are log 
pre-1973 industry averages: avg. industry wages, avg. industry plant size, labor 
productivity, and intermediate outlays, interacted with time effects. All estimates
are relative to 1972, the year before the HCI policy. The line at 1979 demarcates 
the end of the Park regime. Standard errors are clustered at the industry-level. 
95 percent confidence bands are in gray."

footnote_string <- gsub( "\n" , " " , footnote_string )


## B. GGPLOT THEME --------------------------------------------------------------
dodge_width <- .75
error_width <- 0

# Minimal theme for the final plot.
minimal_theme_final_plot <- theme( 
  plot.title = element_text( size = rel(1),  
                             hjust = .5 ) , 
  axis.text = element_text( size = rel(.9),  
                            hjust = 0 ) ,
  axis.text.x = element_text( vjust = .5 , 
                              hjust = 0.5, 
                              size = rel(.9)),
  axis.title.x = element_blank(),
  axis.title.y = element_text(color = annotation_color,
                              size = rel(.9),
                              margin = margin(0, 8, 0, 0)),
  plot.margin = margin(10, 10, 10, 10),
  legend.text = element_text(size = rel(.9)),
  legend.background = element_blank(),
  legend.title.position = "top",
  legend.direction = "horizontal",
  legend.position = "bottom",
)


## ========================================================================== ##
# II. FUNCTIONS ----------------------------------------------------------------
## ========================================================================== ##

## A. DATA LOADER --------------------------------------------------------------

# Dataset loader for all functions
regdataloader <- function( dataset_name_arg ) {
  # Make the dataset.
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

## B. VARIABLE CLEANING FUNCTION -----------------------------------------------
cleantablevariablelist_helper <- function(dataset_argument) {  
  cleaned_dataset <- dataset_argument %>%
    str_replace_all(
      c(
        "(^h_|^l_)" = "",
        "gross[0-9]+|grossoutput" = "gross output",
        "ship$" = "value shipped",
        "valueadded" = "value added"
        )
    ) %>%
    str_to_title()
  return(cleaned_dataset)
}

## C. DATA PREPARER ------------------------------------------------------------
prepareloadedtable <- function( dataset_name , 
                                start_year_arg = NULL ) {
  
  # Load and clean data. Filter only essentials...
  table <- dataset_name %>%
            # Filter and small cleaning:
            dplyr::filter( command == "xtdidregress" ) %>%
            dplyr::mutate(regressortype = ifelse( is.na( regressortype ) , "Baseline" , "Plus Controls" ) ) %>%
            dplyr::mutate(outcome = cleantablevariablelist_helper( outcome ) ) %>%
            dplyr::group_by(modelnumber, regressortype) %>%
            dplyr::mutate(year = start_year_arg + row_number() - 1) %>%
            dplyr::ungroup()
  
  # Test that all coefficients are zero in 1972
  testthat::test_that("All coefficients are zero in 1972", {
    expect_true(
      all(
        table %>% 
          dplyr::filter(year == 1972) %>% 
          dplyr::pull(coef) == 0
      )
    )
  })
  return( table ) 
}

## D. GG PLOT THEME ------------------------------------------------------------

# Theme function for multiple regressions on the same plot.
ggplotter_smallbarstheme <- function( df ,
                                      variabletododge,
                                      start_year_arg = NULL,
                                      end_year_arg = NULL ){
  # If no start year, get min year.
  ifelse( !is.null( start_year_arg ),
          start_year <- start_year_arg ,
          start_year <- min(df$year)-1 )
  
  # If no start year, get ma
  ifelse( !is.null( end_year_arg ),
          end_year <- end_year_arg ,
          end_year <- max(df$year)+1 )
  
  # Make ggplot subplot
  gsub <- ggplot( data = df ,
                  aes( x = year ,
                       group = variabletododge, 
                       color = variabletododge ) ) +
        geom_errorbar( aes( min = ci_lower ,
                            max = ci_upper),
                       alpha = 0.6, 
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
                         shape = variabletododge , 
                         color = variabletododge) , 
                    size = 1.5, 
                    alpha = 1, 
                    position = position_dodge(width = dodge_width) ) +
        scale_x_continuous( breaks = c( start_year + 1,
                                        1972 ,
                                        1979 ,
                                        end_year - 1 ),
                            labels = c( paste0( start_year + 1),
                                        "1972" ,
                                        "1979",
                                        paste0( end_year - 1 ) ) ,
                            limits = c( start_year ,
                                        end_year ) )
  return(gsub) 
}

## ========================================================================== ##
# III. MAIN FUNCTION -----------------------------------------------------------
## ========================================================================== ##

## This is the main function for the rolling GGPLOT graphic. 
make_ggplot  <- function( dataset_name , 
                          start_year_arg = NULL, 
                          end_year_arg = NULL ){
  
  ### 1) ======== LOAD THE DATASET. ======== ### 
  
  # Load the dataset.  
  df <- regdataloader( dataset_name )
  
  # Prepare the dataset.
  table <- prepareloadedtable( df , start_year_arg )

  ### 2) ======== Generate MAIN baseline GGPLOT object. ======== ###
    
  # Generate the GGPLOT object.
  g <- ggplotter_smallbarstheme( table ,
                                 table$outcome )
  
  # Facet wrap by regressor type.
  g <- g + facet_wrap( ~ regressortype , 
                       scales = "free_y" , 
                       ncol = 1 )
  
  ### 3) ======== Adjust the aesthetics of GGPLOT object, g. ======== ###
  
  # Simplifying plot aesthetics. 
  g <- g + minimal_theme_final_plot
  
  # Tweak labels...
  g <- g + labs( x = "Year", y = "Coefficient (Targeted x Year)" )+ 
      scale_color_manual( values = c(annotation_color,
                                     med_grey_argument,
                                     deep_red_argument), 
                          guide = guide_legend( title = "Output Measure (log)" ))+
      scale_shape_manual( values = c(16, 17, 15),  # Example shape codes
                           guide = guide_legend(title = "Output Measure (log)"))


  return( g )  
}

## ========================================================================== ##
# IV.  MAKE GGPLOTS ------------------------------------------------------------  
## ========================================================================== ##

## A. MAKE EACH PLOT -----------------------------------------------------------

# Defining arguments for dataframes in the plots.
csvfilename5d <- "did_largerolling_mainresults_alloutput_all_results.csv"
csvfilename4d <- "did_largerolling_mainresults_alloutput_4d_all_results.csv"

# Generate plots.
gg_robust_output_5d <- make_ggplot( csvfilename5d, 
                                    start_year_arg = 1970 )
gg_robust_output_4d <- make_ggplot( csvfilename4d , 
                                    start_year_arg = 1967 )
# Label plots.
gg_robust_output_5d <- gg_robust_output_5d + 
  labs( title = "Panel A) Five-Digit Panel, 1970-1986" )
gg_robust_output_4d <- gg_robust_output_4d + 
  labs( title = "Panel B) Four-Digit Panel, 1967-1986" )

## B. ARRANGE PLOTS ------------------------------------------------------------
gg_robust_output <- ggpubr::ggarrange( 
  plotlist = list( gg_robust_output_5d ,
                   gg_robust_output_4d ),
  common.legend = TRUE,
  ncol = 1 ,
  nrow = 2,
  legend = "bottom" )

## ========================================================================== ##
# V. SAVE PLOT AND FOOTNOTE --------------------------------------------------
## ========================================================================== ##

# Save plot.
save_plot( plot_object = gg_robust_output ,
           filename = "appendixrobustoutput" ,
           width = 8 ,
           height = 10.5 ,
           output_dir = figures_appendix_dir )

save_figure_footnote( footnote_string ,
                      output_dir = figures_appendix_dir ,
                      label = "appendixrobustoutput" )

test_that("Test that plot and footnote are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                        "appendixrobustoutput.pdf" ) ) )
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                        "appendixrobustoutput.tex" ) ) )
})

