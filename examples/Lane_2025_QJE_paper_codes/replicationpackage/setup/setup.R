# ------------------------------------------------------------------------------
# Project:       South Korea Industrial Policy Project
#  Description:  SETUP SCRIPT FOR REPLICATION
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
#  Architecture: aarch64-apple-darwin20.6.0
#  OS Used:      macOS 14.4.1 darwin20 | Tested across platforms
# ------------------------------------------------------------------------------
#
#  DOCUMENTATION: setup.R
#
#     DESCRIPTION: This setup R script sets up the global environment to run 
#     the R scripts in the project.
#
#     The file is executed by the master.R script and is not run directly.
#
# ------------------------------------------------------------------------------


## ========================================================================== ##
# 1. LOAD REQUIRED PACKAGES AND SET SEED ---------------------------------------
## ========================================================================== ##

# Function to install and load packages.
install_and_load <- function(packages, repos = "https://cloud.r-project.org") {

  # Get names of already installed packages, determine which are not installed.
  installed_package_names <- utils::installed.packages()[, "Package"]
  new_packages <- packages[!(packages %in% installed_package_names)]

  if (length(new_packages) > 0) {
    message("Attempting to install missing package(s)",
            paste(new_packages, collapse = ", "))
    # Install missing packages, with dependencies, from a specified repository.
    tryCatch(
      utils::install.packages(new_packages,
                              repos = repos,
                              verbose = FALSE,
                              quiet = TRUE,
                              dependencies = TRUE),
      error = function(e) {
        stop("Failed to install required package(s)",
             paste(new_packages, collapse = ", "), ". Error", e$message,
             call. = FALSE)
      }
    )
  }

  # Load all requested packages
  results <- suppressPackageStartupMessages(
    lapply(packages, library, character.only = TRUE, warn.conflicts = FALSE)
  )

  # Make the return value (list from lapply) invisible.
  invisible(results)
}

# List of common packages
common_package_list <- c(
  "rlang", "assertthat", "DescTools", "devtools", "data.table",
  "ggplot2", "gghighlight", "ggnewscale", "ggpubr", "ggridges", 
  "grDevices", "grid", "gridExtra", "kableExtra", "knitr", 
  "magrittr", "openxlsx", "papaja", "plyr", "dplyr", "RColorBrewer", 
  "reshape", "reshape2", "RUnit", "scales", "stringr", "showtext", 
  "sysfonts", "testthat", "tidyr", "utils", "viridis", "yaml"
)

install_and_load(common_package_list)
message("Installed and loaded common packages")

# Set the seed by base().
base::set.seed( 541102832 ) 


## ========================================================================== ##
# 2. ARGUMENTS AND GRAPHICS, TYPE, MORE. ---------------------------------------
## ========================================================================== ##

## A. TYPOGRAPHY ARGUMENTS. ----------------------------------------------------
showtext::showtext_auto()

# Sets ggplot font.
font_family_argument <- "Arial"

# Set default font size to 12
font_size_argument <- 12


## B. AESTHETIC ARGUMENTS. -----------------------------------------------------

# Main plot features in background.
annotation_color <- "black"

# Greys
control_grey_argument <- "grey35"
light_grey_argument <- "lightgrey"
med_grey_argument <- "grey35"
dark_grey_argument <- "grey20"

# Reds
light_red_argument <- "indianred"
med_red_argument <- "indianred3"
deep_red_argument <- "indianred4"


## C. SET GLOBAL GGPLOT THEME. GGPLOT ARGUMENTS. -------------------------------

## Ggplot theme setter. Set global minimal theme.
ggplot2::theme_set(
  theme_minimal(
    base_family = font_family_argument,
    base_size = font_size_argument
  ) +
    theme(
      text = element_text( size = font_size_argument, 
                           family = font_family_argument,
                           color = annotation_color ),
      panel.grid = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.background = element_blank(), 
      panel.border = element_blank(),
      plot.background = element_blank(),
      strip.background = element_blank(),
      axis.ticks = element_line(linewidth = .4 ),
      axis.title = element_text(lineheight = 1.2),
      axis.text = element_text(family = font_family_argument, 
                               size = rel(.9)),
      axis.text.x = element_text(family = font_family_argument ),
      axis.text.y = element_text(family = font_family_argument ),
      legend.background = element_blank(),
      legend.title = element_text(family = font_family_argument, 
                                  face = "bold"),
      legend.text = element_text(family = font_family_argument, 
                                 face = "plain")
    )
)

## D.  KNITR/Kable arguments to set. -------------------------------------------
options( knitr.kable.NA = '' )
options( scipen = 999, digits = 3)


## ========================================================================== ##
# 3. COMMON HELPER FUNCTIONS. --------------------------------------------------
## ========================================================================== ##


## A. FUNCTION TO RUN R SCRIPTS. -----------------------------------------------

#' Safely Execute an R Script with Robust Error Handling and Verbosity Control
#'
#' This function executes a specified R script. It includes comprehensive error
#' handling for invalid inputs, file path issues, and errors occurring within
#' the sourced script. It also provides granular control over progress messages
#' and the echoing of sourced commands.
#'
#' @param script_path Character string: The path to the R script to be executed.
#'        This path will be normalized, and the script must exist and be readable.
#' @param verbose_progress Logical: If `TRUE` (default), messages indicating the
#'        start and successful completion of the script execution are printed.
#' @param verbose_source_echo Logical: If `TRUE` (default is `FALSE`), each
#'        expression from the sourced script is printed to the console before
#'        evaluation (`echo = TRUE` in `source()`), and the results of
#'        auto-printing expressions are also displayed (`print.eval = TRUE` in
#'        `source()`). Useful for detailed debugging of the sourced script.
#'
#' @return Invisibly returns `TRUE` if the script executes successfully.
#'         If any error occurs (input validation, file access, or error within
#'         the sourced script), the function stops execution with an informative
#'         error message.
#'
#' @examples
#' \dontrun{
#' # Create a dummy script for example
#' # writeLines("print('Hello from script!'); x <- 1+1; print(x)", "temp_script.R")
#'
#' # Basic execution with progress messages
#' # run_r_scripts("temp_script.R")
#'
#' # Quieter execution (no progress messages, no source echo)
#' # run_r_scripts("temp_script.R", verbose_progress = FALSE)
#'
#' # Detailed execution (progress messages and full source echo)
#' # run_r_scripts("temp_script.R", verbose_source_echo = TRUE)
#'
#' }
run_r_scripts <- function(script_path,
                          verbose_progress = TRUE,
                          verbose_source_echo = FALSE) {

  # --- 1. Input Validation ---
  if (!is.character(script_path) || length(script_path) != 1 || nzchar(trimws(script_path)) == 0) {
    stop("`script_path` must be a single, non-empty string.", call. = FALSE)
  }
  if (!is.logical(verbose_progress) || length(verbose_progress) != 1 || is.na(verbose_progress)) {
    stop("`verbose_progress` must be a single logical value (TRUE/FALSE).", call. = FALSE)
  }
  if (!is.logical(verbose_source_echo) || length(verbose_source_echo) != 1 || is.na(verbose_source_echo)) {
    stop("`verbose_source_echo` must be a single logical value (TRUE/FALSE).", call. = FALSE)
  }

  # --- 2. File Path Resolution and Existence Check ---
  resolved_script_path <- tryCatch({
    normalizePath(script_path, mustWork = TRUE)
  }, warning = function(w) {
    stop(sprintf("Invalid script path or permission issue for: %s\n(Original warning: %s)",
                 script_path, conditionMessage(w)), call. = FALSE)
  }, error = function(e) {
    stop(sprintf("Script not found or not readable: %s\n(Original error: %s)",
                 script_path, conditionMessage(e)), call. = FALSE)
  })

  # --- 3. Script Execution ---
  if (verbose_progress) {
    message(sprintf("Starting script: %s", resolved_script_path))
  }

  tryCatch({
    source(resolved_script_path,
           local = FALSE,
           echo = verbose_source_echo,
           print.eval = verbose_source_echo)

    if (verbose_progress) {
      message(sprintf("Successfully finished script: %s", resolved_script_path))
    }
    invisible(TRUE)

  }, error = function(e_source) {
    error_message <- sprintf(
      "Error encountered while executing script: %s\nScript error message: %s",
      resolved_script_path,
      conditionMessage(e_source)
    )
    stop(error_message, call. = FALSE)
  })
}


## B. FIGURE FOOTNOTE SAVER. ---------------------------------------------------

#' Save Figure Footnote Text to a .tex File
#'
#' Writes footnote text to a .tex file. Ensures the output directory exists
#' (creating it if needed) and handles file writing errors.
#' (Simplified version, backward compatible with original argument names).
#'
#' @param footnotetext_argument Character string: The footnote text.
#'   Must not be empty.
#' @param output_dir_argument Character string: Directory path for the .tex
#'   file. Will be created recursively if it doesn't exist.
#' @param label_argument Character string: Base name for the .tex file
#'   (no extension).
#' @param verbose Logical: If `TRUE` (default), prints progress messages.
#'
#' @return Invisibly returns the full path to the created .tex file on success.
#'   Stops with an error on failure.
#'
#' @examples
#' \dontrun{
#'   # Basic usage
#'   # save_figure_footnote("My footnote.", tempdir(), "fig1_note")
#' }
save_figure_footnote <- function(footnotetext_argument,
                                 output_dir_argument,
                                 label_argument,
                                 verbose = TRUE) {

  # --- 1. Input Validation ---
  if (!is.character(footnotetext_argument) ||
      !length(footnotetext_argument) ||
      all(nchar(trimws(footnotetext_argument)) == 0)) {
    stop(
      "`footnotetext_argument` must be a non-empty character string or vector.",
      call. = FALSE
    )
  }
  if (!is.character(output_dir_argument) ||
      length(output_dir_argument) != 1 ||
      !nzchar(trimws(output_dir_argument))) {
    stop(
      "`output_dir_argument` must be a single, non-empty string for the directory path.",
      call. = FALSE
    )
  }
  if (!is.character(label_argument) ||
      length(label_argument) != 1 ||
      !nzchar(trimws(label_argument))) {
    stop(
      "`label_argument` must be a single, non-empty string for the filename.",
      call. = FALSE
    )
  }
  if (grepl("[/\\]", label_argument)) {
      stop(
        "`label_argument` should not contain path separators like '/' or '\\'.",
        call. = FALSE
      )
  }
  if (!is.logical(verbose) || length(verbose) != 1 || is.na(verbose)) {
    stop("`verbose` must be a single logical value (TRUE/FALSE).",
         call. = FALSE)
  }

  # --- 2. Prepare Directory and File Path ---
  filename <- paste0(trimws(label_argument), ".tex")

  # Ensure output directory exists
  if (!dir.exists(output_dir_argument)) {
    if (verbose) {
      message(sprintf(
        "Output directory '%s' does not exist. Creating...",
        output_dir_argument
      ))
    }
    tryCatch(
      dir.create(output_dir_argument, recursive = TRUE, showWarnings = FALSE),
      error = function(e_dir) {
        stop(sprintf(
          "Failed to create output directory: %s\n(Original error: %s)",
          output_dir_argument, conditionMessage(e_dir)
        ), call. = FALSE)
      }
    )
  }
  
  resolved_output_dir <- tryCatch(
    normalizePath(output_dir_argument, mustWork = TRUE),
    error = function(e_norm) {
      stop(sprintf(
        "Output directory '%s' is not valid or accessible.\n(Original error: %s)",
        output_dir_argument, conditionMessage(e_norm)
      ), call. = FALSE)
    }
  )
  full_file_path <- file.path(resolved_output_dir, filename)

  # --- 3. Write the Footnote File ---
  if (verbose) {
    message(sprintf("Writing footnote for '%s' to: %s",
                    label_argument, full_file_path))
  }

  tryCatch(
    base::writeLines(text = footnotetext_argument, 
                     con = full_file_path, 
                     sep = "\n"),
    error = function(e_write) {
      stop(sprintf(
        "Failed to write footnote file: %s\n(Original error: %s)",
        full_file_path, conditionMessage(e_write)
      ), call. = FALSE)
    }
  )

  # --- 4. Confirmation and Return ---
  if (verbose) {
    message(sprintf("Successfully saved: %s", full_file_path))
  }
  invisible(full_file_path)
}

## C. GGSAVING FUNCTIONS. ------------------------------------------------------

#' Save a ggplot Object as a PDF File using ggsave
#'
#' This function saves a ggplot object to a PDF file using the
#' `ggplot2::ggsave()` function with the `grDevices::cairo_pdf` device.
#' This device provides robust PDF generation with good font handling,
#' especially when used in conjunction with the `showtext` package.
#'
#' @param plot_object A **ggplot** object to be saved.
#' @param filename    Character string: The base filename for the PDF
#'                    **without** the .pdf extension.
#' @param width       Numeric: The width of the plot in inches.
#' @param height      Numeric: The height of the plot in inches.
#' @param dpi         Numeric: The resolution (dots per inch) for any
#'                    rasterized elements within the plot. Defaults to 600.
#'                    This is primarily relevant if your plot includes
#'                    raster images or uses features like `geom_raster()`.
#'                    For pure vector graphics, DPI has less impact on the
#'                    final PDF quality but is still a required `ggsave` parameter.
#' @param output_dir  Character string: The path to an existing directory
#'                    where the PDF file will be saved.
#'
#' @return Invisibly returns the full path to the saved PDF file on success.
#'         Stops with an error if `ggsave()` fails or if the file is not
#'         created.
#' @export
save_plot <- function(plot_object,
                      filename,
                      width,
                      height,
                      dpi = 600,
                      output_dir) {
  # ---- 1. Validate ---------------------------------------------------
  if (!inherits(plot_object, "ggplot")) {
    stop("`plot_object` must be a ggplot object.", call. = FALSE)
  }
  if (!is.character(filename) || length(filename) != 1 || !nzchar(trimws(filename))) {
    stop("`filename` must be a single, non-empty string.", call. = FALSE)
  }
  if (grepl("\\.pdf$", filename, ignore.case = TRUE)) {
    warning("`filename` should not include the '.pdf' extension; it will be added automatically.", call. = FALSE)
    filename <- sub("\\.pdf$", "", filename, ignore.case = TRUE)
  }
  if (!is.character(output_dir) || length(output_dir) != 1 || !nzchar(trimws(output_dir))) {
    stop("`output_dir` must be a single, non-empty string for the directory path.", call. = FALSE)
  }
  if (!dir.exists(output_dir)) {
    stop(sprintf("Output directory '%s' does not exist.", output_dir), call. = FALSE)
  }
  if (!is.numeric(width) || length(width) != 1 || width <= 0) {
    stop("`width` must be a single positive number (inches).", call. = FALSE)
  }
  if (!is.numeric(height) || length(height) != 1 || height <= 0) {
    stop("`height` must be a single positive number (inches).", call. = FALSE)
  }
  if (!is.numeric(dpi) || length(dpi) != 1 || dpi <= 0) {
    stop("`dpi` must be a single positive number.", call. = FALSE)
  }

  # --- 2. Prepare file path ---
  # Normalize output_dir path for robustness
  normalized_output_dir <- normalizePath(output_dir, mustWork = TRUE)
  pdf_file <- file.path(normalized_output_dir, paste0(trimws(filename), ".pdf"))

  # Remove stale copy if it exists, to prevent ggsave appending pages
  if (file.exists(pdf_file)) {
    unlink(pdf_file, force = TRUE)
  }

  message(sprintf("Saving plot to: %s", pdf_file))

  # --- 3. Write the file using ggplot2::ggsave ---
  tryCatch(
    ggplot2::ggsave(
      filename = pdf_file,
      plot     = plot_object,
      device   = grDevices::cairo_pdf, # Consistently use cairo_pdf
      width    = width,
      height   = height,
      dpi      = dpi,
      units    = "in"
    ),
    error = function(e) {
      # Provide a more informative error message
      stop(sprintf("ggplot2::ggsave() failed to save '%s'.\nOriginal error: %s",
                   pdf_file, e$message), call. = FALSE)
    }
  )

  # --- 4. Verify file creation ---
  if (!file.exists(pdf_file)) {
    stop(sprintf("Plot saving reported success, but file not found: %s", pdf_file),
         call. = FALSE)
  }

  message(sprintf("Successfully saved: %s", pdf_file))
  invisible(pdf_file) # Return the path invisibly
}



message("Finished setup.R")


