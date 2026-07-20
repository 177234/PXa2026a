## =============================================================================
# PURPOSE:
#   Creates visualizations showing dynamic differences-in-differences estimates
#   for the relationship between HCI and responses to input use by high versus
#   low marginal revenue product of capital (MRPK) industries.
#
# INPUTS:
#   - did_largerolling_mrpk_all_results.csv
#
# OUTPUTS:
#   - gg_mprk_plot
# ==============================================================================

## ========================================================================== ##
# I. ARGUMENTS AND PLOT/TEXT SETTINGS -----------------------------------------
## ========================================================================== ##

# TEXT AND ARGUMENTS IN KNITR FILE.

## A. BASIC ARGUMENTS. ---------------------------------------------------------
font_size_argument <- 11


footnote_string <- "This figure shows dynamic differences-in-differences estimates for the relationship between 
HCI and responses to in input use by high versus low marginal revenue product of 
capital (MRPK) industries. The figure plots coefficient estimates from equation (9),
estimated separately for (red) targeted and (gray) non-targeted industries. 
These coefficients convey the differences in input use between high-MRPK and low-MRPK
industries, relative to 1972. See Appendix D for MRPK calculation. Outcomes are 
log values: real material outlays, real investment, employment, and real gross output shipped.
Error bars show the 95 percent confidence interval."

footnote_string <- gsub( "\n" , " " , footnote_string )

# Main font, colors in setup.R

## B. GGPLOT ARGUMENTS ---------------------------------------------------------
error_width <- 0
alphaargument <- 0.5
dodge_width <- .85


# Minimal theme for the final plot.
newminimaltheme <- theme( 
  plot.title = element_text( hjust = 0.5, 
                             lineheight = 1.2,
                             size = rel(1),
                             margin = margin( 10 , 0 , 10 , 0 )) , 
         axis.text = element_text( size = rel(.9) ) ,
         axis.text.x = element_text( size = rel(.9)),
         axis.title.x = element_blank(),
         panel.grid = element_blank() ,
         plot.margin = margin( 5 ) ,
         legend.text = element_text( size = rel(1)) ,
         legend.margin = margin( t=27.5, r=10, b=10, l=5 ) ,
         legend.title = element_blank(),
         legend.position = "bottom" ,
         legend.direction = "horizontal" , 
         legend.background = element_blank() ,
         legend.key = element_blank() 
  )


## ========================================================================== ##
# II. HELPING FUNCTIONS ------------------------------------------------------
## ========================================================================== ##

## ========================================================================== ##
## A. LOAD DATA FUNCTION -------------------------------------------------------

# Dataset loader for all functions
regsavedataloader <- function( filename_arg ) {
  
  # Load the data.
  df <- file.path( intermediate_dir , paste0( filename_arg ) ) %>%
    read.csv( . , header = TRUE , na.strings = c( "" , "." , "NA" ) )
  
  # Test that prepared data.frame is not empty.
  testthat::test_that("Test that prepared data.frame is not empty", {
    expect_equal( plyr::empty( df ), FALSE ) })
  
  return( df )
}


## ========================================================================== ##
## B. GGPLOT FUNCTIONS ---------------------------------------------------------

### i. GGPLOT FUNCTION FOR MAKING MRPK PLOTS -----------------------------------
ggplotter_mrpk <- function(df , variabletolayer){
  
  # Add the year variable.
  start_year_arg <- min(df$year)
  ifelse( !is.null( start_year_arg ),
          start_year <- start_year_arg , 
          start_year <- 1970 )
  
  end_year_arg <- max(df$year)
  ifelse( !is.null( end_year_arg ),
          end_year <- end_year_arg , 
          end_year <- 1986 )  
  
  # Make the graph.
  g <- ggplot( data = df ,
                 aes( x = year ,
                      group = variabletolayer, 
                      color = variabletolayer ) ) +
    geom_errorbar( aes( min = ci_lower ,
                        max = ci_upper),
                   alpha = 0.5, 
                   width = error_width, 
                   position = position_dodge(width = dodge_width) ) +
    geom_hline( yintercept = 0 , 
                color = med_grey_argument, 
                linewidth = .2 ) +
    geom_vline( xintercept = 1972 , 
                color = med_grey_argument , 
                lty = "dashed" , 
                linewidth = .25) +
    geom_vline( xintercept = 1979 , 
                color = med_grey_argument , 
                lty = "dashed" , 
                linewidth = .25) +
    geom_point( aes( x = year , 
                     y = coef ,
                     shape = variabletolayer , 
                     color = variabletolayer , 
                     fill = variabletolayer ) , 
                size = 1.33, 
                alpha = .9, 
                position = position_dodge(width = dodge_width )) +
    scale_x_continuous( breaks = c( start_year ,
                                    1972 ,
                                    1979 ,
                                    end_year ),
                        labels = c( paste0( start_year ),
                                    "1972" ,
                                    "1979",
                                    paste0( end_year )) ,
                        limits = c( start_year - 1,
                                    end_year + 1 )) 
  
  # Remove labels for grid.
  g <- g + labs( x = "", y = "" )
  
  # Test that the ggplot object 'g' has at least one layer
  testthat::test_that("Graph has layers", {
    expect_true(length(g$layers) > 0)
  })
  
  return(g)
}


## ========================================================================== ##
# III. FUNCTIONS FOR MAKING PLOTS ----------------------------------------------
## ========================================================================== ##


## A. FUNCTION FOR MAKING MRPK PLOTS -------------------------------------------

## This is the main function for the rolling GGPLOT graphic. 
make_mrpk_plot <- function( dataset_name , outcome_keyword ){

  
  ### 1) ======== LOAD THE DATASET. ======== ### 
  
  ## Load and clean data. Filter only essentials...
  table <- regsavedataloader( datasetname ) %>%
    
    # Filter the outcome keyword and ONLY interaction terms...
    dplyr::filter( . , outcome == outcome_keyword ) %>%
    dplyr::filter( . , grepl( "^(1o*.*mrpk)\\#[0-9]{4}b*\\.year" , var ) ) %>%
    
    # Mutate variables a bit. If string equals "1", HCI.
    dplyr::mutate(. , constrainttype = ifelse( grepl( "1", constrainttype), 
                                               "HCI" , 
                                               "Non-HCI" ) ) 
  
  # Generate YEAR variable from VAR variable string. 
  table$year <- stringr::str_match( table$var , "[0-9]{4}") %>% as.numeric( . )
  
  # Test if the data set is empty.
  testthat::test_that("Data set is not empty." ,
                      expect_false( nrow( table ) == 0 ) )
  
  ### 2) ======== Generate MAIN baseline GGPLOT object. ======== ###
  
  # NOTE: Inserts the minimum year below:
  g <- ggplotter_mrpk( table , table$constrainttype )
  

  ### 3) ======== Adjust the aesthetics of GGPLOT object, g. ======== ###
  
  # Simplifying plot aesthetics. 
  g <- g + newminimaltheme
  
  # Color scales 
  g <- g + scale_color_manual( values = c(deep_red_argument, 
                                          med_grey_argument ),
                               labels = c("Targeted Industry Sample", 
                                          "Non-Targeted Industry Sample")) +
    scale_fill_manual( values = c(deep_red_argument, 
                                  control_grey_argument ),
                       labels = c("Targeted Industry Sample", 
                                  "Non-Targeted Industry Sample")) +
    scale_shape_manual( values = c( 21 , 24 ) ,
                        labels = c("Targeted Industry Sample", 
                                   "Non-Targeted Industry Sample"))
  
  # Test that the GGPLOT object is not empty.
  testthat::test_that("Graph has layers", {
    expect_true(length(g$layers) > 0)
  })
  
  return( g )
  
}


## ========================================================================== ##
# IV. EXECUTE FUNCTIONS AND MAKE GRID ------------------------------------------
## ========================================================================== ##


## ========================================================================== ##
## 1. MAKE MRPK PLOTS ----------------------------------------------------------


### A. PREPARE ARGUMENTS -------------------------------------------------------

# Defining arguments for data frames in the plots
datasetname <- "did_largerolling_mrpk_all_results.csv"

# Variable outcomes
listofvariables <- c("l_costs","l_inv_tot","l_workers","l_ship")

# Outcomes labels
listofoutcomes <- c(
  "Intermediate Outlays (log)",
  "Investment (log)",
  "Workers (log)",
  "Output (log)"
)

### B. EXECUTE THE PLOT MAKER FUNCTION -----------------------------------------

# Generate the plots: loop over outcomes and apply function.
gg_mrpk_list <- lapply( listofvariables, 
                        make_mrpk_plot,
                        dataset_name = datasetname ) 

# Add titles to top row.
for (i in seq_along(gg_mrpk_list)) {
  # Add title to each ggplot
  gg_mrpk_list[[i]] <- gg_mrpk_list[[i]] + 
    labs( title = paste0( LETTERS[i], ") ", listofoutcomes[i] ) )
}



### C. COMBINE LIST OF PLOTS INTO PANEL ----------------------------------------

# Make the GGPLOT object.
gg_mprk_plot <- ggpubr::ggarrange( 
  plotlist = gg_mrpk_list , 
  nrow = 2 , 
  ncol = 2 , 
  align = "hv",
  common.legend = TRUE, 
  legend	= "bottom" 
)



## ========================================================================== ##
## 2. MAKE GRID PLOT -----------------------------------------------------------


### A. COMBINE LIST OF PLOTS INTO PANEL ----------------------------------------

# Add the coefficients to the left of the plot.
gg_mprk_plot <- ggpubr::annotate_figure( gg_mprk_plot, 
  left = text_grob("Coefficients (Targeted x High MRPK)",
                   color = annotation_color ,
                   rot = 90,
                   size = font_size_argument-.5,
                   family = font_family_argument )
) 



## ========================================================================== ##
# SAVE PLOT AND FOOTNOTE ---------------------------------------------------
## ========================================================================== ##

# Save plot.
save_plot( plot_object = gg_mprk_plot ,
           filename = "gg_mprk_plot" ,
           width = 11.75 ,
           height = 6.75 ,
           output_dir = figures_appendix_dir )

save_figure_footnote( footnote_string ,
                      output_dir = figures_appendix_dir ,
                      label = "gg_mprk_plot" )

test_that("Test that plot and footnote are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_mprk_plot.pdf" ) ) )
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_mprk_plot.tex" ) ) )
})
