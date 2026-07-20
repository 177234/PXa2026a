## =============================================================================
# PURPOSE:
#   Creates visualizations showing dynamic differences-in-differences estimates
#   for the relationship between direct forward linkage exposure and various
#   development outcomes.
#
# INPUTS:
#   - did_io_moredev_all_results.csv
#
# OUTPUTS:
#   - gg_devlink_grid
# ==============================================================================

## ========================================================================== ##
# I. - TEXT ARGUMENTS ----------------------------------------------------------
## ========================================================================== ##

## A. BASIC ARGUMENTS. ---------------------------------------------------------
font_size_argument <- 11

footnote_string <- "This figure plots dynamic differences-in-differences 
estimates for the relationship between direct forward linkage exposure and outcomes: 
(log) employment, number of plants (plant entry), labor productivity, average wages, 
and TFP. Coefficients are estimated relative to, 1972, the year before HCI. The 
year 1979 corresponds to collapse of Park regime. Years are on the x-axis. Estimates 
for the effect of direct forward (Linkage × Year) linkages are on y-axis. Full 
sample regressions control for the main HCI × Year effect. All regressions 
include controls for direct backward linkage connections, interacted with time. 95 
percent confidence intervals are shown in gray."

footnote_string <- gsub( "\n" , " " , footnote_string )

# B. GGPLOT ARGUMENTS ----------------------------------------------------------

error_width <- 0
error_alpha <- .45

# Theme argument
newminimaltheme <- theme( 
  plot.title = element_text( size = rel(1),  
                             color = annotation_color,
                             hjust = 0.5, 
                             lineheight = 1.1 ) , 
  axis.text.x = element_text( size = rel(.85)),
  axis.text.y = element_text(size = rel(.9)),
  axis.title.x = element_blank(),
  axis.title.y = element_text(size = rel(1)),
  plot.margin = unit(c(0,4,0,0), "pt"),
  panel.grid = element_blank() ,
  panel.border = element_blank(),
  legend.background = element_blank() ,
  legend.key = element_blank() 
)
  
## ========================================================================== ##
# II. - HELPING FUNCTIONS ------------------------------------------------------
## ========================================================================== ##

## A. LOAD DATA FUNCTION -------------------------------------------------------

# Data set loader
regsavedataloader <- function( dataset_name_arg ) {
  
  df <- paste0( dataset_name_arg ) %>%
      # Read in the data set...
      file.path( intermediate_dir , . ) %>%
      read.csv( . , header = TRUE , na.strings = c( "" , "." , "NA" ) ) %>%
      as.data.frame( . )
  
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
        "est|_est" = "num. plants",
        "valueadded" = "value add.",
        "workers" = "employment",
        "_" = " ",
        "^ | $" = "")
    ) %>%
    str_to_title()
  return(cleaned_dataset)
}


## C. GG THEME SUB-FUNCTION ----------------------------------------------------

ggplotter_smallbars <- function( df ){
  
  start_year <- 1967 
  end_year <- 1986   
  
  # Make subplot.
  gsub <- ggplot( data = df , 
                  aes( x = year ) ) +
    geom_errorbar( aes( min = ci_lower , 
                        max = ci_upper),
                   alpha = error_alpha, 
                   width = error_width ) +
    geom_hline( yintercept = 0 , color = med_grey_argument, size = .2 ) +
    geom_vline( xintercept = 1972 , color = med_grey_argument , lty = "dotted" , size = .5) +
    geom_vline( xintercept = 1979 , color = med_grey_argument , lty = "dotted" , size = .5) +
    geom_point( aes( x = year , y = coef ) , size = 1, alpha = 0.9, color = annotation_color ) +
    scale_y_continuous( breaks = pretty_breaks( n = 4 )) +
    scale_x_continuous( breaks = c( start_year , 
                                    1972 , 
                                    1979 , 
                                    end_year ), 
                        labels = c( paste0( start_year ), 
                                    "1972" , 
                                    "1979", 
                                    paste0( end_year ) ) ,
                        limits = c( start_year - 1, 
                                    end_year + 1 )  
    )

  # Add blank labels to re-add.
  gsub <- gsub + labs( x = "", y = "" )

  return(gsub)
}


## ========================================================================== ##
# III. - MAIN GGPLOT FUNCTION --------------------------------------------------
## ========================================================================== ##



## This is the main function for the rolling GGPLOT graphic. 
rolling_graphs_linkage  <- function( dataset_name , 
                                      outcome_keyword , 
                                      datatype_argument, 
                                      restrictions_argument,
                                      linktype_argument){
  
  
  ### 1) ======== PREPARE DATASET ======== ###
  

  ## Load and clean data. Filter only essentials...
  table <- regsavedataloader( dataset_name ) %>%
    ## Grab/slim down data to the basics we want.
    dplyr::filter( . , grepl( "(^[0-9]{4}[bB]?\\.year\\#[coi]+\\..*hci.*)" , var ) ) %>%
    dplyr::filter(. , grepl( ".*rolling|event.*)" , didtype ) ) %>%
    dplyr::filter( . , outcome == outcome_keyword ) %>%
    dplyr::filter( . , datatype == datatype_argument ) %>%
    dplyr::filter( . , restrictions == restrictions_argument )
  
    # Generate proper link variables. Only use/in out/make language.
    table$linktype <- stringr::str_extract_all( table$var , 
                                                "(use|_in|_out|make)" , 
                                                simplify = TRUE ) 
    
    # Now last filter, based on link to show in graph
    table <- dplyr::filter( table , grepl( paste0( ".*", linktype_argument ,".*") , 
                                           linktype ) )
  
    test_that("Test that prepared data.frame is not empty", {
      expect_equal( plyr::empty( table ), FALSE ) })
  
    # Generate YEAR variable from VAR variable string. 
    table$year <- table$var %>% 
                    stringr::str_match( . , "[0-9]{4}") %>% 
                    as.numeric( . )
      
  ### 2) ======== Generate MAIN baseline GGPLOT object. ======== ###
  
  # Start with the prepared data frame....
  g <- ggplotter_smallbars( table )
  
  ### 3) ======== Adjust the aesthetics of GGPLOT object, g. ======== ###
  
  # Simplifying plot aesthetics. 
  g <- g + newminimaltheme
  return( g )
}

## B. Wrapper for the function keeps the "use" argument constant.---------------
gglinkplotwrapper <- function(x , filename , digit, sample ){
  
  rolling_graphs_linkage( dataset_name = filename , 
    outcome_keyword = x , 
    datatype_argument = digit , 
    restrictions_argument = sample ,
    linktype_argument = "use" )
}


## ========================================================================== ##
# IV. - MAKE THE PLOTS ---------------------------------------------------------
## ========================================================================== ##

## A. - SET UP ARGUMENTS -------------------------------------------------------

# Dataset
resultdatasetfile <- "did_io_moredev_all_results.csv"

# For 5d data.
listofoutcomes <- c("l_workers" ,"l_est", "l_y_n", "l_avg_wages",  "tfp_acf")

# For 4d data.
listofoutcomesnottfp <- c("l_workers" ,"l_est", "l_y_n", "l_avg_wages")


## B. RUN AND ASSEMBLE 4 AND 5 DIGIT PLOTS  ------------------------------------

# Entire sample
gglist_devoutcomes_allsample_4 <- lapply( listofoutcomesnottfp,
                                          gglinkplotwrapper ,
                                          filename = resultdatasetfile,
                                          digit = 4 ,
                                          sample = 9 )

gglist_devoutcomes_allsample_5 <- lapply( listofoutcomes,
                                          gglinkplotwrapper ,
                                          filename = resultdatasetfile,
                                          digit = 5 ,
                                          sample = 9 )
# Only non-hci sample.
gglist_devoutcomes_onlynonhci_4 <- lapply( listofoutcomesnottfp,
                                           gglinkplotwrapper ,
                                           filename = resultdatasetfile,
                                           digit = 4 ,
                                           sample = 0 )

gglist_devoutcomes_onlynonhci_5 <- lapply( listofoutcomes,
                                           gglinkplotwrapper ,
                                           filename = resultdatasetfile,
                                           digit = 5 ,
                                           sample = 0 )

## C. CLEAN AND EDIT PLOTS -----------------------------------------------------

### i. Edit titles -------------------------------------------------------------

columnlabels <- c("Full Sample",
                  "Non-Treated")

# Add padding to title.
thememargintitle <- theme( plot.title = element_text( margin( t = 2, b = 3 ) ) ,
                           plot.margin = unit( c( 3, 0, 2, 0 ), "pt" ) )

# Assign column label to first of list.
gglist_devoutcomes_allsample_4[[1]] <- gglist_devoutcomes_allsample_4[[1]] +
  labs( title = paste0("C) ", columnlabels[[1]], "\nFour-Digit Panel") )

gglist_devoutcomes_allsample_5[[1]] <- gglist_devoutcomes_allsample_5[[1]] +
  labs( title = paste0("A) ", columnlabels[[1]], "\nFive-Digit Panel") ) 

# Assign column label to first of list.
gglist_devoutcomes_onlynonhci_4[[1]] <- gglist_devoutcomes_onlynonhci_4[[1]] +
  labs( title = paste0("D) ", columnlabels[[2]], "\nFour-Digit Panel") ) 

gglist_devoutcomes_onlynonhci_5[[1]] <- gglist_devoutcomes_onlynonhci_5[[1]] +
  labs( title = paste0("B) ", columnlabels[[2]], "\nFive-Digit Panel") ) 



### ii. Edit text and variable names -------------------------------------------

## Run the cleaner function for variable names:
listofstuff <- ( listofoutcomes %>%
                   lapply( . , cleantablevariablelist_helper )  %>%
                   unlist( . ) )


# FOR first list ONLY: Add variable names.
# Which will be the first of each row:
gglist_devoutcomes_allsample_5 <- lapply( seq_along( listofoutcomes ) ,
                                          function(i)
                                            gglist_devoutcomes_allsample_5[[i]] +
                                            labs( y = paste0(listofstuff[[i]]) )
)

# Add TFPs label (simple)
gglist_devoutcomes_allsample_5[[5]] <- gglist_devoutcomes_allsample_5[[5]] + labs( y = "TFP")


## D. ASSEMBLE PLOTS INTO GRID -------------------------------------------------

# How many columns are there?:
ncolumns <- 4

# Make plot list.
gglist <- c(gglist_devoutcomes_allsample_5[1],
      gglist_devoutcomes_onlynonhci_5[1],
      gglist_devoutcomes_allsample_4[1],
      gglist_devoutcomes_onlynonhci_4[1],
      gglist_devoutcomes_allsample_5[2],
      gglist_devoutcomes_onlynonhci_5[2],
      gglist_devoutcomes_allsample_4[2],
      gglist_devoutcomes_onlynonhci_4[2],
      gglist_devoutcomes_allsample_5[3],
      gglist_devoutcomes_onlynonhci_5[3],
      gglist_devoutcomes_allsample_4[3],
      gglist_devoutcomes_onlynonhci_4[3],
      gglist_devoutcomes_allsample_5[4],
      gglist_devoutcomes_onlynonhci_5[4],
      gglist_devoutcomes_allsample_4[4],
      gglist_devoutcomes_onlynonhci_4[4],
      NULL,
      NULL,
      gglist_devoutcomes_allsample_5[5],
      gglist_devoutcomes_onlynonhci_5[5])


## ASSEMBLE graphs into grid.
gg_devlink_grid <- ggpubr::ggarrange( plotlist = gglist ,
                                     ncol = ncolumns,
                                     nrow = 5, 
                                     align = "hv" )

## ========================================================================== ##
# SAVE PLOT AND FOOTNOTE ---------------------------------------------------
## ========================================================================== ##

# Save plot.
save_plot( plot_object = gg_devlink_grid ,
           filename = "gg_devlink_grid" ,
           width = 9.5 ,
           height = 7.75 ,
           output_dir = figures_appendix_dir )

save_figure_footnote( footnote_string ,
                      output_dir = figures_appendix_dir ,
                      label = "gg_devlink_grid" )


test_that("Test that plot and footnote are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_devlink_grid.pdf" ) ) )
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_devlink_grid.tex" ) ) )
})
