## =============================================================================
# PURPOSE:
#   Creates visualizations showing dynamic differences-in-differences estimates
#   for the relationship between HCI and labor productivity and output prices.
#
# INPUTS:
#   - did_priceandyn_robust_all_results.csv
#
# OUTPUTS:
#   - sidebyside
#   - productivity_sidebyside_plot
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND FIGURE ARGUMENTS. ------------------------------------------------
## ========================================================================== ##

## A. BASIC ARGUMENTS. ---------------------------------------------------------
font_size_argument <- 11

footnote_string <- "\\indent This figure plots dynamic differences-in-differences 
estimates for the relationship between HCI and labor productivity (value added 
per worker) in Panel A and output prices in Panel B. Estimates come from equation (1)
The top row shows the average outcomes for targeted (red) and non-targeted industries
(black) using the fitted model. For specifications with controls, the model is evaluated using 
means of the controls. The bottom row plots the differences-in-differences estimates. 
All estimates are relative to 1972, the year before the HCI policy. The line at 1979 demarcates 
the end of the Park regime. Standard errors are clustered at the industry level. 
95 percent confidence intervals are shown in gray."

footnote_string <- gsub( "\n" , " " , footnote_string )

## B. GGPLOT THEME --------------------------------------------------------------

# i. Minimal theme for the final plot.

# Minimal theme for the final plot.
avgs_theme_final_plot <- theme(
    text = element_text(size = font_size_argument) ,
    axis.text = element_text( color = annotation_color),
    axis.title.x = element_blank(),
    axis.title.y = element_text(color = annotation_color,
                                size = rel(.8),
                                margin = margin( l = 5, r = 10)),
    axis.text.y = element_text(size = rel(.8) ),
    axis.text.x = element_blank(),
    axis.ticks = element_line(size = .25, 
                              colour = annotation_color ),
    axis.ticks.x = element_blank(),
    strip.text.x = element_text(size = rel(1) ),
    legend.text = element_text(size = rel(.9) ),
    legend.margin = margin( t = 15 ),
    legend.background = element_blank(),
    legend.key = element_blank(),
    legend.title.position = "top",
    legend.direction = "vertical",
    legend.position = "bottom",
    panel.grid = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),

)

# Minimal theme for the DID plots.
dd_theme_final_plot <- theme(text = element_text(size = font_size_argument, 
                        color = annotation_color,
                        family = font_family_argument),
    plot.title = element_blank(),
    plot.margin = margin(-10,0,0,0),
    axis.text.y = element_text(size = rel(.8) ),
    axis.text.x = element_text(size = rel(.8) ),
    axis.ticks = element_line(size = .25, 
                              colour = annotation_color ),
    axis.title.x = element_text(size = font_size_argument - 1, 
                                color = annotation_color,
                                margin = margin( t = 15)),
    axis.title.y = element_text(size = rel(.8), 
                                color = annotation_color,
                                margin = margin( l= 5, r = 10)),
    panel.grid = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    panel.background = element_blank(), 
    panel.border = element_blank(),
    plot.background = element_blank(),
    strip.background = element_blank(),
    legend.background = element_blank(),
    legend.key = element_blank()
) 

## ========================================================================== ##
# II. HELPER FUNCTIONS. --------------------------------------------------------
## ========================================================================== ##

## ========================================================================== ##
# I. Helper function for reducing margins. ------------------------------------
clean_top_row <- function( i , gg ){
  gg[[i]] + theme( strip.text.x = element_blank() ) + 
    ggpubr::rremove("x.ticks") + 
    ggpubr::rremove("x.text") + 
    ggpubr::rremove("x.title")
}

clean_top_row_butkeeplabs <- function( i , gg ){
  gg[[i]] +
    ggpubr::rremove("x.ticks") + 
    ggpubr::rremove("x.text") + 
    ggpubr::rremove("x.title")
}

clean_bottom_row <- function( i , gg ){
  gg[[i]] + theme( strip.text.x = element_blank() )
}


## ========================================================================== ##
## 2. Helper functions for making the GGPLOT objects. --------------------------

### A. MAIN DID GGPLOT GENERATOR FUNCTION. -------------------------------------
rolling_graphs_dids <- function(dataset_name, 
                                outcome_keyword ) {
  
  ### 1) LOAD AND FILTER DATASET.
  
  # Load data set and filter data set
  table <- read.csv(file.path(intermediate_dir, dataset_name), 
                    header = TRUE, na.strings = c("", ".", "NA"))
  
  # Get min/max years
  minyear <- min( as.numeric( table$year ) , na.rm = TRUE)
  maxyear <- max( as.numeric( table$year ) , na.rm = TRUE)
  
  # Filter by outcome and get margin plots.
  table <- dplyr::filter(table, 
                         outcome == outcome_keyword & 
                         stringr::str_detect( command , "reg"))
  ### 2) Clean up the dataset.
  
  # Clean the sterr and controls.
  table$regressortype <- ifelse(is.na(table$regressortype), "Baseline", "Plus Controls")
  
  # Convert regressortype into a factor variable
  table$regressortype <- factor(table$regressortype, levels = c("Baseline", "Plus Controls"))
  
 ### 3) Generate GG PLOT.
  
  ## Run the GGPLOT() function:
  g <- ggplot( data = table, 
               aes(x = year) ) +
              geom_ribbon(aes(min = ci_lower, 
                              max = ci_upper),
                          alpha = 0.1) +
              geom_hline(yintercept = 0, color = med_grey_argument, size = .25) +
              geom_vline(xintercept = 1972, color = annotation_color, lty = "dashed", size = .2) +
              geom_vline(xintercept = 1979, color = annotation_color, lty = "dashed", size = .2) +
              geom_line(aes(x = year, y = coef), size = 1, alpha = 0.75, color = annotation_color) +
              scale_x_continuous(breaks = c(minyear, 1972, 1979, 1986), 
                                 labels = c(paste0(minyear), "1972", "1979", "1986"),
                                 limits = c(minyear, 1986)) + 
              facet_wrap(vars(regressortype), scales = "free_y") +
              theme_minimal() 
    
    # Apply theme
    g <- g + dd_theme_final_plot
  
    # Further customize
    g <- g + labs(y = "Estimated differences\n(Coefficients)",
                  x = "Year" )
  
  ### 4) Return GGPLOT g object..  
  return(g)
}


### B. Margins GGPLOT GENERATOR FUNCTION. --------------------------------------

## This is the main function for the rolling GGPLOT graphic. 
rolling_graphs_margins <- function( dataset_name , 
                                     outcome_keyword){
  
  #### 1) LOAD AND FILTER DATASET.
  
  # Load data set and filter dataset
  table <- read.csv(file.path(intermediate_dir, dataset_name), 
                    header = TRUE, na.strings = c("", ".", "NA"))
  
  ## Grabbing year parameters before filtering dataset.

  # Get min/max years
  minyear <- min( as.numeric( table$year ) , na.rm = TRUE)
  maxyear <- max( as.numeric( table$year ) , na.rm = TRUE)
  
  
  # Filter by outcome and get margin plots.
  table <- dplyr::filter(table, 
                         outcome == outcome_keyword & 
                         stringr::str_detect( command , "margins"))
  
  ### 2) Clean up the dataset.
 
  # Clean the sterr and controls.
  table$regressortype <- ifelse(is.na(table$regressortype), "Baseline", "Plus Controls")
  
  # Convert regressortype into a factor variable
  table$regressortype <- factor(table$regressortype, levels = c("Baseline", "Plus Controls"))
  

  
  ### 3) Adjust GGPLOT main aesthetics. Apply standards.
  
  
  ## Run the GGPLOT() function:
  h <- ggplot( data = table , aes( x = year, group = hci ) ) +
                        geom_vline( xintercept = 1972 , 
                        color = annotation_color , 
                        lty = "dashed" , 
                        size = .2) +
            geom_vline( xintercept = 1979 , 
                        color = annotation_color , 
                        lty = "dashed" , 
                        size = .2) +
            geom_line( aes( x = year , 
                            y = coef , 
                            color = as.factor(hci) ) , 
                       size = 1, alpha = 0.8) +
            scale_x_continuous( breaks = c( minyear , 1972 , 1979 , 1986 ), 
                                labels = c(paste(minyear), "1972" , "1979", "1986" ) ,
                                limits = c( minyear , maxyear ) ) + 
            facet_wrap( vars(regressortype), scales = "free_y" ) +
            xlab("") +
            theme_minimal()
  
  # Apply theme
  h <- h + dd_theme_final_plot
            
  # Further customize
  h <- h + scale_color_manual(values = c(annotation_color, deep_red_argument), 
                       labels = c("Non-Targeted Industries", 
                                  "Targeted (HCI) Industries"),
                       name = "Legend for top row") +
    labs(y = "Average log output\n(Fitted value)")
  ### 4) Return GGPLOT g object..  
  return( h ) 
}

## ========================================================================== ##
## ======= III. GENERATE ROLLING GRAPHICS FUNCTION: DID AND AVERAGES. ======= ##
## ========================================================================== ##

### ====================== 1. MAKE MAIN GGPLOTS. ========================= ###

## Defining arguments for dataframes in the plots.
intermediate_dirfilename <- "did_priceandyn_robust_all_results.csv"
regressionoutcomelist <- c( "l_ppi" , "l_y_n" )

## Label arguments in the multi-plot
reducingmarginbetweenplots <- -.85

### =========== A) Create the GG graphs for extra outcomes =========== ### 

## Render fit plots - 5-digit
gg_fit_list <- lapply( regressionoutcomelist , 
                          rolling_graphs_margins,
                          dataset_name = intermediate_dirfilename )

### Make DID plots for the BOTTOM ROW.
gg_did_list <- lapply( regressionoutcomelist , 
                          rolling_graphs_dids,
                          dataset_name = intermediate_dirfilename )

### ================== B) Render the graphs into GG plots. ================== ### 

# Add titles with increased bottom margin
gg_fit_list[[2]] <- gg_fit_list[[2]] + labs(title = "Panel A) Labor Productivity") + 
  theme(
    plot.title = element_text(size = font_size_argument, 
                              color = annotation_color, 
                              hjust = 0.5, 
                              margin = margin(b = 10)),
    plot.margin = margin(t = 5, r = 5, b = 5, l = 5)
  )

gg_fit_list[[1]] <- gg_fit_list[[1]] + labs(title = "Panel B) Output Price") + 
  theme(
    plot.title = element_text(size = font_size_argument, 
                              color = annotation_color, 
                              hjust = 0.5, 
                              margin = margin(b = 10)),
    plot.margin = margin(t = 5, r = 5, b = 5, l = 5)
  )


productivity_sidebyside_plot <- ggpubr::ggarrange( 
      gg_fit_list[[2]], 
      gg_fit_list[[1]] + ylab(""), 
      gg_did_list[[2]],
      gg_did_list[[1]] + ylab(""),
      nrow = 2, ncol = 2,
      align = "hv", 
      common.legend = TRUE,
      legend = "bottom"
)

productivity_sidebyside_plot <- productivity_sidebyside_plot +
  theme(plot.margin = margin(t = 50, r = 10, b = 10, l = 10, unit = "pt"))

## ========================================================================== ##
# IV. SAVE PLOT AND FOOTNOTE ---------------------------------------------------
## ========================================================================== ##

# Save plot.
save_plot( plot_object = productivity_sidebyside_plot ,
           filename = "appendixproductivityprices" ,
           width = 12 ,
           height = 8 ,
           output_dir = figures_appendix_dir )

save_figure_footnote( footnote_string ,
                      output_dir = figures_appendix_dir ,
                      label = "appendixproductivityprices" )

test_that("Test that plot and footnote are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                        "appendixproductivityprices.pdf" ) ) )
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                        "appendixproductivityprices.tex" ) ) )
})
