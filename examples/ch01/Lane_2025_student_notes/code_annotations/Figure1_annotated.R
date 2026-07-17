# Annotated copy for replication audit.
# Original script: Lane2025QJE/replicationpackage/code/1_figures/Figure1.R
# Purpose: Generates Figure 1.
#
# This file intentionally keeps the original .R extension.
# The original code is copied below. Comments in this header identify the
# script role, inputs, outputs, and audit linkage. The earlier prose note is
# archived at: markdown_notes_archive/Figure1_R.md
#
# Audit linkage:
# - Methods report: explains the estimating or output logic.
# - Derivation report: maps equations/design objects to code.
# - Replication report: documents inputs, outputs, and reproducibility limits.
#
# Original code begins after this header.

## =============================================================================
# PURPOSE:
#   Creates the fundamental policy graphs used in the paper, including tax policy
#   and yearbook estimates.
#
# INPUTS:
#   - "policy_taxes.csv" (Yearbook loan data and Kwack et al. marginal tax rate data)
#   - "policy_kdbbanking_yearbook_loans.csv" (KDB banking yearbook loan data)
#
# OUTPUTS:
#   - gg_tax_long (Tax policy ggplot object)
#   - gg_kdb (KDB lending ggplot object)
#   - gg_kdb_eq (KDB equipment lending ggplot object)
#   - policy_plot_figure (Combined plot for Figure.RMD)
# ==============================================================================

## =============================================================================
# I. TEXT AND PLOT ARGUMENTS --------------------------------------------------
## =============================================================================

## ========================================================================== ##
# X. TEXT FOR THE FOOTNOTE. ----------------------------------------------------
## ========================================================================== ##

footnote_string <- "This figure shows the patterns of investment policy 
through time by industry. Panel A plots estimates of the average effective 
marginal tax rate (percentage) on the returns to capital, accounting for changes 
in industry-specific tax subsidies (1969-1983). Thin lines are estimates for 
two-digit manufacturing industries. Thick lines are averages for treated and 
non-treated industries. Gray lines correspond to non-targeted sectors and red 
lines correspond to targeted sectors. Panel B plots the change in the (real) 
value of total loans issued by the Korea Development Bank, 1972-1981, a 
representative state lending institution. Values are real values in won. 
Panel C plots only changes in lending for machinery, a major component of HCI 
lending and policy loans."

footnote_string <- gsub("\n", " ", footnote_string)



## ========================================================================== ##
# I. ARGUMENTS AND PLOT/TEXT SETTINGS -----------------------------------------
## ========================================================================== ##

## A. BASIC ARGUMENTS. ---------------------------------------------------------

# Main font, colors in setup.R

## B. GGPLOT ARGUMENTS ---------------------------------------------------------

# Theme for all plots
newminimaltheme <- theme(
         text = element_text( size = font_size_argument + 1, 
                              color = annotation_color ),
         axis.title = element_text( size = rel(.85) , 
                                    color = annotation_color, 
                                    margin = margin( 10 ),
                                    lineheight = 1.2),
         axis.ticks = element_line( color = med_grey_argument, 
                                   linewidth = .33 ),
         axis.text.x = element_text( size = rel(.85), 
                                     color = annotation_color, 
                                     hjust = 0.5),
         axis.text.y = element_text( size = rel(.85), 
                                     color = annotation_color ),
         plot.title = element_text( size = rel(.9), 
                                    color = annotation_color, 
                                    hjust = 0.5, 
                                    margin = margin( t = 5, b = 15 ) ),
         plot.title.position = "plot",
         plot.margin = margin( t = 25, r = 10, b = 15, l = 15, unit = "pt" ),
         legend.title = element_text( size = rel(.9), 
                                      face = "bold",
                                      color = annotation_color ),
         legend.title.position = "top",
         legend.direction = "horizontal",
         legend.position = "bottom" ) 

# Minimal guides
minimalguides <- guides( fill = "none", 
                         linetype = "none", 
                         size = "none", 
                         alpha = "none" )


## ========================================================================== ##  
# II. SETUP DATA. --------------------------------------------------------------
## ========================================================================== ##  

## A. LOAD DATA ----------------------------------------------------------------    

# TAX DATA
tax_long <- "policy_taxes.csv"  %>%
                  file.path( input_dir , . ) %>%
                  read.csv( . , header = TRUE)

tax_long <- dplyr::rename( tax_long , c( "rate" = "X" ))

# Test data isn't empty
test_that( "Data is not empty" , {
  expect_false( plyr::empty( tax_long ) )
} )

# LOAN DATA
kdb_long_years_mfg <- "policy_kdbbanking_yearbook_loans.csv"  %>%
                file.path( input_dir , . ) %>%
                read.csv( . , header = TRUE )

# Test data isn't empty
test_that( "Data is not empty" , {
  expect_false( plyr::empty( kdb_long_years_mfg ) )
} )

## ========================================================================== ##  
# III. ASSEMBLE GRAPHS OR TABLES -----------------------------------------------
## ========================================================================== ##  

## ========================================================================== ##  
## 1. MAKE TAX PLOTS. ----------------------------------------------------------
gg_tax_long <- ggplot( data = tax_long , 
                        aes( y = rate, 
                            x = factor( year ), 
                        color = factor( hci ),
                        group = Industry, 
                        label = Industry ) ) +
    geom_line(  alpha =.33, linewidth = 1.25 ) +
    geom_vline( aes( xintercept="1972"), colour=med_grey_argument, size = .33 , linetype=c( 2 ) )+
    geom_vline( aes( xintercept="1979"), colour=med_grey_argument, size = .33, linetype=c( 2 ) )+
    scale_color_manual(values=c(med_grey_argument, med_red_argument),
                      guide = guide_legend(title = "Industry Type" ),
                      labels=c("Non-Targeted Industry",
                      "Targeted Industry" ) )+
    stat_summary( fun = mean, 
                  geom="line", 
                  aes(group = factor(hci), 
                      colour = factor(hci)) , size = 1.5 , alpha=.8)+
    scale_x_discrete( "Year" , 
                      labels = c("1969" ,"1972" , "1979" , "1983" ), 
                      breaks = c("1969", "1972", "1979", "1983"),)+
    scale_y_continuous( "Rate (%)\n", 
                        breaks = c( 10 , 25 , 50 ) ) + 
    newminimaltheme


## ========================================================================== ##
## 2. MAKE KDB PLOTS. ----------------------------------------------------------

### A. MAIN LENDING ----------------------------------------------------------
gg_kdb <- ggplot( data = kdb_long_years_mfg, 
          aes( y = tot_change ,
                x = year , 
                group = ind ,
                color = factor(hci) ,
                na.rm = TRUE) ) +
      stat_summary( fun = mean , 
                    geom = "line", 
                    aes(group = factor( hci ) , 
                        colour = factor( hci ) ), 
                    na.rm = TRUE,
                    linewidth = 1.5,
                    alpha = .8) +
      geom_vline( aes( xintercept = 1973 ) , 
                  colour = med_grey_argument , 
                  linewidth = .33,
                  linetype = c(2) )+
      geom_vline( aes( xintercept = 1979 ) , 
                  colour = med_grey_argument , 
                  linewidth = .33,
                  linetype = c(2) )+
      geom_line( aes( y = tot_change, 
                      x = year , 
                      color = factor( hci ) , 
                      group = ind ),
                na.rm = TRUE,
                alpha =.2, 
                linewidth = 1 ) +
      geom_hline( aes( yintercept = 0) , 
                  colour = med_grey_argument, 
                  linewidth = .33 )+
      scale_x_continuous("Year", 
                        breaks=c( 1972,1973,1979,1981), 
                        labels=c( 1972,1973,1979,1981)) +
      scale_color_manual(values=c(med_grey_argument, 
                                  med_red_argument),
                        guide = guide_legend( title = "Industry Type", 
                                              face = "bold" ),
                        labels = c( "Non-Targeted" , 
                                    "Targeted" ) ) +
      scale_y_continuous( name= "Real value (bn. won)\n") +
  newminimaltheme

gg_kdb <- gg_kdb + minimalguides


### B. EQ LOANS MAKE GGPLOT ----------------------------------------------------

gg_kdb_eq <- ggplot( data = kdb_long_years_mfg, 
                    aes( y = eq_change ,
                         x = year , 
                         group = ind ,
                         color = factor(hci) ) ) +
              stat_summary( fun = mean , 
                            geom = "line", 
                            aes(group = factor( hci ) , 
                                colour = factor( hci ) ), 
                            na.rm = TRUE,
                            linewidth = 1.5,
                            alpha = .8) +
              geom_vline( aes( xintercept = 1973 ) , 
                          colour = med_grey_argument , 
                          linetype = c(2),
                          linewidth = .33 )+
              geom_vline( aes( xintercept = 1979 ) , 
                          colour = med_grey_argument , 
                          linetype = c(2), 
                          linewidth = .33 )+
              geom_line( aes( y = tot_change, 
                              x = year , 
                              color = factor( hci ) , 
                              group = ind ),
                         na.rm = TRUE,
                         alpha =.2, 
                         linewidth = 1 ) +
              geom_hline( aes( yintercept = 0) , 
                          colour = med_grey_argument, 
                          linewidth = .33 )+
              scale_x_continuous("Year", 
                                 breaks=c( 1972,1973,1979,1981), 
                                 labels=c( 1972,1973,1979,1981)) +
              scale_color_manual(values=c(med_grey_argument, 
                                          med_red_argument),
                                 guide = guide_legend( title = "Industry Type" ),
                                 labels = c( "Non-Targeted Industry" , 
                                             "Targeted Industry" ) ) +
              scale_y_continuous( name = "Real value (won)\n")+ 
              newminimaltheme

gg_kdb_eq <- gg_kdb_eq + minimalguides


## ========================================================================== ##
# V. MAKE RENDERABLE GGPLOT FIGURE 2. ------------------------------------------
## ========================================================================== ##

# Add titles to each plot.
gg_tax_long <- gg_tax_long + labs( title = "Panel A) Effective Marginal Corporate Tax Rate" )
gg_kdb <- gg_kdb + labs( title = "Panel B) New Total Lending by Korean Development Bank" )
gg_kdb_eq <- gg_kdb_eq + labs( title = "Panel C) New Machinery Lending by Korean Development Bank" )


# And render the plot.
policy_plot_figure <- ggpubr::ggarrange( 
  gg_tax_long + theme( axis.title.x = element_blank() ),
    gg_kdb + theme( axis.title.x = element_blank() ),
    gg_kdb_eq, 
    ncol = 1,
    nrow = 3,
    legend = "bottom" ,
    common.legend = TRUE
) 


## ========================================================================== ##
# VI. SAVE FIGURE FOOTNOTE. ----------------------------------------------------
## ========================================================================== ##


# Save the plot to the current_save_path
save_plot( plot_object = policy_plot_figure, 
            filename = "policyplot", 
            width = 6, 
            height = 8,
            output_dir = figures_dir )

# Save the footnote to the current_save_path
save_figure_footnote( footnotetext_argument = footnote_string, 
                      output_dir_argument = figures_dir, 
                      label_argument = "policyplot" )
