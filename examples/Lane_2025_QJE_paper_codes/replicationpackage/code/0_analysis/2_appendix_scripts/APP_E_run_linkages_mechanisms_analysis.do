*------------------------------------------------------------------------------*
* PURPOSE:
*   Performs analysis of linkages with more mechanism outcomes.
*   Loops iterate over:
*   - Both types of linkages (forward and backward) together.
*   - Non-HCI samples and combined samples.
*   - Pre-Post DiD and rolling DiD.
*   All use regressions with simple controls. Generates regression output.
*
* INPUTS: 
*   - ./data/input/supp/mms_linkage_mech_4digit.dta
*   - ./data/input/supp/mms_linkage_mech_5digit.dta
*
* OUTPUTS: Estout files:
*   - did_io_mechanism_rolling_bothlink_allvars_4estout.csv
*   - did_io_mechanism_rolling_bothlink_allvars_5estout.csv
*   - did_iolf_mechanism_rolling_bothlink_allvars_4estout.csv
*   - did_iolf_mechanism_rolling_bothlink_allvars_5estout.csv
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* PROGRAMS
*------------------------------------------------------------------------------*
capture program drop prep_data
program define prep_data

	args filenameargument 

	use "`filenameargument'", clear 
	capture: drop post
	gen post = 0 
	replace post = 1 if year >= 1973
	xtset id year
end

capture program drop make_pretest_vars
program define make_pretest_vars, rclass

	args regressorlistforloop outcomeargument
	
	levelsof year if year < 1972 & !missing( `outcomeargument' ) , local(yearlist) clean
	local listofregressorstotest

	* Loop over each year AND each regressor to make the interaction
	foreach yearstring of local yearlist {
		foreach variablestring of local regressorlistforloop {
			* Add interaction to regressor string list.
			local listofregressorstotest `variablestring'#`yearstring'.year `listofregressorstotest'
		} 
	}
	return local result `"`listofregressorstotest'"'	
end

capture program drop nameanalysisfromregressor
program define nameanalysisfromregressor, rclass

	args listofregressorstotest 

	* Either links have both directions....
	if regexm("`listofregressorstotest'" , "make|out" ) == 1 & regexm("`listofregressorstotest'" , "use|in" ) == 1 {
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

	* Pass locals
	args temp_regressionfile regressiondir namesuffix
	
	* Format and outsheet results for use.
	use "`temp_regressionfile'", clear

	* Clean junk lines.
	local regexstringlist "^[0-9][0-9][0-9][0-9]o.year" "^o.hci" "0b.post" "1o.post" "^o.*_0$" "^1972b.year$"
	foreach string of local regexstringlist {
		
		drop if regexm( var, `"`string'"' ) == 1
	}

	* Keep only the relevant observations/coefficients
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
	replace restrictiontype = "all" if restrictions == 9

	* Clean datatype for SITC data. The datatype variable is a string here.
	local typ: type datatype
	if ( substr("`typ'" , 1, 3) == "str" ) {
		replace datatype = "4" if regexm( datatype, "4sitc|sitc4") == 1
	}

	* Save the regsave dump.
	
	outsheet using ///
			"./data/intermediate_datasets/`namesuffix'_all_results.csv", ///
			comma replace
	* Clean up the file for next run.
	capture: tempfile drop temp_regressionfile
	tempfile temp_regressionfile

end

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*

* A. INPUT(S) 
local dataset5 "./data/input/supp/mms_linkage_mech_4digit.dta"
local dataset4 "./data/input/supp/mms_linkage_mech_5digit.dta"

* B. PREPARATION  
set showomitted off 
set showemptycells off
set showbaselevels off 
capture: tempfile drop temp_regressionfile
tempfile temp_regressionfile

* C. REGRESSION ARGUMENTS USED IN LOOP
local did_rolling ib(1972).year 
local fullsampleabsorb id hci#year year
local partsampleabsorb id year
local harmonized_direct `""hci_share_use_tot_0 hci_share_make_tot_0""'
local harmonized_leontief `""lf_hci_link_use_0 lf_hci_link_make_0""'

*------------------------------------------------------------------------------*
* I. MECH INPUT-OUTPUT ANALYSIS: MORE INDUSTRIAL DEVELOPMENT OUTCOMES.
*------------------------------------------------------------------------------*/

*------------------------------------------------------------------------------*
* 1. LOOP OVER DIRECT LINKS, FOR OUTCOMES ABOVE
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* A. SETUP THE ANALYSIS-LEVEL PARAMETERS/NAMES
*------------------------------------------------------------------------------*
local outcome_list l_inv_tot l_costs
local namesuffix did_io_mechanism
local mainregressorlist `harmonized_direct'
local estoutkeep "*year*hci_*"

*------------------------------------------------------------------------------*
* B. SETUP REGRESSION ANALYSIS AND RUN
*------------------------------------------------------------------------------*
local replace "replace"
capture: tempfile drop temp_regressionfile
tempfile temp_regressionfile

* Run program to automatically assign name to regressor
nameanalysisfromregressor "`mainregressorlist'"
local mainregressorlist_name "`r(resultname)'" // Assign regressor "name" for string....
assert "`mainregressorlist_name'" != "" // Test that it isn't empty
local analysis_name `namesuffix'_rolling_`mainregressorlist_name'

estimates clear

*------------------------------------------------------------------------------*
* C. LOOP THROUGH 4 AND 5 DIGIT
*------------------------------------------------------------------------------*
foreach datatype in 4 5 {
    prep_data "`dataset`datatype''"

    * i. Loop over outcomes.
    foreach outcome of local outcome_list {
        local modelnumber = 1

        * ii. Loop over sample.
        foreach restrictiondummy in 9 0 {

            

            // Regression for full sample (restrictiondummy == 9)
            if `restrictiondummy' > 1 {
                local fixedeffects `fullsampleabsorb' 
                reghdfe `outcome' ib(1972).year##c.(`mainregressorlist') , /// 
                                absorb( `fixedeffects') ///
                                vce(cluster id) verbose(0) noconstant
            }
            else {
                // Else, regression for partial samples (restrictiondummy == 0)
                local fixedeffects `partsampleabsorb' 
                reghdfe `outcome' ib(1972).year##c.(`mainregressorlist') ///
                                if hci == `restrictiondummy' , /// 
                            absorb( `fixedeffects') ///
                            vce(cluster id) verbose(0) noconstant

            }
            
            * Save results to regsave table.
            
            regsave using "`temp_regressionfile'", pval ci ///
                addlabel( outcome , `outcome', didtype, rolling, regressortype ,`mainregressorlist' , restrictions, `restrictiondummy', fixedeffects, "`fixedeffects'" , command,`e(cmd)',datatype,`datatype')  `replace'

            * ESTOUT: Save regression table, model for estout.

            * If two, tokenize and perform pre-trend test for both.
            tokenize "`mainregressorlist'"

            * FIRST, with TOKEN 1
            make_pretest_vars "`1'" "`outcome'"

            test `r(result)'
            local pre_ftest = `r(F)'
            local pre_testprob = `r(p)'

            * Add test results to estout.
            estadd scalar Fs r(F)
            estadd scalar ps r(p)

            * SECOND, with TOKEN 2
            make_pretest_vars "`2'" "`outcome'"

            test `r(result)'
            local pre_ftest = `r(F)'
            local pre_testprob = `r(p)'

            * Add test results to estout.
            estadd scalar Fs2 r(F)
            estadd scalar ps2 r(p)

            * Save regression table, model for estout.
            estimates store `outcome'`datatype'_`modelnumber'

            * Add number of clusters.
            estadd scalar N_cluster = e(N_clust)

            * MISC: Model iteration, etc.

            * Model counter.
            local modelnumber = `modelnumber' + 1

            * Replacement switch for REGSAVE.
            local replace "append"

        } // Loop over non-HCI industry sample and full sample.
    } // Loop over regression outcomes. 
} // Loop over 4 and 5-digit datasets. 

*------------------------------------------------------------------------------*
* D. SAVE REGRESSION OUTPUT: ESTOUT DATASET
*------------------------------------------------------------------------------*


estfe . *, labels(id "Industry Effects" year "Year Effects" hci#year "Targeted \(\times\) Year") 
return list

* Save ESTOUT regression table for each group of outcomes AND 4 versus 5-digit:
estout * ///
    using "./data/intermediate_datasets/`analysis_name'_allvars_`datatype'estout.csv" , ///
        replace ///
        cells(b(star fmt(a3)) se(par fmt(a3))) ///
        starlevels(* 0.10 ** 0.05 *** .01) ///
        stats(r2 N N_cluster Fs ps Fs2 ps2, fmt(3 0 0 %9.3f %9.3f %9.3f %9.3f) labels("\(R^2\)" Observations Clusters "1st Joint Test of Pre-Trend (F-Test)" "1st Joint Test of Pre-Trend (p-values)" "2nd Joint Test of Pre-Trend (F-Test)" "2nd Joint Test of Pre-Trend (p-values)")) ///
        numbers noomitted nobaselevels ///
        mlabels(none) ///
        collabels(none) ///
        indicate(`r(indicate_fe)') ///
        keep( `estoutkeep' ) 


*------------------------------------------------------------------------------*
* E. SAVE REGRESSION OUTPUT: REGSAVE DATASET
*------------------------------------------------------------------------------*

* Format and save all results for use in R.
export_reg_results `temp_regressionfile' `"./data/intermediate_datasets"' `namesuffix'


*------------------------------------------------------------------------------*
* II. LEONTIEF INPUT-OUTPUT ANALYSIS: MORE INDUSTRIAL DEVELOPMENT OUTCOMES.
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* 1. LOOP OVER DIRECT LINKS, FOR OUTCOMES ABOVE
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* A. SETUP THE ANALYSIS-LEVEL PARAMETERS/NAMES
*------------------------------------------------------------------------------*

local outcome_list l_inv_tot l_inv_eq l_costs 
local namesuffix did_iolf_mechanism
local mainregressorlist `harmonized_leontief'
local estoutkeep "*year*hci_*"

*------------------------------------------------------------------------------*
* B. SETUP REGRESSION X ANALYSIS AND RUN
*------------------------------------------------------------------------------*

// Toggle outside the loop. First time it is run.
local replace "replace"
capture: tempfile drop temp_regressionfile
tempfile temp_regressionfile

* Run program to automatically assign name to regressor
nameanalysisfromregressor "`mainregressorlist'"
local mainregressorlist_name "`r(resultname)'" // Assign regressor "name" for string....
assert "`mainregressorlist_name'" != "" // Test that it isn't empty
local analysis_name `namesuffix'_rolling_`mainregressorlist_name'

estimates clear


*------------------------------------------------------------------------------*
* C. LOOP THROUGH 4 AND 5 DIGIT
*------------------------------------------------------------------------------*
foreach datatype in 4 5 {
    prep_data "`dataset`datatype''"

    foreach outcome of local outcome_list {
        local modelnumber = 1

        foreach restrictiondummy in 9 0 {

            * a. RUN regressions.

            // Regression for full sample (restrictiondummy == 9)
            if `restrictiondummy' > 1 {
                local fixedeffects `fullsampleabsorb' 
                reghdfe `outcome' ib(1972).year##c.(`mainregressorlist') , /// 
                                absorb( `fixedeffects') ///
                                vce(cluster id) verbose(0) noconstant
            }
            else {

                // Else, regression for partial samples (restrictiondummy == 0)
                // Take out the HCI dummy. Since data is restricted to HCI or non-HCI.
                local fixedeffects `partsampleabsorb' 
                reghdfe `outcome' ib(1972).year##c.(`mainregressorlist') ///
                                if hci == `restrictiondummy' , /// 
                            absorb( `fixedeffects') ///
                            vce(cluster id) verbose(0) noconstant

            }

            * b. REGSAVE
            regsave using "`temp_regressionfile'", pval ci ///
                addlabel( outcome , `outcome', didtype, rolling, regressortype ,`mainregressorlist' , restrictions, `restrictiondummy', fixedeffects, "`fixedeffects'" , command,`e(cmd)',datatype,`datatype')  `replace'

            * c. POST REGRESSION
            tokenize "`mainregressorlist'"

            * First, with TOKEN 1
            make_pretest_vars "`1'" "`outcome'"

            test `r(result)'
            local pre_ftest = `r(F)'
            local pre_testprob = `r(p)'
            estadd scalar Fs r(F)
            estadd scalar ps r(p)

            * Second, with TOKEN 2
            make_pretest_vars "`2'" "`outcome'"

            test `r(result)'
            local pre_ftest = `r(F)'
            local pre_testprob = `r(p)'
            estadd scalar Fs2 r(F)
            estadd scalar ps2 r(p)
            estimates store `outcome'`datatype'_`modelnumber'
            estadd scalar N_cluster = e(N_clust)

            local modelnumber = `modelnumber' + 1
            local replace "append"

        } // Loop over non-HCI industry sample and full sample.
    } // Loop over regression outcomes. 
} // Loop over 4 and 5-digit datasets. 

*------------------------------------------------------------------------------*
* D. SAVE REGRESSION OUTPUT: ESTOUT DATASET
*------------------------------------------------------------------------------*
estfe . *, labels(id "Industry Effects" year "Year Effects" hci#year "Targeted \(\times\) Year") 
return list
estout * ///
    using "./data/intermediate_datasets/`analysis_name'_allvars_`datatype'estout.csv" , ///
        replace ///
        cells(b(star fmt(a3)) se(par fmt(a3))) ///
        starlevels(* 0.10 ** 0.05 *** .01) ///
        stats(r2 N N_cluster Fs ps Fs2 ps2, fmt(3 0 0 %9.3f %9.3f %9.3f %9.3f) labels("\(R^2\)" Observations Clusters "1st Joint Test of Pre-Trend (F-Test)" "1st Joint Test of Pre-Trend (p-values)" "2nd Joint Test of Pre-Trend (F-Test)" "2nd Joint Test of Pre-Trend (p-values)")) ///
        numbers noomitted nobaselevels ///
        mlabels(none) ///
        collabels(none) ///
        indicate(`r(indicate_fe)') ///
        keep( `estoutkeep' ) 

*------------------------------------------------------------------------------*
* E. SAVE REGRESSION OUTPUT: REGSAVE DATASET
*------------------------------------------------------------------------------*
export_reg_results `temp_regressionfile' `"./data/intermediate_datasets"' `namesuffix'
