## =============================================================================
# PURPOSE:
#   Creates visualizations showing the decline and convergence in nominal tariff
#   rates and quantitative restrictions for targeted and non-targeted products.
#
# INPUTS:
#   - tariffs.csv
#
# OUTPUTS:
#   - trade_ridge_plots
#   - trade_ridge_plots.svg
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS.--------------------------------------------------
## ========================================================================== ##

## A. BASIC ARGUMENTS. ---------------------------------------------------------
font_size_argument <- 11

footnote_string <- "\\indent This figure shows the decline and convergence in (A) 
nominal tariff rates (percent) and (B) quantitative restrictions (severity scores 0-3). 
The kernel density distribution for targeted products is in red; non-targeted products 
are in gray. Distributions are estimated over annual product-level data (unweighted, 
CCCN code, 4-digit level) for years 1968, 1974, 1978, 1980, and 1982. The severity 
of quantitative restrictions within 4-digit products is measured using a qualitative 
{0-3} scale, from (0) no restrictions to (3) high restrictions."

footnote_string <- gsub( "\n" , " " , footnote_string )


## B. New minimal theme. -------------------------------------------------------

# For the main plot.
newminimaltheme <- theme( 
       plot.title = element_text(size = font_size_argument, 
                                 colour = annotation_color , 
                                 family = font_family_argument, 
                                 face = "plain",
                                 hjust = 0.5), 
       axis.text = element_text(size = font_size_argument, colour = annotation_color , family = font_family_argument ), 
       axis.text.y = element_text( size = font_size_argument , colour = annotation_color , family = font_family_argument ),
       axis.title = element_text(size = font_size_argument, colour = annotation_color , family = font_family_argument ),
       panel.grid.major = element_line( color = light_grey_argument , size = .5 ) ,
       panel.grid.minor = element_blank() ,
       plot.margin = margin( 5 ) ,
       panel.margin = margin( 5 ) ,
       legend.background = element_blank(),
       legend.position = "bottom" , 
       legend.box = "horizontal" ,
       legend.direction = "horizontal" ,
       legend.margin = margin( 5 ) ,
       legend.spacing = margin( 5 ) ,
       legend.title = element_text( size = font_size_argument + 1, 
                                    family = font_family_argument,
                                    colour = annotation_color,
                                    lineheight = 1.2) ,
       legend.text = element_text( size = font_size_argument - 1 , 
                                   family = font_family_argument,
                                   colour = annotation_color,
                                   lineheight = 1.2) ,
       legend.key.spacing = unit( 0.25 , "cm" ) ,
       legend.justification = "center"
)


## ========================================================================== ##
## ============== 2. PLOT-FUNCTIONS FOR THE GGPLOTS BELOW. ================== ##
## ========================================================================== ##


## ======================= JOY DIVISION GRAPHS ======================= ##


# Load the raw trade policy dataset.
cccn_dataset <- "tariffs.csv" %>%
                    file.path( policy_dir , . ) %>%
                    read.csv( . )


# A. MAKE RIDGE PLOTS. --------------------------------------------------------

# i. TARIFF PLOT. -------------------------------------------------------------

# Make tariff ridge plot.
tariff_ridge_plot <- ggplot( cccn_dataset, 
                      aes( x = tariff, y = as.factor(year), color = as.factor(hci), 
                           point_color = as.factor(hci), fill = as.factor(hci))) +
                geom_density_ridges(
                  jittered_points = TRUE, scale = .95, rel_min_height = .01,
                  point_shape = "|", point_size = 1.5, size = 0.2, alpha = .3, 
                  position = position_points_jitter(height = 0)) +
                scale_y_discrete( expand = c(.01, 0), name = "\nYear\n") +
                scale_x_continuous( expand = c(0, 0), name = "\nNominal Tariff Rates (Percent)\n") +
                scale_fill_manual( values = c( light_grey_argument , 
                                               med_red_argument), 
                                   labels = c("Non-Targeted Industries", "Targeted Industries")) +
                scale_color_manual( values = c( control_grey_argument , 
                                                light_red_argument), 
                                    guide = "none") +
                scale_discrete_manual( "point_color" , 
                                       values = c(light_grey_argument , 
                                                  med_red_argument), 
                                       guide = "none") +
                # Add legend.
                guides( fill = guide_legend(
                  override.aes = list(
                    fill = c(light_grey_argument , med_red_argument),
                    color = c(med_grey_argument , deep_red_argument), 
                    point_color = NA)) 
                ) +
                theme_ridges(center = TRUE) 


# Adjust tariff plot theme.
tariff_ridge_plot <- tariff_ridge_plot + newminimaltheme


# Add title.
tariff_ridge_plot <- tariff_ridge_plot + 
                      labs(title = "Panel A) Tariffs", 
                           fill = "Sector Type", 
                           color = "Sector Type")

# 
#tariff_ridge_plot <- tariff_ridge_plot + labs(color = "", 
#                                              alpha = "" , 
#                                              fill = "") 


# ii. QUANT REST PLOT. ---------------------------------------------------------

# Make quantitative restrictions ridge plot.
qr_ridge_plot <- ggplot( cccn_dataset, 
                    aes( x = qr, y = as.factor(year), color = as.factor(hci), 
                         point_color = as.factor(hci), fill = as.factor(hci))) +
                    geom_density_ridges(
                      jittered_points = TRUE, scale = .95, rel_min_height = .01,
                      point_shape = "|", point_size = 1.5, size = 0.2, alpha = .3, 
                      position = position_points_jitter(height = 0) ) +
                    scale_y_discrete(expand = c(.01, 0), name = "\nYear\n") +
                    scale_x_continuous(expand = c(0, 0), name = "\nIndex (Low to High)\n") +
                    scale_fill_manual( name = "Group" , 
                                       values = c(light_grey_argument , med_red_argument), 
                                       labels = c("Non-targeted industries", "Targeted industries")) +
                    scale_color_manual( values = c(control_grey_argument , light_red_argument), 
                                        guide = "none" ) +
                    scale_discrete_manual( "point_color", 
                                           values = c(light_grey_argument , med_red_argument), 
                                           guide = "none") +
                    # Add legend.
                    guides( fill = guide_legend(
                              override.aes = list(
                                fill = c(light_grey_argument , med_red_argument),
                                color = c(med_grey_argument , deep_red_argument), 
                                point_color = NA)) 
                            ) +
                    theme_ridges(center = TRUE) 


# Quantitative restrictions ridge plot adjust theme.
qr_ridge_plot <- qr_ridge_plot + newminimaltheme

# Add title.
qr_ridge_plot <- qr_ridge_plot + 
                  labs(title = "Panel B) Quantitative Restrictions",
                       fill = "Sector Type", 
                       color = "Sector Type")



# C. MAKE FIGURE. ------------------------------------------------------------- 



# Make gg plot for rendering.
trade_ridge_plots <- ( ggpubr::ggarrange( tariff_ridge_plot , 
                                          qr_ridge_plot ,
                                         common.legend = TRUE, 
                                         legend = "bottom" ) )

## ========================================================================== ##
# SAVE PLOT AND FOOTNOTE ---------------------------------------------------
## ========================================================================== ##
save_plot( plot_object = trade_ridge_plots ,
           filename = "trade_ridge_plots" ,
           width = 7 ,
           height = 8.5 ,
           output_dir = figures_appendix_dir )

save_figure_footnote( footnote_string ,
                      output_dir = figures_appendix_dir ,
                      label = "trade_ridge_plots" )

test_that("Test that plot and footnote are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "trade_ridge_plots.pdf" ) ) )
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                       "trade_ridge_plots.tex" ) ) )
})


