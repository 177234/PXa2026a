

/*

	SAME AS MAIN ONE, BUT WITH ONLY CONTROLS.

	NOTE: Main sub-do-file for rolling analysis in the 4-d analysis file.

	May 24, 2021. Then May 2023.

*/


****. A. Preparation. ****

// NOTE: Common to all loops. Now redundant, but to be safe.

* Define local temporary file for regression dataset.
capture: tempfile drop tmpfile
tempfile tmpfile

* Toggle replace local
local replace "replace"

* All regs have controls.
local regressortype "basic_regressors"


****. B. Outer loop over the outcome variables. ****  


* Loop over outcomes.
foreach variable of local outcomevariablelist {

	// Start model number.
	local modelnumber = 1

	*** Execute regression.
	reghdfe `variable' i.hci##ib(1972).year ///
			``regressortype'' , ///
		absorb( id year ) ///
		vce( cluster id ) noconstant

	
	** ESTOUT: Save regression table, model for estout.
	estimates store output_`variable'_`modelnumber'

	* Add FEs to estout
	estadd local id_fe Yes
	estadd local year_fe Yes

	* Add controls.
	if "`regressortype'" == "basic_regressors" {
		estadd local control_indicator Yes
	}
	else {
		estadd local control_indicator No
	}
	

	* Add number of clusters to estout 
	estadd scalar N_cluster = e( N_clust )



	** JOINT TEST: Run test and save test, with regular REGSAVE:
	
	make_pretest_vars "1.hci" "`variable'"

	test `r(result)'
	local pre_ftest = `r(F)'
	local pre_testprob = `r(p)'

	* Add test results to estout.
	estadd scalar Fs r(F)
	estadd scalar ps r(p)



	*** REGSAVE: regression output and the TEST results:
	regsave using "`tmpfile'", ci ///
		addlabel(outcome,`variable',regressortype,`regressortype',fixedeffects,"id year",command,`e(cmd)') `replace'	



	*** MISC: Model iteration, etc.

	* Model counter.
	local modelnumber = `modelnumber' + 1

	* Replacement switch for REGSAVE.
	local replace "append"

} // Loop over outcomes. 


