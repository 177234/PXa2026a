/*
Annotated copy for replication audit.
Original script: Lane2025QJE/replicationpackage/code/0_analysis/0_master_run_analysis.do
Purpose: Top-level Stata dispatcher for all analysis do-files.

This file intentionally keeps the original .do extension.
The original code is copied below. Comments in this header identify the
script role, inputs, outputs, and audit linkage. The earlier prose note is
archived at: markdown_notes_archive/0_master_run_analysis_do.md

Audit linkage:
- Methods report: explains the estimating or output logic.
- Derivation report: maps equations/design objects to code.
- Replication report: documents inputs, outputs, and reproducibility limits.

Original code begins after this header.
*/

*------------------------------------------------------------------------------*
* Project:      South Korea Industrial Policy Project
* Description:  Master file for running all Stata scripts.
* Author(s):    Nathan Lane
* Contact:      nathaniel.lane@economics.ox.ac.uk
* Date created: 2025-05-08
* Last updated: 2025-05-08
* Purpose:      Sequentially run Stata master modules:
*              - MAIN analyses
*              - APPENDIX analyses
*              - SUPPLEMENTAL-APPENDIX analyses
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* 0.  HELPER FUNCTION: SAFE-RUNNER
*------------------------------------------------------------------------------*
capture program drop master_run
program define master_run

    args masterfile
    // full path to a master do-file

    display as text "Starting : `masterfile'"
    noisily do "`masterfile'"
    if _rc {
        display as error "Error in `masterfile'  (return code = `_rc')"
        display as error "    Aborting 0_master_run_analysis.do"
        log close
        exit _rc
    }
    display as text "Finished : `masterfile'  (rc = 0)"
end
*------------------------------------------------------------------------------*
* 0.A GLOBAL ANALYSIS TOGGLE
*------------------------------------------------------------------------------*
// This global macro controls whether micro analyses are executed.
capture noisily ifndef RUN_MICRO global RUN_MICRO = 1
display as text "RUN_MICRO set to: $RUN_MICRO"
*------------------------------------------------------------------------------*
* 1.  OPEN / RESET  LOG
*------------------------------------------------------------------------------*
capture log close
local logfile  "./log/0_master_run_analysis.log"
log using "`logfile'", replace

display as text "--------------------------------------------------------------"
display as text "Working directory : `c(pwd)'"
display as text "Start date & time : " ///
                 c(current_date) "  " c(current_time)
display as text "--------------------------------------------------------------"

*------------------------------------------------------------------------------*
* 2.  DEFINE MASTER FILES
*------------------------------------------------------------------------------*
local basedir   "./code/0_analysis"
local main_do   "`basedir'/1_main_scripts/0_1_master_run_main_analyses.do"
local app_do    "`basedir'/2_appendix_scripts/0_2_master_run_appendix_analyses.do"
local supp_do   "`basedir'/3_suppappendix_scripts/0_3_master_run_suppappendix_analyses.do"

*------------------------------------------------------------------------------*
* 3.  RUN EACH MODULE
*------------------------------------------------------------------------------*
master_run "`main_do'"   // MAIN analyses
master_run "`app_do'"    // APPENDIX analyses
master_run "`supp_do'"   // SUPPLEMENTAL-APPENDIX analyses

*------------------------------------------------------------------------------*
* 4.  WRAP-UP
*------------------------------------------------------------------------------*
display as text "--------------------------------------------------------------"
display as text "All Stata master modules completed successfully."
display as text "Log file : `logfile'"
display as text "End time : " ///
                 c(current_time) "  on  " c(current_date)
display as text "--------------------------------------------------------------"

log close