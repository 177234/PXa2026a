*------------------------------------------------------------------------------*
* What this does:
*   5-digit TFP analysis.
*	
* Inputs: 
*   - mms_TFP_5digit.dta
*
* Outputs: 
*   - did_largerolling_results_tfp_results_estout.csv
*   - did_largerolling_results_tfp_all_results.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*

capture program drop exportregsaveresultdump
program define exportregsaveresultdump, rclass

	* Pass locals
	args tmpfile regressiondir outputfilenameprefix estoutoptions

	local starlevelsstring starlevels(* 0.10 ** 0.05 *** .01)

	estout output_* ///
		using "./data/intermediate_datasets/`outputfilenameprefix'_results_estout.csv" , ///
			replace cells(b(star fmt(3)) se(par fmt(3))) ///	
					`starlevelsstring' ///
					stats(id_fe year_fe r2 N N_cluster, fmt(%9.3f %9.3f 3 0 0) ///
					labels("Industry Effect" "Year Effect" "\(R^2\)" Observations Clusters)) ///
					numbers noomitted nobaselevels ///
					collabels(none) ///
					keep( `estoutoptions' )

	// 2 - REGSAVE PART 
	use "`tmpfile'", clear
	// Not using second file. append using "`tmpfile2'", force	
	local regex_list ///
	    "^1[0-9][0-9][0-9]*.year" ///
	    "^0b.hci" ///
	    "#c.h_(c|avg|y)" ///
	    "#0.korea" ///
	    "^1972b.year$" ///
	    "^o.hci" ///
	    "^1.hci$"

	* Loop over each regular expression and apply the drop condition
	foreach stringtomatch in `regex_list' {
	    capture drop if regexm(var, "`stringtomatch'") == 1 & regexm(command, "reg") == 1
	}

	
	outsheet using  "./data/intermediate_datasets/`outputfilenameprefix'_all_results.csv", ///
			comma replace
			
	* Clean up the file for next run.
	capture: tempfile drop tmpfile
	tempfile tmpfile
end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*

* DATA ARGUMENT
local inputfile "./data/input/mms_TFP_5digit.dta"

*------------------------------------------------------------------------------*
* I. CALCULATE AND EASTIMATE TFPS.
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* 1. - FLEXIBLE REGRESSIONS
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* A. SETUP REGRESSION PARAMETERS
*------------------------------------------------------------------------------*

* Load and prepare data.
use "`inputfile'", clear 
estimates clear

* Output file prefix.
local outputfilenameprefix did_largerolling_results_tfp

* Key outcomes for regressions
local outcomevariablelist 
foreach var of varlist tfp_* {
	local outcomevariablelist `var' `outcomevariablelist'
}

*------------------------------------------------------------------------------*
* B. LOOP THROUGH REGRESSION PARAMETERS
*------------------------------------------------------------------------------*

* NOTE: Common to all loops.

* Define local temporary file for regression dataset.
capture: tempfile drop tmpfile
tempfile tmpfile

* Toggle replace local
local replace "replace"

* Loop through regression parameters.
// Start model number.
local modelnumber = 1


// NOTE: Only basic regressions. 
* Loop over outcomes.
foreach variable of local outcomevariablelist {

	*** i. Execute regression.
	reghdfe `variable' i.hci##ib(1970).year , ///
		absorb( id year ) ///
		vce(cluster id)
	
	** ESTOUT: Save regression table, model for estout.
	estimates store output_`variable'_`modelnumber'

	* Add FEs to estout
	estadd local id_fe Yes
	estadd local year_fe Yes

	* Add number of clusters. 
	estadd scalar N_cluster = e( N_clust )


	*** ii. REGSAVE: regression output and the TEST results:
	regsave using "`tmpfile'", ci ///
		addlabel(outcome,`variable',fixedeffects,"id year",command,`e(cmd)') `replace'
	
	
	*** iii. MISC: Model iteration, etc.

	* Model counter.
	local modelnumber = `modelnumber' + 1

	* Replacement switch for REGSAVE.
	local replace "append"

}

*------------------------------------------------------------------------------*
* C. SAVE REGRESSION OUTPUT: ESTOUT AND REGSAVE DATASET
*------------------------------------------------------------------------------*

* Format and save all results for use in R.
exportregsaveresultdump `tmpfile' `"./data/intermediate_datasets"' `outputfilenameprefix' "1.hci#*"
