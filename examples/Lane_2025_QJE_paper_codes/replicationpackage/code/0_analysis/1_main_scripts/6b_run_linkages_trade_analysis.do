*------------------------------------------------------------------------------*
* What this does:
*
*   This takes merged/harmonized MMS/KSIC data and performs analysis of linkages.
*   This purely output from many types of regressions for the original 
*   R-based reports.
*
*   Uses PPMLHDFE and REGHDFE.
*
* Inputs: 
*
*   comtrade_merged_harmonized_panel_cleaned4reg_4digit.dta
*
* Outputs: 
*
*   Graphs, Tables, Etc. 
*   "did_io_comtrade_rolling_bothlink_allvars_4estout.csv"
*   "did_iolf_comtrade_rolling_bothlink_allvars_4estout.csv"
*   
*   did_io_comtrade_all_results.csv
*   did_iolf_comtrade_all_results.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*

// Data loading program.
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


* Program for naming analysis based on regressorlist
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
	* Return a result for local. Program must be rclass to pass this.
	return local resultname `"`regressornamestring'"'	
end

// Program for saving regression dumps.
capture program drop export_reg_results
program define export_reg_results, rclass
	args temp_regressionfile regressiondir namesuffix

	* i. Format and outsheet results for use.
	use "`temp_regressionfile'", clear

	* ii. Clean junk lines, keep only relevant results.
	local regexstringlist "^[0-9][0-9][0-9][0-9]o.year" "^o.hci" "0b.post" "1o.post" "^o.*_0$" "^1972b.year$"
	foreach string of local regexstringlist {
		drop if regexm( var, `"`string'"' ) == 1
	}
	keep if ( regexm( command, "^reg|^ppml" ) == 1 ) & ///
			( regexm( var, "^19[0-9b]+..*year#c.*hci.*0$" ) == 1 )

	* iii. Clean up output for R.
	gen linktype = "use" if regexm( var , "use|in" ) == 1
	replace linktype = "make" if regexm( var , "make|out" ) == 1
	replace regressortype = "use" if regexm(regressortype, "use|in") & !regexm(regressortype, "make|out")
	replace regressortype = "make" if !regexm(regressortype, "use|in") & regexm(regressortype, "make|out")
	replace regressortype = "both" if regexm(regressortype, "use|in") & regexm(regressortype, "make|out")

	* Clean sample restriction
	gen restrictiontype = "nonhci" if restrictions == 0
	replace restrictiontype = "hci" if restrictions == 1
	replace restrictiontype = "all" if restrictions == 9

	* iv. Save the regsave dump.
	outsheet using ///
			"./data/intermediate_datasets/`namesuffix'_all_results.csv", ///
			comma replace
	capture: tempfile drop temp_regressionfile
	tempfile temp_regressionfile
end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*

* A. Setup arguments
local datasetsitc4 "./data/input/comtrade_merged_harmonized_panel_cleaned4reg_4digit.dta"
set showomitted off 
set showemptycells off
set showbaselevels off 
local estoutkeep_prepost "*post*hci_*"
local estoutkeep_rolling "*year*hci_*"

* B. Regression arguments
local outcome_list rca_core h_rca_core rca_cdk
local did_prepost i.post
local did_rolling ib(1972).year 
local fullsampleabsorb id hci#year year
local partsampleabsorb id year

* Harmonized linkage variables
local harmonized_direct `""hci_share_use_tot_0 hci_share_make_tot_0""'
local harmonized_leontief `""lf_hci_link_use_0 lf_hci_link_make_0""'


*------------------------------------------------------------------------------*
* COMTRADE KOREA (ONLY) SITC AND LINKAGES - REGRESSIONS
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* 1. LOOP OVER DIRECT LINKS, FOR OUTCOMES ABOVE - PPMLHDFE
*------------------------------------------------------------------------------*

* A. SETUP THE ANALYSIS-LEVEL PARAMETERS/NAMES.

* Analysis name suffix (for output file).
local namesuffix did_io_comtrade

* Regressor list for Part 1.
local mainregressorlist `harmonized_direct'


* Toggle replace local when DO file is opened.
local replace "replace"

* Start clean regression dump file. Must be here.
capture: tempfile drop temp_regressionfile
tempfile temp_regressionfile


* B. REGRESSION PARAMETERS. 

* i. Setup arguments, filenames, and data.

* Load the SITC4-digit datset
prep_data "`datasetsitc4'"

** a. Estout/regsave arguments.

* Run program to automatically assign name to regressor TYPE (in/out/both)
nameanalysisfromregressor "`mainregressorlist'"
local mainregressorlist_name "`r(resultname)'" // Assign regressor "name" for string....
assert "`mainregressorlist_name'" != "" // Test that it isn't empty

* Analysis name (for output file) estout and others.
local analysis_name `namesuffix'_rolling_`mainregressorlist_name'

// NOTE: Local argument for variables to keep.
local estoutkeep "`estoutkeep_rolling'"

* ii. Loop over outcomes.
foreach outcome of local outcome_list {

    * Counter starts. Updated at end of internal loop.
    local modelnumber = 1

    * Choose reghd or ppml:
    if regexm("`outcome'", "(cdk|dummy)"){
        // Reg for dummies or non-zero:
        local regcommand reghdfe
    }
    else {
        local regcommand ppmlhdfe
    }

    * iii. Loop over total dataset and nontreated only sample. 
        
    // 9 and 0 for now. HCI is redundant 
    foreach restrictiondummy in 9 0 {
        
        * a. RUN regressions. 
        * Run for each sample.
        if `restrictiondummy' > 1 {

            * Use full sample FEs if no restrictions.
            local fes `fullsampleabsorb' 

            * Regression
            `regcommand' `outcome' ib(1972).year##c.(`mainregressorlist')  , /// 
                  absorb( `fes' ) ///
                  vce(cluster id) noconstant

        }
        else {

            * Use full sample FEs if restrictions.
            local fes `partsampleabsorb' 

            * Regression on restricted sample.
            `regcommand' `outcome' ib(1972).year##c.(`mainregressorlist') ///
                        if hci == `restrictiondummy' , /// 
                    absorb( `fes' ) ///
                    vce(cluster id) noconstant
        } 

        * b. REGSAVE and pretests: only for rolling event study.
        regsave using "`temp_regressionfile'", pval ci ///
            addlabel( outcome , `outcome',  didtype, rolling, regressortype ,`mainregressorlist' , fixedeffects, `fes', restrictions, `restrictiondummy' , command,`e(cmd)' )  `replace'

        * c. ESTOUT: Save regression table, model for estout.
        estimates store `outcome'_`modelnumber'

        * Use pseudo v. conventional adjusted "\(R^2\)", depending on command.
        if regexm("`e(cmd)'", "reghdfe") == 1 {
            // Use pseudo R for REGHDEFE
            estadd scalar r2adj = `e(r2_a)'
        } 
        else {
            // Else use PPML's pseudo r2:
            estadd scalar r2adj = `e(r2_p)'
        }

        * Add number of clusters.
        estadd scalar N_cluster = e(N_clust)

        * d. MISC: Model iteration, etc.
        local modelnumber = `modelnumber' + 1
        local replace "append"

    } // Loop over non-HCI industry sample and full sample.
} // Loop over regression outcomes. 

* iv. SAVE REGRESSION OUTPUT: ESTOUT DATASET.

estfe . *, labels(id "Industry Effects" year "Year Effects" hci#year "Targeted \(\times\) Year") 
return list

* Save estout regression table for each group of outcomes AND 4 versus 5-digit:
estout * ///
    using "./data/intermediate_datasets/`analysis_name'_allvars_4estout.csv" , ///
        replace ///
        cells(b(star fmt(a3)) se(par fmt(a3))) ///
        starlevels(* 0.10 ** 0.05 *** .01) ///
        stats(r2adj N N_cluster, fmt(3 0 0) ///
            labels("\(R^2\)" Observations Clusters )) ///
        mlabels(none) ///
        numbers noomitted nobaselevels ///
        collabels(none) ///
        indicate(`r(indicate_fe)') ///
        keep( `estoutkeep' ) 

* C. SAVE REGRESSION OUTPUT: REGSAVE DATASET.

* Format and save all results for use in R.
export_reg_results `temp_regressionfile' `"./data/intermediate_datasets"' `namesuffix'

*------------------------------------------------------------------------------*
* 2. LOOP OVER LEONTIEF IO LINKS, FOR OUTCOMES ABOVE - PPML NOW.
*------------------------------------------------------------------------------*

* A. SETUP THE ANALYSIS-LEVEL PARAMETERS/NAMES.

//NOTE: The are passed to the "include" subfile. 

* Analysis name suffix (for output file).
local namesuffix did_iolf_comtrade


* Regressors list for 1. 
local mainregressorlist `harmonized_leontief'

* Toggle replace local when DO file is opened.
local replace "replace"

* Start clean regression dump file. Must be here.
capture: tempfile drop temp_regressionfile
tempfile temp_regressionfile


* B. REGRESSION PARAMETERS. 

* i. Setup arguments, filenames, and data.

* Load the SITC4-digit datset
prep_data "`datasetsitc4'"

* a. Estout/regsave arguments.

* Run program to automatically assign name to regressor TYPE (in/out/both)
nameanalysisfromregressor "`mainregressorlist'"
local mainregressorlist_name "`r(resultname)'" // Assign regressor "name" for string....
assert "`mainregressorlist_name'" != "" // Test that it isn't empty

* Analysis name (for output file) estout and others.
local analysis_name `namesuffix'_rolling_`mainregressorlist_name'


// NOTE: Local argument for variables to keep.
local estoutkeep "`estoutkeep_rolling'"

* ii. Loop over outcomes.
foreach outcome of local outcome_list {

    * Counter starts. Updated at end of internal loop.
    local modelnumber = 1

    * Choose reghd or ppml:
    if regexm("`outcome'", "(cdk|dummy)"){
        // Reg for dummies or non-zero:
        local regcommand reghdfe
    }
    else {
        local regcommand ppmlhdfe
    }

    * iii. Loop over total dataset and nontreated only sample. 
        
    // 9 and 0 for now. HCI is redundant 
    foreach restrictiondummy in 9 0 {
        
        * a. RUN regressions. 
        if `restrictiondummy' > 1 {

            * Use full sample FEs if no restrictions.
            local fes `fullsampleabsorb' 

            * Regression
            `regcommand' `outcome' ib(1972).year##c.(`mainregressorlist')  , /// 
                  absorb( `fes' ) ///
                  vce(cluster id) noconstant

        }
        else {

            // NOTE: Else take out the HCI dummy to non-HCI

            * Use full sample FEs if restrictions.
            local fes `partsampleabsorb' 

            * Regression on restricted sample.
            `regcommand' `outcome' ib(1972).year##c.(`mainregressorlist') ///
                        if hci == `restrictiondummy' , /// 
                    absorb( `fes' ) ///
                    vce(cluster id) noconstant
        } 

        * b. REGSAVE and pretests: only for rolling event study.
        regsave using "`temp_regressionfile'", pval ci ///
            addlabel( outcome , `outcome',  didtype, rolling, regressortype ,`mainregressorlist' , fixedeffects, `fes', restrictions, `restrictiondummy' , command,`e(cmd)' )  `replace'

        * c. ESTOUT: Save regression table, model for estout.

        * Save regression table, model for estout.
        estimates store `outcome'_`modelnumber'

        * Use pseudo v. conventional adjusted "\(R^2\)", depending on command.
        if regexm("`e(cmd)'", "reghdfe") == 1 {
            // Use pseudo R for REGHDEFE
            estadd scalar r2adj = `e(r2_a)'
        } 
        else {
            // Else use PPML's pseudo r2:
            estadd scalar r2adj = `e(r2_p)'
        }

        * Add number of clusters.
        estadd scalar N_cluster = e(N_clust)

        * d. MISC: Model iteration, etc.

        * Model counter.
        local modelnumber = `modelnumber' + 1

        * Replacement switch for REGSAVE.
        local replace "append"

    } // Loop over non-HCI industry sample and full sample.

} // Loop over regression outcomes. 

* iv. SAVE REGRESSION OUTPUT: ESTOUT DATASET.

estfe . *, labels(id "Industry Effects" year "Year Effects" hci#year "Targeted \(\times\) Year") 
return list

* Save estout regression table for each group of outcomes AND 4 versus 5-digit:
estout * ///
    using "./data/intermediate_datasets/`analysis_name'_allvars_4estout.csv" , ///
        replace ///
        cells(b(star fmt(a3)) se(par fmt(a3))) ///
        starlevels(* 0.10 ** 0.05 *** .01) ///
        stats(r2adj N N_cluster, fmt(3 0 0) ///
            labels("\(R^2\)" Observations Clusters )) ///
        mlabels(none) ///
        numbers noomitted nobaselevels ///
        collabels(none) ///
        indicate(`r(indicate_fe)') ///
        keep( `estoutkeep' ) 

* C. SAVE REGRESSION OUTPUT: REGSAVE DATASET.

* Format and save all results for use in R.
export_reg_results `temp_regressionfile' `"./data/intermediate_datasets"' `namesuffix'
