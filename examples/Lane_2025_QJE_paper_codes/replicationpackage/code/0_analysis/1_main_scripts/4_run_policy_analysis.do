*------------------------------------------------------------------------------*
* What this does:	
* Main analysis for investment for the policy section of the paper. 
*
* Inputs: 
*	mms_policy_4digit.dta
*	mms_policy_5digit.dta
*
* Outputs: 
*	- did_largerolling_mainpolicycapital.csv
*	- did_largerolling_mainpolicycapital_results_papermain.csv
*	- did_largerolling_mainpolicycapital_4digit.csv
*	- did_largerolling_mainpolicycapital_4digit_results_papermain.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*

// Program to load and prepare the datasets for each chunk.
capture program drop prep_data
program define prep_data
	args filenameargument 
	use "`filenameargument'", clear 
	estimates clear
end


* Program for generating f-test statistics
capture program drop make_pretest_vars
program define make_pretest_vars, rclass

	* Pass strings
	args regressorlistforloop outcomeargument
	
	* Get years before the baseline year ... where outcome is not missing.
	levelsof year if year < 1972 & !missing( `outcomeargument' ) , local(yearlist) clean

	* Make result local...
	local listofregressorstotest

	* Loop over each year AND each regressor to make the interaction
	foreach yearstring of local yearlist {
		foreach variablestring of local regressorlistforloop {
			* Add interaction to regressor string list.
			local listofregressorstotest `variablestring'#`yearstring'.year `listofregressorstotest'
		} 
	}

	* Return a result for local. Program must be rclass to pass this.
	return local result `"`listofregressorstotest'"'	
end


*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*


*------------------------------------------------------------------------------*
* I. - CORE INVESTMENT REGRESSIONS IN PAPER
*------------------------------------------------------------------------------*
local inputfile "./data/input/mms_policy_5digit.dta"
local inputfile_4 "./data/input/mms_policy_4digit.dta"

*------------------------------------------------------------------------------*
* 1. MAIN 5-DIGIT WORKFLOW
*------------------------------------------------------------------------------*

* A. SETUP REGRESSION PARAMETERS.
prep_data "`inputfile'"

* First part of the output file name:
local outputfilenameprefix did_largerolling_mainpolicycapital

* Key outcomes.
local outcomevariablelist l_costs l_m_n l_inv_tot l_i_n l_stock_tot

* B. LOOP THROUGH REGRESSION PARAMETERS. 

* i. PREPARE THINGS FOR REGRESSION LOOP.
capture: tempfile drop tmpfile
tempfile tmpfile
local replace "replace"

* ii. LOOP THROUGH REGRESSION PARAMETERS.  
foreach variable of local outcomevariablelist {

	* a. Execute regression.
	reghdfe `variable' i.hci##ib(1972).year, ///
		absorb( id year ) ///
		vce(cluster id)
	
	* Post regression:
	estimates store output_`variable'
	estadd scalar N_cluster = e( N_clust )
	estadd local id_fe Yes
	estadd local year_fe Yes

	*** b. JOINT TEST: Run test and save test, with regular REGSAVE:
	make_pretest_vars "1.hci" "`variable'"

	test `r(result)'
	local pre_ftest = `r(F)'
	local pre_testprob = `r(p)'

	* Add test results to estout.
	estadd scalar Fs r(F)
	estadd scalar ps r(p)

	*** c. REGSAVE: regression output and the TEST results:
	regsave using "`tmpfile'", ci ///
		addlabel(outcome,`variable',fixedeffects,"id year",command,`e(cmd)') `replace'

	* Replacement switch for REGSAVE.
	local replace "append"

} // LOOP over outcomes


* C. SAVE REGRESSION OUTPUT: ESTOUT AND RESULTS DATASET.

* 1 - Save ESTOUT regression table: CSV output.

* Save estout output.
estout output_* ///
	using "./data/intermediate_datasets/`outputfilenameprefix'.csv" , ///
	replace ///
	cells(b(star fmt(3)) se(par fmt(3))) ///
	starlevels(* 0.10 ** 0.05 *** .01) ///
	stats(id_fe year_fe r2 N N_cluster Fs ps, fmt(%9.3f %9.3f 3 0 0 %9.3f %9.3f) ///
		labels("Industry Effects" "Year Effects" "\(R^2\)" Observations Clusters "Joint Test of Pre-Trend (F-Test)" "Joint Test of Pre-Trend (p-values)" )) ///
	numbers noomitted nobaselevels ///
	collabels(none) ///
	mlabels(none) ///
	keep( 1*hci*year* )

// 2) - Generate large dataset set of saved values.
use "`tmpfile'", clear

* Define a local macro with all the regular expressions
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
	    "(c(o)?.*_0|o.[_aA-zZ]+_0)" ///
    "0b.post" ///
    "1o.post"

* Loop over each regular expression and apply the drop condition
foreach stringtomatch in `regex_list' {
    capture drop if regexm(var, `"`stringtomatch'"') == 1 & regexm(command, "reg|ppml") == 1
}

outsheet using ///
	"./data/intermediate_datasets/`outputfilenameprefix'_results_papermain.csv", ///
	comma replace

*------------------------------------------------------------------------------*
* 2. MAIN 4-DIGIT WORKFLOW
*------------------------------------------------------------------------------*

* A. SETUP REGRESSION PARAMETERS.

* Load and prepare data.
prep_data "`inputfile_4'"

* First part of the output file name:
local outputfilenameprefix did_largerolling_mainpolicycapital_4digit

* Key outcomes.
local outcomevariablelist l_costs l_m_n l_inv_tot l_i_n


* B. LOOP THROUGH REGRESSION PARAMETERS. 

* i. PREPARE THINGS FOR REGRESSION LOOP.

* Define local temporary file for regression dataset.
capture: tempfile drop tmpfile
tempfile tmpfile

* Toggle replace local
local replace "replace"

* ii. LOOP THROUGH REGRESSION PARAMETERS.  

* Loop over outcomes.
foreach variable of local outcomevariablelist {

	* a. Execute regression.
	reghdfe `variable' i.hci##ib(1972).year, ///
		absorb( id year ) ///
		vce(cluster id)
	
	** ESTOUT: Save regression table, model for estout. **
	estimates store output_`variable'

	* Add number of clusters. *
	estadd scalar N_cluster = e( N_clust )

	* Add FEs to estout
	estadd local id_fe Yes
	estadd local year_fe Yes

	*** b. JOINT TEST: Run test and save test, with regular REGSAVE:
	make_pretest_vars "1.hci" "`variable'"

	test `r(result)'
	local pre_ftest = `r(F)'
	local pre_testprob = `r(p)'

	* Add test results to estout.
	estadd scalar Fs r(F)
	estadd scalar ps r(p)

	*** c. REGSAVE: regression output and the TEST results:
	regsave using "`tmpfile'", ci ///
		addlabel(outcome,`variable',fixedeffects,"id year",command,`e(cmd)') `replace'

	* Replacement switch for REGSAVE.
	local replace "append"

} // LOOP over outcomes

* C. SAVE REGRESSION OUTPUT: ESTOUT AND RESULTS DATASET.

* NOTE: `outputfilenameprefix' + .CVS/TEX files. 

* 1 - Save ESTOUT regression table: CSV output.

* Save estout output.
estout output_* ///
	using "./data/intermediate_datasets/`outputfilenameprefix'.csv" , ///
	replace ///
	cells(b(star fmt(3)) se(par fmt(3))) ///
	starlevels(* 0.10 ** 0.05 *** .01) ///
	stats(id_fe year_fe r2 N N_cluster Fs ps, fmt(%9.3f %9.3f 3 0 0 %9.3f %9.3f) ///
		labels("Industry Effects" "Year Effects" "\(R^2\)" Observations Clusters "Joint Test of Pre-Trend (F-Test)" "Joint Test of Pre-Trend (p-values)" )) ///
	numbers noomitted nobaselevels ///
	collabels(none) ///
	mlabels(none) ///
	keep( 1*hci*year* )

// 2) - Generate large dataset set of saved values.
use "`tmpfile'", clear

* Define a local macro with all the regular expressions
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
	    "(c(o)?.*_0|o.[_aA-zZ]+_0)" ///
    "0b.post" ///
    "1o.post"

* Loop over each regular expression and apply the drop condition
foreach stringtomatch in `regex_list' {
    capture drop if regexm(var, `"`stringtomatch'"') == 1 & regexm(command, "reg|ppml") == 1
}

outsheet using ///
	"./data/intermediate_datasets/`outputfilenameprefix'_results_papermain.csv", ///
	comma replace

