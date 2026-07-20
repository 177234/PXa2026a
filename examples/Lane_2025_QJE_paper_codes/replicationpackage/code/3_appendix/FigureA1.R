## =============================================================================
# PURPOSE:
#   Creates visualizations showing the political crisis facing South Korea via
#   U.S. and South Korean media coverage.
#
# INPUTS:
#   - ngram_political_troop.csv
#   - article_info.csv
#
# OUTPUTS:
#   - appendixnewsplotrobust
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS. -------------------------------------------------
## ========================================================================== ##

font_size_argument <- 11

footnote_string <- "\\indent This figure shows the political crisis facing 
South Korea via U.S. and South Korean media. Panel A (left) shows the number 
of articles (count) in Dong-a and Kyunghyang newspapers matching a Korean-language 
dictionary of 'provocation' keywords. See details in Supplemental Data Appendix; 
count includes articles matching dictionary terms appearing on the first five 
pages. Panel B (right) shows the share of New York Times news stories referring 
to troop withdrawal. Share is measured as the total number of full-text article 
hits ('South Korea+Troop Withdrawal') divided by the number of stories published."

footnote_string <- gsub( "\n" , " " , footnote_string )


## ========================================================================== ##
# II. SUB-FUNCTIONS: Helper and sub-helper functions. --------------------------
## ========================================================================== ##

# Define the custom theme as a variable
trooptheme <- theme(
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


## ========================================================================== ##
# III. SETUP DATA --------------------------------------------------------------
## ========================================================================== ##


## A. Newspaper NYT NGRAMs. ----------------------------------------------------
ngram_file <- file.path( ngram_dir , "ngram_political_troop.csv" )

# Ngram politics file.
ngram_df <- read.csv( ngram_file ) 

# Get dataset dates to match other plots.
ngram_df <- dplyr::filter( ngram_df , year > 1960) %>%
            dplyr::filter( . , year <= 1978)

test_that("Test that prepared data.frame is not empty", {
  expect_equal( plyr::empty( ngram_df ), FALSE ) })


## B. NAVER-Korean newspaper ngrams. -------------------------------------------

### i. Load data ---------------------------------------------------------------

# Load notebook from data/military dir.
nk_workbook_file <- file.path( naver_dir , "article_info.csv" )
provocation_df <- readr::read_csv( nk_workbook_file , 
                             col_names = TRUE, 
                             show_col_types = FALSE )

test_that("Test that prepared data.frame is not empty", {
  expect_equal( plyr::empty( provocation_df ), FALSE ) })


### ii. FILTER DATA ------------------------------------------------------------

# Set Arguments
count_ = 3
page_ = 10

# Filter observations
count_df <- dplyr::filter( provocation_df , 
                           count >= count_ & page <= page_ ) %>%
              dplyr::group_by( . , year ) %>%
              dplyr::summarise( . , n() )

test_that("Test that prepared data.frame is not empty", {
  expect_equal( plyr::empty( count_df ), FALSE ) })


## ========================================================================== ##
# IV. MAKE PLOTS ---------------------------------------------------------------
## ========================================================================== ##


## A. NAVER PROVOCATIONS PLOT --------------------------------------------------

colnames( count_df ) <- c( "Year" , "Count" )

text_provocations <- ggplot( data = count_df ) +
    geom_hline( aes( yintercept = 0 ) , 
                size = .5 , color = med_grey_argument ) +
    geom_line( aes( x = as.numeric( Year ), y = as.numeric( Count ) ) , 
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
    ylab( "Number of articles in major newspapers" ) +
    ggtitle( "Panel A) Articles on North Korean Provocations \n in Top South Korean Newspapers" ) +
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
      ggtitle( "Panel B) Mentions of US Troop Withdrawal \n From South Korea in New York Times" ) +
      trooptheme # Apply the custom theme.


## ========================================================================== ##
# V. ASSEMBLE PLOTS ------------------------------------------------------------
## ========================================================================== ##

# Assemble main plot and add blanks for spacing.
troop_news_plots <- ggpubr::ggarrange( text_provocations ,
                                       troopwithdrawal_graph,
                                         nrow = 1, 
                                         ncol = 2 )

## ========================================================================== ##
# VI. SAVE PLOT AND FOOTNOTE ---------------------------------------------------
## ========================================================================== ##
save_plot( plot_object = troop_news_plots ,
           filename = "appendixnewsplotrobust" ,
           width = 12 ,
           height = 7 ,
           output_dir = figures_appendix_dir )

save_figure_footnote( footnote_string ,
                      output_dir = figures_appendix_dir ,
                      label = "appendixnewsplotrobust" )

test_that("Test that plot and footnote are saved", {
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                        "appendixnewsplotrobust.pdf" ) ) )
  expect_true( file.exists( file.path( figures_appendix_dir , 
                                        "appendixnewsplotrobust.tex" ) ) )
})
