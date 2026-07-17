/*
Annotated copy for replication audit.
Original script: Lane2025QJE/replicationpackage/code/0_analysis/1_main_scripts/3c_run_worldtrade_analysis.do
Purpose: Runs world trade comparison and DDD analyses.

This file intentionally keeps the original .do extension.
The original code is copied below. Comments in this header identify the
script role, inputs, outputs, and audit linkage. The earlier prose note is
archived at: markdown_notes_archive/3c_run_worldtrade_analysis_do.md

Audit linkage:
- Methods report: explains the estimating or output logic.
- Derivation report: maps equations/design objects to code.
- Replication report: documents inputs, outputs, and reproducibility limits.

Original code begins after this header.
*/

*------------------------------------------------------------------------------*
* What this does:
*
*   Main world trade analysis triple difference trade regressions. 
*
* Inputs: 
*   Prepared COMTRADE dataset:
*   "comtrade_worldsitc_panel_cleaned4reg_4digit.dta"
*
* Outputs: 
*   - did_largerolling_worldtrade_ppml_rca_results_estout.csv
*   - did_largerolling_worldtrade_ppml_rca_all_results.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*
local inputfile "./data/input/comtrade_worldsitc_panel_cleaned4reg_4digit.dta"

*------------------------------------------------------------------------------*
* I. - CORE TRADE REGRESSIONS IN PAPER : RCA COMPARATIVE ADV. 
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* 1. - FLEXIBLE REGRESSIONS 
*------------------------------------------------------------------------------

*------------------------------------------------------------------------------*
* A. SETUP REGRESSION PARAMETERS. 
*------------------------------------------------------------------------------
use "`inputfile'", clear
estimates clear
compress


*------------------------------------------------------------------------------*
* B. LOOP THROUGH REGRESSION PARAMETERS. 
*------------------------------------------------------------------------------

* i. Setup regression parameters.
local outcomevariablelist rca_cdk rca_dummy rca_core h_rca_core
local replace "replace"
tempfile tmpfile

* ii. Loop through regression parameters.  
foreach variable of local outcomevariablelist {
	local modelnumber = 1

	* Loop over each FE-type:
	foreach fixedeffects in "code reportercode" "i.code#i.year i.reportercode#i.year" "i.code#i.year i.reportercode#i.year i.reportercode#i.code" {
			
		* A. EXECUTE REGRESSION.
		if regexm("`variable'", "dummy|cdk|h_") {
			quietly: reghdfe `variable' i.hci##ib(1972).year##i.korea, ///
				absorb( `fixedeffects' ) ///
				vce(cluster reportercode code)
			local adjustedr = `e(r2_a)'			
		}
		else {
			quietly: ppmlhdfe `variable' i.hci##ib(1972).year##i.korea, ///
				absorb( `fixedeffects' ) ///
				vce(cluster reportercode code)
			// for PPML
			local adjustedr = `e(r2_p)'
		}

		* B. Post-regression saving.
		estimates store output_`variable'_`modelnumber'
		estadd local twowayvce "`e(N_clust1)' x `e(N_clust2)'"
		estadd scalar rsq = `adjustedr'		

		* REGSAVE: regression output and the TEST results:
		regsave using "`tmpfile'", ci tstat pval ///
			addlabel(outcome,`variable', fixedeffects,"`fixedeffects'",command,`e(cmd)') `replace'
		local modelnumber = `modelnumber' + 1
		local replace "append"
	} // Loop over fixed effects
} // Loop over outcomes. 
local replace "replace"

*------------------------------------------------------------------------------*
* C. SAVE REGRESSION OUTPUT: ESTOUT AND REGSAVE DATASET. 
*------------------------------------------------------------------------------*
local outputfilenameprefix did_largerolling_worldtrade_ppml_rca
local estoutoptions "1*hci*1*year*"

// 1 - Save ESTOUT regression table: CSV output.
estout output_* ///
	using "./data/intermediate_datasets/`outputfilenameprefix'_results_estout.csv" , ///
		replace cells(b(star fmt(3)) se(par fmt(3))) ///
				starlevels(* 0.10 ** 0.05 *** .01) ///
				stats(rsq N twowayvce, fmt(3 0 %9.0g) ///
					labels("\(R^2\)" Observations "Clusters (Country-Product)")) ///
				numbers noomitted nobaselevels ///
				collabels(none) ///
				keep( `estoutoptions' )

// 2 - REGSAVE Export and clean.
use "`tmpfile'", clear

* Keep only the relevant rows.
keep if regexm(var, "^1*\.hci#[0-9][0-9][0-9][0-9]b*\.year.*korea") == 1

// Save results.
outsheet using  "./data/intermediate_datasets/`outputfilenameprefix'_all_results.csv", ///
		comma replace

di "Finished running trade analysis." 