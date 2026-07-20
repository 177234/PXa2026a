*------------------------------------------------------------------------------*
* What this does:
*   Runs the crowding out regressions.
* Inputs: mms_crowding_out.dta
*
* Outputs: 
*   Regression outputs starting with, 
*   - did_largerolling_crowding_basic_results_estout.csv
*   - did_largerolling_crowding_basic_all_results.csv
*   - did_largerolling_crowding_intensity_results_estout.csv
*   - did_largerolling_crowding_intensity_all_results.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*

// Load and prepare the datasets for each chunk.
capture program drop prep_data
program define prep_data

	args filenameargument 

	
	use "`filenameargument'", clear 
	estimates clear

	//* Capture, empty estfe if it has been run already.
	capture: estfe . output_*, clear
	
	* Replace post for most analysis.
	capture: drop post
	gen post = 0 
	replace post = 1 if year >= 1973
end


// Program for saving regression dumps.
capture program drop export_reg_results
program define export_reg_results, rclass

	* Pass locals
	args tmpfile regressiondir outputfilenameprefix

	* Format and outsheet results.
	* Load the datasets with saved regression results:
	use "`tmpfile'", clear
	
	* Capture junk lines, all zeros.
	capture: drop if regexm( var, "^_cons" ) == 1

	capture: drop if regexm( var, "^1o.hci" ) == 1 & ///
					 regexm( command, "reg" ) == 1
	
	capture: drop if regexm( var, "^0b.hci" ) == 1 & ///
					 regexm( command, "reg" ) == 1

	capture: drop if regexm( var, "^1o.hci$" ) == 1 & ///
					 regexm( command, "reg" ) == 1
	
	capture: drop if regexm( var, "^o.hci" ) == 1 & ///
					 regexm( command, "reg" ) == 1
	
	capture: drop if regexm( var, "0b.post" ) == 1 & ///
					 regexm( command, "reg" ) == 1

	capture: drop if regexm( var, "1o.post" ) == 1 & ///
					 regexm( command, "reg" ) == 1

	outsheet using  "./data/intermediate_datasets/`outputfilenameprefix'_all_results.csv", ///
			comma replace

	* Clean up the file for next run.
	capture: tempfile drop tmpfile
	tempfile tmpfile

end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*

* Main data file.
local inputfile "./data/input/supp/mms_crowding_out.dta"

*------------------------------------------------------------------------------*
* 1. - BASIC CROWDING OUT REGRESSION.
*------------------------------------------------------------------------------*

* i. Load and prepare data.
prep_data "`inputfile'"

* ii. Define local temporary file for regression dataset.
capture: tempfile drop tmpfile
tempfile tmpfile

* First part of the output file name:
local outputfilenameprefix did_largerolling_crowding_basic


* Outcome variable.
local variable l_inv_tot 

* FEs: basic regression with id indicator. Year included in diff part.
local fixedeffects "id" 

* The main regressor is simply year; label for regression output.
local mainregressor "year"


* Toggle replace local.
local replace "replace"


* iii. Loop over constraints.
foreach constrainttype in "if hci == 1" "if hci == 0" {
	
	// Start model number.
	local modelnumber = 1

	* A. EXECUTE REGRESSION.
	reghdfe `variable' ib(1972).year ///
			`constrainttype' , ///
		absorb( `fixedeffects' ) ///
		vce(cluster id)

	
	* B. POST REGRESSION SAVING AND MISC.

	* ESTOUT: Save regression table, model for estout.
	estimates store output_`variable'_`modelnumber'

	* Add number of clusters. 
	estadd scalar N_cluster = e( N_clust )


	** REGSAVE: regression output and the TEST results:
	regsave using "`tmpfile'", ci ///
		addlabel(outcome,`variable',constrainttype,`constrainttype',fixedeffects,"`fixedeffects'",command,`e(cmd)',mainregressor,`mainregressor') `replace'

	
	* C. MISC: MODEL ITERATION, ETC.

	* Model counter.
	local modelnumber = `modelnumber' + 1

	* Replacement switch for REGSAVE.
	local replace "append"


} // Loop over the constraints. 


* iv. SAVE REGRESSION OUTPUT: ESTOUT AND REGSAVE DATASET.

* Only uses one FE.

estfe . output_*, labels(id "Industry Effect") 
return list

* Run estout.
estout output_* ///
	using "./data/intermediate_datasets/`outputfilenameprefix'_results_estout.csv" , ///
		replace cells(b(star fmt(3)) se(par fmt(3))) ///
				stats(r2 N N_cluster Fs ps, fmt(3 0 0) ///
					labels("\(R^2\)" Observations Clusters)) numbers ///
				indicate( `r(indicate_fe)' ) ///
				collabels(none) ///
				keep( "1*year*"  )

* Format and save all results for use in R.
export_reg_results `tmpfile' `"./data/intermediate_datasets"' `outputfilenameprefix'


*------------------------------------------------------------------------------*
* 2. - CROWDING OUT BY CAPITAL INTENSITY.
*------------------------------------------------------------------------------*

* i. SETUP DATA AND REGRESSION PARAMETERS.

* Load and prepare data.
prep_data "`inputfile'"
capture: rename l_k_n l_k_intensity // More descriptive.

* First part of the output file name:
local outputfilenameprefix did_largerolling_crowding_intensity

* Define local temporary file for regression dataset.
capture: tempfile drop tmpfile
tempfile tmpfile

* Outcome variables.
local variable l_inv_tot 

* "Main regressor" is the cap intensity interaction:
local mainregressor "l_k_intensity"

* FEs here (now two-way)
local fixedeffects "id year"

* Toggle replace local.
local replace "replace"

* ii. LOOP THROUGH REGRESSION PARAMETERS. 

* Loop over constraints.
foreach constrainttype in "if hci == 1" "if hci == 0" {

	// Start model number.
	local modelnumber = 1

	* A. EXECUTE REGRESSION.
	reghdfe `variable' ib(1972).year##c.(l_k_intensity) ///
				`constrainttype' , ///
				absorb( `fixedeffects'  ) ///
				vce(cluster id)

	* B. POST REGRESSION SAVING AND MISC.

	* ESTOUT: Save regression table, model for estout.
	estimates store output_`variable'_`modelnumber'

	* Add number of clusters. 
	estadd scalar N_cluster = e( N_clust )

	* REGSAVE: regression output and the TEST results:
	regsave using "`tmpfile'", ci ///
		addlabel(outcome,`variable',constrainttype,`constrainttype',fixedeffects,"`fixedeffects'",command,`e(cmd)',mainregressor,`mainregressor') `replace'
	
	* C. MISC: MODEL ITERATION, ETC.

	* Model counter.
	local modelnumber = `modelnumber' + 1

	* Replacement switch for REGSAVE.
	local replace "append"

}  // Loop over the constraints. 


* iv. SAVE REGRESSION OUTPUT: ESTOUT AND REGSAVE DATASET.

* Only uses one FE.

estfe . output_*, labels(id "Industry Effect" year "Year Effect") 
return list

* Run estout.
estout output_* ///
	using "./data/intermediate_datasets/`outputfilenameprefix'_results_estout.csv" , ///
		replace cells(b(star fmt(3)) se(par fmt(3))) ///
				stats(r2 N N_cluster, fmt(3 0 0) ///
					labels("\(R^2\)" Observations Clusters)) numbers ///
				indicate( `r(indicate_fe)' ) ///
				collabels(none) ///
				keep( "*_intensity*" )
				
* Format and save all results for use in R.
export_reg_results `tmpfile' `"./data/intermediate_datasets"' `outputfilenameprefix'
