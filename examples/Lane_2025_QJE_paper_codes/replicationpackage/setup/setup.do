*------------------------------------------------------------------------------*
* Project:      South Korea Industrial Policy Project
* Description:  Stata setup program for South Korea Industrial Policy Project
* Author(s):    Nathan Lane
* Contact:      nathaniel.lane@economics.ox.ac.uk
*------------------------------------------------------------------------------*
* REQUIREMENTS:
*   - Stata 17+
*   - Requires internet connection for automatic package installation
* 
* ABOUT setup.do:
*   - This file is used to set up the Stata environment for the project.
*   - It is called by the master.R script or external drivers (Stata helpers).
*   - It setups of the global STATA environment variables and Stata logging.
*   - It inherit the project root of master files and checks if it is set.
*   - It installs the Stata packages required for the Stata workflow.
* 
* DEPENDENCIES:
*   Core:      reghdfe ppmlhdfe ftools
*   Analysis:  csdid drdid binscatter
*   Output:    estout regsave gph2xl
*   Utilities: erepost
*
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* I. SETUP STATA ENVIRONMENT
*------------------------------------------------------------------------------*

clear all
version 17.0, user
set more off 
set seed 1312
set sortseed 1231

set maxvar 30000           // Increase maximum number of variables allowed
set varabbrev off          // Enforce full variable names
set type double            // Use double precision for calculations
set scrollbufsize 500000   // Increase scrollback buffer for long output
set tracedepth 2           // Keep tracebacks simple and manageable
set linesize 120           // Set line size to 120 characters

// Debugging (optional; enable only if needed)
* set trace on
* set tracedepth 3

*------------------------------------------------------------------------------*
* II. PROJECT ROOT VERIFICATION
*------------------------------------------------------------------------------*
// Validates the working directory is set to master files by checking for
// configuration files. Required for proper relative path resolution.
//
// EXPECTED STRUCTURE:
//   [project_root]/
//   ├── config.yml          <-- Verification file
//   ├── setup/              
//   ├── code/
//   └── data/
//
// TROUBLESHOOTING:
//    - Errors occur when master.R (or external driver) doesn't properly 
//      set working directory to project root.
//    - Verify master.R sets working directory to project root.
//    - Open project in RStudio using .Rproj file and run master.R.
//    - Verify config.yml exists in project root.
//    - Refer to README.md for more information.
*------------------------------------------------------------------------------*

// Get the current working directory
local current_Stata_pwd "`c(pwd)'"
display as text "Current working Stata directory: `current_Stata_pwd'"

// Check if the expected file exists relative to the current pwd
local expected_file "config.yml"
capture confirm file "`current_Stata_pwd'/`expected_file'"

// If `confirm file` fails, _rc will be non-zero (specifically, 601 file not found)
if _rc != 0 {
    display ""
    display as error "--------------------------------------------------------------------------------"
    display as error "ERROR: Stata's current working directory does not appear to be the project root."
    display as error "       Could not find the expected file: `expected_file'."
    display as error "       within the current directory: `current_Stata_pwd'"
    display as error ""
    display as error "Please ensure R has set Stata's working directory to the main folder"
    display as error "containing this replication package BEFORE running this setup.do file."
    display as error ""
    display as error "Refer to README.md for more information."
    display as error ""
    display as error "--------------------------------------------------------------------------------"
    error 601 // Halt script execution with a file not found error code
}
else {
    display ""
    display as text "Confirmation: Current working Stata directory is `current_Stata_pwd'"
    display as text "Confirmation: Found expected file: `expected_file'."
    display as text "Proceeding with script execution."
    display ""
}

*------------------------------------------------------------------------------*
* II. SET MAIN STATA-WIDE DIRECTORY 
*------------------------------------------------------------------------------*

capture log close
local logfile = "./log/setup.log"
log using "`logfile'", replace

display as text "Working Directory: $PROJ_ROOT"
display as text "Date and Time: " c(current_date) " " c(current_time)
display as text "Log file: `logfile'"

*------------------------------------------------------------------------------*
* II. INSTALL REQUIRED PACKAGES 
*------------------------------------------------------------------------------*

// Automatically install required packages if not already installed.
local packages "reghdfe ppmlhdfe regsave estout ftools csdid drdid erepost binscatter"
foreach pkg in `packages' {
    * Check if package exists
    capture which `pkg'
    if _rc == 0 {
        display as text "`pkg' is already installed."
        continue
    }
    
    * Attempt installation
    display as text "Installing `pkg'..."
    capture noisily ssc install `pkg', replace
    
    * Verify installation success
    if _rc == 0 {
        capture which `pkg'
        if _rc {
            display as error "Package `pkg' installed but not found in path"
            exit 680
        }
    }
    else {
        display as error "Failed to install `pkg' (Error `=_rc')"
        display as error "Possible solutions:"
        display as error "1. Check internet connection"
        display as error "2. Try manual install: ssc install `pkg'"
        display as error "3. Contact maintainer if package was renamed/moved"
        exit 681
    }
}

// Install gph2xl from CGD if not already present
capture which gph2xl
if _rc {
    display as text "Installing gph2xl..."
    capture noisily net from http://digital.cgdev.org/doc/stata/MO/Misc
    capture noisily net install gph2xl, replace
}
else {
    display as text "gph2xl is already installed."
}

*------------------------------------------------------------------------------*
display as text "Setup complete."
display as text "Working Directory: $PROJ_ROOT"
display as text "Date and Time: " c(current_date) " " c(current_time)
