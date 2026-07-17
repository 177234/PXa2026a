# Annotated copy for replication audit.
# Original script: Lane2025QJE/replicationpackage/master.R
# Purpose: Top-level R driver that configures paths, opens logging, runs Stata analysis, and dispatches R figure/table scripts.
#
# This file intentionally keeps the original .R extension.
# The original code is copied below. Comments in this header identify the
# script role, inputs, outputs, and audit linkage. The earlier prose note is
# archived at: markdown_notes_archive/master_R.md
#
# Audit linkage:
# - Methods report: explains the estimating or output logic.
# - Derivation report: maps equations/design objects to code.
# - Replication report: documents inputs, outputs, and reproducibility limits.
#
# Original code begins after this header.

# ------------------------------------------------------------------------------
# Project:       South Korea Industrial Policy Project
#  Description:  MASTER SCRIPT FOR REPLICATION
#  Author(s):    Nathan Lane
#  Contact:      nathaniel.lane@economics.ox.ac.uk
#  Date created: 2025-05-08
#  Last updated: 2025-05-08
#  Contributors: 
#    - Nathan Lane
#    - Lottie Field
#    - Shehryar Hasan
#    - Hannah Wei
#    - Stephen Xu
#  R Version:    Written in R version 4.3.3, tested across multiple versions
#  Run time:     Total will vary significantly by core and OS. 
#                2-3 hours for StataMP on a 16-core MacBook Pro.
# ------------------------------------------------------------------------------
# DOCUMENTATION: master.R
#
#   DESCRIPTION: This master R script replicates all analyses, tables, and
#                figures for the paper "Manufacturing Revolutions". It runs
#                both Stata and R scripts required for replication.
#
#   REQUIREMENTS:
#   - You must have R 4.3+ installed. RStudio is recommended.
#   - You must have Stata 17.0+ installed.
#   - Internet connection is required to automatically install packages.
#   - Config.yml must be configured with your Stata path and version.
#
#   USAGE:
#   - (Recommended) Open the .Rproj file in RStudio.
#   - Open this file in RStudio, or other R environment.
#   - Run the script.
#   - This script will automatically set the project root.
#     - If you use .Rproj (RStudio), the project root will be set automatically.
#     - If you do not use .Rproj, this file will attempt to set the project 
#       root automatically.
#
#   OPTIONS:
#   - To skip execution of Stata scripts, set 'skip_stata: TRUE' in 'config.yml'
#
#   OUTPUT:
#   - All outputs are saved in the '/output' directory.
#   - master.log file is saved in the '/log' directory.
#
#   SEE ALSO:
#   - README.md for detailed instructions and troubleshooting.
#   - config.yml for project settings.
#
# ------------------------------------------------------------------------------

# Clear workspace, print session info, and timestamp start.
rm(list = ls(all.names = TRUE)) 
gc()                            
print(sessionInfo()) 
start_time <- Sys.time()  
message("Starting time: ", start_time) 


# I. SETUP ---------------------------------------------------------------------


## 1. Set up project root directory --------------------------------------------

# Install and load the 'rprojroot' package to find the project root directory.
if (!requireNamespace("rprojroot", quietly = TRUE)) install.packages("rprojroot")
library(rprojroot)

# Set project root directory.
root_criterion <- rprojroot::has_file("config.yml")  # Root is the dir containing config.yml
project_root <- rprojroot::find_root(root_criterion) # Find the root directory.
message("Project root directory: ", project_root)


## 2. Set up logging -----------------------------------------------------------
log_file <- file.path(project_root,"log","master.log")

# Track initial sink state to restore on exit
initial_sink_number <- sink.number()

sink(log_file, append = FALSE, split = TRUE)
message("Log file opened: ", log_file)

# Robust log closure on exit - restore to initial state
on.exit({
  message("Closing log file.") 
  # Close only sinks we opened
  while(sink.number() > initial_sink_number) sink()
  if (grDevices::dev.cur() > 1) grDevices::dev.off() 
  gc()
}, add = TRUE)



## 3. Settings: load config.yml settings ---------------------------------------

# Install and load yaml package.
if (!requireNamespace("yaml", quietly = TRUE)) install.packages("yaml")
library(yaml)

# Load config.yml.
message("Loading config.yml with your settings.")
config <- yaml::read_yaml(file.path(project_root, "config.yml"))


# Get project $dirs from config.yml.
dirs <- lapply(config$dirs, \(p) file.path(project_root, p)) 
names(dirs) <- names(config$dirs)

# Verify and then global directories.
missing <- names(Filter(\(d) !dir.exists(d), dirs))
if (length(missing))
  stop("Missing directories: ", paste(missing, collapse = ", "))

list2env(dirs, .GlobalEnv)  
message("Set global directories.")


# Set global skip_stata
skip_stata <- FALSE # Default is FALSE.

# Load skip_stata from config.yml; check for TRUE.
raw_skip_stata <- config$user_settings$skip_stata

skip_stata <- if (is.logical(raw_skip_stata)) { # If logical, use as is.
  raw_skip_stata
} else if (is.character(raw_skip_stata)) {
  tolower(raw_skip_stata) %in% c("true", "t", "yes", "y", "1")
} else {
  warning("Invalid type for skip_stata in config.yml; defaulting to FALSE.")
  FALSE
}
message(sprintf("Set global skip_stata: %s", skip_stata))


# II. STATA WORKFLOW -----------------------------------------------------------
message("Running Stata workflow. This may take a while.")


## 1. Set up RStata ------------------------------------------------------------

# Install and load RStata package.
if (!requireNamespace("RStata", quietly = TRUE)) install.packages("RStata")
library(RStata) # Load RStata package.


# Set Stata path and version; check for valid path.
if (isFALSE(skip_stata)) {

  # Get Stata path from config.yml.
  stata_path <- Sys.getenv("STATA_PATH", unset = config$user_dirs$stata_path)
  if (!nzchar(stata_path) || !file.exists(stata_path))
    stop("Valid Stata executable not found. ",
         "Set STATA_PATH or edit config.yml. See README.md for details.")
  
  # Get Stata version.
  raw_stata_ver <- config$user_dirs$stata_version

  # Parse stata_version.
  stata_ver <- tryCatch({
    # If numeric/integer, directly convert to integer.
    if (is.numeric(raw_stata_ver)) {
      as.integer(raw_stata_ver)
    } else if (is.character(raw_stata_ver)) {
      # Remove whitespace and convert to integer
      parsed_ver <- as.integer(trimws(raw_stata_ver))
      if (is.na(parsed_ver)) stop("Invalid character input for stata_version.")
      parsed_ver
    } else {
      stop("stata_version must be numeric or character.")
    }
  }, error = function(e) {
    stop("Error parsing stata_version from config.yml: ", e$message)
  })

  # Final validation
  if (is.na(stata_ver) || stata_ver <= 0) {
    stop("stata_version must be a positive integer. Check your config.yml.")
  }

  # Set Stata path and version.
  options(RStata.StataPath = stata_path,
          RStata.StataVersion = stata_ver)

  # Print Stata path and version.
  message(sprintf("RStata: Set up Stata path: %s", stata_path))
  message(sprintf("RStata: Set up Stata version: %s", stata_ver))
}


## 2. Set up Stata environment -------------------------------------------------

### 2.1. Define RStata helper function -----------------------------------------
run_stata <- function(x,
                      is_file    = TRUE,
                      stata_echo = TRUE,
                      skip       = skip_stata) {

  ## 0.  Respect the flag ------------------------------------------------------
  if (isTRUE(skip)) {
    message("run_stata(): skipping call because skip_stata = TRUE")
    return(invisible(NULL))
  }

  ## 1.  Validate inputs -------------------------------------------------------
  stopifnot(is.character(x), length(x) == 1L, nzchar(x))

  ## 2.  Resolve path if we were given a .do file ------------------------------
  if (isTRUE(is_file)) {
    x <- tryCatch(
      normalizePath(x, winslash = "/", mustWork = TRUE),
      error = function(e)
        stop("run_stata(): file not found: ", x, "\n", e$message)
    )
  }

  ## 3.  Delegate to RStata ----------------------------------------------------
  result <- tryCatch(
    RStata::stata(x, stataEcho = stata_echo),
    error = function(e)
      stop("run_stata(): Stata execution failed:\n", e$message)
  )

  ## 4.  Check Stata’s exit status --------------------------------------------
  if (!is.null(attr(result, "status")) &&
      attr(result, "status") != 0) {
    stop("run_stata(): Stata returned non-zero exit status (",
         attr(result, "status"), ")")
  }

  invisible(result)
}


### 2.2. Set up Stata environment ----------------------------------------------

# Set Stata's global root; calling Stata from RStata.
root_for_stata <- normalizePath(project_root, winslash = "/")
run_stata(sprintf('global PROJ_ROOT "%s"', root_for_stata  ), is_file = FALSE)
run_stata('cd \"$PROJ_ROOT\"',is_file = FALSE)
run_stata('pwd',is_file = FALSE)



## 3. Run Stata scripts --------------------------------------------------------
message("Starting Stata workflow. RUNTIME: 2-3 hours.")
message("ATTENTION: Long runtime. This will take a while.")


## A. Run Stata setup script. --------------------------------------------------

# Set safe path to setup do file.
setup_do_file <- normalizePath(file.path( setup_dir, 
                                          "setup.do"),
                               winslash = "/", mustWork = TRUE)

# Execute Stata setup script.
run_stata(setup_do_file)


## B. Run Stata master script. -------------------------------------------------

# Set safe path to master do file.
master_do_file <- normalizePath(file.path( analysiscode_dir,
                                           "0_master_run_analysis.do"),
                               winslash = "/", mustWork = TRUE)

# Send console output to log file.
# Track sink depth to avoid disrupting user sinks
n_sinks_before_stata <- sink.number()
sink(log_file, append = TRUE, split = FALSE)

# Execute Stata master script.
message(sprintf("\n=== Running Stata master scripts at %s ===\n", Sys.time()))
run_stata(master_do_file)
message(sprintf("\n=== Finished Stata master scripts at %s ===\n", Sys.time()))

# Restore console output - only close the sink we opened
if (sink.number() > n_sinks_before_stata) sink()


# III. R FILE WORKFLOW ---------------------------------------------------------
message("Starting R workflow. RUNTIME: 2-6min.")


## A. Run R setup script. ------------------------------------------------------
# Critical: If setup fails, stop() will terminate all execution
tryCatch(
  source(file.path(setup_dir, "setup.R")), error = function(e) {
    stop("Failed to run R setup script: ", e$message)
  }
)

# Verify critical function from setup.R is available
if (!exists("run_r_scripts", mode = "function")) {
  stop("Critical: run_r_scripts function not defined after setup.R. ",
       "Check setup/setup.R for errors.")
}

## B. Run R master scripts. ----------------------------------------------------
# Note: run_r_scripts() is defined in setup/setup.R and must be available
r_scripts <- list(
  "Figures R master script" = file.path( figurescode_dir, 
                          "0_master_run_figure.R"),
  "Tables R master script" = file.path(tablescode_dir, 
                          "0_master_run_table.R"),
  "Appendix R master script" = file.path(appendixcode_dir, 
                          "0_master_run_appendix.R"),
  "Supp. Appendix R master script" = file.path(supplementalcode_dir,
                          "0_master_run_suppappendix.R")
)

# Run R scripts silently.
sink(log_file, append = TRUE, split = FALSE)
message(sprintf("\n=== Running R-scripts at %s ===\n", Sys.time()))


# Loop over the scripts to execute each one.
for (r_script in names(r_scripts)) {
  message(sprintf("Running %s", r_script))
  run_r_scripts(r_scripts[[r_script]])
}

# Log completion, restore console behavior.
message(sprintf("\n=== Finished R-scripts at %s ===\n", Sys.time()))
sink(log_file, append = TRUE, split = TRUE)


# IV. CLOSE AND CLEAN UP -------------------------------------------------------
message("\n--------------------------------------------------------------------")
message("Master script completed successfully.")

# Calculate and report total duration
end_time <- Sys.time()
total_duration_mins <- as.numeric(difftime(end_time, start_time, units = "mins"))
message(sprintf("Total execution time: %.1f minutes", total_duration_mins))
message(sprintf("Start time: %s", start_time))
message(sprintf("End time: %s", end_time))
message("---------------------------------------------------------------------")

message("Clearing memory, closing log file, and ending session")
if (grDevices::dev.cur() > 1) grDevices::dev.off()
rm(list = ls(all.names = TRUE))
gc()
