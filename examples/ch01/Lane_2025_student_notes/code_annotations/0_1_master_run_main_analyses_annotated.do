/*
Annotated copy for replication audit.
Original script: Lane2025QJE/replicationpackage/code/0_analysis/1_main_scripts/0_1_master_run_main_analyses.do
Purpose: Dispatches main-paper Stata analysis scripts.

This file intentionally keeps the original .do extension.
The original code is copied below. Comments in this header identify the
script role, inputs, outputs, and audit linkage. The earlier prose note is
archived at: markdown_notes_archive/0_1_master_run_main_analyses_do.md

Audit linkage:
- Methods report: explains the estimating or output logic.
- Derivation report: maps equations/design objects to code.
- Replication report: documents inputs, outputs, and reproducibility limits.

Original code begins after this header.
*/

*------------------------------------------------------------------------------*
* Project:      South Korea Industrial Policy Project
* Description:  Master do file for South Korea Industrial Policy MAIN analyses
*------------------------------------------------------------------------------*
display as text "--------------------------------------------------------------"
display as text "Running main master script analyses"
display as text "Working Directory: `c(pwd)'"
display as text "Date & Time      : `c(current_date)' `c(current_time)'"
display as text "--------------------------------------------------------------"

local localscriptdir "./code/0_analysis/1_main_scripts"

*------------------------------------------------------------------------------*
* 1. Run growth analysis
local scriptname "`localscriptdir'/1_run_growth_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 2. Run development outcomes analysis
local scriptname "`localscriptdir'/2a_run_devoutcomes_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 3. Run Korea trade analysis
local scriptname "`localscriptdir'/2b_run_koreatrade_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 4. Run micro TFP analysis
// NOTE: Source file is not included in the replication package.
if "$RUN_MICRO" == "1" {
    local scriptname "`localscriptdir'/3a_run_micro_tfp_analysis.do"
    noisily do "`scriptname'"
    if _rc != 0 {
        display as error "Error in `scriptname' (rc = `_rc')"
        exit _rc 
    }
}


* 5. Run doubly robust analysis
local scriptname "`localscriptdir'/3b_run_doublerobust_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 6. Run world trade analysis
local scriptname "`localscriptdir'/3c_run_worldtrade_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 7. Run policy analysis
local scriptname "`localscriptdir'/4_run_policy_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 8. Run mechanisms LBD analysis
local scriptname "`localscriptdir'/5a_run_mechanisms_lbd_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 9. Run mechanisms LBD micro analysis
// NOTE: Source file is not included in the replication package.
if "$RUN_MICRO" == "1" {
    local scriptname "`localscriptdir'/5b_run_mechanisms_lbd_micro_analysis.do"
    noisily do "`scriptname'"
    if _rc != 0 {
        display as error "Error in `scriptname' (rc = `_rc')"
        exit _rc 
    }
}

* 10. Run linkages growth price analysis
local scriptname "`localscriptdir'/6a_run_linkages_growthprice_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 11. Run linkages trade analysis
local scriptname "`localscriptdir'/6b_run_linkages_trade_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}


display as text "--------------------------------------------------------------"
display as text "Main master script completed successfully."
display as text "Completion time: `c(current_time)' on `c(current_date)'"
display as text "--------------------------------------------------------------"

exit 0

