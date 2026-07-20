*------------------------------------------------------------------------------*
* What this does:
*
*   KOREA ONLY - DIFFERENCE TRADE REGRESSIONS WITH PPMLHDFE
*
*   Stata packages:
*   - ssc install ppmlhdfe
*   - ssc install reghdfe
*
* Outputs: 
*   - did_largerolling_koreatrade_ppml_rca_results_estout.csv
*   - did_largerolling_koreatrade_ppml_rca_all_results.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*

// PROGRAM: make_pretest_vars
capture program drop make_pretest_vars
program define make_pretest_vars, rclass

	* Set program arguments
	args regressorlistforloop outcomeargument

	* Create an empty local to store the list of regressors to test
	local listofregressorstotest
	
	* Identify years before the baseline year (1972where outcome is not missing.
	levelsof year if year < 1972 & !missing( `outcomeargument' ) , local(yearlist) clean


	* Create and store interaction terms between each of these years and each regressor
	* Loop over each year AND each regressor to make the interactions
	foreach yearstring of local yearlist {
		foreach variablestring of local regressorlistforloop {
			* Add interaction to regressor string list.
			local listofregressorstotest `variablestring'#`yearstring'.year `listofregressorstotest'
		} 
	}

	* Return the interaction terms as a local called result.
	return local result `"`listofregressorstotest'"'	

end


// PROGRAM: export_reg_results
// This is run in the sub-do file regression.
* This program exports two versions of the regression results to csv files.

capture program drop export_reg_results
program define export_reg_results, rclass

	* Set program arguments
	args tmpfile regressiondir outputfilenameprefix
	
	*** A. Save Estout ***
	estout output_* ///
		using "./data/intermediate_datasets/`outputfilenameprefix'_results_estout.csv" , ///
			replace ///
				cells(b(star fmt(3)) se(par fmt(3))) ///
				starlevels(* 0.10 ** 0.05 *** .01) ///
				stats(id_fe year_fe control_indicator rsqalt N N_cluster Fs ps, fmt(%9.3f %9.3f %9.3f 3 0 0 %9.3f) ///
					labels("Industry Effects" "Year Effects" "Controls" R2 Observations Clusters "Joint Test of Pre-Trend (F-Test)" "Joint Test of Pre-Trend (p-values)")) ///
				numbers noomitted nobaselevels ///
				mlabels(none) ///
				collabels(none) ///
				keep( "1*hci*year*" )

	*** B. Save Regsave ***
	use "`tmpfile'", clear

	* Define a local macro with all the regular expressions that identify variables to drop
	local regex_list ///
	    "^1[0-9][0-9][0-9]*.year" ///
	    "^1[0-9][0-9][0-9].year" ///
	    "1[0-9][0-9][0-9]o.year" ///
	    "_cons" ///
	    "^0b.hci" ///
	    "#c.(h|l)_(c|avg|y)" ///
	    "^1972b.year$" ///
	    "^1o.hci$" ///
	    "^o.hci" ///
  	    "(c(o)?.*_0|o.[_aA-zZ]+_0)"

    * Drop variables that match any of the regular expressions and contain "reg" in their command column
	foreach stringtomatch in `regex_list' {
	    capture drop if regexm(var, `"`stringtomatch'"') == 1 & regexm(command, "reg|ppml") == 1
	}	
	outsheet using  "./data/intermediate_datasets/`outputfilenameprefix'_all_results.csv", ///
			comma replace
	capture: tempfile drop tmpfile
	tempfile tmpfile
end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*
local inputfile "./data/input/comtrade_merged_harmonized_panel_cleaned4reg_4digit.dta"

*------------------------------------------------------------------------------*
* CORE TRADE REGRESSIONS IN PAPER : RCA COMPARATIVE ADV.
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* FLEXIBLE REGRESSIONS
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* A. SETUP REGRESSION
*------------------------------------------------------------------------------*

**** i. PREPARE DATA. ****
use "`inputfile'", clear 

* Clear any estimates in memory.
estimates clear
capture: estfe . output_*, restore

* Drop tempfile 'tmpfile' and generate a new empty one.
capture: tempfile drop tmpfile
tempfile tmpfile

* Output file name prefix.
local outputfilenameprefix did_largerolling_koreatrade_ppml_rca

**** ii. REGRESSION PARAMETERS. ****

* Key outcomes: output...
local outcomevariablelist rca_core h_rca_core rca_cdk rca_dummy l_export_sh  

* Regressors: interactions method is diff than OLS for PPML.
local basic_regressors c.l_costs_0#b(1972).year c.l_avg_wages_0#b(1972).year c.l_y_n_0#b(1972).year c.l_avg_size_0#b(1972).year
local regressortype "basic_regressors"

* Toggle replace local when DO file is opened.
local replace "replace"

*------------------------------------------------------------------------------*
* B. LOOP THROUGH REGRESSION PARAMETERS
*------------------------------------------------------------------------------*

***  a. LOOP OVER OUTCOMES.
foreach variable of local outcomevariablelist {

	// Initialize model number.
	local modelnumber = 1

	*** b. EXECUTE REGRESSION.

	if regexm("`variable'", "dummy|cdk|h_|l_") {

		* Use reghdfe for non-zero and binary.
		reghdfe `variable' i.hci##ib(1972).year , ///
			absorb( id year ``regressortype'') ///
			vce(cluster id) 

		local adjusted_r2 = e(r2_a)
	}
	else {
		* Else use PPML default.
		ppmlhdfe `variable' i.hci##ib(1972).year , ///
			absorb( id year ``regressortype'') ///
			vce(cluster id) 

		* Store R^2 in local
		local adjusted_r2 = e(r2_p)
	}

	*** c. POST REGRESSION SAVING AND MISC.

	** ESTOUT: Save regression table, model for estout.
	estimates store output_`variable'_`modelnumber'

	* Add FEs to estout
	estadd local id_fe Yes
	estadd local year_fe Yes
	
	* Add r2...
	estadd scalar rsqalt = `adjusted_r2'

	* Add Control indicator
	if "`regressortype'" == "basic_regressors" {
		estadd local control_indicator Yes
	}
	else {
		estadd local control_indicator No
	}
	
	* Add number of clusters to estout 
	estadd scalar N_cluster = e( N_clust )


	** JOINT TEST: Run test and save test, with regular REGSAVE:
	if regexm("`variable'", "dummy|cdk|h_|l_") {
		make_pretest_vars "1.hci" "`variable'"

		test `r(result)'
		local pre_ftest = `r(F)'
		local pre_testprob = `r(p)'

		* Add test results to estout.
		estadd scalar Fs r(F)
		estadd scalar ps r(p)
	}
	else {
		make_pretest_vars "1.hci" "`variable'"

		test `r(result)'
		local pre_ftest = `r(chi2)'
		local pre_testprob = `r(p)'

		* Add test results to estout.
		estadd scalar Fs r(chi2)
		estadd scalar ps r(p)
	}

	*** d. REGSAVE: regression output and the TEST results:
	regsave using "`tmpfile'", ci ///
		addlabel(outcome,`variable',regressortype,`regressortype',fixedeffects,"id year",command,`e(cmd)') `replace'
	local modelnumber = `modelnumber' + 1
	local replace "append"
} // Loop over outcomes

*------------------------------------------------------------------------------*
* C. SAVE REGRESSION OUTPUT: ESTOUT AND REGSAVE DATASET
*------------------------------------------------------------------------------*
export_reg_results `tmpfile' `"./data/intermediate_datasets"' `outputfilenameprefix' `estoutkeep_rolling'
