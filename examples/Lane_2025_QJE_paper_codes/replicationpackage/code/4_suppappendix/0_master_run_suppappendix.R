# =============================================================================
# Script Name: 0_master_run_suppappendix.R
# Purpose: A master script to run all supplemental appendix scripts.
# =============================================================================

# I. SETUP PATHS AND DIRECTORIES. ----------------------------------------------

# Set the current script directory.
current_script_dir <- file.path(code_dir, "4_suppappendix")

# II. EXECUTE FIGURE SCRIPTS ---------------------------------------------------

## 1. FIGURE A1 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Figure_A1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 2. FIGURE B1 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Figure_B1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 3. FIGURE B2 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Figure_B2.R" )
source( file_to_run, verbose = TRUE , local = FALSE)

## 4. FIGURE C1 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Figure_C1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 5. FIGURE C2 ---------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Figure_C2.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

# III. EXECUTE TABLE SCRIPTS ---------------------------------------------------

## 1. TABLE A1 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table_A1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 2. TABLE A2 ---------------------------------------------------------------
file_to_run<-file.path( current_script_dir,"Table_A2.R")
source( file_to_run, verbose = TRUE , local = FALSE)        

## 3. TABLE A3 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table_A3.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 4. TABLE B1 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table_B1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 5. TABLE B2 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table_B2.R" )
source( file_to_run, verbose = TRUE , local = FALSE)            

## 6. TABLE C1 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table_C1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)

## 7. TABLE C2 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table_C2.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 8. TABLE C3 ---------------------------------------------------------------
file_to_run<-file.path( current_script_dir,"Table_C3.R")
source( file_to_run, verbose = TRUE , local = FALSE)        

## 9. TABLE D1 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table_D1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 10. TABLE D2 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table_D2.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 11. TABLE E1 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table_E1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)            

## 12. TABLE E2 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table_E2.R" )
source( file_to_run, verbose = TRUE , local = FALSE)

## 13. TABLE E3 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table_E3.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 14. TABLE E4 ---------------------------------------------------------------
file_to_run<-file.path( current_script_dir,"Table_E4.R")
source( file_to_run, verbose = TRUE , local = FALSE)        

## 15. TABLE E5 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table_E5.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 16. TABLE F1 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table_F1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)            

## 17. TABLE F2 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table_F2.R" )
source( file_to_run, verbose = TRUE , local = FALSE)

## 18. TABLE F3 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table_F3.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        


message("Supplemental appendix figures and tables completed successfully.")
