## =============================================================================
# PURPOSE:
#   Creates dynamic differences-in-differences plots showing the relationship between
#   HCI and industrial development outcomes using a continuous measure of HCI.
#
# INPUTS:
#   - did_largerolling_continuous_4d_all_results.csv
#
# OUTPUTS:
#   - continuoustreatmentplot
# ==============================================================================

## ============================================================================ ##
# I. TEXT AND FIGURE ARGUMENTS. -------------------------------------------------
## ============================================================================ ##

## TITLE: Main figure title text.
mainlatex_label <- "\\label{fig:suppcontinuousdev}"
mainfigure_name <- "Robustness: Industrial Policy (Continuous Measure) and Industrial Development"
maintitletext <- paste0( mainlatex_label, mainfigure_name)


## FOOTNOTE: Main figure title text.

footertext <- "\\indent This figure shows dynamic differences-in-differences (DD) estimates for the relationship between HCI and industrial development outcomes (all log). HCI is now a continuous measure, measured as the share of HCI products shipped by each 4-digit industry; see Appendix for details. All outcomes are log: Shipments are the real value shipped. Labor productivity is real value added over number of workers. Employment is the number of workers. Output share is the manufacturing share of industry output. Prices are industry-level output prices. Num. Plants are the number of establishments operating in a given industry. Standard errors are clustered at the industry level. Estimates are relative to 1972, the year before the HCI policy. 1979 demarcates the end of the Park regime. Standard errors are clustered at the industry level. 95 percent confidence bars are shown."

## I. GGPLOT ARGUMENTS ---------------------------------------------------------

# Constants
dodge_width <- 0.75
error_width <- 0
alpha_errorbars <- .5

# Theme for all plots
newminimaltheme <- theme(
    plot.title = element_text(size = font_size_argument, 
                              color = annotation_color, 
                              hjust = 0.5),
    axis.title.x = element_blank(),
    panel.grid = element_blank(),
    legend.position = "bottom",
    legend.background = element_blank(),
    legend.key = element_blank()
  )

# II. - HELPING FUNCTIONS ------------------------------------------------------

## A. LOAD DATA FUNCTION -------------------------------------------------------

# Dataset loader for all functions
regsavedataloader <- function(dataset_name_arg) {
  df <- dataset_name_arg %>%
    file.path(intermediate_dir, .) %>%
    read.csv(header = TRUE, na.strings = c("", ".", "NA")) %>%
    as.data.frame()
  
  # Test that prepared data.frame is not empty.
  testthat::expect_false(plyr::empty(df), info = "Prepared data.frame is empty")
  
  return(df)
}

## B. VARIABLE CLEANING FUNCTION -----------------------------------------------

cleantablevariablelist_helper <- function(dataset_argument) {
  cleaned_dataset <- dataset_argument %>%
    stringr::str_replace_all(
      c(
        "(^h_|^l_)" = "",
        "gross[0-9]+|grossoutput" = "gross out.",
        "ship_sh" = "output share",
        "ppi" = "prices",
        "ship$" = "value shipped",
        "lab_sh" = "labor share",
        "avg_" = "avg. ",
        "y_n" = "labor prod.",
        "[ikm]_n" = "\\1 per worker",
        "est|_est" = "num. plants",
        "valueadded" = "value add.",
        "workers" = "employment",
        "costs" = "material cost",
        "_" = " ",
        "^ | $" = ""
      )
    ) %>%
    stringr::str_to_title()
  
  return(cleaned_dataset)
}

# C. Remove X-ticks and X-tick labels ------------------------------------------

simplify_xaxis <- function(ggplot_object) {
  ggplot_object + 
    ggplot2::theme(axis.text.x = ggplot2::element_blank(),
                   axis.ticks.x = ggplot2::element_blank())
}

## D. GG THEME SUB-FUNCTION ----------------------------------------------------

ggplotter_smallbarstheme <- function(df) {
  
  start_year <- 1967
  end_year <- 1986
  
  ggplot2::ggplot(data = df, ggplot2::aes(x = year)) +
    ggplot2::geom_errorbar(ggplot2::aes(min = ci_lower, max = ci_upper),
                           alpha = alpha_errorbars, 
                           width = error_width) +
    ggplot2::geom_hline(yintercept = 0, color = light_grey_argument, size = .2) +
    ggplot2::geom_vline(xintercept = 1972, color = med_grey_argument, lty = "dashed", size = .3) +
    ggplot2::geom_vline(xintercept = 1979, color = med_grey_argument, lty = "dashed", size = .3) +
    ggplot2::geom_point(ggplot2::aes(x = year, y = coef), size = 1, alpha = 0.75, color = annotation_color) +
    ggplot2::scale_x_continuous(breaks = c(start_year, 1972, 1979, end_year),
                                labels = c(paste0(start_year), "1972", "1979", paste0(end_year)),
                                limits = c(start_year, end_year)) +
    ggplot2::labs(x = "Year", y = "")
}

## ========================================================================== ##
# II. SETUP DATA ---------------------------------------------------------------
## ========================================================================== ##

## This is the main function for the rolling GGPLOT graphic. 
rolling_graphs_main <- function(dataset_name, outcome_keyword) {
  
  ### 1) ======== PREPARE DATASET ======== ### 
  
  ## Load and clean data. Filter only essentials...
  table <- regsavedataloader(dataset_name) %>%
    dplyr::filter(outcome == outcome_keyword) %>%
    dplyr::filter(grepl("^(1o*\\.hci\\#[0-9]{4}b*\\.year)|^([0-9]{4}b*\\.year.*share)", var))
  
  # Generate YEAR variable from VAR variable string. 0
  table$year <- table$var %>% 
    stringr::str_match("[0-9]{4}") %>% 
    as.numeric()
  
  # Test the table is non-empty....
  testthat::expect_false(plyr::empty(table), info = "Filtered table is empty")
  
  ### 2) ======== GENERATE FACETED PLOT ======== ###
  
  g <- ggplotter_smallbarstheme(table)
  
  ### 3) ======== Adjust the aesthetics of GGPLOT object, g. ======== ###
  
  # Simplifying plot aesthetics. 
  g + newminimaltheme
}

## ========================================================================== ##
# III. MAKE PLOTS --------------------------------------------------------------
## ========================================================================== ##

## A. Make many continuous treatment plots. ------------------------------------

# Arguments for the function.
datasetfile <- "did_largerolling_continuous_4d_all_results.csv"
listofoutcomes <- c("l_ship", "l_y_n", "l_ppi", "l_workers", "l_est", "l_ship_sh")


rolling_graphs_main(datasetfile, "l_ship" )

# Generate the plots over outcomes.
gglist_continuous <- purrr::map(listofoutcomes, 
                                ~rolling_graphs_main(datasetfile, .))

### ======== 2) EDIT GG PLOT AESTHETICS. ======== ###

# Remove figure annotations for GGARRANGE.
lengthless1 <- length(listofoutcomes) - 1
gglist_continuous[1:lengthless1] <- purrr::map(gglist_continuous[1:lengthless1], simplify_xaxis)

## Run the cleaner function for variable names:
listofstuff <- listofoutcomes %>%
  purrr::map(cleantablevariablelist_helper) %>%
  unlist()

gglist_continuous <- purrr::map2(gglist_continuous, listofstuff, 
                                 ~.x + ggplot2::labs(subtitle = .y))

### ======== 3) ARRANGE THESE INTO ONE FUNCTION. ======== ###

continuoustreatment_plot <- ggpubr::ggarrange(
  plotlist = gglist_continuous,
  ncol = 1,
  nrow = length(listofstuff)
)

## ========================================================================== ##
# IV. SAVE FIGURE & FOOTNOTE ----------------------------------------------------
## ========================================================================== ##

save_plot( continuoustreatment_plot, 
           "continuoustreatmentplot", 
           width = 6, 
           height = 8,
           output_dir = figures_supplementalappendix_dir)

save_figure_footnote( footertext, 
                      figures_supplementalappendix_dir, 
                      "continuoustreatmentplot" )
