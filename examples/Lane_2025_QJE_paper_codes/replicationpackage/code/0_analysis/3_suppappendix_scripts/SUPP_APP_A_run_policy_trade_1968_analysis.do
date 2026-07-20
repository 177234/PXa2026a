*------------------------------------------------------------------------------*
* NOTES
*------------------------------------------------------------------------------*
* + What this does:
* 	Generates analysis for 1968 trade.
*
* + Dependencies:
* 	2_MMS_TRADEPOLICY_mergepolicy_4digit.dta
*
* + Inputs: 
* 	
*
* + Outputs: 
* 	did_output_tradepolicy_1968only_results_estout.csv
*
* + Dates: 
* 	Made, May 2024. Forked from investment file to make trade policy file.
* 	4_run_policy_trade_analysis.do
*
* 	Trade policy was previously part IV. before refactoring 
* 	policy files, and forking into its own.
*
* 	Refactored March 2024. Then refactored May 2024. Renamed to 
* 	SUPP_APP_A_run_policy_trade_1968_analysis.do (minor renaming).
*
*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*
capture program drop prep_data
program define prep_data
	args filenameargument 
	use "`filenameargument'", clear 
	estimates clear
	capture: estfe . output_*, clear
	capture: drop post
	gen post = 0 
	replace post = 1 if year >= 1973

	* Only 1968
	keep if year == 1968

	* Make year group.
	capture: drop t
	egen t = group( year )
	tsset id t
end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*
*------------------------------------------------------------------------------*
* I - 1968 REGRESSIONS FOR TRADE POLICY OUTCOMES.
*------------------------------------------------------------------------------*

* A. Setup dataset.
local inputfile4d "./data/input/tradepolicy_panel.dta"
prep_data "`inputfile4d'"

* B. Setup regression loop parameters.
local outcomevariablelist_output l_tariff l_tariff_wt l_qr l_qr_wt
local outputfilenameprefix did_output_tradepolicy_1968only
local modelnumber = 1

* C. Loop over the type of trade policy.
foreach variable of local outcomevariablelist_output {
	reg `variable' hci, robust

	* Rename to avoid length issues.
	local renamevariable = regexr( "`variable'" , "_wt", "" )
	local renamevariable = regexr( "`renamevariable'" , "\.", "" )
	estimates store output_`renamevariable'_`modelnumber'

	if strpos("`variable'", "_wt") > 0 {
		local weighttypelabel "Weighted"
	} 
	else {
		local weighttypelabel "Regular"
	}
	estadd local weighttype "`weighttypelabel'"
	estadd local year_constraint "1968 Only"
	local modelnumber = `modelnumber' + 1

} // Loop over outcome variables.

* D. Save regression output: ESTOUT and results dataset.
estout output_* ///
	using "./data/intermediate_datasets/`outputfilenameprefix'_results_estout.csv" , ///
		replace cells(b(star fmt(3)) se(par fmt(3))) ///
		stats(year_constraint weighttype r2 N , fmt(%9.3f %9.3f 3 0) ///
			labels(Sample Weighted "\(R^2\)" Observations)) ///
		numbers ///
		mlabels( none ) ///
		keep( *hci* )
