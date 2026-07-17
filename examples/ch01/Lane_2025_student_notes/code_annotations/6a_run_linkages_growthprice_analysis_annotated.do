/*
Annotated copy for replication audit.
Original script: Lane2025QJE/replicationpackage/code/0_analysis/1_main_scripts/6a_run_linkages_growthprice_analysis.do
Purpose: Runs input-output linkage growth and price analyses.

This file intentionally keeps the original .do extension.
The original code is copied below. Comments in this header identify the
script role, inputs, outputs, and audit linkage. The earlier prose note is
archived at: markdown_notes_archive/6a_run_linkages_growthprice_analysis_do.md

Audit linkage:
- Methods report: explains the estimating or output logic.
- Derivation report: maps equations/design objects to code.
- Replication report: documents inputs, outputs, and reproducibility limits.

Original code begins after this header.
*/

*------------------------------------------------------------------------------*
* What this does:
*
*   This takes merged/harmonized MMS/KSIC data and performs
*   analysis of linkages.
*
*   This is the main linkage analysis for output and price outcomes.
*   Uses sub-do file loop: "subdofiles/linkages_subrollingloop.do"

* Inputs: 
*   - Harmonized MMS files:
*   "./data/input/mms_merged_harmonized_panel_cleaned4reg_5digit.dta"
*   "./data/input/mms_merged_harmonized_panel_cleaned4reg_4digit.dta"
*
* Outputs: 
*   Pre-post, rolling event study for networks.
*   Files are named:
*     did_io_main_all_results.csv
*     did_iolf_main_all_results.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*

// Define data loading program.
capture program drop prep_data
program define prep_data
	args filenameargument 	
	use "`filenameargument'", clear 
	capture: drop post
	gen post = 0 
	replace post = 1 if year >= 1973
	xtset id year
	estimates clear
end

// Program for generating F-test statistics
capture program drop make_pretest_vars
program define make_pretest_vars, rclass
	args regressorlistforloop outcomeargument


	* Get years before the baseline year ... where outcome is not missing.
	levelsof year if year < 1972 & !missing( `outcomeargument' ) , local(yearlist) clean

	* Loop over each year AND each regressor to make interaction
	local listofregressorstotest
	foreach yearstring of local yearlist {
		foreach variablestring of local regressorlistforloop {
			* Add interaction to regressor string list.
			local listofregressorstotest `variablestring'#`yearstring'.year `listofregressorstotest'
		} 
	}

	* Return a result for local. Must be rclass to pass this.
	return local result `"`listofregressorstotest'"'	
end




* Program for naming analysis based on regressorlist
capture program drop nameanalysisfromregressor
program define nameanalysisfromregressor, rclass
	args listofregressorstotest 

	* Either links have both directions....
	if regexm("`listofregressorstotest'" , "make|out" ) == 1 & regexm("`listofregressorstotest'" , "use|in" ) == 1 {
		local regressornamestring bothlink
	} // OR ... ONLY make OR use.
	else {
		* If only OUT/MAKE (backward transmission, hci shock -> upstream)
		if regexm("`listofregressorstotest'" , "make|out" ) == 1 {
			local regressornamestring backlink
		}
		* If only IN/USE (forward transmission hci shock -> downstream)		
		else if regexm("`listofregressorstotest'" , "use|in" ) == 1 {
			local regressornamestring forwardlink
		}
	    else {
			* Else empty (breaks test after this in loop if empty)
			local regressornamestring ""\
	    }
	}
	* Return a result for local. Must be rclass to pass this.
	return local resultname `"`regressornamestring'"'	
end

* Program for saving regression dumps.
capture program drop export_reg_results
program define export_reg_results, rclass


	* Pass locals to arguments
	args temp_regressionfile regressiondir namesuffix
	

	* i. Format and outsheet results for use.
	use "`temp_regressionfile'", clear

	* ii. Clean junk lines, keep only relevant results.
	local regexstringlist "^[0-9][0-9][0-9][0-9]o.year" "^o.hci" "0b.post" "0.post" "1o.post" "^o.*_0$" "^1972b.year$"
	foreach string of local regexstringlist {
		drop if regexm( var, `"`string'"' ) == 1
	}
	keep if ( regexm( command, "^reg" ) == 1 ) & ///
			( regexm( var, "^19[0-9b]+..*year#c.*hci.*0$" ) == 1 )

	* iii. Clean up output for R.
	replace regressortype = "use" if ///
							regexm( regressortype, "use|in" ) == 1 & ///
							regexm( regressortype, "make|out" ) != 1
	replace regressortype = "make" if ///
							regexm( regressortype, "use|in" ) != 1 & ///
							regexm( regressortype, "make|out" ) == 1
	replace regressortype = "both" if ///
							regexm( regressortype, "use|in" ) == 1 & regexm( regressortype, "make|out" ) == 1

	* Clean sample restriction. 
	gen restrictiontype = "nonhci" if restrictions == 0
	replace restrictiontype = "hci" if restrictions == 1
	replace restrictiontype = "all" if restrictions == 9

	* Clean datatype for SITC data. The datatype variable is a string here.
	local typ: type datatype
	if ( substr("`typ'" , 1, 3) == "str" ) {
		replace datatype = "4" if regexm( datatype, "4sitc|sitc4") == 1
	}
	duplicates drop

	* iv. Save the regsave dump.
	outsheet using ///
			"./data/intermediate_datasets/`namesuffix'_all_results.csv", ///
		comma replace
	capture: tempfile drop temp_regressionfile
	tempfile temp_regressionfile
end


*------------------------------------------------------------------------------*
* ARGUMENTS
*------------------------------------------------------------------------------*
local dataset5 "./data/input/mms_merged_harmonized_panel_cleaned4reg_5digit.dta"
local dataset4 "./data/input/mms_merged_harmonized_panel_cleaned4reg_4digit.dta"

* Sub-do file with regression loops.
local subloopdofile "./code/0_analysis/subdofiles/6b_linkages_subrollingloop.do"

* B. GLOBAL PREPARATION 
set showomitted off 
set showemptycells off
set showbaselevels off 

* C. Regression arguments
local outcome_list l_valueadded l_ppi

* Interactions for PRE-POST/ROLLING DID regressions.
local did_prepost i.post
local did_rolling ib(1972).year 

* Reghdfe FEs for full sample and partial sample.
local fullsampleabsorb id hci#year year
local partsampleabsorb id year

* Harmonized linkage variables
local harmonized_direct `""hci_share_use_tot_0 hci_share_make_tot_0""'
local harmonized_leontief `""lf_hci_link_use_0 lf_hci_link_make_0""'


*------------------------------------------------------------------------------*
* I. MAIN INPUT-OUTPUT ANALYSIS: MAIN OUTPUT REGRESSIONS
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* 1. LOOP OVER DIRECT LINKS, FOR OUTCOMES ABOVE
*------------------------------------------------------------------------------*

* A. Analysis-level parameters
// Passed to subfile. 
local namesuffix did_io_main
local mainregressorlist `harmonized_direct'
local estoutkeep_prepost "*post*hci_*"
local estoutkeep_rolling "*year*hci_*"
local replace "replace"

* B. Run regression analysis.
include "`subloopdofile'"

* C. Save regression output: REGSAVE DATASET.
export_reg_results `temp_regressionfile' `"./data/intermediate_datasets"' `namesuffix'


*------------------------------------------------------------------------------*
* 2. LOOP OVER *TOTAL* REGRESSION LINKS, FOR OUTCOMES ABOVE
*------------------------------------------------------------------------------*

* A. Regression arguments
// Passed to subfile. 
local namesuffix did_iolf_main
local mainregressorlist `harmonized_leontief'
local estoutkeep_prepost "*post*lf*"
local estoutkeep_largerolling "*year*lf*"
local replace "replace"

* B. Run regression analysis.
include "`subloopdofile'"

* C. Save regression output: REGSAVE DATASET.
export_reg_results `temp_regressionfile' `"./data/intermediate_datasets"' `namesuffix'
