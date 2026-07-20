## =============================================================================
# PURPOSE:
#   Creates visualizations showing changes in real value of loans issued by South
#   Korean commercial banks, comparing targeted (HCI) and non-targeted sectors.
#
# INPUTS:
#   - policy_commercialbanking_yearbook_loans.csv
#
# OUTPUTS:
#   - appendix_policy_plot
# ==============================================================================

## ========================================================================== ##
# I. ARGUMENTS AND PLOT/TEXT SETTINGS -----------------------------------------
## ========================================================================== ##

## A. BASIC ARGUMENTS. ---------------------------------------------------------
font_size_argument <- 11

footnote_string <- "\\indent This figure shows the change in the real value of loans 
issued by South Korean commercial banks (traditional deposit money banks). 
The top panel plots changes in total new lending. The bottom panel plots new 
lending for machinery loans only. Units are real won (2010 base). Gray 
lines correspond to non-targeted (non-HCI) sectors, red corresponds to targeted 
(HCI) sectors. Thick lines are averages by treatment status. Subsidized policy 
loans were lent through the commercial banking sector. After 1979, the banking 
sector was liberalized, and the differences in policy interest rates were 
eliminated. See text for details. Source: Korean Yearbooks."

footnote_string <- gsub( "\n" , " " , footnote_string )


## B. GGPLOT ARGUMENTS ---------------------------------------------------------
newminimaltheme <- ggplot2::theme(
            plot.margin = margin(10),
            panel.grid.major = element_blank(),
            panel.grid.minor = element_blank(), 
            panel.border = element_blank(), 
            panel.background = element_blank(),
            text = element_text( size = font_size_argument ),
            plot.title = element_text( color = annotation_color, 
                                        size = rel(1.2), 
                                        hjust = .5,
                                        margin = margin(15, 0, 15, 0),
                                        lineheight = 1.2 ),
            axis.title = element_text( color = annotation_color, 
                                     size = rel(1.1), 
                                     margin = margin(10) ),
            axis.title.x = element_text( margin = margin(10) ),
            axis.title.y = element_text( margin = margin(10) ),
            axis.text = element_text( color = annotation_color, 
                                    size = rel(1) ),
            legend.margin = margin(15),
            legend.position = "bottom" , 
            legend.text = element_text( color = annotation_color, 
                                    size = rel(1) ),
            legend.title = element_text( color = annotation_color, 
                                    size = rel(1.1) )
    )

minimalguides <- guides( fill = "none", 
                        linetype = "none", 
                        size = "none", 
                        alpha = "none" )
        
## ========================================================================== ##
# II. MAKE PLOTS. --------------------------------------------------------------
## ========================================================================== ##

## 1. LOAD DATA. ---------------------------------------------------------------
csvname_to_use <- "policy_commercialbanking_yearbook_loans.csv"
name_to_use <- file.path( input_dir , csvname_to_use )
yearbook_long_years_mfg <- read.csv( name_to_use )
                              
## 2. MAKE GGPLOTS -------------------------------------------------------------

### A. TOTAL LOANS -------------------------------------------------------------
yearbook.tot.g <- ggplot( data = yearbook_long_years_mfg, 
                          aes( y = tot_change ,
                               x = year , 
                               group = factor(ind) ,
                               color = factor(hci) ) ) +
                    stat_summary( fun = mean , 
                                  geom = "line", 
                                  aes(group = factor(hci), 
                                      colour = factor(hci), 
                                      na.rm = TRUE), 
                                  size = 1.5,
                                  alpha = .75) +
                    geom_vline( aes( xintercept = 1973) , 
                                colour = med_grey_argument, 
                                linetype = c(2) )+
                    geom_vline( aes( xintercept = 1979) , 
                                colour = med_grey_argument, 
                                linetype = c(2) )+
                    geom_line( aes( y = tot_change, 
                                    x = year , 
                                    color = factor( hci ) , 
                                    group = ind ), 
                               alpha =.15, 
                               size = 1 ) +
                    geom_hline( aes( yintercept = 0) , 
                                colour = annotation_color, 
                                size = .75 )+
                    scale_x_continuous("Year", 
                                       limits = c(1966,1982),
                                       breaks=c(1966,1970,1973,1979,1982), 
                                       labels=c(1966,1970,1973,1979,1982)) +
                    scale_color_manual(values=c(med_grey_argument, 
                                                med_red_argument),
                                       guide = guide_legend(title = "Industry Type"),
                                       labels=c("Non-Targeted","Targeted")) +
                    scale_alpha_manual("Line Type", values=c("Mean"=.9,"Industry" = .2)) +
                    scale_size_manual("Line Type", values=c("Mean" = 2,"Industry" = 1)) +
                    scale_y_continuous( name= "\nReal Value (Bn. won, 2010)\n")+ 
                    ggnewscale::new_scale_color() +
                    scale_color_manual( "Industry Type" , 
                                        values=c(med_grey_argument, 
                                        deep_red_argument ),
                                        labels=c("Non-Targeted","Targeted")) +
                    geom_errorbarh( data = subset(yearbook_long_years_mfg, year>1965),
                                    aes(xmin = min, 
                                        xmax = max, 
                                        y = tot_change_bin_mean,
                                        group = factor(hci_mean),
                                        color = factor(hci_mean) ), 
                                    size = .5) +
                    newminimaltheme
                    
# Attach minimal guides.                
yearbook.tot.g <- yearbook.tot.g + minimalguides


### B. MACHINERY LOANS ---------------------------------------------------------
yearbook.eq.g <- ggplot( data = yearbook_long_years_mfg, 
                         aes( y = eq_change ,
                              x = year , 
                              group = factor(ind) ,
                              color = factor(hci) ) ) +
                  stat_summary( fun = mean , 
                                geom = "line", 
                                aes(group = factor(hci), 
                                    colour = factor(hci), 
                                    na.rm=TRUE), 
                                size = 1.5,
                                alpha = .75) +
                  geom_vline( aes( xintercept = 1973) , 
                              colour = med_grey_argument, 
                              linetype = c(2) )+
                  geom_vline( aes( xintercept = 1979) , 
                              colour = med_grey_argument, 
                              linetype = c(2) )+
                  geom_line( aes( y = eq_change, 
                                  x = year , 
                                  color = factor( hci ) , 
                                  group = ind ), 
                             alpha =.10, 
                             size = 1 ) +
                  geom_hline( aes( yintercept = 0) , 
                              colour = med_grey_argument, 
                              size = .25 )+
                  scale_x_continuous("Year", 
                                     limits = c(1966,1982),
                                     breaks=c(1966,1970,1973,1979,1982), 
                                     labels=c(1966,1970,1973,1979,1982))+
                  scale_color_manual(values=c(med_grey_argument, 
                                              med_red_argument),
                                     guide = guide_legend(title = "Industry Type"),
                                     labels=c("Non-Targeted","Targeted")) +
                  
                  scale_alpha_manual("Line Type", values=c("Mean"=.9,"Industry" = .2)) +
                  scale_size_manual("Line Type", values=c("Mean" = 2,"Industry" = 1)) +
                  scale_y_continuous( name= "\nReal Value (Bn. won, 2010)\n")+ 
                  ggnewscale::new_scale_color() +
                  scale_color_manual( "Industry Type" , 
                                      values=c(med_grey_argument, 
                                                deep_red_argument ),
                                      labels=c("Non-Targeted","Targeted")) +
                  geom_errorbarh( data = yearbook_long_years_mfg,
                                  aes(xmin = min, 
                                      xmax = max, 
                                      y = eq_change_bin_mean,
                                      group = factor(hci_mean),
                                      color = factor(hci_mean) ), 
                                  size = .5) +
                  newminimaltheme

# Attach minimal guides.                
yearbook.eq.g <- yearbook.eq.g + minimalguides


## ========================================================================== ##
## 3. TWEAK LABELS AND MAKE APPENDIX PLOT --------------------------------------
## ========================================================================== ##

# Tweak labels.
yearbook.tot.g <- yearbook.tot.g + labs( title = "Panel A) New Total Lending by Deposit Money Banks" )
yearbook.eq.g <- yearbook.eq.g + labs( title = "Panel B) New Machinery Lending by Deposit Money Banks" )

# Make appendix plot.
appendixpolicyplot <- ggpubr::ggarrange(yearbook.tot.g,
                                        yearbook.eq.g ,
                                        ncol = 1,
                                        nrow = 2,
                                        legend = "bottom" ,
                                        common.legend = TRUE)



## ========================================================================== ##
# III. SAVE PLOT AND FOOTNOTE --------------------------------------------------
## ========================================================================== ##

# Save plot.
save_plot( plot_object = appendixpolicyplot ,
           filename = "appendixpolicyplot" ,
           width = 8 ,
           height = 10.5 ,
           output_dir = figures_appendix_dir)


save_figure_footnote( footnote_string ,
                      output_dir = figures_appendix_dir ,
                      label = "appendixpolicyplot" )

test_that("Test that plot and footnote are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                        "appendixpolicyplot.pdf" ) ) )
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                        "appendixpolicyplot.tex" ) ) )
})
