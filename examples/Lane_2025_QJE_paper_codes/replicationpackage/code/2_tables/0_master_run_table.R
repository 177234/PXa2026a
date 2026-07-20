# =============================================================================
# Script Name: 0_master_run_table.R
# Purpose: A master script to run all main table scripts.
# =============================================================================

# I. SETUP PATHS AND DIRECTORIES. ----------------------------------------------

## 1. ROOT PATH FOR PROJECT ----------------------------------------------------

# Set the current script directory.
current_script_dir <- file.path(code_dir, "2_tables")

# II. EXECUTE R. SCRIPTS -------------------------------------------------------

## 1. TABLE 1 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 2. TABLES 2-4 ---------------------------------------------------------------
file_to_run<-file.path( current_script_dir,"Table2-4.R")
source( file_to_run, verbose = TRUE , local = FALSE)        

## 3. TABLE 5 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table5.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 4. TABLE 6 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table6.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 5. TABLE 7 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table7.R" )
source( file_to_run, verbose = TRUE , local = FALSE)            

## 6. TABLE 8 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Table8.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        


message("Tables completed successfully.")