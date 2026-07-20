*------------------------------------------------------------------------------*
* Project:      South Korea Industrial Policy Project
* Description:  Master do file for South Korea Industrial Policy APPENDIX
*------------------------------------------------------------------------------*
display as text "--------------------------------------------------------------"
display as text "Running appendix master script analyses"
display as text "Working Directory: `c(pwd)'"
display as text "Date & Time      : `c(current_date)' `c(current_time)'"
display as text "--------------------------------------------------------------"

local localscriptdir "./code/0_analysis/2_appendix_scripts"

*------------------------------------------------------------------------------*
* 1. Run price and yn analysis
local scriptname "`localscriptdir'/APP_B_run_priceandyn_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 2. Run industry TFP analysis
local scriptname "`localscriptdir'/APP_B_run_industry_tfp_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 3. Run world trade analysis (probability)
local scriptname "`localscriptdir'/APP_C_run_worldtrade_analysis_prob.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 4. Run LBD micro analysis
// NOTE: Source file is not included in the replication package.
if "$RUN_MICRO" == "1" {
    local scriptname "`localscriptdir'/APP_D_run_lbd_micro_analysis.do"
    noisily do "`scriptname'"
    if _rc != 0 {
        display as error "Error in `scriptname' (rc = `_rc')"
        exit _rc 
    }
}

* 5. Run policy aggregate figures
local scriptname "`localscriptdir'/APP_D_run_policy_aggregate_figures.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 6. Run policy crowding out analysis
local scriptname "`localscriptdir'/APP_D_run_policy_crowdingout_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 7. Run policy MRPK analysis
local scriptname "`localscriptdir'/APP_D_run_policy_mrpk_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 8. Run policy trade analysis
local scriptname "`localscriptdir'/APP_D_run_policy_trade_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 9. Run linkages mechanisms analysis
local scriptname "`localscriptdir'/APP_E_run_linkages_mechanisms_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 10. Run linkages more outcomes analysis
local scriptname "`localscriptdir'/APP_E_run_linkages_morecomes_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 11. Run SUTVA analysis
local scriptname "`localscriptdir'/APP_G_run_sutva_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

*------------------------------------------------------------------------------*
display as text "-----------------------------------------------------------"
display as text "Appendix master script completed successfully."
display as text "Completion time: `c(current_time)' on `c(current_date)'"
display as text "-----------------------------------------------------------"

exit 0

