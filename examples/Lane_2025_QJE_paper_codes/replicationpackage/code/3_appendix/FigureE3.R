## =============================================================================
# PURPOSE:
#   Creates visualizations showing dynamic differences-in-differences estimates
#   for the relationship between direct forward linkage exposure and intermediate
#   input outlays and total investment.
#
# INPUTS:
#   - did_io_mechanism_rolling_bothlink_allvars_estout.csv
#
# OUTPUTS:
#   - gg_mechanismlink_grid
# ==============================================================================

## ========================================================================== ##
# I. ARGUMENTS AND PLOT/TEXT SETTINGS -----------------------------------------
## ========================================================================== ##

## A. BASIC ARGUMENTS. ---------------------------------------------------------
font_size_argument <- 11

footnote_string <- "\\indent This figure plots dynamic differences-in-differences
 estimates for the relationship between direct forward linkage exposure and 
 outcomes: log real intermediate input outlays, and log real total investment. 
 Estimates are relative to, 1972, the year before HCI. The year 1979 corresponds to 
 collapse of Park regime. Years are on the x-axis. Estimates for the effect of 
 direct forward (Linkage $\\times$ Year) linkages are on y-axis. Full sample 
 regressions control for the main HCI $\\times$ Year effect. All regressions 
 include controls for direct backward linkage connections, interacted with time.
 95 percent confidence intervals are shown in gray."

footnote_string <- gsub( "\n" , " " , footnote_string )


## B. GGPLOT ARGUMENTS ---------------------------------------------------------

# Graphical arguments
error_width <- 0
error_alpha <- 0.5

# Dodge width.
dodge_width <- .75

# Main minimal theme.
newminimaltheme <- theme( 
    plot.title = element_text( size = rel(.9),  
                                hjust = 0.5,
                                lineheight = 1.1 ) , 
    axis.text.x = element_text( size = rel(.85) ), 
    axis.text.y = element_text( size = rel(.9) ),
    axis.title.x = element_text(size = rel(1) , 
                                lineheight = 1.15, 
                                margin = margin( t = 3, r = 0, b = 0, l = 0) ) ,                          
    axis.title.y = element_text(size = rel(.9) , 
                                lineheight = 1.15, 
                                margin = margin( t = 0, r = 5, b = 0, l = 0) ) ,
    legend.position = "bottom",
    legend.background = element_blank(),
    legend.key = element_blank()
  )

## ========================================================================== ##
# II. - HELPING FUNCTIONS ------------------------------------------------------
## ========================================================================== ##

## A. LOAD DATA FUNCTION -------------------------------------------------------

# Dataset loader for all functions
regsavedataloader <- function( dataset_name_arg ) {
  
  df <- paste0( dataset_name_arg ) %>%
    
          # Read in the data set...
          file.path( intermediate_dir , . ) %>%
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
        "(h_|l_)" = "",
        "avg_" = "avg. ",
        "[ikm]_n" = "\\1 per worker",
        "costs" = "intermediate",
        "inv_tot" = "investment",
        "_" = " ",
        "^ | $" = ""
      )
    ) %>%
  str_to_title()
  
  return(cleaned_dataset)
}

## C.Remove X-ticks and X-tick labels ------------------------------------------

simplify_xaxis <- function(ggplot_object) {
  ggplot_object + theme(axis.text.x = element_blank(),
                        axis.ticks.x = element_blank())
}

# D. GG THEME SUB-FUNCTION ----------------------------------------------------
ggplotter_smallbarstheme <- function( df ,
                                      start_year_arg = NULL,
                                      end_year_arg = NULL ){
  

  # If no start year, were equal.
  ifelse( !is.null( start_year_arg ),
          start_year <- start_year_arg , 
          start_year <- min( df$year ) )
  
  # If no start year, were equal.
  ifelse( !is.null( end_year_arg ),
          end_year <- end_year_arg , 
          end_year <- max( df$year ) )  
  
  # Make gsubplot object.
  gsub <- ggplot( data = df , 
                  aes( x = year ) ) +
    geom_errorbar( aes( min = ci_lower , 
                        max = ci_upper),
                   alpha = error_alpha, 
                   width = error_width ) +
    geom_hline( yintercept = 0 , color = med_grey_argument, size = .2 ) +
    geom_vline( xintercept = 1972 , color = med_grey_argument , lty = "dotted" , size = .3) +
    geom_vline( xintercept = 1979 , color = med_grey_argument , lty = "dotted" , size = .3) +
    geom_point( aes( x = year , y = coef ) , 
                size = 1, 
                alpha = 0.75, 
                color = annotation_color ) +
    scale_x_continuous(
      breaks = c(start_year, 1972, 1979, end_year),
      labels = c(
        ifelse(start_year == 1970, "", paste0(start_year)),  # Blank 1970
        "1972", 
        "1979", 
        paste0(end_year)
      ),
      limits = c(start_year, end_year),
      guide = guide_axis(n.dodge = 1)
    )
  
  # Add labels for later:
  gsub <- gsub + labs( x = "", y = "" )

  return(gsub)

}

# II.  LINKAGES - MAIN PLOT FUNCTIONS. -------------------------------------

rolling_graphs_linkage_main  <- function( dataset_name , 
                                          outcome_keyword , 
                                          datatype_argument, 
                                          restrictions_argument,
                                          linktype_argument){
  
  ### 1) ======== LOAD THE DATASET. ======== ### 
  
  ## Load and clean data. Filter only essentials...
  table <- regsavedataloader( dataset_name ) %>%
            dplyr::filter(grepl("^[0-9]{4}[bB]?\\.year\\#[coi]+\\..*hci.*", var)) %>%
            dplyr::filter(grepl(".*rolling|event.*", didtype)) %>%
            dplyr::filter(outcome == outcome_keyword) %>%
            dplyr::filter(datatype == datatype_argument) %>%
            dplyr::filter(restrictions == restrictions_argument)

  # Test the table is non-tempty....
  test_that( "Filtered table is not empty", {
    expect_equal( plyr::empty( table ), FALSE ) } )
  
  # Generate YEAR variable from VAR variable string. 
  table$year <- table$var %>% 
                    str_match( . , "[0-9]{4}") %>% 
                    as.numeric( . )
  
  # Generate proper link variables. Using forward/backward language.       
  table$linktype <- stringr::str_extract_all( table$var , "(use|_in|_out|make)" , simplify = TRUE ) 
  
        
  # Now last filter, based on link to show in graph
  table <- dplyr::filter( table , grepl( paste0( ".*", linktype_argument ,".*") , 
                                  linktype ) )
  
  # Test the table is non-empty....
  test_that( "Cleaned table is not empty", {
    expect_equal( plyr::empty( table ), FALSE ) } )
  
  ### 2) ======== Generate MAIN baseline GGPLOT object. ======== ###
  
  # Start with the prepared data frame....
  g <- ggplotter_smallbarstheme( table )
  
  ### 3) ======== Adjust the aesthetics of GGPLOT object, g. ======== ###
  
  # Simplifying plot aesthetics. 
  g <- g + newminimaltheme
  
  return( g )
  
}


# III. (FOR MAIN) WRAPPER FUNCTION FOR EASE. --------------------------------

# Wrapper for the function that allows us to vary things more simply.
gglinkplotwrapper <- function(x , filename , digit, sample ){
  
  rolling_graphs_linkage_main( dataset_name = filename , 
                               outcome_keyword = x , 
                               datatype_argument = digit , 
                               restrictions_argument = sample ,
                               linktype_argument = "use" )
}

# III. FORWARD LINKAGES AND MECHANISMS -----------------------------------------

## A. MAKE MECHANISM PLOTS ------------------------------------------------------

## Arguments for the function.

resultdataset <- "did_io_mechanism_all_results.csv"
listofoutcomes <- c("l_costs", "l_inv_tot" )


## Make ggplots for the mechanism outcomes.
gg_mech_allsample_4 <- lapply( listofoutcomes,
                               gglinkplotwrapper ,
                               filename = resultdataset,
                               digit = 4 ,
                               sample = 9 )

gg_mech_allsample_5 <- lapply( listofoutcomes,
                               gglinkplotwrapper ,
                               filename = resultdataset,
                               digit = 5 ,
                               sample = 9 )

gg_mech_nonhci_4 <- lapply( listofoutcomes,
                            gglinkplotwrapper ,
                            filename = resultdataset,
                            digit = 4 ,
                            sample = 0 )

gg_mech_nonhci_5 <- lapply( listofoutcomes,
                            gglinkplotwrapper ,
                            filename = resultdataset,
                            digit = 5 ,
                            sample = 0 )

## B. MAKE IO LEONTIEF MECHANISM PLOTS -----------------------------------------

## Arguments for the function.

resultdataset <- "did_iolf_mechanism_all_results.csv"
listofoutcomes <- c("l_costs", "l_inv_tot" )


## Make ggplots for the mechanism outcomes.
gg_lf_mech_allsample_4 <- lapply( listofoutcomes,
                               gglinkplotwrapper ,
                               filename = resultdataset,
                               digit = 4 ,
                               sample = 9 )

gg_lf_mech_allsample_5 <- lapply( listofoutcomes,
                               gglinkplotwrapper ,
                               filename = resultdataset,
                               digit = 5 ,
                               sample = 9 )

gg_lf_mech_nonhci_4 <- lapply( listofoutcomes,
                            gglinkplotwrapper ,
                            filename = resultdataset,
                            digit = 4 ,
                            sample = 0 )

gg_lf_mech_nonhci_5 <- lapply( listofoutcomes,
                            gglinkplotwrapper ,
                            filename = resultdataset,
                            digit = 5 ,
                            sample = 0 )

## B. EDIT MECHANISM PLOTS -----------------------------------------------------

### i. ADD TITLES TO DIRECT MECHANISM PLOTS ------------------------------------

column_labels <- c("Full Sample", "Non-Targted")

# Add titles to the plots.
gg_mech_allsample_4[[1]] <- gg_mech_allsample_4[[1]] +
  labs(title = paste0("i) ", column_labels[[1]], "\nFour-Digit Panel"))

gg_mech_allsample_5[[1]] <- gg_mech_allsample_5[[1]] +
  labs(title = paste0("iii) ", column_labels[[1]], "\nFive-Digit Panel"))

# Assign column label to first of list.
gg_mech_nonhci_4[[1]] <- gg_mech_nonhci_4[[1]] +
  labs(title = paste0("ii) ", column_labels[[2]], "\nFour-Digit Panel"))

gg_mech_nonhci_5[[1]] <- gg_mech_nonhci_5[[1]] +
  labs(title = paste0("iv) ", column_labels[[2]], "\nFive-Digit Panel"))


## Remove x-ticks and x-tick labels from all plots

# Apply the function to each ggplot object
gg_mech_allsample_4[[1]] <- simplify_xaxis( gg_mech_allsample_4[[1]] )
gg_mech_nonhci_4[[1]] <- simplify_xaxis( gg_mech_nonhci_4[[1]] )
gg_mech_allsample_5[[1]] <- simplify_xaxis( gg_mech_allsample_5[[1]] )
gg_mech_nonhci_5[[1]] <- simplify_xaxis( gg_mech_nonhci_5[[1]] )


## Run the cleaner function for variable names:
list_of_cleanedoutcomes <- lapply(listofoutcomes, 
                              cleantablevariablelist_helper) %>% 
                              unlist()


# FOR first list ONLY: Add variable names.
# Which will be the first of each row:
gg_mech_allsample_4 <- lapply(seq_along(list_of_cleanedoutcomes), function(i)
  gg_mech_allsample_4[[i]] +
    labs(y = paste0(list_of_cleanedoutcomes[[i]]))
)


### ii. ADD TITLES TO DIRECT MECHANISM PLOTS ------------------------------------

column_labels <- c("Entire Sample", "Non-HCI Only")

# Add titles to the plots.
gg_lf_mech_allsample_4[[1]] <- gg_lf_mech_allsample_4[[1]] +
  labs(title = paste0("i) ", column_labels[[1]], "\nFour-Digit Panel"))

gg_lf_mech_allsample_5[[1]] <- gg_lf_mech_allsample_5[[1]] +
  labs(title = paste0("iii) ", column_labels[[1]], "\nFive-Digit Panel"))

# Assign column label to first of list.
gg_lf_mech_nonhci_4[[1]] <- gg_lf_mech_nonhci_4[[1]] +
  labs(title = paste0("ii) ", column_labels[[2]], "\nFour-Digit Panel"))

gg_lf_mech_nonhci_5[[1]] <- gg_lf_mech_nonhci_5[[1]] +
  labs(title = paste0("iv) ", column_labels[[2]], "\nFive-Digit Panel"))


## Remove x-ticks and x-tick labels from all plots

# Apply the function to each ggplot object
gg_lf_mech_allsample_4[[1]] <- simplify_xaxis( gg_lf_mech_allsample_4[[1]] )
gg_lf_mech_nonhci_4[[1]] <- simplify_xaxis( gg_lf_mech_nonhci_4[[1]] )
gg_lf_mech_allsample_5[[1]] <- simplify_xaxis( gg_lf_mech_allsample_5[[1]] )
gg_lf_mech_nonhci_5[[1]] <- simplify_xaxis( gg_lf_mech_nonhci_5[[1]] )

## Run the cleaner function for variable names:
list_of_cleanedoutcomes <- lapply(listofoutcomes, 
                                  cleantablevariablelist_helper) %>% unlist()

# FOR first list ONLY: Add variable names.
# Which will be the first of each row:
gg_lf_mech_allsample_4 <- lapply(seq_along(list_of_cleanedoutcomes), function(i)
  gg_lf_mech_allsample_4[[i]] + labs(y = paste0(list_of_cleanedoutcomes[[i]]))
)


## C. ASSEMBLE MECHANISM PLOT GRID FOR RENDERING -------------------------------

### i. IO PLOT GRID ------------------------------------------------------------

# Assemble the grid for the mechanism plots.
gg_io_grid <- ggpubr::ggarrange( plotlist = c(gg_mech_allsample_4[1],
                  gg_mech_nonhci_4[1],
                  gg_mech_allsample_5[1],
                  gg_mech_nonhci_5[1],
                  gg_mech_allsample_4[2],
                  gg_mech_nonhci_4[2],
                  gg_mech_allsample_5[2],
                  gg_mech_nonhci_5[2]),
    heights = c(1.25, 1),
    ncol = 4,
    nrow = 2 )


# Add main title to gg_lf_mechanismlink_grid. Set the font to Palatino:
gg_io_grid <- gg_io_grid + labs(title = "Panel A) Direct Forward Linkages") +
              theme(plot.title = element_text(size = font_size_argument + 2,
                                  hjust = 0.5,
                                  margin = margin(30,5,30,5)))

### ii. LF PLOT GRID -----------------------------------------------------------

# Assemble Leontief mechanism plot grid.
gg_lf_grid <- ggpubr::ggarrange( plotlist = c(gg_lf_mech_allsample_4[1],
                                                 gg_lf_mech_nonhci_4[1],
                                                 gg_lf_mech_allsample_5[1],
                                                 gg_lf_mech_nonhci_5[1],
                                                 gg_lf_mech_allsample_4[2],
                                                 gg_lf_mech_nonhci_4[2],
                                                 gg_lf_mech_allsample_5[2],
                                                 gg_lf_mech_nonhci_5[2]),
                                    heights = c(1.25, 1),
                                    ncol = 4,
                                    nrow = 2 )


# Add main title to gg_lf_mechanismlink_grid. Set the font to Palatino:
gg_lf_grid <- gg_lf_grid + labs(title = "Panel B) Total (Leontief) Forward Linkages") +
  theme(plot.title = element_text(size = font_size_argument + 2,
                                  hjust = 0.5,
                                  margin = margin(30,5,30,5)))


### iii. COMBINE THE TWO GRIDS -------------------------------------------------

# Combine the two grids, label both plots with centered text:
gg_mechanismlink_grid <- ggpubr::ggarrange( gg_io_grid,
                                            gg_lf_grid,
                                            ncol = 1,
                                            nrow = 2 )

## ========================================================================== ##
# SAVE PLOT AND FOOTNOTE ---------------------------------------------------
## ========================================================================== ##

# Save plot.
save_plot( plot_object = gg_mechanismlink_grid ,
           filename = "gg_mechanismlink_grid" ,
           width = 11.5 ,
           height = 8.5 ,
           output_dir = figures_appendix_dir )

save_figure_footnote( footnote_string ,
                      output_dir = figures_appendix_dir ,
                      label = "gg_mechanismlink_grid" )


test_that("Test that plot and footnote are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_mechanismlink_grid.pdf" ) ) )
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_mechanismlink_grid.tex" ) ) )
})
