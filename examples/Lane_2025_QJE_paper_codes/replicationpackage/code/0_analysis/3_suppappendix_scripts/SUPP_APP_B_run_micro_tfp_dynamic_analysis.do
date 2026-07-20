*------------------------------------------------------------------------------*
* NOTES
*------------------------------------------------------------------------------*
* + What this does:
* 	This file must be run after:
* 		data_cleaning/7_MMS_prepareforanalysis_tfp_estimates_micro.do
* 	which contains the TFP estimates. Performs dynamic event study analysis.
*
* + Inputs: 
* 	Micro Post-1980: mms_TFP_micro.dta
*
* + Outputs:
* 	did_largerolling_results_microtfp_all_results.csv
*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*
capture program drop prep_data
program define prep_data
	args filenameargument 
	use "`filenameargument'", clear 
	estimates clear
	capture: estfe . output_*, clear
	egen ksic_id = group(ksic_merged)
end

capture program drop export_reg_results
program define export_reg_results, rclass

	args tmpfile outputfilenameprefix
	use "`tmpfile'", clear
	capture: drop if regexm( var, "^[10][bo].hci$" ) == 1 & ///
					 regexm( command, "reghdfe" ) == 1

	capture: drop if regexm( var, "^[10][bo].hci$" ) == 1 & ///
					 regexm( command, "reghdfe" ) == 1

	capture: drop if regexm( var, "cons" ) == 1 & ///
					 regexm( command, "reghdfe" ) == 1

	outsheet using  "./data/included_datasets/`outputfilenameprefix'_all_results.csv", ///
			comma replace
	capture: tempfile drop tmpfile
	tempfile tmpfile
end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* I. - ROLLING TFP REGRESSION LOOP
*------------------------------------------------------------------------------*

* A. Load data and prepare regressions.
* NOTE: This file is not included in the replication package.
local inputfile "./data/input/mms_TFP_micro.dta"

use "`inputfile'", clear
estimates clear
egen ksic_id = group(ksic_merged)
local outputfilenameprefix did_largerolling_results_microtfp

* B. Prepare for regressions.
capture: tempfile drop tmpfile
tempfile tmpfile

local outcomevariablelist 
foreach var of varlist tfp_* {
	local outcomevariablelist `var' `outcomevariablelist'
}

local outcomevariablelist "tfp_w tfp_acf tfp_lp tfp_op tfp_ols"
local replace "replace"
local modelnumber = 1

* C. Regression loop.
foreach variable of local outcomevariablelist {
	reghdfe `variable' i.hci##ib(1980).year , ///
			absorb( id year ) ///
			vce( cluster ksic_id id )
	regsave using "`tmpfile'", ci ///
		addlabel(outcome,`variable',regressortype,`regressortype',fixedeffects,"id year",command,`e(cmd)') `replace'
	local modelnumber = `modelnumber' + 1
	local replace "append"
}

* D. Save regression output.
export_reg_results `tmpfile' `outputfilenameprefix'
