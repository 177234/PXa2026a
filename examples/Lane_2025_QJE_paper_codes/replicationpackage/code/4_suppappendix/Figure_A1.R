## =============================================================================
# PURPOSE:
#   Creates visualizations for the history section of the main paper, showing
#   political events around the heavy and chemical industry drive.
#
# INPUTS:
#   - ./Data/ngram/ngram_political_troop.csv
#   - ./Data/defensedata/defense.xlsx
#
# OUTPUTS:
#   - newsplotalternative
# ==============================================================================

## ============================================================================ ##
# I. TEXT AND FIGURE ARGUMENTS. -------------------------------------------------
## ============================================================================ ##

font_size_argument <- 11

footnote_string <- "\\indent The figure shows political events around the heavy and chemical industry drive. This plot shows alternative data to the plots in the main appendix. Panel A (left) recorded North Korean military actions that violate armistice; see Online Appendix. Panel B (right) shows the share of New York Times news stories referring to troop withdrawal. Share is measured as the total number of full-text article hits ('South Korea+Troop Withdrawal') divided by the number of stories published, via New York Times."


# Define the custom theme as a variable
trooptheme <- theme_minimal() +
  theme(
    panel.grid.minor = element_blank(), 
    panel.grid.major = element_blank(), 
    text = element_text(family = font_family_argument, 
                        color = annotation_color, 
                        size = font_size_argument),
    axis.title = element_text(
      color = annotation_color,
      margin = margin(15, 15, 15, 15)
    ),
    axis.title.x = element_text(
      color = annotation_color,
      margin = margin(15, 15, 15, 15)
    ),
    axis.title.y = element_text(
      color = annotation_color,
      size = font_size_argument,
      margin = margin(15, 15, 15, 15)
      
    ),
    axis.text.x = element_text(
      angle = 45,
      hjust = 1, 
      size = rel(1.2),
    ), 
    axis.text.y = element_text(
      size = rel(.95),
    ), 
    plot.title = element_text(
      color = annotation_color, 
      size = rel(1.1), 
      lineheight = 1.1,
      hjust = 0.5,
      margin = margin(5, 0, 10, 0)
    ),
    plot.title.position = "panel",
    plot.margin = unit(c(25, 15, 15, 15), "pt")
  )

## ============================================================================ ##
# II. SETUP DATA ----------------------------------------------------------
## ============================================================================ ##


## A. Newspaper NYT NGRAMs. ----------------------------------------------------
ngram_file <- file.path( data_dir , "ngrams" , "ngram_political_troop.csv" )

# Ngram politics file.
ngram_df <- read.csv( ngram_file ) 

# Get dataset dates to match other plots.
ngram_df <- dplyr::filter( ngram_df , year > 1960) %>%
            dplyr::filter( . , year <= 1978)

test_that("Test that ngram_df is not empty", {
  expect_false(is.null(ngram_df))
  expect_gt(nrow(ngram_df), 0)
  expect_gt(ncol(ngram_df), 0)
})


## B. DEFENSE DATA. ----------------------------------------------------

# Defense politics file.
"defense.xlsx" %>% 
    file.path( data_dir , "defensedata" , . ) %>% 
    openxlsx::loadWorkbook( . ) -> defense_workbook

# Violation graph
violation_dataframe <- defense_workbook %>%
                            openxlsx::readWorkbook( . , sheet = "nk_violations") %>%
                            as.data.frame( . ) %>%
                            dplyr::filter( . , grepl( "19(6|7)[0-9]" , Year) )  %>%
                            dplyr::filter( . , as.numeric( Year ) > 1960 )

test_that("Test that prepared data.frame is not empty", {
  expect_false(is.null(violation_dataframe))
  expect_gt(nrow(violation_dataframe), 0)
  expect_gt(ncol(violation_dataframe), 0)
})

## ============================================================================ ##
# III.  ASSEMBLE GRAPHS --------------------------------------------------------
## ============================================================================ ##



## A. MAKE VIOLATIONS PLOTS ----------------------------------------------------


# Violations Plot #
violation_graph <- ggplot( data = violation_dataframe ) +
                    geom_hline( aes( yintercept = 0 ) , 
                                size = .5 , color = med_grey_argument ) +
                    geom_line( aes( x = as.numeric( Year ) , y = as.numeric( Total ) ) , 
                               size = 1 , color = annotation_color  ) +
                    geom_vline( aes( xintercept = 1973 ) , 
                                size = .75 , lty = "dotted" , 
                                color = med_grey_argument , 
                                alpha = .9 ) +
                    geom_vline( aes( xintercept = 1969 ) , 
                                size = .75 , 
                                lty = "dotted" ) +
                    scale_x_continuous(" " , breaks = c( 1961 , 1969 , 1973 , 1978 ) ,
                         labels = c("1961",
                                    "(Nixon's announcment) 1969" ,
                                    "(Drive starts) 1973",
                                    "1978" ))+
                    ylab( "Total Recorded Actions \n" ) +
                    ggtitle( "A) North Korean Actions Against Armistice" ) +
                    trooptheme # Apply the custom theme.


## B. NYT TROOP WITHDRAWAL PLOT ------------------------------------------------

# Plot.
troopwithdrawal_graph  <- ggplot( data = ngram_df ) +
      geom_hline( aes( yintercept = 0 ), 
                  size = .5 , 
                  color = med_grey_argument ) +
      geom_line( aes( x = year , y = ( article_matches_troop/total_articles_published )*100 ) , 
                 size = 1 , color = annotation_color ) +
      ylab( "Share of articles published (x100)" ) +
      geom_vline( aes( xintercept = 1969 ) , size = .75 , lty = "dotted" )+
      geom_vline( aes( xintercept = 1973 ) , size = .75 , lty = "dotted" , 
                  color = med_grey_argument, alpha = .9 ) +
      scale_x_continuous(" " , breaks = c( 1961 , 1969 , 1973 , 1978 ) ,
                          labels = c("1961",
                                     "(Nixon's announcment) 1969" ,
                                     "(Drive starts) 1973",
                                    "1978" ))+
      ggtitle( "Panel B) Mentions of US Troop Withdrawal (NYT)" ) +
      trooptheme # Apply the custom theme.


## ========================================================================== ##
# IV MAKE FIGURE 1 WITH ANNOTATION FOR RENDERING. ------------------------
## ========================================================================== ##

# Assemble main plot and add blanks for spacing.
troop_news_plots_suppappendix <- ggarrange( violation_graph,
                                             troopwithdrawal_graph, 
                                             nrow = 1 , 
                                             ncol = 2 )

## ========================================================================== ##
# VI. SAVE FIGURE & FOOTNOTE ----------------------------------------------------
## ========================================================================== ##

save_plot( troop_news_plots_suppappendix, 
           filename = "newsplotalternative", 
           width = 10 ,
           height = 6 ,
           output_dir = figures_supplementalappendix_dir)

save_figure_footnote( footnote_string, 
                      output_dir_argument = figures_supplementalappendix_dir, 
                      label_argument = "newsplotalternative" )

