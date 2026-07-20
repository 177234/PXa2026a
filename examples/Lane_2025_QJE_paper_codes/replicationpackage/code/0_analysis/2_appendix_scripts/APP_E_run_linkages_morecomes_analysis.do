*------------------------------------------------------------------------------*
* What this does:
*   Performs linkage analysis with more industrial development outcomes.
*   Loops iterate over:
*   - Both types of linkages (forward and backward) together.
*   - Non-HCI samples and combined samples.
*   - Pre-Post DiD and rolling DiD.
*   Generates regression output (estout and results files).
*
* Outputs: 
*   Estout and results files including (among others):
*   - did_io_moredev_prepost_bothlink_allvars_4estout.csv
*   - did_io_moredev_rolling_bothlink_allvars_4estout.csv
*   - did_io_moredev_all_results.csv
*   - did_iolf_moredev_prepost_bothlink_allvars_4estout.csv
*   - did_iolf_moredev_rolling_bothlink_allvars_4estout.csv
*   - did_iolf_moredev_rolling_bothlink_all_results.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*

capture program drop prep_data
program define prep_data
	args filenameargument 
	use "`filenameargument'", clear 
	estimates clear
	capture: drop post
	gen post = 0 
	replace post = 1 if year >= 1973
	xtset id year
end


capture program drop nameanalysisfromregressor
program define nameanalysisfromregressor, rclass
	args listofregressorstotest 

	* Either links have both directions....
	if regexm("`listofregressorstotest'" , "make|out" ) == 1 & ///
		regexm("`listofregressorstotest'" , "use|in" ) == 1 {
		* Has both variables:
		local regressornamestring bothlink
	} // OR ... ONLY make OR use.
	else {
		* If only OUT/MAKE (backward transmission, hci shock -> upstream makers)
		if regexm("`listofregressorstotest'" , "make|out" ) == 1 {
			* Has both variables:
			local regressornamestring backlink
		}
		* If only IN/USE (forward transmission) hci shock -> downstream users
		else if regexm("`listofregressorstotest'" , "use|in" ) == 1 {
			* Has both variables:
			local regressornamestring forwardlink
		}
	    else {
			* Else empty (breaks test after this in loop if empty)
			local regressornamestring ""
	    }
	}
	return local resultname `"`regressornamestring'"'
end


capture program drop export_reg_results
program define export_reg_results, rclass

	args temp_regressionfile regressiondir namesuffix 

	use "`temp_regressionfile'", clear

	* Clean junk lines, keep only relevant results.
	local regexstringlist "^[0-9][0-9][0-9][0-9]o.year" "^o.hci" "0b.post" "1o.post" "^o.*_0$" "^1972b.year$"
	foreach string of local regexstringlist {
		
		drop if regexm( var, `"`string'"' ) == 1
	}

	keep if ( regexm( command, "^reg" ) == 1 ) & ///
			( regexm( var, "^19[0-9b]+..*year#c.*hci.*0$" ) == 1 )

	* Clean regressor types. 
	replace regressortype = "use" if ///
							regexm( regressortype, "use|in" ) == 1 & ///
							regexm( regressortype, "make|out" ) != 1
	replace regressortype = "make" if ///
							regexm( regressortype, "use|in" ) != 1 & ///
							regexm( regressortype, "make|out" ) == 1
	replace regressortype = "both" if ///
							regexm( regressortype, "use|in" ) == 1 & regexm( regressortype, "make|out" ) == 1

	gen restrictiontype = "nonhci" if restrictions == 0
	replace restrictiontype = "hci" if restrictions == 1
	replace restrictiontype = "all" if restrictions == 9

	local typ: type datatype
	if ( substr("`typ'" , 1, 3) == "str" ) {
		replace datatype = "4" if regexm( datatype, "4sitc|sitc4") == 1
	}

	outsheet using ///
			"./data/intermediate_datasets/`namesuffix'_all_results.csv", ///
			comma replace

	capture: tempfile drop temp_regressionfile
	tempfile temp_regressionfile
end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* A. INPUT(S) AND SET GLOBALS
*------------------------------------------------------------------------------*
local dataset5 "./data/input/supp/mms_linkage_more_5digit.dta"
local dataset4 "./data/input/supp/mms_linkage_more_4digit.dta"
set showomitted off 
set showemptycells off
set showbaselevels off

*------------------------------------------------------------------------------*
* B. REGRESSION ARGUMENTS USED IN LOOP
*------------------------------------------------------------------------------*

local did_prepost i.post
local did_rolling ib(1972).year 
local fullsampleabsorb id hci#year year
local partsampleabsorb id year
local harmonized_direct `""hci_share_use_tot_0 hci_share_make_tot_0""'
local harmonized_leontief `""lf_hci_link_use_0 lf_hci_link_make_0""'

*------------------------------------------------------------------------------*
* I. MAIN INPUT-OUTPUT ANALYSIS: MORE INDUSTRIAL DEVELOPMENT OUTCOMES
*------------------------------------------------------------------------------*
local outcome_list l_workers l_est l_y_n tfp_acf l_avg_wages


*------------------------------------------------------------------------------*
* 1. RUN REGRESSIONS FOR DIRECT LINKS
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* A. SETUP THE ANALYSIS-LEVEL PARAMETERS/NAMES.
local namesuffix did_io_moredev
local mainregressorlist `harmonized_direct'
local estoutkeep_prepost "*post*hci_*"
local estoutkeep_rolling "*year*hci_*"
capture: tempfile drop temp_regressionfile
tempfile temp_regressionfile
local replace "replace"

*------------------------------------------------------------------------------*
* B. RUN REGRESSION ANALYSIS.
*------------------------------------------------------------------------------*
* i. Loop over DiD type.
foreach didtype in prepost rolling {

	* ii. Setup analysis name and variables.
	nameanalysisfromregressor "`mainregressorlist'"
	local mainregressorlist_name "`r(resultname)'" // Assign regressor "name" for string....
	assert "`mainregressorlist_name'" != "" // Test that it isn't empty

	local analysis_name `namesuffix'_`didtype'_`mainregressorlist_name'
	local estoutkeep "`estoutkeep_`didtype''"
	local didinteraction "`did_`didtype''"

	* iii. Loop over 4 and 5-digit datasets.
	foreach datatype in 4 5 {
		prep_data "`dataset`datatype''"

		* iv. Loop over outcomes.
		foreach outcome of local outcome_list {
			if ( regexm("`outcome'","tfp") == 1 & `datatype' == 4 ){
				
				continue
			}
			local modelnumber = 1

			* v. Loop over total dataset and nontreated only sample.
			foreach restrictiondummy in 9 0 {

				// Regression for full sample (restrictiondummy == 9)
				if `restrictiondummy' > 1 {
					local fixedeffects `fullsampleabsorb' 

					* Regression
					reghdfe `outcome' `didinteraction'##c.(`mainregressorlist') , /// 
									absorb( `fixedeffects' ) ///
									vce(cluster id) verbose(0) noconstant vsquish
				}
				else {

					// Else, regression for partial samples (restrictiondummy == 0)
					local fixedeffects `partsampleabsorb' 
					reghdfe `outcome' `didinteraction'##c.(`mainregressorlist') ///
									if hci == `restrictiondummy' , /// 
								absorb( `fixedeffects') ///
								vce(cluster id) verbose(0) noconstant vsquish
				}

				* b. Post regression save.
				regsave using "`temp_regressionfile'", pval ci ///
					addlabel( outcome , `outcome',  didtype, `didtype', regressortype ,`mainregressorlist' , restrictions, `restrictiondummy', fixedeffects, "`fixedeffects'" , command,`e(cmd)',datatype,`datatype')  `replace'

				estimates store `outcome'_`modelnumber'
				estadd scalar N_cluster = e(N_clust)
				local modelnumber = `modelnumber' + 1
				local replace "append"
			} // Loop over non-HCI industry sample and full sample.
		} // Loop over regression outcomes. 

		* vi. Save regression output: ESTOUT dataset.
		estfe . * , labels(id "Industry Effects" year "Year Effects" hci#year "Targeted \(\times\) Year") 
		return list
		estout * ///
			using "./data/intermediate_datasets/`analysis_name'_allvars_`datatype'estout.csv" , ///
				replace ///
				cells(b(star fmt(a3)) se(par fmt(a3))) ///
				starlevels(* 0.10 ** 0.05 *** .01) ///
				stats(r2 N N_cluster, fmt(3 0 0) labels("\(R^2\)" Observations Clusters)) ///
				numbers noomitted nobaselevels ///
				collabels(none) ///
				indicate(`r(indicate_fe)') ///
				keep( `estoutkeep' ) 
	} // Loop over 4 and 5-digit datasets. 
} // Loop over pre-post/rolling regressions. 


*------------------------------------------------------------------------------*
* C. SAVE REGRESSION OUTPUT: REGSAVE DATASET.
*------------------------------------------------------------------------------*
export_reg_results `temp_regressionfile' `"./data/intermediate_datasets"' `namesuffix'

*------------------------------------------------------------------------------*
* 2. RUN REGRESSIONS FOR TOTAL LINKS.
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* A. SETUP THE ANALYSIS-LEVEL PARAMETERS/NAMES.
*------------------------------------------------------------------------------*
local namesuffix did_iolf_moredev
local mainregressorlist `harmonized_leontief'
local estoutkeep_prepost "*post*lf*"
local estoutkeep_largerolling "*year*lf*"

capture: tempfile drop temp_regressionfile
tempfile temp_regressionfile
local replace "replace"


*------------------------------------------------------------------------------*
* B. RUN REGRESSION ANALYSIS.
*------------------------------------------------------------------------------*

* i. Loop over type.
foreach didtype in prepost rolling {

	* Setup arguments and filenames for each DID-type.
	nameanalysisfromregressor "`mainregressorlist'"
	local mainregressorlist_name "`r(resultname)'" // Assign regressor "name" for string....
	assert "`mainregressorlist_name'" != "" // Test that it isn't empty
	local analysis_name `namesuffix'_`didtype'_`mainregressorlist_name'
	local estoutkeep "`estoutkeep_`didtype''"
	local didinteraction "`did_`didtype''"

	* ii. Loop through 4 and 5 digit.
	foreach datatype in 4 5 {
		prep_data "`dataset`datatype''"

		* iii. Loop over outcomes.
		foreach outcome of local outcome_list {
			if ( regexm("`outcome'","tfp") == 1 & `datatype' == 4 ){
				continue
			}

			local modelnumber = 1

			* iv. Loop over total dataset and nontreated only sample.
			foreach restrictiondummy in 9 0 {

				* a. RUN regressions.

				// Regression for full sample (restrictiondummy == 9)
				if `restrictiondummy' > 1 {
					local fixedeffects `fullsampleabsorb' 
					reghdfe `outcome' `didinteraction'##c.(`mainregressorlist') , /// 
									absorb( `fixedeffects') ///
									vce(cluster id) verbose(0) noconstant vsquish
				}
				else {
					// Else, regression for partial samples (restrictiondummy == 0)
					local fixedeffects `partsampleabsorb' 
					reghdfe `outcome' `didinteraction'##c.(`mainregressorlist') ///
									if hci == `restrictiondummy' , /// 
								absorb( `fixedeffects') ///
								vce(cluster id) verbose(0) noconstant vsquish
				}

				* b. Post regression save.		
				regsave using "`temp_regressionfile'", pval ci ///
					addlabel( outcome , `outcome',  didtype, `didtype', regressortype ,`mainregressorlist' , restrictions, `restrictiondummy',fixedeffects, "`fixedeffects'" , command,`e(cmd)',datatype,`datatype')  `replace'
				estimates store `outcome'_`modelnumber'
				estadd scalar N_cluster = e(N_clust)
				local modelnumber = `modelnumber' + 1
				local replace "append"
			} // Loop over non-HCI industry sample and full sample.
		} // Loop over regression outcomes. 

		* v. Save regression output: ESTOUT dataset.
		estfe . * , labels(id "Industry Effects" year "Year Effects" hci#year "Targeted \(\times\) Year") 
		return list
		estout * ///
			using "./data/intermediate_datasets/`analysis_name'_allvars_`datatype'estout.csv" , ///
				replace ///
				cells(b(star fmt(a3)) se(par fmt(a3))) ///
				starlevels(* 0.10 ** 0.05 *** .01) ///
				stats(r2 N N_cluster, fmt(3 0 0) labels("\(R^2\)" Observations Clusters)) ///
				numbers noomitted nobaselevels ///
				collabels(none) ///
				indicate(`r(indicate_fe)') ///
				keep( `estoutkeep' ) 
	} // Loop over 4 and 5-digit datasets. 
} // Loop over pre-post/rolling regressions. 

*------------------------------------------------------------------------------*
* C. SAVE REGRESSION OUTPUT: REGSAVE DATASET.
*------------------------------------------------------------------------------*
export_reg_results `temp_regressionfile' `"./data/intermediate_datasets"' `namesuffix'
