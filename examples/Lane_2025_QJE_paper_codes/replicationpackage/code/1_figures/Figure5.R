## =============================================================================
# PURPOSE:
#   Makes visualizations for the policy section, transforming and plotting
#   investment incentive responses from regression outputs.
#
# INPUTS:
#   - "did_largerolling_mainpolicycapital_results_papermain.csv" (Main policy capital regression results)
#
# OUTPUTS:
#   - gg_invest_grid (Combined ggplot object for investment outcomes)
# ==============================================================================

## =============================================================================
# I. TEXT AND PLOT ARGUMENTS --------------------------------------------------
## =============================================================================

## ========================================================================== ##
# X. FOOTNOTES. ----------------------------------------------------------------
## ========================================================================== ##

# Put things together.
footnote_string <- "\\indent This figure plots dynamic differences-in-differences 
estimates for responses to investment incentives. The coefficients in the plot 
are estimated using equation \\eqref{eq:mainflexible}. All outcomes are real log 
values: real total intermediate outlays (material costs), intermediate outlays 
per worker, total investment, investment per worker, and capital stock. Panels 
report baseline estimates from the 5-digit industry panel (1970-1986). Estimates 
are relative to 1972, the year before the HCI drive. The line at 1979 demarcates 
the end of the Park regime. Standard errors are clustered at the industry level. 
95 percent confidence intervals are shown in gray."

footnote_string <- gsub( "\n", " ", footnote_string )

## ========================================================================== ##
# I. ARGUMENTS AND PLOT/TEXT SETTINGS -----------------------------------------
## ========================================================================== ##

# Graphical arguments
error_width <- 0
alphaargument <- 0.35

# Minimal theme for the final plot.
newminimaltheme <- theme( 
    plot.title = element_text( size = rel(1.05),  
                              color = annotation_color,
                              hjust = 0.5,
                              lineheight = 1.15,
                              margin = margin( 12 , 0 , 12 , 0 )) , 
    axis.text.y = element_text( size = rel(.95)), 
    axis.text.x = element_text( size = rel(.875)),
    axis.title.x = element_blank(),
    panel.grid = element_blank() ,
    plot.margin = margin( 5 )
)

## ========================================================================== ##
# II. HELPING FUNCTIONS ------------------------------------------------------
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

## B. GGPLOT FUNCTIONS ---------------------------------------------------------
ggplotter_didinvest <- function( df ){
  
  # Add the year variable.  
  start_year_arg <- min(df$year)
  ifelse( !is.null( start_year_arg ),
          start_year <- start_year_arg , 
          start_year <- 1970 )
  
  end_year_arg <- max(df$year)
  ifelse( !is.null( end_year_arg ),
          end_year <- end_year_arg , 
          end_year <- 1986 )  
  
  # Make the ggplot object.
  g <- ggplot( data = df ,
               aes( x = year ) ) +
    geom_errorbar( aes( min = ci_lower ,
                        max = ci_upper),
                   alpha = alphaargument , 
                   width = error_width,
                   size = .75 ) +
    geom_hline( yintercept = 0 , 
                color = med_grey_argument, 
                size = .2 ) +
    geom_vline( xintercept = 1972 , 
                color = med_grey_argument , 
                lty = "dotted" , 
                size = .5 ) +
    geom_vline( xintercept = 1979 , 
                color = med_grey_argument , 
                lty = "dotted" , 
                size = .5 ) +
    geom_point( aes( x = year , 
                     y = coef ) , 
                size = 1.25, 
                alpha = .9 ) +
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
  # Tweak labels...
  g <- g + labs( x = "Year", y = "" )  
  # Test that the GGPLOT object is not empty.
  testthat::test_that( "Test if ggplot object", {
    expect_true(is.ggplot(g))
  })
  # Return the GGPLOT object.
  return( g )
}

## ========================================================================== ##
# III. FUNCTIONS FOR MAKING PLOTS ----------------------------------------------
## ========================================================================== ##

## A. FUNCTION FOR MAKING DID INVESTMENT PLOTS ---------------------------------

# This makes the main investment plot.
make_didinvest_plot  <- function( dataset_name ,
                               outcome_keyword ){
  
  ### 1) ======== LOAD THE DATASET. ======== ### 
  
  ## Load and clean data. Filter only essentials...
  table <- regsavedataloader( dataset_name ) %>%
    
    # Filter the outcome keyword and ONLY interaction terms...
    dplyr::filter( outcome == outcome_keyword ) %>%
    dplyr::filter( grepl( "^(1o*\\.hci\\#[0-9]{4}b*\\.year)" , var ) ) %>%
    
    # Mutate variables a bit. Make into dummies
    dplyr::mutate( year = str_match( var, "[0-9]{4}") %>% as.numeric() )
    
  # Test the table is non-tempty....
  testthat::test_that( "Cleaned table is not empty", {
    expect_equal( plyr::empty( table ), FALSE ) } )
  
  
  ### 2) ======== Generate MAIN baseline GGPLOT object. ======== ###
    
  # Start with the prepared data frame....
  g <- ggplotter_didinvest(table)

  ### 3) ======== Adjust the aesthetics of GGPLOT object, g. ======== ###
  
  # Simplifying plot aesthetics. 
  g <-  g + newminimaltheme
  
  # Test that the GGPLOT object is not empty.
  testthat::test_that( "Test if ggplot object", {
    expect_true(is.ggplot(g))
  })
  return( g )
}


## ========================================================================== ##
# IV. EXECUTE FUNCTIONS AND MAKE GRID ------------------------------------------
## ========================================================================== ##

## 1. MAKE THE DID INVESTMENT PLOTS -------------------------------------------

### A. PREPARE PLOT ARGUMENTS --------------------------------------------------

# Defining arguments for data frames in the plots
regdatafilename <- "did_largerolling_mainpolicycapital_results_papermain.csv"

# Variable outcomes
listofvariables <- c( "l_costs", "l_m_n","l_inv_tot", "l_i_n", "l_stock_tot" )

#$ Outcomes labels
listofoutcomes <- c( "Intermediate Outlays" ,
                     "Intermediate Outlays\nper Worker" ,
                     "Investment", 
                     "Investment per Worker",
                     "Capital Stock")

### B. EXECUTE THE PLOT MAKER FUNCTION -----------------------------------------

# Run plot making function, loop over outcome.
gg_invest_list <- lapply( listofvariables, 
                          make_didinvest_plot,
                          dataset_name = regdatafilename ) 

# Add titles to top row.
for (i in seq_along(gg_invest_list)) {
  # Add title to each ggplot
  gg_invest_list[[i]] <- gg_invest_list[[i]] + 
    labs( title = paste0(LETTERS[i],") ", listofoutcomes[i] ))
}

## 2. MAKE GRID PLOT -----------------------------------------------------------

### A. COMBINE LIST OF PLOTS INTO PANEL ----------------------------------------
gg_invest_grid <- ggpubr::ggarrange( plotlist = gg_invest_list , 
                                     nrow = 2 , 
                                     ncol = 3 , 
                                     common.legend = TRUE, 
                                     legend	= "bottom" )

### B. MAKE FINAL PLOT ---------------------------------------------------------
gg_invest_grid <- ggpubr::annotate_figure( gg_invest_grid, 
   left = text_grob("Coefficients ( Targeted x Year )",
                    color = annotation_color ,
                    rot = 90,
                    size = font_size_argument + 4 ,
                    family = font_family_argument ) 
)

## ========================================================================== ##
# V. SAVE PLOT AND FOOTNOTE ----------------------------------------------------
## ========================================================================== ##
save_plot( gg_invest_grid, 
           "capitalplot", 
           output_dir = figures_dir,
           width = 11, 
           height = 5.5 )

save_figure_footnote( footnote_string, 
                     figures_dir, 
                     "capitalplot" )