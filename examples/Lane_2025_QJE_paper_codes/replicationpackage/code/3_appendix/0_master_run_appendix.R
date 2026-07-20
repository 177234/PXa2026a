# =============================================================================
# Script Name: 0_master_run_appendix.R
# Purpose: A master script to run all appendix scripts.
# =============================================================================

# I. SETUP PATHS AND DIRECTORIES. ----------------------------------------------

# Set the current script directory.
current_script_dir <- file.path(code_dir, "3_appendix")

# II. EXECUTE FIGURE SCRIPTS ---------------------------------------------------

## 1. FIGURE A1 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureA1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 2. FIGURE A2 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureA2.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 3. FIGURE B1 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureB1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 4. FIGURE B2 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureB2.R" )
source( file_to_run, verbose = TRUE , local = FALSE)  

## 5. FIGURE B3 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureB3.R" )
source( file_to_run, verbose = TRUE , local = FALSE)  

## 6. FIGURE B4 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureB4.R" )
source( file_to_run, verbose = TRUE , local = FALSE)  

## 7. FIGURE D1 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureD1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)  

## 8. FIGURE D2 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureD2.R" )
source( file_to_run, verbose = TRUE , local = FALSE)  

## 9. FIGURE D3 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureD3.R" )
source( file_to_run, verbose = TRUE , local = FALSE)  

## 10. FIGURE D4 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureD4.R" )
source( file_to_run, verbose = TRUE , local = FALSE)  

## 11. FIGURE E1 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureE1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)  

## 12. FIGURE E2 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureE2.R" )
source( file_to_run, verbose = TRUE , local = FALSE)  

## 13. FIGURE E3 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureE3.R" )
source( file_to_run, verbose = TRUE , local = FALSE)  

## 14. FIGURE F1 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureF1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)  

## 15. FIGURE F2 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureF2.R" )
source( file_to_run, verbose = TRUE , local = FALSE)  

## 16. FIGURE G1 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureG1.R" )
source( file_to_run, verbose = TRUE , local = FALSE) 

## 17. FIGURE G2 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureG2.R" )
source( file_to_run, verbose = TRUE , local = FALSE) 

## 18. FIGURE G3 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "FigureG3.R" )
source( file_to_run, verbose = TRUE , local = FALSE) 

# III. EXECUTE TABLE SCRIPTS ---------------------------------------------------

## 1. TABLE A1 ------------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "TableA1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 2. TABLES C1 ---------------------------------------------------------------
file_to_run<-file.path( current_script_dir,"TableC1.R")
source( file_to_run, verbose = TRUE , local = FALSE)        

## 3. TABLE D1 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "TableD1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 4. TABLE D2 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "TableD2.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 5. TABLE D3 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "TableD3.R" )
source( file_to_run, verbose = TRUE , local = FALSE)            

## 6. TABLE E1 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "TableE1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)            

## 7. TABLE E2 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "TableE2.R" )
source( file_to_run, verbose = TRUE , local = FALSE)    

## 8. TABLE E3 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "TableE3.R" )
source( file_to_run, verbose = TRUE , local = FALSE)   

## 9. TABLE E4 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "TableE4.R" )
source( file_to_run, verbose = TRUE , local = FALSE)   


message("Appendix figures and tables completed successfully.")
