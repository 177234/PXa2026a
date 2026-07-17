# Annotated copy for replication audit.
# Original script: Lane2025QJE/replicationpackage/code/1_figures/Figure2.R
# Purpose: Generates Figure 2.
#
# This file intentionally keeps the original .R extension.
# The original code is copied below. Comments in this header identify the
# script role, inputs, outputs, and audit linkage. The earlier prose note is
# archived at: markdown_notes_archive/Figure2_R.md
#
# Audit linkage:
# - Methods report: explains the estimating or output logic.
# - Derivation report: maps equations/design objects to code.
# - Replication report: documents inputs, outputs, and reproducibility limits.
#
# Original code begins after this header.

## =============================================================================
# PURPOSE:
#   Creates dynamic differences-in-differences graphs and averages from regression
#   analysis for output analysis.
#
# INPUTS:
#   - "did_largerolling_mainresults_alloutput_all_results.csv" (5-digit panel results)
#   - "did_largerolling_mainresults_alloutput_4d_all_results.csv" (4-digit panel results)
#
# OUTPUTS:
#   - gg_output (Combined ggplot object for rendering)
# ==============================================================================

## =============================================================================
# I. TEXT AND PLOT ARGUMENTS --------------------------------------------------
## =============================================================================

## ========================================================================== ##
# X. TEXT FOR THE FOOTNOTE. ----------------------------------------------------
## ========================================================================== ##

footnote_string <- "\\indent This figure shows the dynamic differences-in-differences 
estimates for the relationship between HCI and output, measured as (log) real value 
of gross output shipped. Coefficients in the plot are estimated using equation 
\\eqref{eq:mainflexible}. The bottom row shows dynamic DD estimates: Panel A corresponds 
to estimates for the detailed (short) 5-digit level panel. Panel B corresponds to estimates 
for the aggregate (long) 4-digit level panel. 'Baseline' columns are baseline two-way 
fixed effects regressions, and 'Plus Controls' columns include pre-treatment controls. 
The top row shows the predicted outcomes of the fitted model to show group-specific 
trends; lines correspond to predicted values for treated and control industries for 
each point in time before and after 1972. For specifications with controls, predictions 
use the mean values of the controls. All estimates are relative to 1972, the year 
before the HCI policy. 1979 demarcates the end of the Park regime. Standard errors are 
clustered at the industry level. 95 percent confidence intervals are shown in gray."

footnote_string <- gsub( "\n", " ", footnote_string )

## ========================================================================== ##
# I. ARGUMENTS AND PLOT/TEXT SETTINGS -----------------------------------------
## ========================================================================== ##

.

## A. BASIC ARGUMENTS. ---------------------------------------------------------
# Main font, colors in setup.R

## B. GGPLOT ARGUMENTS ---------------------------------------------------------

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
    axis.ticks = element_line(size = .25),
    axis.ticks.x = element_blank(),
    strip.text.x = element_text(size = rel(1) ),
    legend.text = element_text(size = rel(.9) ),
    legend.margin = margin( t = 15 ),
    legend.background = element_blank(),
    legend.key = element_blank(),
    legend.title.position = "top",
    legend.direction = "horizontal",
    legend.position = "bottom",
    panel.grid = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank()
)


# Minimal theme for the DID plots.
dd_theme_final_plot <- theme(text = element_text(size = font_size_argument, 
                        color = annotation_color,
                        family = font_family_argument),
    plot.title = element_blank(),
    plot.margin = margin(-10,0,0,0),
    axis.text = element_text( color = annotation_color),
    axis.text.y = element_text(size = rel(.8) ),
    axis.text.x = element_text(size = rel(.8) ),
    axis.ticks = element_line(size = .25),
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
# II. FUNCTIONS. ---------------------------------------------------------------
## ========================================================================== ##


## 1. Main GGPLOT functions. ---------------------------------------------------


### A. Main averages plot function. --------------------------------------------
# TOP ROW

# Main averages plot function
rolling_graphs_avgs <- function(dataset_name, outcome_keyword) {
  
  # Load data
  table <- read.csv(file.path(intermediate_dir, dataset_name), 
                    header = TRUE, na.strings = c("", ".", "NA"))
  
  # Process data
  minyear <- min(as.numeric(table$year), na.rm = TRUE)
  maxyear <- max(as.numeric(table$year), na.rm = TRUE)
  
  table <- dplyr::filter(table, 
                         outcome == outcome_keyword & 
                         stringr::str_detect(command, "margins"))
  
  table$regressortype <- ifelse(is.na(table$regressortype), "Baseline", "Controls")
  table$regressortype <- factor(table$regressortype, levels = c("Baseline", "Controls"))
  
  test_that("Test that prepared data.frame is not empty", {
    expect_equal(plyr::empty(table), FALSE)
  })
  
  # Generate plot
  g <- ggplot(data = table, aes(x = year, group = hci)) +
    geom_vline(xintercept = 1972, color = med_grey_argument, lty = "dashed", size = .25) +
    geom_vline(xintercept = 1979, color = med_grey_argument, lty = "dashed", size = .25) +
    geom_line(aes(x = year, y = coef, color = as.factor(hci)), size = 1, alpha = 0.8) +
    scale_x_continuous(breaks = c(minyear, 1972, 1979, 1986), 
                       labels = c(paste(minyear), "1972", "1979", "1986"),
                       limits = c(minyear, maxyear)) + 
    facet_wrap(vars(regressortype),scales = "free_y") +
    avgs_theme_final_plot

  g <- g + scale_color_manual(values = c(annotation_color, deep_red_argument), 
                       labels = c("Non-Targeted Industries", 
                                  "Targeted (HCI) Industries"),
                       name = "Legend for top row") +
    labs(y = "Average log output\n(Fitted values)")
    
  
  return(g)
}


### B. Main DID plot functions. ------------------------------------------------

# BOTTOM ROW
rolling_graphs_dids <- function(dataset_name, outcome_keyword) {
  
  # Load data
  table <- read.csv(file.path(intermediate_dir, dataset_name), 
                    header = TRUE, na.strings = c("", ".", "NA"))
  
  # Process data
  minyear <- min(as.numeric(table$year), na.rm = TRUE)
  maxyear <- max(as.numeric(table$year), na.rm = TRUE)
  
  table <- dplyr::filter(table, 
                         outcome == outcome_keyword & 
                           stringr::str_detect(command, "xtdidregress"))
  
  table$regressortype <- ifelse(is.na(table$regressortype), "Baseline", "Controls")
  table$regressortype <- factor(table$regressortype, levels = c("Baseline", "Controls"))
  
  
  test_that("Test that prepared data.frame is not empty", {
    expect_equal(plyr::empty(table), FALSE)
  })
  
  # Generate plot
  g <- ggplot(data = table, aes(x = year)) +
        geom_ribbon(aes(min = ci_lower, max = ci_upper), alpha = 0.1) +
        geom_hline(yintercept = 0, color = med_grey_argument, size = .25) +
        geom_vline(xintercept = 1972, color = med_grey_argument, lty = "dashed", size = .25) +
        geom_vline(xintercept = 1979, color = med_grey_argument, lty = "dashed", size = .25) +
        geom_line(aes(x = year, y = coef), size = 1, alpha = 0.75, color = annotation_color) +
        scale_x_continuous(breaks = c(minyear, 1972, 1979, 1986), 
                          labels = c(paste0(minyear), "1972", "1979", "1986"),
                          limits = c(minyear, 1986)) + 
        facet_wrap(vars(regressortype),scales = "free_y") +
        dd_theme_final_plot

  # Further customize
  g <- g + labs(y = "Estimated differences\n(Coefficients)",
         x = "Year" )

  return(g)
}



## ========================================================================== ##
# III. EXECUTE FUNCTIONS TO MAKE PLOT. -----------------------------------------
## ========================================================================== ##

## A. ARGUMENTS. ---------------------------------------------------------------  

# Define input files and outcome variable
csvdataset_5d <- "did_largerolling_mainresults_alloutput_all_results.csv"
csvdataset_4d <- "did_largerolling_mainresults_alloutput_4d_all_results.csv"
outcomevariable <- "l_ship"

## B. EXECUTE FUNCTIONS. -------------------------------------------------------

# Generate plots
g1 <- rolling_graphs_avgs(csvdataset_5d, outcomevariable)
h1 <- rolling_graphs_dids(csvdataset_5d, outcomevariable)

# Generate plots
g2 <- rolling_graphs_avgs(csvdataset_4d, outcomevariable)
h2 <- rolling_graphs_dids(csvdataset_4d, outcomevariable)

## C. ADJUST PLOTS. ------------------------------------------------------------

# Top row
g1 <- g1 + theme(plot.margin = margin(0,5,20,0))
g2 <- g2 + theme(plot.margin = margin(0,5,20,0))

# Bottom row
h1 <- h1 + theme(strip.text.x = element_blank(),
                 plot.margin = margin(0,5,0,0))
h2 <- h2 + theme(strip.text.x = element_blank(),
                 plot.margin = margin(0,5,0,0))


# Add titles
g1 <- g1 + labs(title = "Panel A) Five-Digit Panel") + 
  theme(plot.title = element_text(size = rel(1), 
                                  color = annotation_color, 
                                  hjust = 0.5))

g2 <- g2 + labs(title = "Panel B) Four-Digit Panel") + 
  theme(plot.title = element_text(size = rel(1), 
                                  color = annotation_color, 
                                  hjust = 0.5))

## D. MAKE COMBINED PLOT. ------------------------------------------------------
gg_output <- ggpubr::ggarrange(g1, 
                               g2 + ggpubr::rremove("ylab"),
                               h1, 
                               h2 + ggpubr::rremove("ylab"), 
                               label.x = 0,
                               font.label = list(size = rel(1), 
                                                 color = annotation_color, 
                                                 face = "plain"),
                               widths = 4, 
                               align = "v", 
                               common.legend = TRUE,
                               legend = "bottom")

## ========================================================================== ##
# V. SAVE PLOT AND FOOTNOTE ----------------------------------------------------
## ========================================================================== ##
save_plot( gg_output, 
           "mainoutputplot", 
           width = 12.75, 
           height = 7, 
           output_dir = figures_dir )

save_figure_footnote( footnote_string, 
                      figures_dir, 
                     "mainoutputplot" )