*------------------------------------------------------------------------------*
* What this does:
*   Performs an alternative linkage analysis for SUTVA (Stable Unit Treatment
*   Value Assumption) robustness checks.
*   Key difference from main linkage analysis:
*   - HCI (Heavy Chemical Industry policy) is NOT absorbed as a fixed effect.
*   - Linkage interaction terms ARE absorbed as fixed effects.
*   This design aims to show the robustness of HCI estimates.
*
* Inputs:
*   - "./data/input/mms_merged_harmonized_panel_cleaned4reg_5digit.dta"
*   - "./data/input/mms_merged_harmonized_panel_cleaned4reg_4digit.dta"
*
* Outputs:
*   Generates various regression output files, typically starting with prefixes:
*   - did_io_limitexposure...
*   - did_iolf_limitexposure...
*   - did_io_downonly_sutva...
*   - did_iolf_downonly_sutva...
*   - did_io_sutva...
*   - did_iolf_sutva...
*   - did_io_crowdingout...
*
* Dependencies:
*   - X_MMS_digitized_prepare_foranalysis_5digit ...do
*   - X_MMS_digitized_prepare_foranalysis_4digit ...do
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

capture program drop prep_data_nonhci
program define prep_data_nonhci

	args filenameargument 
	use "`filenameargument'", clear 
	capture: drop post
	gen post = 0 
	replace post = 1 if year >= 1973

	* Linkages for non-HCI
	gen nonhci = (hci != 1)
	local linkagelist lf_hci_link_use_0 lf_hci_link_make_0 hci_share_use_tot_0 hci_share_make_tot_0
	foreach linkage of local linkagelist  {
		replace `linkage'=`linkage'*nonhci
	}
    xtset id year
end

capture program drop nameanalysisfromregressor
program define nameanalysisfromregressor, rclass

	* Pass strings
	args listofregressorstotest 

	* Either links have both directions....
	if regexm("`listofregressorstotest'" , "make|out" ) == 1 & regexm("`listofregressorstotest'" , "use|in" ) == 1 {
		* Has both variables:
		local regressornamestring bothlink
	} // OR ... ONLY make OR use.
	else {
		* If only OUT/MAKE (backward transmission, hci -> upstream makers
		if regexm("`listofregressorstotest'" , "make|out" ) == 1 {
			* Has both variables:
			local regressornamestring backlink
		}
		* If only IN/USE (forward transmission) hci -> downstream users
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


* Program for saving regression dumps.
capture program drop export_reg_results
program define export_reg_results, rclass

	* Pass locals
	args temp_regressionfile regressiondir namesuffix temp_regressionfile2

	* Format and outsheet results for use in PivotTable
	use "`temp_regressionfile'", clear

	* If tempfile exists, add it.
	capture confirm file "`temp_regressionfile2'"
	display "is `temp_regressionfile2' present ? " (_rc == 0)
	if _rc == 1 {
		append using "`temp_regressionfile2'", force
	}

	* Capture junk lines, all zeros.
	capture: drop if regexm( var, "^[0-9][0-9][0-9][0-9]o.year" ) == 1
	capture: drop if regexm( var, "^o.hci" ) == 1
	capture: drop if regexm( var, "0b.post" ) == 1
	capture: drop if regexm( var, "1o.post" ) == 1

	* Clean-up output for R.	
	replace fixedeffects = "Main Effect + Links x Year" if regexm( fixedeffects, "fullcontrolsabsorb") == 1
	replace fixedeffects = "Main Effect + Links x Post" if regexm( fixedeffects, "controlsabsorb") == 1
	replace fixedeffects = "Main Effect" if regexm( fixedeffects, "basesabsorb") == 1

	* Rename constraint strings for R plotting.
	capture: replace constraints = "Restricting to low downstream exposure" if ///
									regexm( constraints, "lowuse") == 1
	capture: replace constraints = "Restricting to low upstream exposure" if ///
									regexm( constraints, "lowmake") == 1
	capture: replace constraints = "No restrictions" if ///
									constraints == "" | missing( constraints )

	* Rename 4-digit and 5-digit labels.
	capture: tostring datatype, replace
	capture: replace datatype = "5-Digit Panel" if ///
									regexm( datatype, "5") == 1	
	capture: replace datatype = "4-Digit Panel" if ///
									regexm( datatype, "4") == 1
	* Clean linkage regressor types. 
	capture: replace regressortype = "use" if ///
							regexm( regressortype, "use|in" ) == 1 & ///
							regexm( regressortype, "make|out" ) != 1
	capture: replace regressortype = "make" if ///
							regexm( regressortype, "use|in" ) != 1 & ///
							regexm( regressortype, "make|out" ) == 1
	capture: replace regressortype = "both" if ///
							regexm( regressortype, "use|in" ) == 1 & ///
							regexm( regressortype, "make|out" ) == 1

	* Clean sample restriction types. 
	capture: gen restrictiontype = "nonhci" if restrictions == 0
	capture: replace restrictiontype = "hci" if restrictions == 1
	capture: replace restrictiontype = "all" if restrictions == 9

	* Clean sample control type. 
	capture: replace controltype = "none" if controltype == "" | missing(controltype)
	capture: replace controltype = "Main Effect + Links x Post" if ///
							regexm( controltype, "i.post") == 1
	capture: replace controltype = "Main Effect + Links x Trend" if ///
							regexm( controltype, "c.t") == 1

	* Clean sample constraint type.
	capture: replace constrainttype = "none" if controltype == "" | missing(controltype)
	capture: replace constrainttype = "Main Effect + Links x Post" if ///
							regexm( controltype, "i.post") == 1
	capture: replace constrainttype = "Main Effect + Links x Trend" if ///
							regexm( controltype, "c.t") == 1

	* Save the regsave dump.
	outsheet using ///
			"./data/intermediate_datasets/`namesuffix'_all_results.csv", ///
			comma replace	

	* Clean up the file for next run.
	capture: tempfile drop temp_regressionfile
	tempfile temp_regressionfile
end

* Program for saving regression dumps.
capture program drop makeexposureindicator
program define makeexposureindicator, rclass
	
	* Arguments v1 v2
	args usevar makevar
	
	* A. Make forward indicator.
	quietly: sum `usevar' if hci == 0, detail 
	capture: drop hci_io_lowuse_plus_hci
	gen hci_io_lowuse_plus_hci = 0 
	replace hci_io_lowuse_plus_hci = 1 if ///
				( hci == 0 & `usevar' <= `r(p50)' ) | hci == 1

	* B. Make backward indicator.
	quietly: sum `makevar' if hci == 0, detail 
	capture: drop hci_io_lowmake_plus_hci
	gen hci_io_lowmake_plus_hci = 0 
	replace hci_io_lowmake_plus_hci = 1 if ///
			( hci == 0 & `makevar' <= `r(p50)' ) | hci == 1		
end 

* Program for pre-treatment capital:
capture program drop makepretreatmentcapital
program define makepretreatmentcapital, rclass
	* Generate pre-treatment capital.
	gen temp_k_intensity = stock_tot/workers if year <= 1972
	bysort id: egen k_intensity = max(temp_k_intensity)
	gen h_k_intensity = asinh( k_intensity )
	gen l_k_intensity = ln( k_intensity + 1)

end 

*------------------------------------------------------------------------------*
* MAIN
*------------------------------------------------------------------------------*
* Arguments
local dataset5 "./data/input/mms_merged_harmonized_panel_cleaned4reg_5digit.dta"
local dataset4 "./data/input/mms_merged_harmonized_panel_cleaned4reg_4digit.dta"
set showomitted off 
set showemptycells off
set showbaselevels off 
local estoutkeep_rolling "*year*hci*"

*------------------------------------------------------------------------------*
* I. MAIN SUTVA/IO ANALYSIS: SUTVA VIA EXPOSURE.
*------------------------------------------------------------------------------*

* Common arguments
local did_rolling ib(1972).year 
local harmonized_direct `""hci_share_use_tot_0 hci_share_make_tot_0""'
local harmonized_leontief `""lf_hci_link_use_0 lf_hci_link_make_0""'
local outcome_list l_ship l_y_n

*------------------------------------------------------------------------------*
* 1. LOOP OVER DIRECT LINKS, FOR OUTCOMES ABOVE
*------------------------------------------------------------------------------*

* A. SETUP THE ANALYSIS-LEVEL PARAMETERS/NAMES. *********

* Analysis name suffix (for output file).
local namesuffix did_io_limitexposure
local restrictiondummy = 9 // Backwards compatibility
local replace "replace"

capture: tempfile drop temp_regressionfile
tempfile temp_regressionfile

* B. RUN REGRESSION ANALYSIS.
local analysis_name `namesuffix'_rolling
local estoutkeep "`estoutkeep_rolling'"

* i. Loop over 4 and 5-digit data.
foreach datatype in 4 5 {
    prep_data "`dataset`datatype''"
    makeexposureindicator hci_share_use_tot_0 hci_share_make_tot_0

    * ii. Loop over outcomes. 
    foreach outcome of local outcome_list {
        local modelnumber = 1

        * iv. Loop over constraints.
        foreach constraints in "" "if hci_io_lowuse_plus_hci == 1" "if hci_io_lowmake_plus_hci == 1" {

            * v. Run regression.
            reghdfe `outcome' ib(1972).year##i.hci `constraints', ///
                        absorb( id year ) ///
                    vce(cluster id) /// 
                    verbose(0) ///
                    noconstant ///
                    vsquish

            * vi. Save regression output.
            regsave using "`temp_regressionfile'", pval ci ///
                addlabel( outcome , `outcome',  didtype, rolling , restrictions, `restrictiondummy', fixedeffects, "id year", command,`e(cmd)',datatype,`datatype', constraints, "`constraints'")  `replace'

            * Save regression table, model for estout.
            estimates store `outcome'_`modelnumber'
            estadd scalar N_cluster = e(N_clust)
            local modelnumber = `modelnumber' + 1

            local replace "append"
        } // Loop over constraints.

        * vii. Save regression output: estout dataset.
        estfe . `outcome'_*, labels(id "Industry Effects" year "Year Effects") 
        return list
        estout `outcome'_* ///
            using "./data/intermediate_datasets/`analysis_name'_`outcome'_`datatype'estout.csv" , ///
                replace ///
                cells(b(star fmt(a3)) se(par fmt(a3))) ///
                starlevels(* 0.10 ** 0.05 *** .01) ///
                stats(r2 N N_cluster, fmt(3 0 0) labels("\(R^2\)" Observations Clusters)) ///
                numbers collabels(none) ///
                indicate(`r(indicate_fe)') ///
                keep( `estoutkeep' ) 
    } // Loop over outcomes.
} // Loop over 4 or 5-digit datasets.

* C. SAVE REGRESSION OUTPUT: REGSAVE DATASET.
export_reg_results `temp_regressionfile' `"./data/intermediate_datasets"' `namesuffix'


*------------------------------------------------------------------------------*
* 2. LOOP OVER TOTAL LINKS, FOR OUTCOMES ABOVE
*------------------------------------------------------------------------------*

* A. SETUP THE ANALYSIS-LEVEL PARAMETERS/NAMES.

local namesuffix did_iolf_limitexposure
local restrictiondummy = 9 // Backwards compatibility.
local replace "replace"
capture: tempfile drop temp_regressionfile
tempfile temp_regressionfile


* B. RUN REGRESSION ANALYSIS.
local analysis_name `namesuffix'_rolling
local estoutkeep "`estoutkeep_rolling'"

* i. Loop over 4 and 5-digit data.
foreach datatype in 4 5 {
    prep_data "`dataset`datatype''"
    makeexposureindicator lf_hci_link_use_0 lf_hci_link_make_0

    * ii. Loop over outcomes. 
    foreach outcome of local outcome_list {
        local modelnumber = 1

        * iii. Loop over constraints.
        foreach constraints in "" "if hci_io_lowuse_plus_hci == 1" "if hci_io_lowmake_plus_hci == 1" {

            * iv. Run regression.
            reghdfe `outcome' ib(1972).year##i.hci `constraints', ///
                        absorb( id year ) ///
                    vce(cluster id) ///
                    verbose(0) ///
                    noconstant ///
                    vsquish
                    

            * v. Save results to regsave table.
            regsave using "`temp_regressionfile'", pval ci ///
                addlabel( outcome , `outcome',  didtype, rolling , restrictions, `restrictiondummy', fixedeffects, "id year", command,`e(cmd)',datatype,`datatype', constraints, "`constraints'")  `replace'

            * Save regression table, model for estout.
            estimates store `outcome'_`modelnumber'
            estadd scalar N_cluster = e(N_clust)
            local modelnumber = `modelnumber' + 1
            local replace "append"

        } // Loop over constraints.

        * vi. Save regression output: estout dataset.
        estfe . `outcome'_*, labels(id "Industry Effects" year "Year Effects") 
        return list
        estout `outcome'_* ///
            using "./data/intermediate_datasets/`analysis_name'_`outcome'_`datatype'estout.csv" , ///
                replace ///
                cells(b(star fmt(a3)) se(par fmt(a3))) ///
                starlevels(* 0.10 ** 0.05 *** .01) ///
                stats(r2 N N_cluster , fmt(3 0 0) labels("\(R^2\)" Observations Clusters)) ///
                numbers collabels(none) ///
                indicate(`r(indicate_fe)') ///
                keep( `estoutkeep' ) 
    } // Loop over outcomes.
} // Loop over 4- or 5-digit datasets.

* C. SAVE REGRESSION OUTPUT: REGSAVE DATASET.
export_reg_results `temp_regressionfile' `"./data/intermediate_datasets"' `namesuffix'


*------------------------------------------------------------------------------*
* II. SUTVA/IO ANALYSIS: SUTVA VIA WITH IO DOWNSTREAM CONTROLS ONLY.
*------------------------------------------------------------------------------*
local outcome l_ship
*------------------------------------------------------------------------------*
* 1. LOOP OVER DIRECT LINKS, FOR REGS WITH IO CONTROLS.
*------------------------------------------------------------------------------*

* A. SETUP THE ANALYSIS-LEVEL PARAMETERS/NAMES.
local namesuffix did_io_downonly_sutva
capture: tempfile drop temp_regressionfile
tempfile temp_regressionfile
local replace "replace"

* B. RUN REGRESSION ANALYSIS.
local analysis_name `namesuffix'_rolling

* i. Loop over 4 and 5-digit data.
foreach datatype in 4 5 {

    * Estout/regsave arguments for rolling regression.
    local estoutkeep "`estoutkeep_rolling'"
    local didinteraction "`did_rolling'"
    prep_data_nonhci "`dataset`datatype''"
    local modelnumber = 1

    * ii. Loop over control types.
    foreach control_set in "" "#i.post" {

        * iii. Run regression.
        reghdfe `outcome' `didinteraction'##i.hci ///
                c.(hci_share_use_tot_0)`control_set', ///
                    absorb( id year ) ///
                vce(cluster id) ///
                verbose(0) ///
                noconstant ///
                vsquish
                

        * iv. Save regression output.
        regsave using "`temp_regressionfile'", pval ci ///
            addlabel( outcome , `outcome',  didtype, rolling , restrictions, `restrictiondummy', fixedeffects, "id year", command,`e(cmd)',datatype,`datatype', controltype, "`control_set'")  `replace'

        * v. Save regression table, model for estout.
        estimates store `outcome'_`modelnumber'
        estadd scalar N_cluster = e(N_clust)
        local modelnumber = `modelnumber' + 1
        local replace "append"

    } // Loop over control types.

    * vi. Save regression output: estout dataset.
    estfe . `outcome'_*, labels(id "Industry Effects" year "Year Effects") 
    return list

    * Save estout regression table for each group of outcomes AND 4 versus 5-digit:
    estout `outcome'_* ///
        using "./data/intermediate_datasets/`analysis_name'_`outcome'_`datatype'estout.csv" , ///
            replace ///
            cells(b(star fmt(a3)) se(par fmt(a3))) ///
            starlevels(* 0.10 ** 0.05 *** .01) ///
            stats(r2 N N_cluster, fmt(3 0 0) labels("\(R^2\)" Observations Clusters)) ///
            numbers collabels(none) ///
            indicate(`r(indicate_fe)') ///
            keep( `estoutkeep' ) 
} // Loop over 4- or 5-digit datasets.

* C. Save regression output: regsave dataset.
export_reg_results `temp_regressionfile' `"./data/intermediate_datasets"' `namesuffix'

*------------------------------------------------------------------------------*
* 2. LOOP OVER TOTAL LINKS. 
*------------------------------------------------------------------------------*

* A. SETUP THE ANALYSIS-LEVEL PARAMETERS/NAMES.
local namesuffix did_iolf_downonly_sutva
capture: tempfile drop temp_regressionfile
tempfile temp_regressionfile
local replace "replace"

* B. RUN REGRESSION ANALYSIS.
local analysis_name `namesuffix'_rolling

* i. Loop over 4 and 5-digit data.
foreach datatype in 4 5 {

    local estoutkeep "`estoutkeep_rolling'"
    local didinteraction "`did_rolling'"
    
    prep_data_nonhci "`dataset`datatype''"

    * ii. Loop over outcomes. 
    foreach outcome of local outcome_list {
        local modelnumber = 1

        * iii. Loop over control types.
        foreach control_set in "" "#i.post" {

            * iv. Run regression.
            reghdfe `outcome' `didinteraction'##i.hci ///
                    c.(hci_share_use_tot_0)`control_set', ///
                        absorb( id year ) ///
                    vce(cluster id) ///
                    verbose(0) ///
                    noconstant ///
                    vsquish
                    

            * v. Save regression output.
            regsave using "`temp_regressionfile'", pval ci ///
                addlabel( outcome , `outcome',  didtype, rolling , restrictions, `restrictiondummy', fixedeffects, "id year", command,`e(cmd)',datatype,`datatype', controltype, "`control_set'")  `replace'

            * vi. Save regression table, model for estout.
            estimates store `outcome'_`modelnumber'
            estadd scalar N_cluster = e(N_clust)
            local modelnumber = `modelnumber' + 1
            local replace "append"

        } // Loop over control types.

        * vi. Save regression output: estout dataset.
        estfe . `outcome'_*, labels(id "Industry Effects" year "Year Effects") 
        return list
        estout `outcome'_* ///
            using "./data/intermediate_datasets/`analysis_name'_`outcome'_`datatype'estout.csv" , ///
                replace ///
                cells(b(star fmt(a3)) se(par fmt(a3))) ///
                starlevels(* 0.10 ** 0.05 *** .01) ///
                stats(r2 N N_cluster, fmt(3 0 0) labels("\(R^2\)" Observations Clusters)) ///
                numbers collabels(none) ///
                indicate(`r(indicate_fe)') ///
                keep( `estoutkeep' ) 
    } // Loop over outcomes.
} // Loop over 4- or 5-digit datasets.

* C. Save regression output: regsave dataset.
export_reg_results `temp_regressionfile' `"./data/intermediate_datasets"' `namesuffix'

*------------------------------------------------------------------------------*
* III. SUTVA/IO ANALYSIS: SUTVA
*------------------------------------------------------------------------------*
local outcome l_ship 
*------------------------------------------------------------------------------*
* 1. LOOP OVER DIRECT LINKS, FOR REGS WITH IO CONTROLS.
*------------------------------------------------------------------------------*

* A. SETUP THE ANALYSIS-LEVEL PARAMETERS/NAMES.
local namesuffix did_io_sutva
capture: tempfile drop temp_regressionfile
tempfile temp_regressionfile
local replace "replace"

* B. RUN REGRESSION ANALYSIS.
local analysis_name `namesuffix'_rolling
local estoutkeep "`estoutkeep_rolling'"

* i. Loop over 4 and 5-digit data.
foreach datatype in 4 5 {
    prep_data_nonhci "`dataset`datatype''"

    * ii. Loop over outcomes. 
    foreach outcome of local outcome_list {
        local modelnumber = 1

        * iii. Regression interaction: none and post
        foreach control_set in "" "#i.post" {
            reghdfe `outcome' ib(1972).year##i.hci ///
                    c.(hci_share_use_tot_0 hci_share_make_tot_0)`control_set', ///
                        absorb( id year ) ///
                    vce(cluster id) ///
                    verbose(0) ///
                    noconstant ///
                    vsquish
                    

            * iv. Save results to regsave table.
            regsave using "`temp_regressionfile'", pval ci ///
                addlabel( outcome , `outcome',  didtype, rolling , restrictions, `restrictiondummy', fixedeffects, "id year", command,`e(cmd)',datatype,`datatype', controltype, "`control_set'")  `replace'

            * v. Save regression table, model for estout.
            estimates store `outcome'_`modelnumber'
            estadd scalar N_cluster = e(N_clust)
            local modelnumber = `modelnumber' + 1
            local replace "append"

        } // Loop over control sets.

        * vi. Save regression output: estout dataset.
        estfe . `outcome'_*, labels(id "Industry Effects" year "Year Effects") 
        return list
        estout `outcome'_* ///
            using "./data/intermediate_datasets/`analysis_name'_`outcome'_`datatype'estout.csv" , ///
                replace ///
                cells(b(star fmt(a3)) se(par fmt(a3))) ///
                starlevels(* 0.10 ** 0.05 *** .01) ///
                stats(r2 N N_cluster , fmt(3 0 0) labels("\(R^2\)" Observations Clusters)) ///
                numbers collabels(none) ///
                indicate(`r(indicate_fe)') ///
                keep( `estoutkeep' ) 
    } // Loop over outcomes.
} // Loop over 4- or 5-digit datasets.

* C. SAVE REGRESSION OUTPUT: REGSAVE DATASET.
export_reg_results `temp_regressionfile' `"./data/intermediate_datasets"' `namesuffix'

*------------------------------------------------------------------------------*
* 2. LOOP OVER TOTAL LINKS, FOR REGS WITH TOTAL IO CONTROLS. 
*------------------------------------------------------------------------------*

* A. SETUP THE ANALYSIS-LEVEL PARAMETERS/NAMES.
local namesuffix did_iolf_sutva
capture: tempfile drop temp_regressionfile
tempfile temp_regressionfile
local replace "replace"

* B. RUN REGRESSION ANALYSIS.
local analysis_name `namesuffix'_rolling

* i. Loop over 4 and 5-digit data.
foreach datatype in 4 5 {
    local estoutkeep "`estoutkeep_rolling'"
    prep_data_nonhci "`dataset`datatype''"

    * ii. Loop over outcomes. 
    foreach outcome of local outcome_list {
        local modelnumber = 1

        * iii. Regression interaction: none and post.
        foreach control_set in "" "#i.post" {

            * iv. Run regression.
            reghdfe `outcome' ib(1972).year##i.hci ///
                    c.(hci_share_use_tot_0 hci_share_make_tot_0)`control_set', ///
                        absorb( id year ) ///
                    vce(cluster id) ///
                    verbose(0) ///
                    noconstant ///
                    vsquish
                    

            * v. Save results to regsave table.
            regsave using "`temp_regressionfile'", pval ci ///
                addlabel( outcome , `outcome',  didtype, rolling , restrictions, `restrictiondummy', fixedeffects, "id year", command,`e(cmd)',datatype,`datatype', controltype, "`control_set'")  `replace'

            * vi. Save regression table, model for estout.
            estimates store `outcome'_`modelnumber'
            estadd scalar N_cluster = e(N_clust)
            local modelnumber = `modelnumber' + 1
            local replace "append"

        } // Loop over control sets.

        * vii. Save regression output: estout dataset.
        estfe . `outcome'_*, labels(id "Industry Effects" year "Year Effects") 
        return list
        estout `outcome'_* ///
            using "./data/intermediate_datasets/`analysis_name'_`outcome'_`datatype'estout.csv" , ///
                replace ///
                cells(b(star fmt(a3)) se(par fmt(a3))) ///
                starlevels(* 0.10 ** 0.05 *** .01) ///
                stats(r2 N N_cluster, fmt(3 0 0) labels("\(R^2\)" Observations Clusters)) ///
                numbers collabels(none) ///
                indicate(`r(indicate_fe)') ///
                keep( `estoutkeep' ) 
    } // Loop over outcomes.
} // Loop over 4- or 5-digit datasets.

* C. SAVE REGRESSION OUTPUT: REGSAVE DATASET.
export_reg_results `temp_regressionfile' `"./data/intermediate_datasets"' `namesuffix'


*------------------------------------------------------------------------------*
* IV. SUTVA/IO ANALYSIS: SUTVA VIA WITH CAPITAL INV. 
*------------------------------------------------------------------------------*

* Outcome list for ENTIRE part I. 
local outcome l_inv_tot

* Arguments for estoutkeep.
local estoutkeep_rolling "1*year*"
local controlsabsorb "id year c.(hci_share_use_tot_0 hci_share_make_tot_0)#i.post"
local fullcontrolsabsorb "id year c.(hci_share_use_tot_0 hci_share_make_tot_0)#i.year"

* A. SETUP THE ANALYSIS-LEVEL PARAMETERS/NAMES. 
local namesuffix did_io_crowdingout
capture: tempfile drop temp_regressionfile
tempfile temp_regressionfile
local replace "replace"

* B. RUN REGRESSION ANALYSIS.

* i. Setup loop 
local analysis_name `namesuffix'_rolling
local estoutkeep "`estoutkeep_rolling'"
local didinteraction "`did_rolling'"

prep_data "`dataset5'"
local modelnumber = 1

* ii. Loop over constraints.
foreach constrainttype in "if hci == 1" "if hci == 0" {

    * iii. Loop over FE and control sets.
    foreach fes in "controlsabsorb" "fullcontrolsabsorb" {

        * iv. Run regression.
        reghdfe `outcome' `didinteraction'##c.(l_k_intensity) ///
                `constrainttype' , ///
                    absorb( id year ) ///
                vce(cluster id) ///
                verbose(0) ///
                noconstant ///
                vsquish
                

        * v. Save results to regsave table.
        regsave using "`temp_regressionfile'", pval ci ///
            addlabel( outcome , `outcome',  didtype, rolling , restrictions, `restrictiondummy', fixedeffects, "`fes'", command,`e(cmd)', constrainttype, "`constrainttype'")  `replace'

        * vi. Save regression table, model for estout.
        estimates store `outcome'_`modelnumber'
        estadd scalar N_cluster = e(N_clust)
        local modelnumber = `modelnumber' + 1
        local replace "append"
    } // Loop over the different FE/controls.
} // Loop over constraints.

* vi. Save regression output: estout dataset.
estfe . `outcome'_*, labels(id "Industry Effects" year "Year Effects") 
return list
estout `outcome'_* ///
	using "./data/intermediate_datasets/`analysis_name'_`outcome'_5estout.csv" , ///
		replace ///
		cells(b(star fmt(a3)) se(par fmt(a3))) ///
		starlevels(* 0.10 ** 0.05 *** .01) ///
		stats(r2 N N_cluster, fmt(3 0 0) labels("\(R^2\)" Observations Clusters)) ///
		numbers collabels(none) ///
		indicate(`r(indicate_fe)') ///
		keep( `estoutkeep' ) 

* C. SAVE REGRESSION OUTPUT: REGSAVE DATASET.
export_reg_results `temp_regressionfile' `"./data/intermediate_datasets"' `namesuffix'
