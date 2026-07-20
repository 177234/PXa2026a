## =============================================================================
# PURPOSE:
#   Creates visualizations showing investment and protection outcomes for targeted
#   (HCI) and non-targeted industries.
#
# INPUTS:
#   - investment_binscatter.csv
#
# OUTPUTS:
#   - gg_gridinvest
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS.--------------------------------------------------
## ========================================================================== ##


## A. BASIC ARGUMENTS. ---------------------------------------------------------

# Main font, colors in setup.R

font_size_argument <- 11
footnote_string <- "\\indent Each panel plots outcomes related to investment and
protection. Points are averages across targeted (HCI) and non-targeted (non-HCI) 
industries. The top row, Panels A-C, shows outcomes related to investment incentives. 
Panel A reports mean real total capital formation across targeted and non-targeted 
industries. Panel B shows real total material costs. Note: average intermediate 
material outlays can exceed investment. Panels C and D show outcomes for trade 
policy: C reports average ad valorem tariff rates (percent), and D shows quantitative
restriction measures (QR). QR is a qualitative ranking of coverage on products 
within an industry, 0 being minimal coverage and 3 being high coverage."
footnote_string <- gsub( "\n" , " " , footnote_string )

## B. New minimal theme. -------------------------------------------------------
dodge_width <- .75
error_width <- 0

# For the main plot.
newminimaltheme <- theme( 
  panel.spacing = unit(2,"cm"), 
  plot.title = element_text(hjust = 0.5, 
                            size = font_size_argument),
  axis.title.y = element_text(size = font_size_argument),
  legend.position = "none",
  legend
)


# A. HELPER FUNCTIONS. ----------------------------------------------------


# Dataset loader for all functions
regsavedataloader <- function( dataset_name_arg ) {
  
  df <- paste0( dataset_name_arg ) %>%
    
    # Read in the data set...
    file.path( intermediate_dir , . ) %>%
    read.csv( . , header = TRUE , 
              na.strings = c( "" , "." , "NA" ) ) %>%
    as.data.frame( . )
  
  
  return( df )
}

# Data set loader plus general, small cleaner. 
regsavedataloaderandsmallcleaner <- function( dataset_name_arg ) {
  
  
  df <- paste0( dataset_name_arg )  %>%
    
    # Run the regression dataset loader...
    regsavedataloader( . ) %>%
    
    # Filter the outcome keyword and ONLY interaction terms...
    dplyr::filter( . , outcome == outcome_keyword ) %>%
    dplyr::filter( . , grepl( "^(1o*\\.hci\\#[0-9]{4}b*\\.year)" , var ) ) %>%
    
    # Mutate variables a bit. Make into dummies
    mutate(. , standarderror = ifelse( is.na( standarderror ) , "None" , 1 ) ) %>%
    mutate(. , regression_type = ifelse( is.na( regressortype ) , "Baseline FE" , "Plus Controls" ) ) 
  
  return( df )
}


## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS.--------------------------------------------------
## ========================================================================== ##


## Binscatter version of the dataset.
binscatter_graph_cleaner <- function( dataset_name , 
                                      outcome_keyword){
  
  
  ### 1) ======== LOAD AND PREP DATASET. ======== ### 
  
  # Load and clean data. Filter only essentials...
  table <- paste0( dataset_name ) %>%
  
      
  # Read in the data set...
    file.path( intermediate_dir , . ) %>%
    read.csv( . , header = TRUE, sep = "\t" ) %>%
    as.data.frame( . ) %>%
  
      
  # Filter the outcome keyword and ONLY interaction terms...
    filter( . , variable == outcome_keyword )
  
  
  # Clean year.
  table$year <- table$year %>%
    as.character( . ) %>%
    str_match( . , "[0-9]{4}") %>% 
    as.numeric( . )
  
  
  # Make sure is a datat frame and rename for further editing...
  df <- as.data.frame( table )
  

  
  ### 2) ======== LOAD AND PREP DATASET. ======== ### 
  
  
  # Get the minimum year from the dataset.
  # ... this allows us to customize dataset for 
  # ... long or short datasets.
  start_year <- min( df$year )
  start_policy <- 1972
  end_policy <- 1979
  end_year <- max( df$year ) 
  
  
  
  # Start with the prepared data frame....
  g <- df %>%
        ggplot( data = . , aes( x = year ) ) +
        geom_hline( yintercept = 0 , color = med_grey_argument, size = .25 ) +
        geom_vline( xintercept = 1972 , color = annotation_color , lty = "dashed" , size = .2) +
        geom_vline( xintercept = 1979 , color = annotation_color , lty = "dashed" , size = .2) +
        geom_line( aes( x = year , y = value, group = hci, color = as.factor(hci) ) , size = .75, alpha = 0.8) +
        geom_point( aes( x = year , y = value, group = hci, color = as.factor(hci) ) , size = 1, alpha = .9) +
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
  
  
  g <- g + scale_color_manual( values = c( annotation_color, 
                                           deep_red_argument ), 
                               labels = c("Non-Targeted Industries",
                                          "Targeted (HCI) Industries") , 
                               name = "" )
  
  g <- g + theme(axis.title.x = element_blank())
  
  # Return GGPLOT g object..  
  return( g )
}  

# Small function for grabbing distinct legend.
get_legend<-function(myggplot){
  
  tmp <- ggplot_gtable(ggplot_build(myggplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)
}

## ====================== Generate binscatter graphs. ====================== ##

## First row: INCENTIVES.
invest_4d_1 <- binscatter_graph_cleaner( "investment_binscatter.csv" , "inv_tot" )

legend <- get_legend( invest_4d_1 )

invest_4d_1 <- invest_4d_1 + labs( title = "A) Capital Investment", 
                                   y = "Value (100 ml. won)") +
  newminimaltheme


invest_4d_2 <- binscatter_graph_cleaner( "investment_binscatter.csv" , "costs" )
invest_4d_2 <- invest_4d_2 + labs( title = "B) Intermediate Outlays",
                                   y = "Value (100 ml. won)") +
  newminimaltheme


invest_4d_3 <- binscatter_graph_cleaner( "investment_binscatter.csv" , "qr" )
invest_4d_3 <- invest_4d_3 + labs( title = "C) Quantitative Restrictions",
                                   y = "QR coverage (low to high)") +
  newminimaltheme

invest_4d_4 <- binscatter_graph_cleaner( "investment_binscatter.csv" , "tariff" )
invest_4d_4 <- invest_4d_4 + labs( title = "D) Avgerage Tariff" , 
                                   y = "Value tariff rate") + 
  newminimaltheme


## ====================== Arrange binscatter graphs. ====================== ##

# Clean up the 4d.
invest_4d_1 <- invest_4d_1 + rremove("xlab") 

gg_gridinvest <- ggpubr::ggarrange(invest_4d_1,
                                   invest_4d_2,
                                   invest_4d_3,
                                   invest_4d_4,
                                   align = "hv",
                                   hjust = 1,
                                   legend = "bottom",
                                   common.legend = TRUE,
                                   nrow = 2, 
                                   ncol = 2 )

## ========================================================================== ##
# SAVE PLOT AND FOOTNOTE ---------------------------------------------------
## ========================================================================== ##

# Save plot.
save_plot( plot_object = gg_gridinvest ,
           filename = "gg_gridinvest" ,
           width = 8 ,
           height = 6 ,
           output_dir = figures_appendix_dir )

save_figure_footnote( footnote_string ,
                      output_dir = figures_appendix_dir ,
                      label = "gg_gridinvest" )

test_that("Test that plot and footnote are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_gridinvest.pdf" ) ) )
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_gridinvest.tex" ) ) )
})
