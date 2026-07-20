*------------------------------------------------------------------------------*
* Project:      South Korea Industrial Policy Project
* Description:  Master do file for South Korea Industrial Policy SUPP-APPENDIX
*------------------------------------------------------------------------------*
display as text "--------------------------------------------------------------"
display as text "Running supplemental appendix master script analyses"
display as text "Working Directory: `c(pwd)'"
display as text "Date & Time      : `c(current_date)' `c(current_time)'"
display as text "--------------------------------------------------------------"

local localscriptdir "./code/0_analysis/3_suppappendix_scripts"

*------------------------------------------------------------------------------*
* 1. Run policy trade 1968 analysis
local scriptname "`localscriptdir'/SUPP_APP_A_run_policy_trade_1968_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 2. Run 4-digit continuous analysis
local scriptname "`localscriptdir'/SUPP_APP_B_run_4digit_continuous_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 3. Run micro TFP dynamic analysis
// NOTE: Source file is not included in the replication package.
if "$RUN_MICRO" == "1" {
    local scriptname "`localscriptdir'/SUPP_APP_B_run_micro_tfp_dynamic_analysis.do"
    noisily do "`scriptname'"
    if _rc != 0 {
        display as error "Error in `scriptname' (rc = `_rc')"
            exit _rc 
    }
}

* 4. Run UNIDO analysis
// NOTE: Source file is not included in the replication package.
if "$RUN_MICRO" == "1" {
    local scriptname "`localscriptdir'/SUPP_APP_C_run_unido_analysis.do"
    noisily do "`scriptname'"
    if _rc != 0 {
        display as error "Error in `scriptname' (rc = `_rc')"
        exit _rc 
    }
}

* 5. Run policy disaggregated investment analysis
local scriptname "`localscriptdir'/SUPP_APP_D_run_policy_dissagg_investment_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

* 6. Run DD COMTRADE analysis
local scriptname "`localscriptdir'/SUPP_APP_E_run_dd_comtrade_analysis.do"
noisily do "`scriptname'"
if _rc != 0 {
    display as error "Error in `scriptname' (rc = `_rc')"
    exit _rc 
}

display as text "-----------------------------------------------------------"
display as text "Supplemental appendix master script completed successfully."
display as text "Completion time: `c(current_time)' on `c(current_date)'"
display as text "-----------------------------------------------------------"

exit 0

