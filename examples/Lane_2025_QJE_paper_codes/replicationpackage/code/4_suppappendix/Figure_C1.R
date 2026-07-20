## =============================================================================
# PURPOSE:
#   Creates triple difference plots using UNIDO data to show the impact of HCI
#   on industrial development outcomes.
#
# INPUTS:
#   - did_largerolling_unido_all_results.csv
#
# OUTPUTS:
#   - combine_ddd_unido_figure
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS. -------------------------------------------------
## ========================================================================== ##

## TITLE: Main figure title text.
mainlatex_label <- "\\label{fig:suppappdddunido}"
mainfigure_name <- "Robustness - Triple Difference Estimations Korean HCI on Industrial Development, UNIDO Data"
dddunidotitletext <- paste0( mainlatex_label, mainfigure_name)

footertext <- "\\indent This figure shows dynamic triple difference (DDD) 
estimates using alternative data. The figure plots the main triple difference 
interaction (Treated Industry x Korea x Year) for the impact of HCI on 
ISIC 2-digit level UNIDO data. All specifications include Country-Industry, 
Country-Year, and Industry-Year effects. Estimates are relative to 1972, 
the year before the HCI policy intervention. All specifications use two-way 
clustering at the country and industry level. 95 percent confidence intervals 
are shown in light gray. Note that UNIDO data is very incomplete, expecially for
earlier years, and should be interpreted with caution; this is strictly a
robustness check."

footertext <- gsub( "\n", " ", footertext )


## A. GGPLOT ARGUMENTS ---------------------------------------------------------

# Constants
dodge_width <- 1
error_width <- 0
alpha_errorbars <- .4

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
    legend.direction = "vertical"
)


## ========================================================================== ##
# II. FUNCTIONS. ---------------------------------------------------------------
## ========================================================================== ##

# Helper function to test for non-empty data
testnonemptydata <- function(dataargument) {
  if (nrow(dataargument) == 0) {
    stop("Table contains no observations.")
  }
}

# Data set loader for all functions
regsavedataloader <- function(dataset_name_arg) {
  df <- file.path(included_dir, dataset_name_arg) %>%
    read.csv(header = TRUE, na.strings = c("", ".", "NA")) %>%
    as.data.frame()
  
  return(df)
}

# The world trade barplot separates estimates by the type of factor we factor by
ggplotter_smallbars <- function( df ) {

  start_year <- 1966
  end_year <- 1986

  ggplot2::ggplot(data = df, 
         aes(x = year )) +
    ggplot2::geom_hline(yintercept = 0, 
                color = annotation_color, 
                size = .2) +
    ggplot2::geom_vline(xintercept = c(1972, 1979), 
                color = annotation_color, 
                lty = "dashed", 
                size = .3) +
    ggplot2::geom_point(aes(x = year, 
                    y = coef), 
               size = 1.6, 
               alpha = .9, 
               position = ggplot2::position_dodge(width = dodge_width)) +
    ggplot2::geom_errorbar(aes(min = ci_lower, max = ci_upper),
                   alpha = alpha_errorbars, 
                   width = error_width, 
                   position = ggplot2::position_dodge(width = dodge_width)) +
    ggplot2::scale_x_continuous(breaks = c(start_year, 1972, 1979, end_year), 
                        labels = c(start_year, "1972", "1979", end_year),
                        limits = c(start_year-1, end_year+1))
}

# Main function for the rolling GGPLOT graphic
rolling_graphs_unido_fes <- function(dataset_name, 
                                     outcome_keyword ) {
  
  # Load and clean data
  table <- regsavedataloader(dataset_name) %>%
    dplyr::filter(outcome == outcome_keyword,
                  grepl("^(1*\\.hci\\#[0-9]{4}b*\\.year.*korea)", var))
  
  # Generate YEAR variable from VAR variable string
  table$year <- as.numeric(stringr::str_match(table$var, "[0-9]{4}"))

  # Generate main GGPLOT object
  g <- ggplotter_smallbars(table)
  
  # Adjust aesthetics
  g <- g + newminimaltheme + ggplot2::labs(x = "Year", y = "")
  
  return(g)
}

## ========================================================================== ##
## ======== III. NOW MAKE THE PLOTS, RUNNING THE GGPLOT FUNCTIONS. ========== ##
## ========================================================================== ##

# UNIDO DDD
outcome_keywords <- c( "l_workers", "l_grossout", "l_valueadded" , "l_y_n" )

gg_reghdfe_world_unido <- lapply(outcome_keywords,
                                 rolling_graphs_unido_fes,
                                 dataset_name = "did_largerolling_unido_all_results.csv")
# Add subtitles to plots
gg_reghdfe_world_unido[[1]] <- gg_reghdfe_world_unido[[1]] + ggplot2::labs(subtitle = "A) Total Employment (log)")
gg_reghdfe_world_unido[[2]] <- gg_reghdfe_world_unido[[2]] + ggplot2::labs(subtitle = "B) Gross Output (log)")
gg_reghdfe_world_unido[[3]] <- gg_reghdfe_world_unido[[3]] + ggplot2::labs(subtitle = "C) Value Added (log)")
gg_reghdfe_world_unido[[4]] <- gg_reghdfe_world_unido[[4]] + ggplot2::labs(subtitle = "D) Labor Productivity (log)")

## ========================================================================== ##
## ==== 2. ANNOTE AND ARRANGES FIGURE PLOTS FOR RENDER ====================== ##
## ========================================================================== ##

# Combine plots and make panel for plotting
combine_ddd_unido_figure <- ggpubr::ggarrange(gg_reghdfe_world_unido[[1]], 
                                              gg_reghdfe_world_unido[[2]], 
                                              gg_reghdfe_world_unido[[3]], 
                                              gg_reghdfe_world_unido[[4]],
                                              nrow = 2, 
                                              ncol = 2 )

## ========================================================================== ##
# IV. SAVE FIGURE & FOOTNOTE ----------------------------------------------------
## ========================================================================== ##

save_plot( combine_ddd_unido_figure, 
           "combine_ddd_unido_figure", 
           width = 10, 
           height = 7,
           output_dir = figures_supplementalappendix_dir)

save_figure_footnote( footertext, 
                      figures_supplementalappendix_dir, 
                      "combine_ddd_unido_figure" )


