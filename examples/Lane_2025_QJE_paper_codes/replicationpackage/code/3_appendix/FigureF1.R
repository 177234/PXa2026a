## =============================================================================
# PURPOSE:
#   Creates visualizations showing dynamic differences-in-differences estimates
#   for the relationship between direct backward linkage exposure and log real
#   value added.
#
# INPUTS:
#   - did_io_main_all_results.csv
#
# OUTPUTS:
#   - gg_backwardlink_grid
# ==============================================================================

## ========================================================================== ##
# I. ARGUMENTS AND PLOT/TEXT SETTINGS -----------------------------------------
## ========================================================================== ##

## A. BASIC ARGUMENTS. ---------------------------------------------------------
font_size_argument <- 11

footnote_string <- "\\indent This figure plots dynamic differences-in-differences
estimates for the relationship between direct backward linkage exposure and outcomes: 
log real value added. Estimates are relative to, 1972, the year before HCI. The year 1979 corresponds to 
collapse of Park regime. Years are on the x-axis. Estimates for the effect of 
direct backward (Linkage $\\times$ Year) linkages are on y-axis. Full sample 
regressions control for the main HCI $\\times$ Year effect. All regressions 
include controls for direct forward linkage connections, interacted with time. 
95 percent confidence intervals are shown in gray."

footnote_string <- gsub( "\n" , " " , footnote_string )

## B. GGPLOT ARGUMENTS ---------------------------------------------------------

# Graphical arguments
error_width <- 0
error_alpha <- .5

# Aesthetics for the main output plot at end. Using gg theme().
newminimaltheme <- ggplot2::theme(
  plot.title = ggplot2::element_text(size = rel(1), hjust = 0.5),
  axis.text.x = ggplot2::element_text(size = rel(1)),
  axis.text.y = ggplot2::element_text(size = rel(1)),
)

## ========================================================================== ##
# II. - HELPING FUNCTIONS ------------------------------------------------------
## ========================================================================== ##

## A. LOAD DATA FUNCTION -------------------------------------------------------

#' Load regression data from CSV file
#'
#' @param dataset_name_arg Name of the dataset file
#' @return A data frame containing the loaded data
#' @importFrom dplyr %>%
regsavedataloader <- function(dataset_name_arg) {
  df <- file.path(intermediate_dir, dataset_name_arg ) %>%
          utils::read.csv(., header = TRUE, na.strings = c("", ".", "NA")) %>%
          as.data.frame()
        
  testthat::test_that("Prepared data.frame is not empty", {
    testthat::expect_false(plyr::empty(df))
  })
  
  return(df)
}

## B. GG THEME SUB-FUNCTION ----------------------------------------------------

#' Create a small bar plot for linkage data
#'
#' @param df Data frame containing the plot data
#' @param start_year_arg Optional start year for x-axis
#' @param end_year_arg Optional end year for x-axis
#' @return A ggplot object
#' @importFrom dplyr %>%
ggplotter_smallbars <- function(df, start_year_arg = NULL, end_year_arg = NULL) {
  start_year <- if (!is.null(start_year_arg)) start_year_arg else min(df$year)
  end_year <- if (!is.null(end_year_arg)) end_year_arg else max(df$year)
  
  ggplot2::ggplot(data = df, ggplot2::aes(x = year)) +
    ggplot2::geom_errorbar(ggplot2::aes(min = ci_lower, max = ci_upper),
                  alpha = error_alpha, width = error_width) +
    ggplot2::geom_hline(yintercept = 0, color = light_grey_argument, size = .2) +
    ggplot2::geom_vline(xintercept = 1972, color = med_grey_argument, linetype = "dashed", size = .3) +
    ggplot2::geom_vline(xintercept = 1979, color = med_grey_argument, linetype = "dashed", size = .3) +
    ggplot2::geom_point(ggplot2::aes(x = year, y = coef), 
                size = 1, alpha = 0.75, color = annotation_color) +
    ggplot2::scale_x_continuous(breaks = c(start_year, 1972, 1979, end_year), 
                       labels = c(paste0(start_year), "1972", "1979", paste0(end_year)),
                       limits = c(start_year, end_year)) +
    ggplot2::labs(x = "", y = "")
}

## III. MAIN FUNCTION: MAKE LINKAGE PLOT FROM DATASET --------------------------

#' Create a rolling graph for linkage analysis
#'
#' @param dataset_name Name of the dataset file
#' @param outcome_keyword Keyword for the outcome variable
#' @param datatype_argument Argument for data type
#' @param restrictions_argument Argument for restrictions
#' @param linktype_argument Argument for link type
#' @return A ggplot object
#' @importFrom dplyr %>%
rolling_graphs_linkage_main <- function(dataset_name, outcome_keyword, datatype_argument, 
                                        restrictions_argument, linktype_argument) {
  # Load and clean data
  table <- regsavedataloader(dataset_name) %>%
    dplyr::filter(grepl("^[0-9]{4}[bB]?\\.year\\#[coi]+\\..*hci.*", var)) %>%
    dplyr::filter(grepl(".*rolling|event.*", didtype)) %>%
    dplyr::filter(outcome == outcome_keyword) %>%
    dplyr::filter(datatype == datatype_argument) %>%
    dplyr::filter(restrictions == restrictions_argument) %>%
    dplyr::mutate(year = as.numeric(stringr::str_match(var, "[0-9]{4}")))
  
  # Generate proper link variables
  table$linktype <- stringr::str_extract_all(table$var, "(use|_in|_out|make)", simplify = TRUE)
  
  # Filter based on link type
  table <- dplyr::filter(table, grepl(paste0(".*", linktype_argument, ".*"), linktype))
  
  testthat::test_that("Cleaned table is not empty", {
    testthat::expect_false(plyr::empty(table))
  })
  
  # Generate and return the ggplot object
  ggplotter_smallbars(table) + newminimaltheme
}

## IV. WRAPPER FUNCTION --------------------------------------------------------

#' Wrapper function for creating linkage plots
#'
#' @param x Outcome keyword
#' @param filename Dataset filename
#' @param digit Data type argument
#' @param sample Restrictions argument
#' @return A ggplot object
gglinkplotwrapper <- function(x, filename, digit, sample) {
  rolling_graphs_linkage_main(dataset_name = filename, 
                              outcome_keyword = x, 
                              datatype_argument = digit, 
                              restrictions_argument = sample,
                              linktype_argument = "make")
}

## V. BACKWARD LINKAGES AND OUTPUT ---------------------------------------------

# Arguments for plots
datasetname <- "did_io_main_all_results.csv"
outcome <- "l_valueadded"

## A. MAKE OUTPUT PLOTS --------------------------------------------------------

# ASSEMBLE GGPLOTS
gg_backva_allsample_4 <- gglinkplotwrapper(outcome, filename = datasetname, digit = 4, sample = 9)
gg_backva_allsample_5 <- gglinkplotwrapper(outcome, filename = datasetname, digit = 5, sample = 9)
gg_backva_nonhci_4 <- gglinkplotwrapper(outcome, filename = datasetname, digit = 4, sample = 0)
gg_backva_nonhci_5 <- gglinkplotwrapper(outcome, filename = datasetname, digit = 5, sample = 0)

## B. EDIT PLOTS ---------------------------------------------------------------

columnlabels <- c("Full Sample", "Non-Targeted Only")

# Add titles to the plots
gg_backva_allsample_4 <- gg_backva_allsample_4 +
  ggplot2::labs(title = paste0("A) ", columnlabels[1], ", Four-Digit Panel"))

gg_backva_nonhci_4 <- gg_backva_nonhci_4 +
  ggplot2::labs(title = paste0("B) ", columnlabels[2], ", Four-Digit Panel"))

gg_backva_allsample_5 <- gg_backva_allsample_5 +
  ggplot2::labs(title = paste0("C) ", columnlabels[1], ", Five-Digit Panel"))

gg_backva_nonhci_5 <- gg_backva_nonhci_5 +
  ggplot2::labs(title = paste0("D) ", columnlabels[2], ", Five-Digit Panel"),
       x = "Year")

## C. ASSEMBLE GRAPHS INTO GRID ------------------------------------------------

gg_backwardlink_grid <- ggpubr::ggarrange(gg_backva_allsample_4, 
                                    gg_backva_nonhci_4,
                                    gg_backva_allsample_5, 
                                    gg_backva_nonhci_5,
                                    nrow = 4, 
                                    ncol = 1)

gg_backwardlink_grid <- ggpubr::annotate_figure(gg_backwardlink_grid, 
                          left = text_grob("Coefficient (Backward Linkage x Year)\n", 
                                           size = font_size_argument+1, 
                                           color = annotation_color,
                                           rot = 90,
                                           hjust = 0.5,
                                           family = font_family_argument))

## ========================================================================== ##
# SAVE PLOT AND FOOTNOTE ---------------------------------------------------
## ========================================================================== ##

# Save plot.
save_plot( plot_object = gg_backwardlink_grid ,
           filename = "gg_backwardlink_grid" ,
           width = 10 ,
           height = 7.5 ,
           output_dir = figures_appendix_dir )

save_figure_footnote( footnote_string ,
                      output_dir = figures_appendix_dir ,
                      label = "gg_backwardlink_grid" )


test_that("Test that plot and footnote are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_backwardlink_grid.pdf" ) ) )
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "gg_backwardlink_grid.tex" ) ) )
})
