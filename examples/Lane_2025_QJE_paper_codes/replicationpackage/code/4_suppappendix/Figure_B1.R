## =============================================================================
# PURPOSE:
#   Creates dynamic/event study micro TFP plot for appendix showing the relationship
#   between HCI and total factor productivity using plant-level data.
#
# INPUTS:
#   - did_largerolling_results_microtfp_all_results.csv
#
# OUTPUTS:
#   - tfpmicrodynamic
# ==============================================================================

# Load required libraries
library(viridis)

## ========================================================================== ##
# I. TEXT AND FIGURE ARGUMENTS. -------------------------------------------------
## ========================================================================== ##

## TITLE: Main figure title text.
mainlatex_label <- "\\label{fig:suppappendixmicrotfp}"
mainfigure_name <- "Robustness: Plant-Level Productivity Dynamics, Post-HCI (1980-1986)"
robustdynamictfp <- paste0( mainlatex_label,
                            mainfigure_name)

footertext <-  "\\indent This figure shows the relationship between HCI and total factor productivity using plant-level data for the post-1979 period. The coefficients in the figure are estimated from the plant-level DD regressions, with 1980 as the omitted year. TFP outcomes are estimated using Ackerberg-Caves-Frazer (ACF), Levinsohn-Petrin (LP), Olley-Pakes (OP), Wooldridge (W) methods, as well as baseline OLS using the Solow residual. Log-transformed production functions are structurally estimated for 4-digit industry. Two-way standard errors are clustered at the industry and plant level. Bars show 95 percent confidence intervals."

## A. GGPLOT ARGUMENTS ---------------------------------------------------------

# Constants
dodge_width <- 0.95
error_width <- 0
alpha_errorbars <- 0.5

# Theme for all plots
newminimaltheme <- ggplot2::theme_minimal() +
  ggplot2::theme(
    text = ggplot2::element_text(size = font_size_argument),
    plot.title = ggplot2::element_text(size = font_size_argument, 
                                     hjust = 0.5),
    axis.text = ggplot2::element_text(size = font_size_argument, hjust = 0 ),
    axis.text.x = ggplot2::element_text(vjust = .5, hjust = 0.5, angle = 0, 
                                      color = annotation_color, 
                                      size = rel(.9)),
    axis.title.x = ggplot2::element_blank(),
    panel.grid = ggplot2::element_blank(),
    legend.position = "bottom",
    legend.background = ggplot2::element_blank(),
    legend.direction = "horizontal",
    legend.key = ggplot2::element_blank()
  )


## ========================================================================== ##
# II. SETUP DATA ---------------------------------------------------------------
## ========================================================================== ##

## A. DATA LOADER --------------------------------------------------------------
regdataloader <- function(dataset_name_arg) {
  df <- dataset_name_arg %>%
    file.path(included_dir, .) %>%
    utils::read.csv(header = TRUE, na.strings = c("", ".", "NA"))
  
  testthat::test_that("Test that prepared data.frame is not empty", {
    testthat::expect_false(plyr::empty(df))
  })
  
  return(df)
}

## B. GG PLOT THEME ------------------------------------------------------------

# Small bar theme specifically for post-1980 TFP.
ggplotmakertfp_withdodge <- function(df) {
  start_year <- 1979
  end_year <- 1987
  
  g <- ggplot2::ggplot(data = df, 
                  aes(x = year, group = outcome, color = outcome)) +
    ggplot2::geom_hline(yintercept = 0, color = light_grey_argument, size = .3) +
    ggplot2::geom_vline(xintercept = 1979, color = med_grey_argument, 
                        lty = "dashed", size = .3) +
    ggplot2::geom_point(aes(x = year, y = coef, shape = outcome, 
                            color = outcome, fill = outcome), 
                        size = 1.75, alpha = 0.90, 
                        position = ggplot2::position_dodge(width = dodge_width)) +
    ggplot2::geom_errorbar(aes(min = ci_lower, 
                               max = ci_upper),
                           alpha = alpha_errorbars, 
                           width = error_width, 
                           position = ggplot2::position_dodge(width = dodge_width)) +
    ggplot2::scale_x_continuous(breaks = c(start_year, 1979, end_year), 
                                labels = c(start_year, "1979", end_year),
                                limits = c(start_year - 1, end_year + 1))
  return(g)
}

## ========================================================================== ##
# III. MAKE PLOTS --------------------------------------------------------------
## ========================================================================== ##

## A. LOAD AND PREPARE DATA ----------------------------------------------------

dataset_name <- "did_largerolling_results_microtfp_all_results.csv"

# Load and clean data
table <- regdataloader(dataset_name) %>%
  dplyr::filter(grepl("^(1o*\\.hci\\#[0-9]{4}b*\\.year)", var)) %>%
  dplyr::mutate(year = as.numeric(stringr::str_match(var, "[0-9]{4}")[,1]))

testthat::test_that("Test that prepared data.frame is not empty", {
  testthat::expect_false(plyr::empty(table))
})

## B. MAKE PLOT ----------------------------------------------------------------

g <- ggplotmakertfp_withdodge(table)

## C. ADDITIONAL PLOT AESTHETICS -----------------------------------------------

g <- g + 
newminimaltheme +
  viridis::scale_color_viridis(discrete = TRUE, end = .7, option = "mako")

# Final plot
gg_micro_tfp_figure <- g + ggplot2::labs(
  x = "Year", y = "",
  color = "TFP Estimate Type",
  shape = "TFP Estimate Type",
  fill = "TFP Estimate Type"
)

## ========================================================================== ##
# IV. SAVE FIGURE & FOOTNOTE ----------------------------------------------------
## ========================================================================== ##

save_plot( gg_micro_tfp_figure, 
           "tfpmicrodynamic", 
           width = 8, 
           height = 5,
           output_dir = figures_supplementalappendix_dir)

save_figure_footnote( footertext, 
                      figures_supplementalappendix_dir, 
                      "tfpmicrodynamic" )
                                      
                                    



