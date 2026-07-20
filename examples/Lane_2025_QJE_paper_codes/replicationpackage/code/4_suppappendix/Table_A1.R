## =============================================================================
# PURPOSE:
#   Creates a table showing South Korean industries matched to industries listed
#   in government legislation for the Heavy-Chemical Industries.
#
# INPUTS:
#   - acts_table_simple_combined_all.csv
#
# OUTPUTS:
#   - sectoracttable.tex
# ==============================================================================

## ========================================================================== ##
# I. TEXT AND TABLE ARGUMENTS -----------------------------------------------
## ========================================================================== ##

# Font size argument for the table
font_size_argument <- 5

# Replace NA values in Kable output with empty strings
options(knitr.kable.NA = '')

# Footnote.
tablelabelstring <- "suppsectoractlist"

tablecaptionstring <- "Sectoral Legislation and Heavy-Chemical Industries (Treated Industries)"

footnotestring <- "This table shows South Korean industries matched to industries listed in government legislation. Official industry lists come from legislative documents and their annexes: Gigyegong [Enforcement Decree of the Machinery Industry Promotion Act], amended by Presidential Decree No. 7850, Oct. 27, 1975 (S. Kor.). Cheolganggong-eopyukseongbeop [Steel Industry Promotion Act], amended by Act. No. 3011, Dec. 16, 1977 (S. Kor.). Cheolganggong-eopyukseongbeopsihaengryung [Enforcement Decree of the Steel Industry Promotion Act], amended by Presidential Decree No. 8885, Mar. 9, 1978 (S. Kor.). Bicheolgeumsokjeryeonsa-eopbeop [Nonferrous Metal Industry Promotion Act], amended by Act. No. 3011, Dec. 16, 1977 (S. Kor.). Bicheolgeumsokjeryeonsa-eopbeopsihaengryung [Enforcement Decree of the Nonferrous Metal Industry Promotion Act], amended by Presidential Decree No. 7743, Aug. 20, 1975 (S. Kor.). Jeonjagong-eopjinheungbeopsihaengryung [Enforcement Decree of the Electronics Industry Promotion Act], amended by Presidential Decree No. 8272, Nov. 5, 1976 (S. Kor.). Joseon-gong-eopjinheungbeop [Shipbuilding Industry Promotion Act], amended by Act. No. 3339, Dec. 31, 1980 (S. Kor.). Joseon-gong-eopjinheungbeopsihaenggyuchik, amended by Decree by the Ministry of Commerce No. 411, Dec. 8, 1975 (S. Kor.). Seokyuhwahakgong-eopyukseongbeopsihaengryung [Enforcement Decree of the Petrochemical Industry Promotion Act], amended by Presidential Decree No. 10331, June 5, 1981 (S. Kor.)."

## ========================================================================== ##
# II. SUB-FUNCTIONS: Helper and sub-helper functions. -----------------------
## ========================================================================== ##

# Function to clean string columns in the data frame
clean_strings <- function(data, columns) {
  data %>%
    dplyr::mutate_at( vars( all_of(columns) ), 
                      ~ stringr::str_trim(.) %>% stringr::str_squish(.) )
}

## ========================================================================== ##
# III. LOAD AND PREPARE DATA ---------------------------------------------------
## ========================================================================== ##

# A. Load data
csv_file <- file.path( policy_dir, "acts_table_simple_combined_all.csv" )
csvdata <- utils::read.csv( csv_file, header = TRUE, sep = "," )

# Unit test to check if data frame is not empty
testthat::test_that("Test that prepared data.frame is not empty", {
  testthat::expect_false( plyr::empty( csvdata ) )
})

# B. Clean string columns
csvdata <- clean_strings( csvdata, c("Act", "Korean", "Translation") )

# Optionally, wrap strings for long columns (commented out)
# colwidth <- 50
# csvdata$Translation <- stringr::str_wrap( csvdata$Translation, width = colwidth )
# csvdata$Korean <- sapply( csvdata$Korean, stringr::str_wrap, width = colwidth )

last_col <- ncol(csvdata)

## ========================================================================== ##
# IV. MAKE THE TABLE -----------------------------------------------------------
## ========================================================================== ##

# Render the table using knitr::kable
hci_legalact_kable <- knitr::kable( csvdata,
                                    format = "latex",
                                    booktabs = TRUE,
                                    longtable = TRUE,
                                    row.names = NA,
                                    label = tablelabelstring,
                                    caption = tablecaptionstring ) %>%
  
  # Apply kable styling
  kableExtra::kable_styling( latex_options = c("striped",
                                               "repeat_header"),
                             table.envir = "table",
                             repeat_header_continued = "\\textit{(Continued ...)}",
                             position = "center",
                             font_size = font_size_argument ) %>%
  
  # Collapse rows for the first column
  kableExtra::column_spec(., c(last_col-1,last_col) , width = "8cm") %>%
  
  kableExtra::column_spec(., 1 , width = "3cm") %>%
  
  kableExtra::collapse_rows( columns = 1,
                             valign = "top",
                             longtable_clean_cut = TRUE ) %>%
  
  
  # Add footnotes to the table
  kableExtra::footnote( general = footnotestring,
                        general_title = "\\\\hspace{1em}\\\\textit{Notes.}",
                        footnote_as_chunk = TRUE,
                        threeparttable = TRUE,
                        escape = FALSE )

## ========================================================================== ##
## V. SAVE THE KABLE TABLE ------------------------------------------------------
## ========================================================================== ##

output_file <- file.path( tables_supplementalappendix_dir, 
                          "sectoracttable.tex")

cat(hci_legalact_kable, file = output_file)

testthat::test_that("HCI Legal Act kable is saved correctly", {
  testthat::expect_true(file.exists(output_file))
})
