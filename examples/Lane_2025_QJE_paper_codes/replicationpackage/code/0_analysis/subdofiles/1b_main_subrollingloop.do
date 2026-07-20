

/*

	MAIN Do-file rolling loop (MUST BE "INCLUDED" IN PARENT DO FILE.)


	NOTE: Main sub-do-file for rolling analysis in growth analysis file.

	May 24, 2021. Then May 2023.

*/


**** 0. Preparation. ****


// NOTE: Common to all loops. Now redundant, but to be safe.


* Define local temporary file for regression dataset.
capture: tempfile drop tmpfile
tempfile tmpfile

capture: tempfile drop tmpfile2
tempfile tmpfile2

* Toggle replace local
local replace "replace"

* Key controls.
local basic_regressors c.(l_avg_wages_0 l_avg_size_0 l_costs_0 l_y_n_0)##ib(1972).year



****. Outer loop over the outcome variables. ****  

* Absorb.
// NOTE: For simplicity, we only absorb ID, year in reg.
// And to build margin plots.
local fixedeffects "id"


* Loop over outcomes.
foreach variable of local outcomevariablelist {


	* Start model number.
	local modelnumber = 1

	* Loop over specifications with/without covariates:
	foreach regressortype in "" "basic_regressors" {
		

		*** A. EXECUTE REGRESSION.
		reghdfe `variable' i.hci##ib(1972).year ///
				``regressortype'' , ///
			absorb( `fixedeffects' ) ///
			vce(cluster id)

		
		*** B. POST REGRESSION SAVING AND MISC.

		** ESTOUT: Save regression table, model for estout.
		estimates store output_`variable'_`modelnumber'

		* Add FEs to estout
		estadd local id_fe Yes
		estadd local year_fe Yes

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


		** REGSAVE: regression output and the TEST results:
		regsave using "`tmpfile'", ci ///
			addlabel(outcome,`variable',regressortype,`regressortype',fixedeffects,"`fixedeffects'",command,`e(cmd)' ) `replace'

		
		** Save margins model. REGSAVE part 2:
		savemarginpredictionplots


		* REGSAVE using the second set of options.
		regsave using "`tmpfile2'", ci ///
			addlabel(outcome,`variable',regressortype,`regressortype',fixedeffects,"`fixedeffects'",command,`e(cmd)' ) `replace'



		*** D. MISC: MODEL ITERATION, ETC.

		* Model counter.
		local modelnumber = `modelnumber' + 1

		* Replacement switch for REGSAVE.
		local replace "append"

	} // Loop over no controls or controls.
} // Loop over outcomes. 
