# =============================================================================
# Script Name: 0_master_run_figure.R
# Purpose: Run all R scripts for figures.
# =============================================================================

# I. SETUP PATHS AND DIRECTORIES. ----------------------------------------------

# Set the current script directory.
current_script_dir <- file.path(code_dir, "1_figures")

# II. EXECUTE R. SCRIPTS -------------------------------------------------------

## 1. FIGURE 1 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Figure1.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 2. FIGURE 2 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Figure2.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 3. FIGURE 3 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Figure3.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 4. FIGURE 4 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Figure4.R" )
source( file_to_run, verbose = TRUE , local = FALSE)        

## 5. FIGURE 5 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Figure5.R" )
source( file_to_run, verbose = TRUE , local = FALSE)            

## 6. FIGURE 6 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Figure6.R" )
source( file_to_run, verbose = TRUE , local = FALSE)            

## 7. FIGURE 7 -----------------------------------------------------------------
file_to_run <- file.path( current_script_dir , "Figure7.R" )
source( file_to_run, verbose = TRUE , local = FALSE)       


message("Figures completed successfully.")