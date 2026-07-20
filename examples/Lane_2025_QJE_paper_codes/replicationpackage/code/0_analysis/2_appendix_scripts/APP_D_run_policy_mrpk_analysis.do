*------------------------------------------------------------------------------*
* What this does: 
*   Generates the MRPK analysis using regression loops for the policy Robustness section.
*
* Inputs: 
*   - Harmonized MMS files 1970-1987. mms_MRPK_5digit.dta
*
* Outputs: 
*   did_largerolling_mrpk_results_estout.csv 
*	did_largerolling_mrpk_all_results}.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*

// PROGRAM: Load and prepare the datasets for each chunk.
capture program drop prep_data
program define prep_data

	args filenameargument 
	
	use "`filenameargument'", clear 
	estimates clear

	//* Capture, empty estfe if it has been run already.
	capture: estfe . output_*, clear
end


// PROGRAM: For saving regression dumps.
capture program drop export_reg_results
program define export_reg_results, rclass

	* Pass locals
	args tmpfile regressiondir outputfilenameprefix estoutoptions

	* Run estout.
	estout output_* ///
		using "./data/intermediate_datasets/`outputfilenameprefix'_results_estout.csv" , ///
			replace cells(b(star fmt(3)) se(par fmt(3))) ///
					starlevels(* 0.10 ** 0.05 *** .01) ///
					stats(id_fe year_fe r2 N N_cluster, fmt(%9.3f %9.3f 3 0 0) ///
					labels("Industry Effect" "Year Effect" "\(R^2\)" Observations Clusters)) ///
					numbers  noomitted nobaselevels ///
					collabels(none) ///
					keep( `estoutoptions' )

	// 2 - REGSAVE PART 

	* Format and outsheet results.

	* Load the datasets with saved regression results:
	use "`tmpfile'", clear
	
	* Define a local macro with all the regular expressions for the drop operations
	local regex_list "^1o.hci" ///
	    "^1.hci#19[0-9][0-9].year$" ///
	    "^1[0-9][0-9][0-9]*.year" ///
	    "^0b.hci|0b.hci$" ///
	    "#c.h_(c|avg|y)" ///
	    "^1972b.year$" ///
	    "^1o.hci$" ///
	    "^o.hci|o.hci$" ///
	    "0b.post" ///
	    "1o.post"

	* Loop over each regular expression and apply the drop condition
	foreach string in `regex_list' {
	    capture: drop if regexm(var, `"`string'"') == 1 & ///
							regexm(command, "reg") == 1
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

* Main input file.
local inputfile "./data/input/supp/mms_MRPK_5digit.dta"

*------------------------------------------------------------------------------*
* 1. MRPK REGRESSIONS
*------------------------------------------------------------------------------*


*------------------------------------------------------------------------------*
* A. SETUP REGRESSION PARAMETERS.
*------------------------------------------------------------------------------*

* Load and prepare data.
prep_data "`inputfile'"

* First part of the output file name:
local outputfilenameprefix did_largerolling_mrpk

* Load and prepare data.
prep_data "`inputfile'"

* First part of the output file name:
local outputfilenameprefix did_largerolling_mrpk

* Key outcomes:
local outcomevariablelist l_inv_tot l_costs l_workers l_ship

* The "extra interaction" for MRPK
local interaction "hi_alphamrpk"

* Common ESTOUT arguments 
local estoutkeep_rolling "1*mrpk*year*"

*------------------------------------------------------------------------------*
* B. LOOP THROUGH REGRESSION PARAMETERS.
*------------------------------------------------------------------------------* 

* i. Prepare for the loop.

* Define local temporary file for regression data set.
capture: tempfile drop tmpfile
tempfile tmpfile

* Toggle replace local.
local replace "replace"

* ii. Outer loop over the outcome variables. 

* Loop over outcomes.
foreach variable of local outcomevariablelist {

	// Start model number.
	local modelnumber = 1

	* Loop over constraint types.
	foreach constrainttype in "if hci == 1" "if hci == 0" {

			* A. EXECUTE REGRESSION.
			reghdfe `variable' i.`interaction'##ib(1972).year ///
						`constrainttype' , ///
					absorb( id year ) ///
					vce(cluster id)

			* B. POST REGRESSION SAVING AND MISC.

			* ESTOUT: Save regression table, model for estout.
			estimates store output_`variable'_`modelnumber'

			* Add number of clusters. 
			estadd scalar N_cluster = e( N_clust )

			* Add FEs to estout
			estadd local id_fe Yes
			estadd local year_fe Yes

			** REGSAVE: regression output and the TEST results:
			regsave using "`tmpfile'", ci ///
				addlabel(outcome,`variable', standarderror,`basic_cluster',constrainttype,`constrainttype',fixedeffects,"id year",command,`e(cmd)',triple,`interaction') `replace'
			
			* C. MISC: MODEL ITERATION, ETC.

			* Model counter.
			local modelnumber = `modelnumber' + 1

			* Replacement switch for REGSAVE.
			local replace "append"
	} // Loop over constraints.
} // Loop over outcomes.


*------------------------------------------------------------------------------*
* C. SAVE REGRESSION OUTPUT: REGSAVE DATASET.
*------------------------------------------------------------------------------

* Format and save all results for use in R.
export_reg_results `tmpfile' `"./data/intermediate_datasets"' `outputfilenameprefix' `estoutkeep_rolling'
