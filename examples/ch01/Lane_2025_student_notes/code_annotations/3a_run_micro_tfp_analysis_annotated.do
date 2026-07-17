/*
Annotated copy for replication audit.
Original script: Lane2025QJE/replicationpackage/code/0_analysis/1_main_scripts/3a_run_micro_tfp_analysis.do
Purpose: Runs micro TFP analysis.

This file intentionally keeps the original .do extension.
The original code is copied below. Comments in this header identify the
script role, inputs, outputs, and audit linkage. The earlier prose note is
archived at: markdown_notes_archive/3a_run_micro_tfp_analysis_do.md

Audit linkage:
- Methods report: explains the estimating or output logic.
- Derivation report: maps equations/design objects to code.
- Replication report: documents inputs, outputs, and reproducibility limits.

Original code begins after this header.
*/

*------------------------------------------------------------------------------*
* What this does:
*
*   This file performs TFP analyses cross sectional estimate (MICRO)
*	MICRO data is proprietary and not included.**
*
* Inputs: 
*   - mms_TFP_micro.dta
* Outputs: 
*   - did_crossection_results_microtfp_results_estout.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*

// PROGRAM: prep_data
capture program drop prep_data
program define prep_data
	args filenameargument 
	use "`filenameargument'", clear 
	compress
	estimates clear
	capture: estfe . output_*, clear
	capture: drop post
	gen post = 0 
	replace post = 1 if year >= 1973

	* Make KSIC ID.
	egen ksic_id = group(ksic_merged)

end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* I. - CROSS SECTION TFP REGRESSION LOOP.
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* A. LOAD DATA AND PREPARE REGRESSIONS
*------------------------------------------------------------------------------*
* NOTE: This file is not included in the replication package.
local inputfile "./data/input/mms_TFP_micro.dta"
prep_data "`inputfile'"

local outputfilenameprefix did_crossection_results_microtfp
local outcomevariablelist "tfp_w tfp_acf tfp_lp tfp_op tfp_ols"
local replace "replace"

*------------------------------------------------------------------------------*
* B. LOOP THROUGH REGRESSION PARAMETERS
*------------------------------------------------------------------------------*
capture: tempfile drop tmpfile
tempfile tmpfile

* Start model number.
local modelnumber = 1

* Loop over outcomes.
foreach variable of local outcomevariablelist {
	reghdfe `variable' i.hci , ///
		absorb( i.ksic_id##i.year ) ///
		vce( cluster ksic_id id )

	* Post-reg setup.
	estimates store output_`variable'_`modelnumber'
	estadd local twowayvce "`e(N_clust1)' x `e(N_clust2)'"
	local modelnumber = `modelnumber' + 1
	local replace "append"
}
*------------------------------------------------------------------------------*
* C. SAVE REGRESSION OUTPUT: ESTOUT AND REGSAVE DATASET
*------------------------------------------------------------------------------*
estfe . output_*, labels( ksic_id#year "Industry \(\times\) Year") 
return list

estout output_* ///
	using "./data/included_datasets/`outputfilenameprefix'_results_estout.csv" , ///
		replace ///
			cells(b(star fmt(3)) se(par fmt(3))) ///
			starlevels(* 0.10 ** 0.05 *** .01) ///
			stats(r2 N twowayvce, fmt(3 0 0) ///
				labels("\(R^2\)" Observations "Two-way Cluster (Industry Plant)")) ///
			numbers ///
			mlabels(none) ///
			indicate( `r(indicate_fe)' ) ///
			collabels(none) ///
			keep( "*1.hci*" )
