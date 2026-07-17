/*
Annotated copy for replication audit.
Original script: Lane2025QJE/replicationpackage/code/0_analysis/1_main_scripts/2a_run_devoutcomes_analysis.do
Purpose: Runs industrial-development outcome analyses.

This file intentionally keeps the original .do extension.
The original code is copied below. Comments in this header identify the
script role, inputs, outputs, and audit linkage. The earlier prose note is
archived at: markdown_notes_archive/2a_run_devoutcomes_analysis_do.md

Audit linkage:
- Methods report: explains the estimating or output logic.
- Derivation report: maps equations/design objects to code.
- Replication report: documents inputs, outputs, and reproducibility limits.

Original code begins after this header.
*/

*------------------------------------------------------------------------------*
* What this does:
*
*   Industrial development outcomes analysis.
*
* Inputs: 
*
*   mms_merged_harmonized_panel_cleaned4reg_4digit.dta
*   mms_merged_harmonized_panel_cleaned4reg_5digit.dta
*
* Outputs: 
*
*   did_largerolling_allproductivity_results_estout.csv
*   did_largerolling_allproductivity_all_results.csv
*   did_largerolling_allproductivity_4d_results_estout.csv
*   did_largerolling_allproductivity_4d_all_results.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*

// PROGRAM: prep_data.
capture program drop prep_data
program define prep_data
	args filenameargument 
	use "`filenameargument'", clear 
	estimates clear
	capture: drop post
	gen post = 0 
	replace post = 1 if year >= 1973
end


// PROGRAM: make_pretest_vars
capture program drop make_pretest_vars
program define make_pretest_vars, rclass
	args regressorlistforloop outcomeargument

	* Initialize local
	local listofregressorstotest
	
	* Identify years before the baseline year.
	levelsof year if year < 1972 & !missing( `outcomeargument' ) , local(yearlist) clean

	* Create and store interactions.
	foreach yearstring of local yearlist {
		foreach variablestring of local regressorlistforloop {
			* Store each interaction term in the local listofregressorstotest
			local listofregressorstotest `variablestring'#`yearstring'.year `listofregressorstotest'
		} 
	}
	return local result `"`listofregressorstotest'"'	
end


// PROGRAM: export_reg_results
capture program drop export_reg_results
program define export_reg_results, rclass
	args tmpfile regressiondir outputfilenameprefix

	* A. Save Estout
	estout output_* ///
		using "./data/intermediate_datasets/`outputfilenameprefix'_results_estout.csv" , ///
			replace ///
				cells(b(star fmt(3)) se(par fmt(3))) ///
				starlevels(* 0.10 ** 0.05 *** .01) ///
				stats(id_fe year_fe control_indicator r2 N N_cluster Fs ps, fmt(%9.3f %9.3f %9.3f 3 0 0 %9.3f) ///
					labels("Industry Effects" "Year Effects" "Controls" "\(R^2\)" Observations Clusters "Joint Test of Pre-Trend (F-Test)" "Joint Test of Pre-Trend (p-values)")) ///
				mlabels(none) ///
				numbers noomitted nobaselevels ///
				collabels(none) ///
				keep( "1*hci*year*" )
	* B. Save Regsave
	use "`tmpfile'", clear

	* String cleaner:
	local regex_list ///
	    "^1[0-9][0-9][0-9]*.year" ///
	    "1[0-9][0-9][0-9]o.year" ///
	    "^0b.hci" ///
	    "#c.(h|l)_(c|avg|y)" ///
	    "^1972b.year$" ///
	    "^1o.hci$" ///
	    "^o.hci" ///
  	    "(c(o)?.*_0|o.[_aA-zZ]+_0)" ///
	    "0b.post" ///
	    "1o.post"
	foreach stringtomatch in `regex_list' {
	    capture drop if regexm(var, `"`stringtomatch'"') == 1 & regexm(command, "reg") == 1
	}

	* Export the results to a CSV file
	outsheet using  "./data/intermediate_datasets/`outputfilenameprefix'_all_results.csv", ///
			comma replace
	capture: tempfile drop tmpfile
	tempfile tmpfile
end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*

* Common regression arguments.
local basic_cluster vce(cluster id)
local basic_regressors c.(l_costs_0 l_avg_wages_0 l_avg_size_0 l_y_n_0)##ib(1972).year
local estoutkeep_rolling "1*hci*year*"

*------------------------------------------------------------------------------*
* I. 5-DIGIT - CORE INDUSTRIAL DEVELOPMENT OUTCOMES.
*------------------------------------------------------------------------------*
local inputfile "./data/input/mms_merged_harmonized_panel_cleaned4reg_5digit.dta"
local outcomevariablelist l_ship_sh l_ppi l_y_n l_avg_size l_est l_workers l_lab_sh  

*------------------------------------------------------------------------------*
* 1 MAIN FLEXIBLE REG.
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* A. SETUP REGRESSION PARAMETERS
*------------------------------------------------------------------------------*
prep_data "`inputfile'"
local replace "replace"
local outputfilenameprefix did_largerolling_allproductivity

*------------------------------------------------------------------------------*
* B. LOOP THROUGH REGRESSION PARAMETERS
*------------------------------------------------------------------------------*
include "./code/0_analysis/subdofiles/2b_devoutcomes_subrollingloop.do"

*------------------------------------------------------------------------------*
* C. SAVE REGRESSION OUTPUT: ESTOUT AND RESULTS DATASET
*------------------------------------------------------------------------------*
export_reg_results `tmpfile' `"./data/intermediate_datasets"' `outputfilenameprefix'

*------------------------------------------------------------------------------*
* II. 4-DIGIT - CORE INDUSTRIAL DEVELOPMENT OUTCOMES.
*------------------------------------------------------------------------------*
local inputfile "./data/input/mms_merged_harmonized_panel_cleaned4reg_4digit.dta"
local outcomevariablelist l_ship_sh l_ppi l_y_n l_avg_size l_est l_workers l_lab_sh  

*------------------------------------------------------------------------------*
* 1 MAIN FLEXIBLE REG.
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* A. SETUP REGRESSION PARAMETERS
*------------------------------------------------------------------------------*
prep_data "`inputfile'"
local replace "replace"
local outputfilenameprefix did_largerolling_allproductivity_4d 

*------------------------------------------------------------------------------*
* B. LOOP THROUGH REGRESSION PARAMETERS
*------------------------------------------------------------------------------*
include "./code/0_analysis/subdofiles/2b_devoutcomes_subrollingloop.do"

*------------------------------------------------------------------------------*
* C. SAVE REGRESSION OUTPUT: ESTOUT AND RESULTS DATASET
*------------------------------------------------------------------------------*
export_reg_results `tmpfile' `"./data/intermediate_datasets"' `outputfilenameprefix'
