*------------------------------------------------------------------------------*
* NOTES
*------------------------------------------------------------------------------*
* + What this does:
* 	CORE differences-in-differences/rolling analysis
* 	but for robustness with continuous variable.
* + Inputs: 
* 	mms_continuous_analysis.dta
*
* + Outputs: 
* 	did_largerolling_continuous_4d_all_results.csv
* 	did_largerolling_continuous_4d_results_estout.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*
capture program drop export_reg_results
program define export_reg_results, rclass
	args tmpfile outputfilenameprefix
	use "`tmpfile'", clear

	* Clean
	capture: drop if regexm( var, "_cons|^o.share_hci$" ) == 1
	capture: drop if (regexm( var, "^1[0-9][0-9][0-9]*.year" ) == 1 & ///
						!regexm( var, "share" ) == 1 ///
					  	regexm( command, "reg" ) == 1)
	capture: drop if regexm( var, "^0b.hci" ) == 1 & ///
					 regexm( command, "reg" ) == 1
	capture: drop if regexm( var, "#c.(l|h)_(c|avg|y)" ) == 1 & ///
					 regexm( command, "reg" ) == 1

	capture: drop if regexm( var, "^1972b.year$" ) == 1 & ///
					 regexm( command, "reg" ) == 1
	
	capture: drop if regexm( var, "^1o.hci$" ) == 1 & ///
					 regexm( command, "reg" ) == 1
	
	capture: drop if regexm( var, "^o.hci" ) == 1 & ///
					 regexm( command, "reg" ) == 1

	* Out and clean up.
	outsheet using  "./data/intermediate_datasets/`outputfilenameprefix'_all_results.csv", ///
			comma replace
	capture: tempfile drop tmpfile
	tempfile tmpfile

end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*
local inputfile "./data/input/supp/mms_continuous_analysis.dta"
use "`inputfile'", clear 
capture: tempfile drop tmpfile
tempfile tmpfile

* Arguments
local replace "replace"
local outputfilenameprefix did_largerolling_continuous_4d 
local outcomevariablelist l_ship l_y_n l_ppi l_workers l_avg_wages l_est l_ship_sh l_lab_sh
local basic_regressors c.(l_avg_wages_0 l_avg_size_0 l_costs_0 l_y_n_0)##ib(1972).year

* Loop over outcomes.
foreach variable of local outcomevariablelist {
	local modelnumber = 1
	reghdfe `variable' c.share_hci##ib(1972).year , ///
					absorb( id year ``basic_regressors'') ///
					vce(cluster id)
	regsave using "`tmpfile'", ci ///
		addlabel(outcome,`variable', standarderror,"vce(cluster id)",regressortype,`basic_regressors',fixedeffects,"id year",command,`e(cmd)') `replace'
	local modelnumber = `modelnumber' + 1
	local replace "append"
}

* Format and save all results for use in R.
export_reg_results `tmpfile' `outputfilenameprefix'
