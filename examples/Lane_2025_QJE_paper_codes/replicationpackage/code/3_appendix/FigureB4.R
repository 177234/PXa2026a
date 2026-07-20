## =============================================================================
# PURPOSE:
#   Creates visualizations showing semi-parametric and doubly robust differences-
#   in-differences estimates for the impact of HCI on various outcomes.
#
# INPUTS:
#   - doublyrobust_all_results.csv
#   - doublyrobust_invest_all_results.csv
#   - doublyrobust_trade_all_results.csv
#
# OUTPUTS:
#   - semidid_4digit_plot
#   - semidid_5digit_plot
#   - semidid_sitc4digit_plot
# ==============================================================================

## ========================================================================== ##
# X. SETUP. -------------------------------------------------------------------
## ========================================================================== ##

## Common text.-----------------------------------------------------------------

semiintrotext <- "\\indent This figure plots semiparametric (doubly-robust) 
differences-in-differences estimates for the impact of HCI on "

semiintrotext <- gsub( "\n", " ", semiintrotext )

semimaintext <- "Black lines are coefficient estimates from equation (3). All point estimates are 
relative to the 1972 baseline level (coefficients normalized to 0). 95% confidence bands are in gray. 
Standard errors are from a bootstrap procedure (n=10,000) and allow for within-industry correlation. 
Specifications are as close as possible to two-way fixed effects estimates from equation (1), including baseline controls. 
These include log pre-1973 industry averages: avg. wages, avg. plant size, intermediate costs, 
and labor productivity."

semimaintext <- gsub( "\n", " ", semimaintext )


## 4-digit text.----------------------------------------------------------------

notebody <- "core (log) industrial development outcomes. Log outcomes include 
real value of shipments, employment, output prices, labor productivity 
(value added per worker), mfg. share (manufacturing share of output), lab. share 
(manufacturing share of employment), and number of plants. This figure reports 
estimates for the aggregate 4-digit panel (1967-1986)."

notebody <- gsub( "\n", " ", notebody )

footnote_string1 <- paste( semiintrotext,
                        notebody , 
                        semimaintext,
                        sep = " ")

## 5-digit text.----------------------------------------------------------------

notebody <- "core (log) industrial development outcomes. Log outcomes include: 
real value of shipments, employment, output prices, labor productivity 
(value added per worker), mfg. share (manufacturing share of output), lab. share 
(manufacturing share of employment), and number of plants. This figure reports 
estimates for the more detailed 5-digit panel (1970-1986)."

notebody <- gsub( "\n", " ", notebody )

footnote_string2 <- paste( semiintrotext,
                        notebody , 
                        semimaintext,
                        sep = " ")

## TRADE text.------------------------------------------------------------------

# FOOTNOTE:
notebody <- "export development. For RCA measures, I show the normal raw 
(Balassa) index alongside log and asinh-transformed RCA. Relative export productivity 
is estimated using CDK. This figure reports estimates from 4-digit SITC panel 
data (1965-1986)."

notebody <- gsub( "\n", " ", notebody )

footnote_string3 <- paste( semiintrotext,
                        notebody , 
                        semimaintext,
                        sep = " ")


## ========================================================================== ##
# I. GGPLOT THEME --------------------------------------------------------------
## ========================================================================== ##

# Dodge width.
alpha_argument <- .425
error_width <- 0

# New minimal theme
newminimalsubtheme <- theme( 
  text = element_text( size = font_size_argument-1, 
                       color = annotation_color,
                       family = font_family_argument) ,
    panel.spacing = unit(2,"cm"), 
    plot.title = element_text(hjust = 0.5, lineheight = 1.2),
    axis.title = element_text( size = rel(1), 
                               color = annotation_color ),
    axis.text.y = element_text(size = rel(1) ) ,
    axis.text.x = element_text( size = rel(1) ) ,
    legend.position = "none",
    plot.margin = unit(c(5,5,5,5), unit = "pt")
)

## ========================================================================== ##
# II. - HELPING FUNCTIONS ------------------------------------------------------
## ========================================================================== ##

## A. LOAD DATA FUNCTION -------------------------------------------------------
regsavedataloader <- function( dataset_name_arg ) {
  
  df <- ( paste0( dataset_name_arg ) %>%
          # Read in the data set...
          file.path( intermediate_dir , . ) %>%
          read.csv( . , header = TRUE , 
                    na.strings = c( "" , "." , "NA" ) ) %>%
          as.data.frame( . ) %>%
          tidyr::as_tibble( . ) )
  
  test_that("Test that prepared data.frame is not empty", {
    expect_equal( plyr::empty( df ), FALSE ) })
  
  return( df )
}

## B. FILTER AND MAKE DATA SET FUNCTION ---------------------------------------
filterandmakedataset <- function( outcome_arg, 
                                   dataset_arg, 
                                   didtype_arg,
                                   datatype_arg) {
  # Create a dataframe by filtering and processing the input dataset
  df <- ( paste0( dataset_arg )  %>%
            # Load the regression dataset using the custom loader function
            regsavedataloader( . ) %>%
            # Filter the dataset based on input arguments
            dplyr::filter( . , outcome == outcome_arg ) %>%  # Filter by outcome
            dplyr::filter( . , didtype == didtype_arg ) %>%  # Filter by DID type
            dplyr::filter( . , dataset == datatype_arg ) %>% # Filter by dataset type
            # Convert the filtered dataframe to a tibble for easier manipulation
            tidyr::as_tibble( . ) 
          )
  # Return filtered tibble.
  return( df )
}

## ========================================================================== ##
# III. - MAIN FUNCTION FOR ROLLING GGPLOT GRAPH --------------------------------
## ========================================================================== ##
plotestimates <- function( estimate_tibble ){
  
  ## i. Annotations and arguments from estimate tibble.
  annotated_cuttoff <- 1973-1
  annotated_min_year <- as.numeric( min(estimate_tibble$year, na.rm = TRUE) )
  annotated_max_year <- as.numeric( max(estimate_tibble$year, na.rm = TRUE) )

  ## ii. Implement the ggplot, using estimate tibble and the annotations/arguments in i). 
  g <- ggplot( data = estimate_tibble, aes( group = didtype ) ) +
    geom_hline( yintercept = 0 , 
                color = med_grey_argument , 
                size = .33 , 
                alpha = .8 ) +
    scale_x_continuous( breaks = c(annotated_min_year,
                                    1972,
                                    1979,
                                    1986), 
                        limits = c(annotated_min_year, 
                                    1986) ) +
    geom_vline( aes( xintercept = annotated_cuttoff ), 
                linetype = "dotted", 
                color = med_grey_argument , 
                size = .5 ) + 
    geom_vline( aes( xintercept = 1979 ), 
                linetype = "dotted", 
                color = med_grey_argument , 
                size = .5 ) + 
    geom_point( aes( group = didtype ,
                    y = coef ,
                    x = year) , 
                color = annotation_color , 
                alpha = .9,
                size = 1.25 ) + 
    geom_errorbar( aes( group = didtype , 
                      ymin = ci_lower , 
                      ymax = ci_upper , 
                      x = year),
                  color = med_grey_argument, 
                  fill =  med_grey_argument , 
                  width = error_width , ,
                  size = .75 ,
                  alpha = alpha_argument ) +
    # Add labels after ggplot generation.
    labs( x = "" , y = "" ) +
    # Adjust x-axis limits to include space.
    coord_cartesian( xlim = c( annotated_min_year ,
                               annotated_max_year ) ,
                          clip = "off",
                          expand = TRUE )
          
    # Adjust/apply custom theme to GGPLOT object.
    g <- g + newminimalsubtheme
    
    # RETURN the ggplot object.
    return( g )
}

## ========================================================================== ##
# IV. MAKE GGPLOTS AND EXECUTE FUNCTION ----------------------------------------
## ========================================================================== ##

## 1. MAKE 4 DIGIT INDUSTRTY PLOTS ---------------------------------------------

### A. PREPARE ARGUMENTS FOR MULTIPLE PLOTS ------------------------------------

# Data
csvdatafilename <- "doublyrobust_all_results.csv"

# List of outcomes.
listofoutcomes <- c("l_ship","l_workers", "l_ppi" , 
                    "l_y_n", "l_ship_sh", "l_lab_sh" , "l_est" )

# Arguments
listofdatatype<- c("dataset4")
listofdidtype <- c("dr")


# NOW: Create argument grid for 4-digit and 5-digit regressions.
argumentgrid <- expand.grid( listofoutcomes, 
                             csvdatafilename , 
                             listofdatatype,
                             listofdidtype,
                             stringsAsFactors = FALSE )
# Make IDs
argumentgrid$id <- row.names(argumentgrid)

### B. MAKE AND RUN PLOT FUNCTIONS ---------------------------------------------

# List of tibbles.
tibble_list <- mapply( filterandmakedataset ,
                       outcome_arg = argumentgrid$Var1,
                       datatype_arg = argumentgrid$Var3,
                       didtype_arg = argumentgrid$Var4,
                       MoreArgs = list(
                         dataset_arg = csvdatafilename[1] ),
                       SIMPLIFY = FALSE,
                       USE.NAMES = TRUE )

# Note: This is output from a LAPPLY() function.
gg4digit_list <- lapply( tibble_list , 
                         plotestimates )

### C. PREPARE PLOTS -----------------------------------------------------------

# Labels of plots for grid
listofvariablelabels <- c("Output", 
                          "Employment", 
                          "Price", 
                          "Labor Prod.",
                          "Mfg. Share",
                          "Labor Share",
                          "Num. Plants" )
# Add A)...Z) to each.
listoflabels <- ( listofvariablelabels %>%
                    length( . ) %>%
                    1:. %>%
                    LETTERS[.] %>%
                    paste0( . , ") ", listofvariablelabels[1:length(listofvariablelabels)]) ) 

# Add titles and themes to each plot.
gg4digit_list <- purrr::map2( gg4digit_list, listoflabels, ~.x + ggtitle(.y) + theme(plot.title = element_text(size = font_size_argument + 1, 
                                                                                                               color = annotation_color , 
                                                                                                               hjust = 0.5)))
### D. MAKE COMBINED 4-DIGIT GRID ----------------------------------------------
semifigure_4digit <- ggpubr::ggarrange( 
    gg4digit_list[[1]] + theme( axis.ticks.x = element_blank() , 
                                axis.text.x = element_blank() ),
    gg4digit_list[[2]] + theme( axis.ticks.x = element_blank() , 
                                axis.text.x = element_blank() ),
    gg4digit_list[[3]] + theme( axis.ticks.x = element_blank() , 
                                axis.text.x = element_blank() ),
    gg4digit_list[[4]] ,
    gg4digit_list[[5]] ,
    gg4digit_list[[6]] ,
    gg4digit_list[[7]] ,
    nrow = 2, 
    ncol = 4)

## ========================================================================== ##
## 2. MAKE 5 DIGIT INDUSTRTY PLOTS ---------------------------------------------

### A. PREPARE ARGUMENTS FOR MULTIPLE PLOTS ------------------------------------

# Data
listofoutcomes <- c("l_ship","l_workers", "l_ppi" , 
                    "l_y_n", "l_ship_sh", "l_lab_sh",
                    "l_est" )

csvdatafilename <- "doublyrobust_all_results.csv"
listofdatatype<- c("dataset5")
listofdidtype <- c("dr")

# NOW: Create argument grid for 4-digit and 5-digit regressions.
argumentgrid <- expand.grid( listofoutcomes, 
                             csvdatafilename , 
                             listofdatatype,
                             listofdidtype,
                             stringsAsFactors = FALSE )
# Make IDs
argumentgrid$id <- row.names(argumentgrid)

### B. MAKE AND RUN PLOT FUNCTIONS ---------------------------------------------

# List of tibbles.
tibble_list <- mapply( filterandmakedataset ,
                       outcome_arg = argumentgrid$Var1,
                       datatype_arg = argumentgrid$Var3,
                       didtype_arg = argumentgrid$Var4,
                       MoreArgs = list(
                         dataset_arg = csvdatafilename[1] ),
                       SIMPLIFY = FALSE,
                       USE.NAMES = TRUE )

## THEN make ggplot list: pass loaded estimates to ggplot() 

# Note: This is output from a LAPPLY() function.
gg5digit_list <- lapply( tibble_list , 
                         plotestimates )

### C. PREPARE PLOTS -----------------------------------------------------------

## Labels of plots for grid
listofvariablelabels_5digit <- c( "Output", 
                                  "Employment", 
                                  "Prices", 
                                  "Labor Prod.", 
                                  "Mfg. Share", 
                                  "Labor Share" , 
                                  "Num. Plants")

# Add A)...Z) to each.
listoflabels <- ( listofvariablelabels_5digit %>%
                    length( . ) %>%
                    1:. %>%
                    LETTERS[.] %>%
                    paste0( . , ") ", listofvariablelabels_5digit[1:length(listofvariablelabels_5digit)]) ) 


# Add titles and themes to each plot.
gg5digit_list <- purrr::map2( gg5digit_list, listoflabels, ~.x + ggtitle(.y) + theme(plot.title = element_text(size = font_size_argument + 1, 
                                                                                                             color = annotation_color , 
                                                                                                             hjust = 0.5)))
### D. MAKE COMBINED 5-DIGIT GRID ----------------------------------------------
semifigure_5digit <- ggpubr::ggarrange( 
    gg5digit_list[[1]] + theme( axis.ticks.x = element_blank() , 
                                axis.text.x = element_blank()),
    gg5digit_list[[2]] + theme( axis.ticks.x = element_blank() , 
                                axis.text.x = element_blank() ),
    gg5digit_list[[3]] + theme( axis.ticks.x = element_blank() , 
                                axis.text.x = element_blank() ),
    gg5digit_list[[4]] ,
    gg5digit_list[[5]] ,
    gg5digit_list[[6]] ,
    gg5digit_list[[7]] ,
    nrow = 2,
    ncol = 4 )

## 3. MAKE SITC TRADE PLOTS ----------------------------------------------------

### A. PREPARE ARGUMENTS FOR MULTIPLE PLOTS ------------------------------------

# Data
csvdatafilename <- "doublyrobust_trade_all_results.csv"

# List of outcomes.
listofoutcomes <- c("rca_core","h_rca_core", "rca_cdk" , 
                    "rca_dummy", "export_sh","h_export_sh" )

listofdatatype<- c("tradedata")
listofdidtype <- c("dr")

# NOW: Create argument grid for 4-digit and 5-digit regressions.
argumentgrid <- expand.grid( listofoutcomes, 
                             csvdatafilename , 
                             listofdatatype,
                             listofdidtype,
                             stringsAsFactors = FALSE )

# Make IDs
argumentgrid$id <- row.names(argumentgrid)

### B. MAKE AND RUN PLOT FUNCTIONS ---------------------------------------------

# List of tibbles.
tibble_list <- mapply( filterandmakedataset ,
                       outcome_arg = argumentgrid$Var1,
                       datatype_arg = argumentgrid$Var3,
                       didtype_arg = argumentgrid$Var4,
                       MoreArgs = list(
                         dataset_arg = csvdatafilename[1] ),
                       SIMPLIFY = FALSE,
                       USE.NAMES = TRUE )

# Note: This is output from a LAPPLY() function.
ggtrade_list <- lapply( tibble_list , 
                        plotestimates )

### C. PREPARE PLOTS -----------------------------------------------------------

# Labels of plots for grid
listofvariablelabels <-c( "RCA", 
                          "RCA (asinh)", 
                          "Export Productivity (CDK)",
                          "Probability of\nComparative Advantage", 
                          "Export Share",
                          "Export Share (asinh)" )
# Add A)...Z) to each.
listoflabels <- ( listofvariablelabels %>%
                    length( . ) %>%
                    1:. %>%
                    LETTERS[.] %>%
                    paste0( . , ") ", listofvariablelabels[1:length(listofvariablelabels)]) ) 

# Add titles and themes to each plot.
ggtrade_list <- purrr::map2( ggtrade_list, listoflabels, ~.x + ggtitle(.y) + theme(plot.title = element_text(size = font_size_argument + 1, 
                                                                    color = annotation_color , 
                                                                    hjust = 0.5)))
### D. MAKE COMBINED TRADE PLOT GRID -------------------------------------------

## Create grid object with simplified labels.
semifigure_sitc4digit <- ggpubr::ggarrange( 
        ggtrade_list[[1]] + theme( axis.ticks.x = element_blank() , 
                                   axis.text.x = element_blank() ),
        ggtrade_list[[2]] + theme( axis.ticks.x = element_blank() , 
                                   axis.text.x = element_blank() ),
        ggtrade_list[[3]] + theme( axis.ticks.x = element_blank() , 
                                   axis.text.x = element_blank() ) ,
        ggtrade_list[[4]] ,
        ggtrade_list[[5]] ,
        ggtrade_list[[6]] , 
    nrow = 2 , 
    ncol = 3 )

## ========================================================================== ##
# V.ASSEMBLE AND ANNOTATE THE PLOTS FROM ABOVE (IV) ----------------------------
## ========================================================================== ##

## 1. MAKE/ANNOTATE FIGURE MAIN 4-DIGIT PLOT SEMI-PARAMETRIC FIGURE -----------
# Adjust output from plot script.
semidid_4digit_plot <- annotate_figure( semifigure_4digit,
    left = text_grob("Coefficient (Targeted x Year)",
                    color = annotation_color ,
                    rot = 90,
                    size = font_size_argument + 2,
                    family = font_family_argument ),
      bottom = text_grob("Year",
                          color = annotation_color,
                          rot = 0 ,
                          size = font_size_argument + 2,
                          family = font_family_argument ) ) 

## 2. MAKE/ANNOTATE FIGURE MAIN 5-DIGIT PLOT SEMI-PARAMETRIC FIGURE -----------
# Adjust output from plot script.
semidid_5digit_plot <- ggpubr::annotate_figure( semifigure_5digit ,
    left = text_grob("Coefficient (Targeted x Year)" ,
                      color = annotation_color ,
                      rot = 90,
                      size = font_size_argument,
                      family = font_family_argument ),
    bottom = text_grob( "Year" ,
                        color = annotation_color,
                        size = font_size_argument,
                        family = font_family_argument )) 

## 3. MAKE/ANNOTATE FIGURE SITC 4-DIGIT PLOT SEMI-PARAMETRIC FIGURE ------------
# Add semi-parametric figure from script.
semidid_sitc4_plot <- ggpubr::annotate_figure( semifigure_sitc4digit ,
    left = text_grob("Coefficient (Targeted x Year)",
                    color = annotation_color ,
                    rot = 90,
                    size = font_size_argument,
                    family = font_family_argument ),
    bottom = text_grob( "Year",
                        color = annotation_color,
                        size = font_size_argument,
                        family = font_family_argument ) ) 

## ========================================================================== ##
# VI. SAVE PLOTS AND FOOTNOTES -------------------------------------------------
## ========================================================================== ##

save_plot( plot_object = semidid_4digit_plot,
           filename = "semidid_4digit_plot",
           width = 13,
           height = 7,
           output_dir = figures_appendix_dir ) 

save_plot( plot_object = semidid_5digit_plot,
           filename = "semidid_5digit_plot",
           width = 13,
           height = 7,
           output_dir = figures_appendix_dir )   

save_plot( plot_object = semidid_sitc4_plot,
           filename = "semidid_sitc4_plot",
           width = 13,
           height = 7,
           output_dir = figures_appendix_dir ) 

save_figure_footnote( footnote_string1,
                      output_dir = figures_appendix_dir,
                      label = "semidid_4digit_plot" )

save_figure_footnote( footnote_string2,
                      output_dir = figures_appendix_dir,
                      label = "semidid_5digit_plot" )

save_figure_footnote( footnote_string3,   
                      output_dir = figures_appendix_dir,
                      label = "semidid_sitc4_plot" )

test_that("Test that plots and footnotes are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                        "semidid_4digit_plot.pdf" ) ) )
})

test_that("Test that plots and footnotes are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                        "semidid_5digit_plot.pdf" ) ) )
})

test_that("Test that plots and footnotes are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                        "semidid_sitc4_plot.pdf" ) ) )
})  